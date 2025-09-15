vim9script
# Name: catppuccin.vim

:set background=dark
:hi clear

if exists("syntax on")
    :syntax reset
endif

g:colors_name = "catppuccin"
:set t_Co=256
:set termguicolors

var rosewater = "#F5E0DC"
var flamingo = "#F2CDCD"
var pink = "#F5C2E7"
var mauve = "#CBA6F7"
var red = "#F38BA8"
var maroon = "#EBA0AC"
var peach = "#FAB387"
var yellow = "#F9E2AF"
var green = "#A6E3A1"
var teal = "#94E2D5"
var sky = "#89DCEB"
var sapphire = "#74C7EC"
var blue = "#89B4FA"
var lavender = "#B4BEFE"

var text = "#CDD6F4"
var subtext1 = "#BAC2DE"
var subtext0 = "#A6ADC8"
var overlay2 = "#9399B2"
var overlay1 = "#7F849C"
var overlay0 = "#6C7086"
var surface2 = "#585B70"
var surface1 = "#45475B"
var surface0 = "#313244"

var base = "#1E1E2E"
var mantle = "#181825"
var crust = "#11111B"

g:terminal_ansi_colors = [
  \ surface1, red, green, yellow, blue, pink, teal, subtext1,
  \ surface2, red, green, yellow, blue, pink, teal, subtext0
\ ]

