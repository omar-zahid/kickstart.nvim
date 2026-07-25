local M = {}

local oxc_files = {
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
}

local prettier_files = {
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
}

local eslint_files = {
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
}

local vite_files = {
  'vite.config.js',
  'vite.config.mjs',
  'vite.config.cjs',
  'vite.config.ts',
  'vite.config.mts',
  'vite.config.cts',
}

local function read(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  local content = file:read '*a'
  file:close()
  return content
end

local function package_json(dir)
  local content = read(vim.fs.joinpath(dir, 'package.json'))
  if not content then
    return nil
  end
  local ok, package = pcall(vim.json.decode, content)
  return ok and type(package) == 'table' and package or nil
end

local function has_dependency(package, names)
  for _, section in ipairs { 'dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies' } do
    local dependencies = package and package[section] or {}
    for _, name in ipairs(names) do
      if dependencies[name] then
        return true
      end
    end
  end
  return false
end

local function start_dir(path)
  path = path and path ~= '' and vim.fs.normalize(path) or vim.uv.cwd()
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == 'directory' and path or vim.fs.dirname(path)
end

local function find_root(path, files, package_field, dependencies, check_vite_plus)
  local dir = start_dir(path)
  while dir do
    for _, name in ipairs(files) do
      if vim.uv.fs_stat(vim.fs.joinpath(dir, name)) then
        return dir
      end
    end
    if check_vite_plus then
      for _, name in ipairs(vite_files) do
        local content = read(vim.fs.joinpath(dir, name))
        if content and content:find 'vite%-plus' then
          return dir
        end
      end
    end
    local package = package_json(dir)
    if package and (package[package_field] ~= nil or has_dependency(package, dependencies)) then
      return dir
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
end

function M.oxc_root(path)
  return find_root(path, oxc_files, 'oxlint', { 'vite-plus', 'oxfmt', 'oxlint' }, true)
end

function M.prettier_root(path)
  return find_root(path, prettier_files, 'prettier', { 'prettier', 'prettierd' }, false)
end

function M.eslint_root(path)
  return find_root(path, eslint_files, 'eslintConfig', { 'eslint', 'eslint_d' }, false)
end

local function nearest(first, second)
  if first and (not second or #first >= #second) then
    return first
  end
  return second
end

function M.formatter(path)
  local oxc = M.oxc_root(path)
  local prettier = M.prettier_root(path)
  return nearest(oxc, prettier) == oxc and oxc and 'oxfmt' or 'prettier'
end

function M.linter(path)
  local oxc = M.oxc_root(path)
  local eslint = M.eslint_root(path)
  if nearest(oxc, eslint) == oxc and oxc then
    return 'oxlint', oxc
  end
  if eslint then
    return 'eslint_d', eslint
  end
end

return M
