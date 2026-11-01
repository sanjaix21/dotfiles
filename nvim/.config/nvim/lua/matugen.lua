 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#101510',
    base01 = '#1c211c',
    base02 = '#262b26',
    base03 = '#8b938a',
    base04 = '#c1c9bf',
    base05 = '#dfe4dc',
    base06 = '#dfe4dc',
    base07 = '#dfe4dc',
    base08 = '#ffb4ab',
    base09 = '#a2ced9',
    base0A = '#b6ccb8',
    base0B = '#97d5a5',
    base0C = '#a2ced9',
    base0D = '#97d5a5',
    base0E = '#b6ccb8',
    base0F = '#d2e8d3',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#dfe4dc',          bg = '#101510' })
  hi('TelescopeBorder',         { fg = '#8b938a',             bg = '#101510' })
  hi('TelescopePromptNormal',   { fg = '#dfe4dc',          bg = '#101510' })
  hi('TelescopePromptBorder',   { fg = '#8b938a',             bg = '#101510' })
  hi('TelescopePromptPrefix',   { fg = '#97d5a5',             bg = '#101510' })
  hi('TelescopePromptCounter',  { fg = '#c1c9bf',  bg = '#101510' })
  hi('TelescopePromptTitle',    { fg = '#101510',             bg = '#97d5a5' })
  hi('TelescopePreviewTitle',   { fg = '#101510',             bg = '#b6ccb8' })
  hi('TelescopeResultsTitle',   { fg = '#101510',             bg = '#a2ced9' })
  hi('TelescopeSelection',      { fg = '#dfe4dc',          bg = '#262b26' })
  hi('TelescopeSelectionCaret', { fg = '#97d5a5',             bg = '#262b26' })
  hi('TelescopeMatching',       { fg = '#97d5a5',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#dfe4dc',          bg = '#101510' })
  hi('MiniPickBorder',         { fg = '#8b938a',             bg = '#101510' })
  hi('MiniPickPrompt',   { fg = '#dfe4dc',          bg = '#101510' })
  hi('MiniPickPromptPrefix',   { fg = '#97d5a5',             bg = '#101510' })
  hi('MiniPickBorderText',    { fg = '#101510',             bg = '#97d5a5' })
  hi('MiniPickMatchCurrent',      { fg = '#dfe4dc',          bg = '#262b26' })
  hi('MiniPickPromptCaret', { fg = '#97d5a5',             bg = '#262b26' })
  hi('MiniPickMatchRanges',       { fg = '#97d5a5',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
