--- Block commenting (`gcb`).
---
--- Neovim's built-in commenting is line based: it only ever uses
--- 'commentstring', so there is no way to reach the `/* */` form of a language.
--- This module reuses that same operator (so toggling, dot-repeat, indentation
--- and range handling stay identical to `gcc`) but forces the block variant of
--- 'commentstring' while it runs.
---
--- Each line in the range gets its own delimiters, e.g. `/* line */`.
--- Languages without a block form (Lua, Python, shell, YAML, ...) fall back to
--- their normal line comment.
local M = {}

--- Block delimiters are derived from 'comments', which is the option Vim
--- already uses to describe three-piece comments:
---   typescriptreact -> sO:* -,mO:*  ,exO:*/,s1:/*,mb:*,ex:*/,://
---   html            -> s:<!--,m:    ,e:-->
--- The `s` flag marks the start piece and `e` the end piece. The last pair wins
--- because leading entries describe documentation comments (`/*!`, `* -`).
---@param ft string
---@return string? commentstring
local function block_commentstring(ft)
  local ok, comments = pcall(vim.filetype.get_option, ft, 'comments')
  if not ok or type(comments) ~= 'string' or comments == '' then
    return nil
  end

  local left, right
  for _, entry in ipairs(vim.split(comments, ',', { plain = true })) do
    local flags, text = entry:match '^(.-):(.*)$'
    if flags and text ~= '' then
      -- Flags are a set of single letters plus an optional numeric offset.
      if flags:find 's' then
        left = text
      elseif flags:find 'e' then
        right = text
      end
    end
  end

  if not left or not right then
    return nil
  end
  return left .. ' %s ' .. right
end

--- Run `fn` with 'commentstring' forced to the block variant.
---
--- `vim.bo.commentstring` alone is not enough: when a tree-sitter parser exists
--- for the buffer, `vim._comment` resolves the string through
--- `vim.filetype.get_option()` instead, which is also the hook ts-comments.nvim
--- uses. Both are overridden, then restored.
---@param fn fun()
local function with_block_commentstring(fn)
  -- If the commentstring that would be used already has a right part, it is
  -- itself a block form and must be kept. This is what makes `gcb` correct
  -- inside JSX, where ts-comments.nvim resolves `{/* %s */}`: the bare `/* */`
  -- of 'comments' would render as literal text there.
  local ok, natural = pcall(vim.filetype.get_option, vim.bo.filetype, 'commentstring')
  if ok and type(natural) == 'string' then
    local right = natural:match '%%s(.*)$'
    if right and vim.trim(right) ~= '' then
      return fn()
    end
  end

  local cs = block_commentstring(vim.bo.filetype)
  if not cs then
    -- No block form for this language: behave exactly like `gcc`.
    return fn()
  end

  local saved_get_option = vim.filetype.get_option
  local saved_commentstring = vim.bo.commentstring

  vim.filetype.get_option = function(filetype, option)
    if option == 'commentstring' then
      return cs
    end
    return saved_get_option(filetype, option)
  end
  vim.bo.commentstring = cs

  local ok, err = pcall(fn)

  vim.filetype.get_option = saved_get_option
  vim.bo.commentstring = saved_commentstring

  if not ok then
    error(err)
  end
end

--- `operatorfunc` used by the `gcb` mappings. Called by Neovim once the range
--- is known, which is exactly when the override has to be active.
---@param mode string?
function M.operator(mode)
  if mode == nil then
    vim.o.operatorfunc = "v:lua.require'block-comment'.operator"
    return 'g@'
  end
  with_block_commentstring(function()
    require('vim._comment').operator(mode)
  end)
  return ''
end

function M.setup()
  -- Current line in Normal mode (`_` is the linewise motion), selection in
  -- Visual mode. Mirrors how Neovim maps `gcc` and `gc`.
  vim.keymap.set('n', 'gcb', function()
    return M.operator() .. '_'
  end, { expr = true, desc = 'Toggle block comment line' })

  vim.keymap.set('x', 'gcb', function()
    return M.operator()
  end, { expr = true, desc = 'Toggle block comment' })
end

return M
