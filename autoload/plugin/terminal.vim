vim9script

import autoload 'window.vim'
import autoload 'buffer.vim'
import autoload 'autocmd.vim'

type Autocmd = autocmd.Autocmd # {{{1

export class Manager # {{{1
	static var _current: buffer.Terminal
	static var _terms: list<buffer.Terminal> = [] # {{{2
	static var _win: window.Window # {{{2
	static var _autocmd = Autocmd.new('WinClosed').Group("TerminalManager").Replace().Once() # {{{2
	static const _NameLimit = 15

	static const _statuslineterms = 'StatusLineTerminals' # {{{2

	static def _OnClose(_) # {{{2
			var old = _current
			Manager.Slide(1)
			_terms->filter((_, term) => term.bufnr != old.bufnr)

			if empty(_terms)
				_current = null_object
			endif
	enddef # }}}

	static def _IsOpen(): bool # {{{2
		return _win != null_object && _win.IsOpen()
	enddef # }}}

	static def ToggleWindow(cmd: string = '', pos: string = '', count: number = 0) # {{{2
		if _IsOpen()
			_win.Close()
		else
			NewTerminal(cmd, pos, count)
		endif
	enddef # }}}

	static def ListTerminals(): list<buffer.Terminal> # {{{2
		return copy(_terms)
	enddef # }}}

	static def Current(): buffer.Terminal # {{{2
		return _current
	enddef # }}}

	static def _TerminalName(name: string): string
		return name->strchars() > _NameLimit ? $'{name->strcharpart(0, _NameLimit)}…' : name
	enddef

	static def StatusLineTerminals(): string # {{{2
		var str = []
		for term in _terms
			str->add(term.bufnr == _current.bufnr ? $'[{_TerminalName(term.name)}]' : _TermName(term.name))
		endfor

		return str->join(' ')
	enddef # }}}

	static def NewTerminal(cmd: string = '', pos: string = '', count: number = 0) # {{{2
		if _current == null_object || _IsOpen()
			_current = buffer.Terminal.new(cmd ?? $SHELL, {
				hidden: true,
				term_kill: 'term',
				term_finish: 'close',
				close_cb: _OnClose,
			})
			_terms->add(_current)
		endif

		if !_IsOpen()
		 _win = window.Window.new(pos, count)
		 _win.OnSetBufPost((w) => {
				w.SetVar('&statusline', '%{%term#Manager.StatusLineTerminals()%}')
				w.SetVar('&number', false)
				w.SetVar('&signcolumn', 'no')
				w.SetVar('&winfixheight', true)
				w.SetVar('&relativenumber', false)
				w.SetVar('&hidden', false)
		 })
		endif

		_win.SetBuf(_current.bufnr)
	enddef # }}}

	static def Slide(offset: number) # {{{2
		for [i, term] in _terms->items()
			if term.bufnr == _current.bufnr
				var index = (i + offset) % len(_terms)
				_current = _terms[index]

				if _win != null_object
					_win.SetBuf(_current.bufnr)
				endif

				return
			endif
		endfor

		_current = null_object
	enddef # }}}

	static def KillCurrentTerminal() # {{{2
		if _current != null_object
			if len(_terms) != 1
				_current.Stop()
			else
				_current.Delete()
			endif
		endif
	enddef # }}}

	static def KillAllTerminals() # {{{2
		_terms->foreach((_, term) => {
			term.Delete()
		})

		_terms = []
		_current = null_object
		_CloseWindow()
	enddef # }}}

	static def _CloseWindow() # {{{2
		if _IsOpen()
			_win.Close()
		endif
	enddef # }}}
endclass
