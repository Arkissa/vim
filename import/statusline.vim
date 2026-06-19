vim9script

import 'vim.vim'
import 'buffer.vim'
import 'quickfix.vim'

type Buffer = buffer.Buffer
type Quickfix = quickfix.Quickfix
type Location = quickfix.Location

interface Provider
	def string(): string
endinterface

export class Cut implements Provider
	def string(): string
		return '%<'
	enddef
endclass

export class Sep implements Provider
	def string(): string
		return '%='
	enddef
endclass

export class BufName implements Provider
	def string(): string
		var buf = buffer.Buffer.newCurrent()
		return $'[{empty(buf.name) ? '(No Name)' : fnamemodify(buf.name, ':t')}%m]'
	enddef
endclass

export class Mode implements Provider
	static const modeMap = {
		'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK',
		'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'
	}

	def string(): string
		return get(modeMap, mode(), '')
	enddef
endclass

export class Dir implements Provider
	def string(): string
		var str = substitute(expand('%:p:h'), $'^{getcwd()}\(.*\)', '.\1', '') ?? '.'
		return str =~ '^\.' ? str : fnamemodify(str, ':~:.')
	enddef
endclass

export class Git implements Provider
	def string(): string
		if exists_compiled('*g:FugitiveStatusline')
			return g:FugitiveStatusline()
		else
			return ''
		endif
	enddef
endclass

export class Diags implements Provider
	def string(): string
		var b = Buffer.newCurrent()
		var lspDiag = b.GetVar('LspDiag', {})

		var type = {
			'E': get(lspDiag, 'Error', 0),
			'W': get(lspDiag, 'Warn', 0),
			'I': get(lspDiag, 'Info', 0),
			'N': get(lspDiag, 'Hint', 0),
		}

		var str = []
		var typeItems = []

		var qf = Quickfix.newCurrent()
		if !qf.IsEmpty()
			typeItems->extend(qf.GetList())
		endif

		var locl = Location.newCurrent()
		if !locl.IsEmpty()
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

		return str->join(' ')
	enddef
endclass

export class Icon implements Provider
	var _icon: string
	def new(icon: string = '≡')
		this._icon = icon
	enddef

	def string(): string
		return this._icon
	enddef
endclass

export class FilePercent implements Provider
	def string(): string
		return '%3P'
	enddef
endclass

export class LineCol implements Provider
	def string(): string
		return '%3l:%-3c'
	enddef
endclass

export class FileType implements Provider
	def string(): string
		return '%y'
	enddef
endclass

export class FileSize implements Provider
	def string(): string
		var name = expand('%:p')
		if name == ''
			return ''
		endif

		var size = getfsize(name)
		if size <= 0
			return ''
		endif

		if size < 1024
			return printf('%dB', size)
		elseif size < 1024 * 1024
			return printf('%.2fK', size / 1024.0)
		elseif size < 1024 * 1024 * 1024
			return printf('%.2fM', size / 1024.0 / 1024.0)
		endif

		return printf('%.2fG', size / 1024.0 / 1024.0 / 1024.0)
	enddef
endclass

export class Build
	var _providers: list<Provider>

	def new(...providers: list<Provider>)
		this._providers = providers
	enddef

	def string(): string
		return $' {this._providers->mapnew((_, provider) => provider->string())->join(' ')} '
	enddef
endclass
