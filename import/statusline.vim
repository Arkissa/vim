vim9script

import 'vim.vim'
import 'buffer.vim'
import 'quickfix.vim'
import autoload 'lsp/diag.vim'

type Buffer = buffer.Buffer
type Coroutine = vim.Coroutine
type Quickfix = quickfix.Quickfix
type Location = quickfix.Location

class Git
	var _cache: dict<string>

	def new()
	enddef

	def _GetBranch(): string
		if executable('git')
			var branch = trim(system('git branch --show-current'))
			if v:shell_error == 0
				return branch
			endif
		endif

		return ''
	enddef

	def Branch(bufnr: string): string
		if has_key(this._cache, bufnr)
			return tis._cache[bufnr]
		endif


	enddef
endclass

export abstract class StatusLine
	static const modeMap = {
		'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK',
		'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'
	}

	var _statusline = ['%<']

	def Cut(): StatusLine
		this._Append('%<')

		return this
	enddef

	def Left(): StatusLine
		this._Append('%=')

		return this
	enddef

	def Right(): StatusLine
		this._Append('%=')
		return this
	enddef

	def _Append(s: string)
		if s == ''
			return
		endif

		add(this._statusline, s)
	enddef

	def BufName(): StatusLine
		var buf = buffer.Buffer.newCurrent()
		this._Append($'[{empty(buf.name) ? '(No Name)' : fnamemodify(buf.name, ':t')}%m]')

		return this
	enddef

	def Mode(): StatusLine
		this._Append(get(modeMap, mode(), ''))

		return this
	enddef

	def Dir(): StatusLine
		var str = substitute(expand('%:p:h'), $'^{getcwd()}\(.*\)', '.\1', '') ?? '.'
		if str =~ '^\.'
			this._Append(str)
		else
			this._Append(fnamemodify(str, ':~:.'))
		endif

		return this
	enddef

	def Git(): StatusLine
		if exists_compiled('*g:FugitiveStatusline')
			this._Append(g:FugitiveStatusline())

			return this
		else
			return this
		endif
	enddef

	def Diags(): StatusLine
		var errCount = diag.DiagsGetErrorCount(Buffer.newCurrent().bufnr)
		var str = []

		var type = {
			'E': errCount.Error,
			'W': errCount.Warn,
			'I': errCount.Info,
			'N': errCount.Hint,
		}

		var typeItems = []
		var qf = Quickfix.newCurrent()
		if !qf.Empty()
			typeItems->extend(qf.GetList())
		endif

		var locl = Location.newCurrent()
		if !locl.Empty()
			typeItems->extend(locl.GetList())
		endif

		for item in typeItems
			if item.type.Value != ''
				type[item.type.Value] += 1
			endif
		endfor

		for [t, n] in type->items()
			if n > 0
				str->add($'{t}:{n}')
			endif
		endfor

		this._Append(str->join(' '))

		return this
	enddef

	def Role(): StatusLine
		this._Append('≡')
		this._Append('%3P')
		this._Append('%3l:%-3c')

		return this
	enddef

	def FileType(): StatusLine
		this._Append('%y')

		return this
	enddef

	def Build(): string
		var s = join(this._statusline, ' ')

		this._statusline = []

		return $' {s} '
	enddef
endclass

class BaseStatusLine extends StatusLine
endclass

export var helper = BaseStatusLine.new()
