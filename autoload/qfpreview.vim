vim9script

import 'vim.vim'
import 'quickfix.vim'
import 'window.vim'
import 'autocmd.vim'

type Autocmd = autocmd.Autocmd
type Location = quickfix.Location
type Quickfix = quickfix.Quickfix
type Coroutine = vim.Coroutine
type Quickfixer = quickfix.Quickfixer

const AsyncIO = vim.AsyncIO

const conf = get(g:, 'QuickfixPreviewerConfig', {
	highlight: "Cursor",
	cursorline: false,
	padding: [],
	border: [],
	borderchars: [],
	borderhighlight: [],
})

const prop_name = "quickfix.Previewer"
prop_type_add(prop_name, {
	highlight: get(conf, 'hightlight', 'Cursor'),
	override: true,
	priority: 100,
})

# peek quickfix buffer with popup window.
class Previewer # {{{1
	static var _qf: Quickfixer
	static var _window: window.Popup

	static def _Filter(win: window.Popup, key: string): bool # {{{2
		if ["\<C-u>", "\<C-d>"]->index(key) != -1
			win.FeedKeys(key, "mx")
			return true
		endif

		return false
	enddef # }}}

	static def _WinOption(opt: autocmd.EventArgs) # {{{2
		var win: window.Popup = opt.data
		win.SetVar("&number", get(conf, 'number', false))
		win.SetVar("&cursorline", get(conf, 'cursorline', false))
		win.SetVar("&relativenumber", false)
	enddef # }}}

	static def _DetectFiletype(opt: autocmd.EventArgs) # {{{2
		AsyncIO.Run(Coroutine.new((win) => {
			var ft = win.GetVar('&filetype')
			if ft == ""
				win.Execute("filetype detect")
			endif
		}, opt.data))
	enddef # }}}

	static def _AddHightlightText(opt: autocmd.EventArgs) # {{{2
		var win: window.Popup = opt.data
		var item = _qf.GetItemUnderTheCursor()
		if item == null_object
			return
		endif

		var lnum = item.lnum ?? 1
		var col = item.col ?? 1
		prop_add(lnum, col, {
			type: prop_name,
			end_lnum: item.end_lnum ?? lnum,
			end_col: item.end_col ?? col,
			bufnr: win.GetBufnr(),
		})
	enddef # }}}

	static def _RemoveHightlightText(opt: autocmd.EventArgs) # {{{2
		var win: window.Popup = opt.data
		prop_remove({
			type: prop_name,
			bufnr: win.GetBufnr()
		})
	enddef # }}}

	static def _DeleteHightlightName(opt: autocmd.EventArgs) # {{{2
		var data: tuple<window.Popup, any> = opt.data
		var [win, _] = data
		prop_remove({
			type: prop_name,
			bufnr: win.GetBufnr()
		})
	enddef # }}}

	static def Open() # {{{2
		var win = window.Window.newCurrent()
		var wt = win.GetWinType()
		if ["quickfix", "loclist"]->index(wt) == -1
			return
		endif

		_qf = wt == "loclist"
			? Location.newCurrent()
			: Quickfix.newCurrent()
		var item = _qf.GetItemUnderTheCursor()
		if _qf.Empty() || item == null_object
			return
		endif

		_window.Open()

		_window.SetFilter(_Filter)
		_CreateAutocmd(_window, win.GetBufnr())
		_SetCursorUnderBuff()
	enddef # }}}

	static def _CreateAutocmd(win: window.Popup, bufnr: number) # {{{2
		var group = "Quickfix.Previewer"
		Autocmd.new('BufWinLeave')
			.Group(group)
			.Pattern([win.winnr->string()])
			.Callback(_RemoveHightlightText)

		Autocmd.new('BufWinEnter')
			.Group(group)
			.Pattern([win.winnr->string()])
			.Callback(_DetectFiletype)
			.Callback(_WinOption)
			.Callback(_AddHightlightText)

		var F = 
		Autocmd.new('WinClosed')
			.Group(group)
			.Pattern([win.winnr->string()])
			.Callback(_DeleteHightlightName)
			.Callback(function(Autocmd.Delete, [[{group: group}], true]))

		Autocmd.new('CursorMoved')
			.Group(group)
			.Bufnr(bufnr)
			.Callback(_SetCursorUnderBuff)

		Autocmd.newMulti(["WinLeave", "BufWipeout", "BufHidden"])
			.Group(group)
			.Bufnr(bufnr)
			.Callback(Close)
	enddef # }}}

	static def _SetCursorUnderBuff() # {{{2
		var item = _qf.GetItemUnderTheCursor()
		if item == null_object
			return
		endif

		_window.SetBuf(item.buffer.bufnr)
		var bufinfo = item.buffer.GetInfo()
		_window.SetTitle($" [{item.lnum}/{bufinfo.linecount}] buffer {item.buffer.bufnr}: {fnamemodify(bufinfo.name, ":~:.")} {bufinfo.changed ? "[+]" : ""}")
		_window.SetCursor(item.lnum, item.col)
		_window.FeedKeys("z.", "mx")
	enddef # }}}

	static def Toggle() # {{{2
		if _window == null_object || !_window.IsOpen()
			var info = window.Window.newCurrent().GetInfo()
			var height = float2nr(&lines * 0.5)
			var width = info.width
			_window = window.Popup.new({
				pos: "botleft",
				padding: get(conf, 'padding', []),
				border: get(conf, 'border', []),
				borderchars: get(conf, 'borderchars', []),
				borderhighlight: get(conf, 'borderhighlight', []),
				wrap: true,
				resize: false,
				maxheight: height,
				minheight: height,
				minwidth: width - 3,
				maxwidth: width - 3,
				col: info.wincol,
				line: info.winrow - 2,
			})
			Open()
		else
			Close()
		endif
	enddef # }}}

	static def Close() # {{{2
		if _window.IsOpen()
			_window.Close()
		endif
	enddef # }}}
endclass # }}}

export const Toggle = Previewer.Toggle
