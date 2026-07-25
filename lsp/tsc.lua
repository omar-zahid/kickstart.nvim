--- TypeScript 7 native language server (the Go port, shipped as `tsc`).
---
--- `tsc --lsp` only exists in TypeScript >= 7. Projects pinned to TypeScript 6
--- or older ship a `tsc` that rejects `--lsp`, so the project-local binary is
--- only used when it is new enough; otherwise the global `tsc` is used. Its
--- checker is documented to produce the same errors as TypeScript 6.0, so it
--- serves older projects correctly.
---
--- `root_dir` mirrors `nvim-lspconfig/lsp/tsgo.lua`: the project root is the
--- nearest package-manager lockfile, and Deno projects are declined so that
--- `denols` owns them instead.

---@param dir string
---@return integer?
local function local_ts_major(dir)
  local manifest = vim.fs.joinpath(dir, 'node_modules', 'typescript', 'package.json')
  local fd = io.open(manifest, 'r')
  if not fd then
    return nil
  end
  local content = fd:read '*a'
  fd:close()
  local ok, package = pcall(vim.json.decode, content)
  if not ok or type(package) ~= 'table' or type(package.version) ~= 'string' then
    return nil
  end
  return tonumber(package.version:match '^(%d+)')
end

---@param root string?
---@return string
local function resolve_cmd(root)
  if root then
    local major = local_ts_major(root)
    local binary = vim.fs.joinpath(root, 'node_modules', '.bin', 'tsc')
    if major and major >= 7 and vim.fn.executable(binary) == 1 then
      return binary
    end
  end
  return 'tsc'
end

---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local cmd = resolve_cmd((config or {}).root_dir)
    return vim.lsp.rpc.start({ cmd, '--lsp', '--stdio' }, dispatchers)
  end,
  filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  root_dir = function(bufnr, on_dir)
    local lockfiles = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' }
    -- Give the lockfiles equal priority by wrapping them in a table.
    local root_markers = vim.fn.has 'nvim-0.11.3' == 1 and { lockfiles, { '.git' } } or vim.list_extend(lockfiles, { '.git' })

    local deno_root = vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc' })
    local deno_lock_root = vim.fs.root(bufnr, { 'deno.lock' })
    local project_root = vim.fs.root(bufnr, root_markers)

    -- Deno lock is closer than the package manager lock; let denols attach.
    if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
      return
    end
    -- Deno config is closer than or equal to the package manager lock.
    if deno_root and (not project_root or #deno_root >= #project_root) then
      return
    end

    on_dir(project_root or vim.fn.getcwd())
  end,
  settings = {
    typescript = {
      inlayHints = {
        parameterNames = {
          enabled = 'literals',
          suppressWhenArgumentMatchesName = true,
        },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
}
