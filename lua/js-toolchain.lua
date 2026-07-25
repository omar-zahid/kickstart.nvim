--- Detects which JavaScript/TypeScript toolchain a file belongs to.
---
--- Projects in the wild fall into two families that must never be mixed:
---   * Oxc      -> oxlint (lint) + oxfmt (format)
---   * Legacy   -> eslint (lint) + prettier (format)
---
--- Vite+ counts as an Oxc project because it configures Oxlint/Oxfmt through its
--- own `vite.config.ts`. Oxc itself does not depend on Vite+, so standalone
--- `.oxlintrc.json` / `oxfmt.config.*` / dependencies are detected as well.
local M = {}

---@class js-toolchain.Spec
---@field files string[] Config files that mark the root.
---@field field string? `package.json` key that marks the root.
---@field deps string[] `package.json` dependencies that mark the root.
---@field embedded boolean? Also treat a `vite-plus` Vite config as a marker.

---@type table<string, js-toolchain.Spec>
local specs = {
  oxc = {
    files = {
      '.oxlintrc.json',
      '.oxlintrc.jsonc',
      '.oxfmtrc.json',
      '.oxfmtrc.jsonc',
      'oxfmt.config.js',
      'oxfmt.config.mjs',
      'oxfmt.config.cjs',
      'oxfmt.config.ts',
      'oxfmt.config.mts',
      'oxfmt.config.cts',
    },
    field = 'oxlint',
    deps = { 'oxlint', 'oxfmt', 'vite-plus' },
    embedded = true,
  },
  prettier = {
    files = {
      '.prettierrc',
      '.prettierrc.json',
      '.prettierrc.json5',
      '.prettierrc.yaml',
      '.prettierrc.yml',
      '.prettierrc.js',
      '.prettierrc.cjs',
      '.prettierrc.mjs',
      '.prettierrc.ts',
      '.prettierrc.cts',
      '.prettierrc.mts',
      'prettier.config.js',
      'prettier.config.cjs',
      'prettier.config.mjs',
      'prettier.config.ts',
      'prettier.config.cts',
      'prettier.config.mts',
    },
    field = 'prettier',
    deps = { 'prettier', 'prettierd' },
  },
  eslint = {
    files = {
      'eslint.config.js',
      'eslint.config.mjs',
      'eslint.config.cjs',
      'eslint.config.ts',
      'eslint.config.mts',
      'eslint.config.cts',
      '.eslintrc',
      '.eslintrc.js',
      '.eslintrc.cjs',
      '.eslintrc.json',
      '.eslintrc.yaml',
      '.eslintrc.yml',
    },
    field = 'eslintConfig',
    deps = { 'eslint' },
  },
}

local vite_configs = {
  'vite.config.js',
  'vite.config.mjs',
  'vite.config.cjs',
  'vite.config.ts',
  'vite.config.mts',
  'vite.config.cts',
}

--- Resolution walks the tree on every save, so memoize per directory.
---@type table<string, table<string, string|false>>
local cache = {}

---@param path string
---@return string?
local function read(path)
  local fd = io.open(path, 'r')
  if not fd then
    return nil
  end
  local content = fd:read '*a'
  fd:close()
  return content
end

---@param dir string
---@return table?
local function package_json(dir)
  local content = read(vim.fs.joinpath(dir, 'package.json'))
  if not content then
    return nil
  end
  local ok, package = pcall(vim.json.decode, content)
  return (ok and type(package) == 'table') and package or nil
end

---@param package table
---@param names string[]
---@return boolean
local function has_dep(package, names)
  for _, section in ipairs { 'dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies' } do
    local deps = package[section]
    if type(deps) == 'table' then
      for _, name in ipairs(names) do
        if deps[name] then
          return true
        end
      end
    end
  end
  return false
end

---@param dir string
---@return boolean
local function has_vite_plus(dir)
  for _, name in ipairs(vite_configs) do
    local content = read(vim.fs.joinpath(dir, name))
    if content and content:find 'vite%-plus' then
      return true
    end
  end
  return false
end

---@param dir string
---@param spec js-toolchain.Spec
---@return boolean
local function matches(dir, spec)
  for _, name in ipairs(spec.files) do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, name)) then
      return true
    end
  end
  if spec.embedded and has_vite_plus(dir) then
    return true
  end
  local package = package_json(dir)
  if package and (package[spec.field] ~= nil or has_dep(package, spec.deps)) then
    return true
  end
  return false
end

---@param path string?
---@return string
local function start_dir(path)
  path = (path and path ~= '') and vim.fs.normalize(path) or assert(vim.uv.cwd())
  local stat = vim.uv.fs_stat(path)
  return (stat and stat.type == 'directory') and path or vim.fs.dirname(path)
end

--- Nearest ancestor directory configured for `kind`.
---@param kind 'oxc'|'prettier'|'eslint'
---@param path string?
---@return string?
function M.root(kind, path)
  local dir = start_dir(path)
  cache[kind] = cache[kind] or {}
  local cached = cache[kind][dir]
  if cached ~= nil then
    return cached or nil
  end

  local found ---@type string?
  for current in vim.fs.parents(vim.fs.joinpath(dir, 'x')) do
    if matches(current, specs[kind]) then
      found = current
      break
    end
  end

  cache[kind][dir] = found or false
  return found
end

--- Deepest of two roots wins, so nested projects override their parent.
---@param a string?
---@param b string?
---@return string?
local function nearest(a, b)
  if a and (not b or #a >= #b) then
    return a
  end
  return b
end

--- Formatter Conform should run for `path`.
---@param path string?
---@return 'oxfmt'|'prettier'
---@return string? root
function M.formatter(path)
  local oxc, prettier = M.root('oxc', path), M.root('prettier', path)
  local winner = nearest(oxc, prettier)
  if winner and winner == oxc then
    return 'oxfmt', oxc
  end
  return 'prettier', prettier
end

--- Language server that should lint `path`, if any.
---@param path string?
---@return 'oxlint'|'eslint'|nil
---@return string? root
function M.linter(path)
  local oxc, eslint = M.root('oxc', path), M.root('eslint', path)
  local winner = nearest(oxc, eslint)
  if not winner then
    return nil, nil
  end
  if winner == oxc then
    return 'oxlint', oxc
  end
  return 'eslint', eslint
end

--- Drop memoized results (config files may have been added or removed).
function M.reset()
  cache = {}
end

return M
