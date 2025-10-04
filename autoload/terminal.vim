vim9script

# import autoload 'vim.vim'
# import autoload 'window.vim'
# import autoload 'buffer.vim'
# import autoload 'autocmd.vim'

import 'vim.vim'
import 'window.vim'
import 'buffer.vim'
import 'autocmd.vim'

type Autocmd = autocmd.Autocmd # {{{1
type Terminal = buffer.Terminal # {{{1
type Ring = vim.Ring

export class Manager # {{{1
	static const group = 'TerminalManager'
	static var _terms: Ring
	static var _win: window.Window # {{{2

	static const _statuslineterms = 'StatusLineTerminals' # {{{2
	static const _NameLimit = 15 # {{{2

	static def _OnClose(_) # {{{2
		if !_terms->empty()
			_terms.Pop()
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

	static def _NewTerm(cmd: string): Terminal
		return Terminal.new(cmd ?? $SHELL, {
				hidden: true,
				term_kill: 'term',
				term_finish: 'close',
				close_cb: _OnClose,
		})
	enddef

	static def NewTerminal(cmd: string = '', pos: string = '', count: number = 0) # {{{2
		if _terms->empty()
			_terms = Ring.new(_NewTerm(cmd))
		endif

		if _IsOpen()
			_terms.Push(_NewTerm(cmd))
		else
			_win = window.Window.new(pos, count)

			Autocmd.new('BufWinEnter')
				.Group(group)
				.Pattern([string(_win.winnr)])
				.Callback((opt: autocmd.EventArgs) => {
					var w = opt.data
					w.SetVar('&statusline', '%{%plugin#terminal#Manager.StatusLineTerminals()%}')
					w.SetVar('&number', false)
					w.SetVar('&signcolumn', 'no')
					w.SetVar('&winfixheight', true)
					w.SetVar('&relativenumber', false)
					w.SetVar('&hidden', false)
				})
		endif

		_win.SetBuf(_terms.Peek().bufnr)
	enddef # }}}

	static def SlideRight() # {{{2
		_terms.SlideRight()
	enddef # }}}

	static def SlideLeft() # {{{2
	  	_terms.SlideLeft()
	enddef # }}}

	static def KillCurrentTerminal() # {{{2
		if _terms->len() != 1
			_terms.Peek().Stop()
		else
			_terms.Peek().Delete()
			_CloseWindow()
		endif
	enddef # }}}

	static def KillAllTerminals() # {{{2
		if !_terms->empty()
			_terms.ForEach((term) => {
				term.Delete()
			})

			_CloseWindow()
		endif
	enddef # }}}

	static def _CloseWindow() # {{{2
		if _IsOpen()
			_win.Close()
		endif
	enddef # }}}
endclass
