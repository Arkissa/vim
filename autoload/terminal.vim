vim9script

import 'vim.vim'
import 'window.vim'
import 'buffer.vim'
import 'autocmd.vim'

type Autocmd = autocmd.Autocmd
type Terminal = buffer.Terminal
type Ring = vim.Ring

export class Manager # {{{1
	static const group = 'TerminalManager'
	static var _terms: Ring
	static var _win: window.Window = window.Window.new()
	static var _pos: string
	static var _count: number

	static const _statuslineterms = 'StatusLineTerminals'
	static const _NameLimit = 15

	static def _OnClose(job: job, code: number) # {{{2
		if !_terms->empty()
			var term = _terms.Pop()
			SlideRight()
			if term.IsExists()
				term.Delete()
			endif
		else
			_CloseWindow()
		endif
	enddef # }}}

	static def ToggleWindow(bang: bool, cmd: string = '', pos: string = '', count: number = 0) # {{{2
		if _win.IsOpen()
			_win.Close()
		else
			NewTerminal(bang, cmd, pos, count)
		endif
	enddef # }}}

	static def ListTerminals(): list<Terminal> # {{{2
		return _terms->ToList<Terminal>()
	enddef # }}}

	static def Current(): Terminal # {{{2
		return _terms.Peek()
	enddef # }}}

	static def _TerminalName(name: string): string # {{{2
		return name->strchars() > _NameLimit ? $'{name->strcharpart(0, _NameLimit)}…' : name
	enddef # }}}

	static def StatusLineTerminals(): string # {{{2
		var str = []

		for term in _terms.ToList<Terminal>()
			str->add(term.bufnr != _terms.Peek().bufnr
				? _TerminalName(term.name)
				: $'[{_TerminalName(term.name)}]'
			)
		endfor

		return str->join(' ')
	enddef # }}}

	static def _NewTerm(cmd: string): Terminal # {{{2
		return Terminal.new(cmd ?? $SHELL, {
			hidden: true,
			term_kill: 'term',
			exit_cb: _OnClose,
		})
	enddef # }}}

	static def NewTerminal(bang: bool, cmd: string = '', pos: string = '', count: number = 0) # {{{2
		if _terms->empty()
			_terms = Ring.new(_NewTerm(cmd))
		endif

		if _win.IsOpen()
			_terms.Push(_NewTerm(cmd))
		else
			_pos = pos ?? _pos
			_count = count ?? _count
			_win.SetPos(_pos)
			_win.Resize(_count)
			_win.Open()
			if bang
				_win.LockSize()
			endif

			Autocmd.new('WinClosed')
				.Group(group)
				.Pattern([_win.winnr->string()])
				.Once()
				.Callback(() => {
					autocmd_delete([{group: Manager.group}])
				})

			Autocmd.new('BufWinEnter')
				.Group(group)
				.Pattern([_win.winnr->string()])
				.Callback((opt: autocmd.EventArgs) => {
					var w = opt.data
					w.SetVar('&statusline', '%{%terminal#Manager.StatusLineTerminals()%}')
					w.SetVar('&number', false)
					w.SetVar('&signcolumn', 'no')
					w.SetVar('&winfixheight', true)
					w.SetVar('&relativenumber', false)
					w.SetVar('&hidden', false)
				})

		endif

		_win.SetBuf(_terms.Peek().bufnr)
		_win.Execute('startinsert')
	enddef # }}}

	static def SlideRight() # {{{2
		_terms.SlideRight()
		if !_terms->empty()
			_win.SetBuf(_terms.Peek().bufnr)
			_win.Execute('startinsert')
		endif
	enddef # }}}

	static def SlideLeft() # {{{2
	  	_terms.SlideLeft()
		if !_terms->empty()
			_win.SetBuf(_terms.Peek().bufnr)
			_win.Execute('startinsert')
		endif
	enddef # }}}

	static def KillCurrentTerminal() # {{{2
		if !_terms->empty()
			_terms.Peek().Stop()
		endif
	enddef # }}}

	static def KillAllTerminals() # {{{2
		if !_terms->empty()
			_terms.ForEach((term) => {
				if term.IsExists()
					term.Delete()
				endif
			})

			_CloseWindow()
		endif
	enddef # }}}

	static def _CloseWindow() # {{{2
		if _win.IsOpen()
			_win.Close()
		endif
	enddef # }}}
endclass
