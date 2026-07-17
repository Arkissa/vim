vim9script

import 'vim.vim'
import 'buffer.vim'
import 'quickfix.vim'

const left = 'left'
const mid = 'mid'
const right = 'right'

type Buffer = buffer.Buffer
type Quickfix = quickfix.Quickfix
type Location = quickfix.Location

export interface Provider
	def string(): string
endinterface

export class Text implements Provider
	var _text: string

	def new(this._text)
	enddef

	def string(): string
		return this._text
	enddef
endclass

export class Icon implements Provider
	const _icon: string
	const _provider: Provider

	def new(this._icon, this._provider)
	enddef

	def string(): string
		return $"{this._icon} {this._provider->string()}"
	enddef
endclass

const id = vim.IncID.new()
export class Color implements Provider
	static const _group_name = 'statusline_color'
	static var _cache: dict<string> = {}

	const _id: number = id.ID()
	const _name: string
	const _provider: Provider

	def new(this._provider, color: any)
		if type(color) == v:t_string
			this._name = color
			return
		endif

		if type(color) != v:t_dict
			throw 'must be string or dict with color arguments.'
		endif

		var fg: dict<any>
		if has_key(color, 'fg')
			fg = this._GetHighlight('fg', color.fg)
		endif

		var bg: dict<any>
		if has_key(color, 'bg')
			bg = this._GetHighlight('bg', color.bg)
		endif

		var attr = get(color, 'attr', '')
		var hash = this._GetColorHash(fg, bg, attr)

		if has_key(_cache, hash)
			this._name = _cache[hash]
		else
			this._name = $'{_group_name}{this._id}'
			var hl = {name: this._name, term: {[attr]: 1}}
			_cache[hash] = this._name

			hl->extend(fg, 'error')
			hl->extend(bg, 'error')

			hlset([hl])
		endif
	enddef

	def string(): string
		return $"%#{this._name}#{this._provider->string()}"
	enddef

	def _GetColorHash(fg: dict<any>, bg: dict<any>, attr: string): string
		return $'{get(fg, 'guifg', '')}{get(fg, 'ctermfg', '')}{get(bg, 'guibg', '')}{get(bg, 'ctermbg', '')}{attr}'
	enddef

	def _GetHighlight(side: string, color: any): dict<any>
		const gui = $'gui{side}'
		const cterm = $'cterm{side}'
		if type(color) == v:t_string
			return {[gui]: color}
		endif

		if type(color) == v:t_number
			return {[cterm]: color}
		endif

		var tname = typename(color)
		if tname == 'tuple<string, number>'
			var [g, c] = color
			return {[gui]: g, [cterm]: c}
		endif

		if tname == 'tuple<number, string>'
			var [c, g] = color
			return {[gui]: g, [cterm]: c}
		endif

		return null_dict
	enddef
endclass

class Cut implements Provider
	def string(): string
		return '%<'
	enddef
endclass

class Sep implements Provider
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
		if exists('*g:FugitiveStatusline')
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

export def Statusline(): string
	const statusline: dict<list<Provider>> = get(g:, 'statusline', {})

	var sidestrs = []

	for side in [left, mid, right]
		if has_key(statusline, side)
			var sidestr = statusline[side]->mapnew((_, provider) => provider->string())->join()

			sidestrs->add(sidestr)
		endif
	endfor

	return sidestrs->join(Sep.new()->string())
enddef
