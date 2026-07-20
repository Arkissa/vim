vim9script

import 'vim.vim'
import 'buffer.vim'
import 'thread.vim'
import 'autocmd.vim'
import 'quickfix.vim'

type Autocmd = autocmd.Autocmd

const left = 'left'
const mid = 'mid'
const right = 'right'

type Buffer = buffer.Buffer
type Quickfix = quickfix.Quickfix
type Location = quickfix.Location

export interface Provider
	def string(): string
endinterface

export class Padding implements Provider
	const _provider: Provider
	var _left: string = ' '
	var _right: string = ' '

	def new(this._provider)
	enddef

	def Left(n: number = 1): Padding
		this._left = repeat(' ', n < 1 ? 0 : n)
		return this
	enddef

	def Right(n: number = 1): Padding
		this._right = repeat(' ', n < 1 ? 0 : n)
		return this
	enddef

	def string(): string
		return $'{this._left}{this._provider->string()}{this._right}'
	enddef
endclass

export class Text implements Provider
	const _text: string

	def new(this._text)
	enddef

	def string(): string
		return this._text
	enddef
endclass

export class Icon implements Provider
	const _provider: Provider
	const _icon: string

	def new(this._icon, this._provider)
	enddef

	def string(): string
		return $"{this._icon} {this._provider->string()}"
	enddef
endclass

const id = vim.IncID.new()
export class Color implements Provider
	static const _group_name = 'StatuslineColor'
	static var _cache: dict<dict<any>> = {}
	static var _once: bool

	const _id: number = id.ID()
	const _name: string
	const _provider: Provider

	def new(this._provider, color: any)
		this._Init()

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
			this._name = _cache[hash].name
			return

		endif
		this._name = $'{_group_name}{this._id}'
		var hl: dict<any> = {name: this._name}

		hl->extend(fg, 'error')
		hl->extend(bg, 'error')
		if !attr->empty()
			hl.term = {[attr]: 1}
		endif

		_cache[hash] = hl

		if hlset([hl]) != 0
			throw $'hlset {color} failed'
		endif
	enddef

	def _Init()
		if _once
			return
		endif

		_once = true
		var cache = _cache
		Autocmd.new('ColorScheme')
			.Group('statusline color')
			.Callback(thread.Wrap(() => {
				hlset(cache->values())
			}))
	enddef

	def string(): string
		return $"%#{this._name}#{this._provider->string()}%0*"
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

class BufName_ implements Provider
	def string(): string
		var buf = buffer.Buffer.newCurrent()
		return $'[{empty(buf.name) ? '(No Name)' : fnamemodify(buf.name, ':t')}%m]'
	enddef
endclass

class Mode_ implements Provider
	static const modeMap = {
		'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK',
		'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'
	}

	def string(): string
		return get(modeMap, mode(), '')
	enddef
endclass

class Dir_ implements Provider
	def string(): string
		var str = substitute(expand('%:p:h'), $'^{getcwd()}\(.*\)', '.\1', '') ?? '.'
		return str =~ '^\.' ? str : fnamemodify(str, ':~:.')
	enddef
endclass

class Git_ implements Provider
	def string(): string
		if exists('*g:FugitiveStatusline')
			return g:FugitiveStatusline()
		else
			return ''
		endif
	enddef
endclass

class Diags_ implements Provider
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

class FilePercent_ implements Provider
	def string(): string
		return '%3P'
	enddef
endclass

class LineCol_ implements Provider
	def string(): string
		return '%3l:%-3c'
	enddef
endclass

class FileType_ implements Provider
	def string(): string
		return '%y'
	enddef
endclass

class FileSize_ implements Provider
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

def Wrap(providers: list<Provider>): list<Provider>
	return providers->mapnew((_, provider) => {
		if instanceof(provider, Padding)
			return provider
		endif

		return Padding.new(provider)
	})
enddef

abstract class Side implements Provider
	var _providers: list<Provider>
	var _once: bool

	def string(): string
		if !this._once
			this._providers = Wrap(this._providers)
		endif

		this._once = true
		return this._providers->mapnew((_, provider) => provider->string())->join('')
	enddef
endclass

export class Left extends Side
	def new(this._providers)
	enddef
endclass

export class Middle extends Side
	def new(this._providers)
	enddef
endclass

export class Right extends Side
	def new(this._providers)
	enddef
endclass

def SideOrder(provider: Provider): number
	if instanceof(provider, Left)
		return 0
	elseif instanceof(provider, Middle)
		return 1
	else
		return 2
	endif
enddef

export class Builtin
	static def BufName(): Provider
		return BufName_.new()
	enddef

	static def Git(): Provider
		return Git_.new()
	enddef

	static def FileType(): Provider
		return FileType_.new()
	enddef

	static def Dir(): Provider
		return Dir_.new()
	enddef

	static def LineCol(): Provider
		return LineCol_.new()
	enddef

	static def FileSize(): Provider
		return FileSize_.new()
	enddef

	static def FilePercent(): Provider
		return FilePercent_.new()
	enddef

	static def Mode(): Provider
		return Mode_.new()
	enddef

	static def Diags(): Provider
		return Diags_.new()
	enddef
endclass

export def Statusline(): string
	var providers: list<Provider> = get(g:, 'statusline', [])
		->copy()
		->sort((p1, p2) => SideOrder(p1) - SideOrder(p2))

	return providers->mapnew((_, provider) => provider->string())->join(Sep.new()->string())
enddef