hlset([
    {name: "Visual", guibg: surface1, guifg: "NONE", gui: {bold: 1}, cterm: {bold: 1}, ctermfg: "NONE", ctermbg: "NONE"},
    {name: "Conceal", guifg: overlay1},
    {name: "ColorColumn", guibg: surface0},
    {name: "Cursor", guifg: base, guibg: rosewater},
    {name: "lCursor", guifg: base, guibg: rosewater},
    {name: "CursorIM", guifg: base, guibg: rosewater},
    {name: "CursorColumn", guibg: mantle},
    {name: "CursorLine", guisp: "NONE", guifg: "NONE", guibg: surface0, gui: {}, cterm: {}},
    {name: "Directory", guisp: "NONE", guifg: blue, guibg: "NONE", gui: {}, cterm: {}},
    {name: "DiffAdd", guisp: "NONE", guifg: "NONE", guibg: "#364144", ctermfg: "NONE", ctermbg: "NONE", gui: {}, cterm: {}},
    {name: "DiffChange", guisp: "NONE", guifg: "NONE", guibg: "#25293d", ctermfg: "NONE", ctermbg: "NONE", gui: {}, cterm: {}},
    {name: "DiffDelete", guisp: "NONE", guifg: "NONE", guibg: "#443245", ctermfg: "NONE", ctermbg: "NONE", gui: {}, cterm: {}},
    {name: "DiffText", guisp: "NONE", guifg: "NONE", guibg: "#3e4b6c", ctermfg: "NONE", ctermbg: "NONE", gui: {}, cterm: {}},
    {name: "EndOfBuffer", guisp: "NONE", guifg: "NONE", guibg: "NONE", gui: {}, cterm: {}},
    {name: "ErrorMsg", guisp: "NONE", guifg: red, guibg: "NONE", gui: {bold: true, italic: true}, cterm: {bold: true, italic: true}},
    {name: "VertSplit", guisp: "NONE", guifg: crust, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Folded", guisp: "NONE", guifg: blue, guibg: "NONE", gui: {}, cterm: {}},
    {name: "FoldColumn", guisp: "NONE", guifg: overlay0, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Folded", guisp: "NONE", guifg: overlay0, guibg: "NONE", gui: {}, cterm: {}},
    {name: "SignColumn", guisp: "NONE", guifg: surface1, guibg: base, gui: {}, cterm: {}},
    {name: "IncSearch", guisp: "NONE", guifg: surface1, guibg: pink, gui: {}, cterm: {}},
    {name: "CursorLineNr", guisp: "NONE", guifg: lavender, guibg: "NONE", gui: {}, cterm: {}},
    {name: "LineNr", guisp: "NONE", guifg: surface1, guibg: "NONE", gui: {}, cterm: {}},
    {name: "MatchParen", guisp: "NONE", guifg: peach, guibg: "NONE", gui: {bold: true}, cterm: {bold: true}},
    {name: "ModeMsg", guisp: "NONE", guifg: text, guibg: "NONE", gui: {bold: true}, cterm: {bold: true}},
    {name: "MoreMsg", guisp: "NONE", guifg: blue, guibg: "NONE", gui: {}, cterm: {}},
    {name: "NonText", guisp: "NONE", guifg: overlay0, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Pmenu", guisp: "NONE", guifg: "NONE", guibg: "NONE", ctermfg: "NONE", ctermbg: "NONE", gui: {}, cterm: {}},
    {name: "PmenuSel", guisp: "NONE", guifg: text, guibg: surface1, gui: {bold: true}, cterm: {bold: true}},
    {name: "PmenuMatch", guisp: "NONE", guifg: lavender, guibg: "NONE", ctermfg: "NONE", ctermbg: "NONE", gui: {}, cterm: {bold: true}},
    {name: "PmenuMatchSel", guisp: "NONE", guifg: lavender, guibg: surface1, ctermfg: "NONE", ctermbg: "NONE", gui: {}, cterm: {bold: true}},
    {name: "PmenuSbar", guisp: "NONE", guifg: "NONE", guibg: surface1, gui: {}, cterm: {}},
    {name: "PmenuThumb", guisp: "NONE", guifg: "NONE", guibg: overlay0, gui: {}, cterm: {}},
    {name: "Question", guisp: "NONE", guifg: blue, guibg: "NONE", gui: {}, cterm: {}},
    {name: "QuickFixLine", guisp: "NONE", guifg: "NONE", guibg: surface1, gui: {bold: true}, cterm: {bold: true}},
    {name: "Search", guisp: "NONE", guifg: "#CDD6F5", guibg: "#3e5768", gui: {bold: true}, cterm: {bold: true}},
    {name: "SpecialKey", guisp: "NONE", guifg: subtext0, guibg: "NONE", gui: {}, cterm: {}},
    {name: "SpellBad", guisp: red, guifg: "NONE", guibg: "NONE", ctermfg: "NONE", ctermbg: "NONE", gui: {underline: true}, cterm: {underline: true}, term: {}},
    {name: "SpellCap", guisp: yellow, guifg: "NONE", guibg: "NONE", ctermfg: "NONE", ctermbg: "NONE", gui: {underline: true}, cterm: {underline: true}},
    {name: "SpellLocal", guisp: blue, guifg: "NONE", guibg: "NONE", ctermfg: "NONE", ctermbg: "NONE", gui: {underline: true}, cterm: {underline: true}, term: {reverse: true}},
    {name: "SpellRare", guisp: green, guifg: "NONE", guibg: "NONE", ctermfg: "NONE", ctermbg: "NONE", gui: {underline: true}, cterm: {underline: true}},
    {name: "StatusLine", guisp: "NONE", guifg: text, guibg: mantle, gui: {}, cterm: {}},
    {name: "StatusLineNC", guisp: "NONE", guifg: surface1, guibg: mantle, gui: {}, cterm: {}},
    {name: "StatusLineTerm", guisp: "NONE", guifg: text, guibg: mantle, gui: {}, cterm: {}},
    {name: "StatusLineTermNC", guisp: "NONE", guifg: surface1, guibg: mantle, gui: {}, cterm: {}},
    {name: "TabLine", guisp: "NONE", guifg: surface1, guibg: mantle, gui: {}, cterm: {}},
    {name: "TabLineFill", guisp: "NONE", guifg: "NONE", guibg: mantle, gui: {}, cterm: {}},
    {name: "TabLineSel", guisp: "NONE", guifg: green, guibg: surface1, gui: {}, cterm: {}},
    {name: "Title", guisp: "NONE", guifg: blue, guibg: "NONE", gui: {bold: true}, cterm: {bold: true}},
    {name: "VisualNOS", guisp: "NONE", guifg: "NONE", guibg: surface1, gui: {bold: true}, cterm: {bold: true}},
    {name: "WarningMsg", guisp: "NONE", guifg: yellow, guibg: "NONE", gui: {}, cterm: {}},
    {name: "WildMenu", guisp: "NONE", guifg: "NONE", guibg: overlay0, gui: {}, cterm: {}},
    {name: "Comment", guisp: "NONE", guifg: overlay0, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Constant", guisp: "NONE", guifg: peach, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Identifier", guisp: "NONE", guifg: flamingo, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Statement", guisp: "NONE", guifg: mauve, guibg: "NONE", gui: {}, cterm: {}},
    {name: "PreProc", guisp: "NONE", guifg: pink, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Type", guisp: "NONE", guifg: yellow, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Special", guisp: "NONE", guifg: pink, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Underlined", guisp: "NONE", guifg: text, guibg: base, gui: {underline: true}, cterm: {underline: true}},
    {name: "Error", guisp: "NONE", guifg: red, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Todo", guisp: "NONE", guifg: base, guibg: flamingo, gui: {bold: true}, cterm: {bold: true}},
    {name: "SignColumn", guisp: "NONE", guifg: surface1, guibg: "NONE", gui: {}, cterm: {}},
    {name: "String", guisp: "NONE", guifg: green, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Character", guisp: "NONE", guifg: teal, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Number", guisp: "NONE", guifg: peach, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Boolean", guisp: "NONE", guifg: peach, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Float", guisp: "NONE", guifg: peach, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Function", guisp: "NONE", guifg: blue, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Conditional", guisp: "NONE", guifg: mauve, guibg: "NONE", gui: {italic: true}, cterm: {italic: true}},
    {name: "Repeat", guisp: "NONE", guifg: mauve, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Label", guisp: "NONE", guifg: blue, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Operator", guisp: "NONE", guifg: sky, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Keyword", guisp: "NONE", guifg: mauve, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Include", guisp: "NONE", guifg: mauve, guibg: "NONE", gui: {}, cterm: {}},
    {name: "StorageClass", guisp: "NONE", guifg: yellow, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Structure", guisp: "NONE", guifg: yellow, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Typedef", guisp: "NONE", guifg: yellow, guibg: "NONE", gui: {}, cterm: {}},
    {name: "debugPC", guisp: "NONE", guifg: "NONE", guibg: crust, gui: {}, cterm: {}},
    {name: "debugBreakpoint", guisp: "NONE", guifg: overlay0, guibg: base, gui: {}, cterm: {}},
    {name: "Define", default: true, linksto: "PreProc"},
    {name: "Macro", default: true, linksto: "Statement"},
    {name: "PreCondit", default: true, linksto: "PreProc"},
    {name: "SpecialChar", default: true, linksto: "Special"},
    {name: "Tag", guisp: "NONE", guifg: lavender, guibg: "NONE", gui: {}, cterm: {}},
    {name: "Delimiter", default: true, linksto: "Special"},
    {name: "SpecialComment", default: true, linksto: "Special"},
    {name: "Debug", default: true, linksto: "Special"},
    {name: "Exception", default: true, linksto: "Error"},
    {name: "StatusLineTerm", default: true, linksto: "StatusLine"},
    {name: "StatusLineTermNC", default: true, linksto: "StatusLineNC"},
    {name: "Terminal", default: true, linksto: "Normal"},
    {name: "Ignore", default: true, linksto: "Comment"},
	{name: "LspTextRef", default: true, linksto: "Visual"},
    {name: "LspDiagSignErrorText", guifg: "#f38ba9"},
    {name: "LspDiagSignWarningText", guifg: "#f9e2b0"},
    {name: "LspDiagSignInfoText", guifg: "#89dcec"},
    {name: "LspDiagSignHintText", guifg: "#94e2d6"},
    {name: "LspInlayHintsType", guifg: "#6c7087"},
    {name: "LspInlayHintsParam", guifg: "#6c7087"}
])
