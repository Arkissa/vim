vim9script

import 'vim.vim'
import 'autocmd.vim'
import 'keymap.vim'
import 'log.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Zipper = vim.Zipper
type Autocmd = autocmd.Autocmd

export class Sign # {{{1
	var id: number
	var lnum: number
	var name: string

	def new(this.id, this.lnum, this.name) # {{{2
	enddef # }}}
endclass # }}}

export class BufferInfo # {{{1
	var bufnr: number
	var name: string
	var changed: bool
	var changedtick: number
	var command: bool
	var hidden: bool
	var lastused: number
	var listed: bool
	var lnum: number
	var linecount: number
	var loaded: bool
	const variables: dict<any>
	const windows: list<number>
	const popups: list<number>
	const signs: list<Sign>

	def new( # {{{2
			this.bufnr,
			this.name,
			this.changed,
			this.changedtick,
			this.command,
			this.hidden,
			this.lastused,
			this.listed,
			this.lnum,
			this.linecount,
			this.loaded,
			this.variables,
			this.windows,
			this.popups
			signs: list<Sign> = null_list,
	)
		if signs != null_list
			this.signs = signs
		endif
	enddef # }}}
endclass # }}}

export class Buffer # {{{1
	var bufnr: number
	var name: string

	def new(this.name) # {{{2
		this.bufnr = bufadd(this.name)
	enddef # }}}

	def newCurrent() # {{{2
		this.bufnr = bufnr()
		this.name = bufname(this.bufnr)
	enddef # }}}

	def newByBufnr(this.bufnr) # {{{2
		this.name = bufname(this.bufnr)
	enddef # }}}

	def LastCursorPosition(): tuple<number, number> # {{{2
		var marks = getmarklist(this.bufnr)->filter((_, m) => m.mark == "'\"")
		if marks == null_list
			return (1, 1)
		endif

		var [_, lnum, col, _] = marks[0].pos
		return (lnum, col)
	enddef # }}}

	def GetVar(name: string): any # {{{2
		return getbufvar(this.bufnr, name)
	enddef # }}}

	def GetOneLine(lnum: number): string # {{{2
		return getbufoneline(this.bufnr, lnum)
	enddef # }}}

	def GetLines(lnum: number, end: number): list<string> # {{{2
		return getbufline(lnum, end != -1 ? end : '$')
	enddef # }}}

	def SetVar(name: string, value: any) # {{{2
		setbufvar(this.bufnr, name, value)
	enddef # }}}

	def SetLine(text: string, lnum: number) # {{{2
		setbufline(this.bufnr, lnum, text)
	enddef # }}}

	def SetLines(lines: list<string>, lnum: number) # {{{2
		setbufline(this.bufnr, lnum, lines)
	enddef # }}}

	def Clear() # {{{2
		deletebufline(this.bufnr, 1, '$')
	enddef # }}}

	def AppendLine(text: string, lnum: number = this.LineCount() - 1) # {{{2
		appendbufline(this.bufnr, lnum, text)
	enddef # }}}

	def GetLinePosition(): number # {{{2
		var info = this.GetInfo()
		if info is null_object
			return 0
		endif

		return info.lnum
	enddef # }}}

	def LineCount(): number # {{{2
		var info = this.GetInfo()
		if info is null_object
			return 1
		endif

		return info.linecount
	enddef # }}}

	def IsDirectory(): bool # {{{2
		return isdirectory(this.name)
	enddef # }}}

	def IsLoaded(): bool # {{{2
		return bufloaded(this.bufnr) == 1
	enddef # }}}

	def IsExists(): bool # {{{2
		return bufexists(this.bufnr) == 1
	enddef # }}}

	def Load(): number # {{{2
		return bufload(this.bufnr)
	enddef # }}}

	def WinID(): number # {{{2
		return bufwinid(this.bufnr)
	enddef # }}}

	def Winnr(): number # {{{2
		return bufwinnr(this.bufnr)
	enddef # }}}

	def InPopupWindow(): bool # {{{2
		return this.GetInfo() isnot null_object && info.popups != null_list
	enddef # }}}

	def InWindow(): bool # {{{2
		return this.GetInfo() isnot null_object && info.windows != null_list
	enddef # }}}

	def Listed(): bool # {{{2
		return buflisted(this.bufnr)
	enddef # }}}

	def GetInfo(): BufferInfo # {{{2
		if !this.IsExists()
			return null_object
		endif

		var info = getbufinfo(this.bufnr)[0]
		return BufferInfo.new(
			info.bufnr,
			info.name,
			info.changed,
			info.changedtick,
			info.command,
			info.hidden,
			info.lastused,
			info.listed,
			info.lnum,
			info.linecount,
			info.loaded,
			info.variables,
			info.windows,
			info.popups,
			has_key(info, "signs") ? map(info.signs, (_, sign) => Sign.new(sign.id, sign.lnum, sign.name)) : null_list
		)
	enddef # }}}

	def Readable(): bool # {{{2
		return filereadable(this.name) == 1
	enddef # }}}

	def Unload() # {{{2
		execute($'silent bunload! {this.bufnr}')
	enddef # }}}

	def Delete() # {{{2
		execute($'silent bwipeout! {this.bufnr}')
	enddef # }}}
endclass # }}}

class BashStyle # {{{1
	var _history = Zipper.new()

	def Keymaps(buffer: Buffer) # {{{2
		Bind.new(Mods.i)
			.Buffer(buffer.bufnr)
			.Callback('<C-l>', buffer.Clear)
			.Callback('<C-e>', this.ToEnd)
			.Callback('<M-d>', this.DeleteAfterWord)
			.Callback('<C-w>', this.DeleteBeforeWord)
			.Callback('<C-k>', this.DeleteToEnd)
			.Callback('<Up>', this.OnUp)
			.Callback('<C-p>', this.OnUp)
			.Callback('<Down>', this.OnDown)
			.Callback('<C-n>', this.OnDown)
	enddef # }}}

	def DeleteAfterWord() # {{{2
		var lnum = line('.')
		var col = col('.')
		var buffer = Buffer.newCurrent()
		var line = buffer.GetOneLine(lnum)
		var start = line->strcharpart(0, col - 1)
		buffer.SetLine(start .. substitute(line->strcharpart(col), '^.\{-\}\<\k\+\>', '', ''), lnum)
	enddef # }}}

	def DeleteBeforeWord() # {{{2
		var lnum = line('.')
		var col = col('.')
		var buffer = Buffer.newCurrent()
		var line = buffer.GetOneLine(lnum)

		var prompt = prompt_getprompt(buffer.bufnr)
		var start = trim(line->strcharpart(0, col - 1), prompt)
		start = substitute(start, '\%(\s*\S\+\|\s\+\)$', '', '')
		buffer.SetLine($'{prompt}{start}{line->strcharpart(col)}', lnum)
	enddef # }}}

	def DeleteToEnd() # {{{2
		var buffer = Buffer.newCurrent()
		var [_, lnum, col, _] = getcharpos('.')
		var line = buffer.GetOneLine(lnum)
		buffer.SetLine(strpart(line, 0, col - 1), lnum)
	enddef # }}}

	def ToEnd() # {{{2
		setcursorcharpos(line('.'), col('$'))
	enddef # }}}

	def OnUp() # {{{2
		this._history.Left()
		if this._history.Peek() == null
			this._history.Left()
		endif

		var lnum = line('.')
		var buffer = Buffer.newCurrent()
		var lines = (this._history.Peek() ?? '')->split("\n")
		lines = lines ?? ['']

		var prompt = prompt_getprompt(buffer.bufnr)
		lines[0] = prompt .. lines[0]
		buffer.SetLines(lines, lnum)
		setcursorcharpos(lnum, col('$'))
	enddef # }}}

	def OnDown() # {{{2
		this._history.Right()

		var lnum = line('.')
		var buffer = Buffer.newCurrent()
		var lines = (this._history.Peek() ?? '')->split("\n")
		lines = lines ?? ['']

		var prompt = prompt_getprompt(buffer.bufnr)
		lines[0] = prompt .. lines[0]
		buffer.SetLines(lines, lnum)
		setcursorcharpos(lnum, col('$'))
	enddef # }}}

	def History(F: func(string)): func(string) # {{{2
		def Record(text: string)
			F(text)
			if trim(text) != ''
				this._history.Push(text)
				this._history.Right()
			endif
		enddef

		return Record
	enddef # }}}
endclass # }}}

export class Prompt extends Buffer # {{{1
	var _bash = BashStyle.new()
	static final _count = vim.IncID.new()

	static def _Name(name: string = ''): string # {{{2
		var id = _count.ID()
		return $'prompt-buffer://{name ?? $'prompt-{id + 1}'}'
	enddef # }}}

	def new(name: string) # {{{2
		this.name = _Name(name)
		this.bufnr = bufadd(this.name)

		this.SetVar('&buftype', 'prompt')
		this.SetVar('&bufhidden', 'hide')
		this.SetVar('&buflisted', false)
	enddef # }}}

	def newByBufnr(bufnr: number) # {{{2
		this.bufnr = bufnr
		this.name = _Name(bufname(bufnr))

		this.SetVar('&buftype', 'prompt')
		this.SetVar('&bufhidden', 'hidden')
		this.SetVar('&buflisted', false)
	enddef # }}}

	def BashStyleKeymaps() # {{{2
		this._bash.Keymaps(this)
	enddef # }}}

	def GetPrompt(): string # {{{2
		return prompt_getprompt(this.bufnr)
	enddef # }}}

	def SetPrompt(prompt: string) # {{{2
		prompt_setprompt(this.bufnr, prompt)
	enddef # }}}

	def SetCallback(F: func(string)) # {{{2
		prompt_setcallback(this.bufnr, this._bash.History(F))
	enddef # }}}

	def SetInterrupt(F: func()) # {{{2
		prompt_setinterrupt(this.bufnr, F)
	enddef # }}}
endclass # }}}

export class Terminal extends Buffer # {{{1
	def new(cmd: string, opt: dict<any>) # {{{2
		opt.hidden = true
		this.bufnr = term_start(cmd, opt)
		this.name = bufname(this.bufnr)
		this.SetVar("&buflisted", false)
		this.SetVar("&relativenumber", false)
		this.SetVar("&number", false)
	enddef # }}}

	def GetJob(): job # {{{2
		return term_getjob(this.bufnr)
	enddef # }}}

	def GetLine(row: number): string # {{{2
		return term_getline(this.bufnr, row)
	enddef # }}}

	def GetSize(): number # {{{2
		return term_getsize(this.bufnr)
	enddef # }}}

	def GetTitle(): string # {{{2
		return term_gettitle(this.bufnr)
	enddef # }}}

	def SendKeys(k: string) # {{{2
		term_sendkeys(this.bufnr, k) == 0
	enddef # }}}

	def SetAPI(s: string) # {{{2
		term_setapi(this.bufnr, s)
	enddef # }}}

	def SetRestore(c: string) # {{{2
		term_setrestore(this.bufnr, c)
	enddef # }}}

	def Wait(time: number) # {{{2
		term_wait(this.bufnr, time)
	enddef # }}}

	def Status(): string # {{{2
		return term_getstatus(this.bufnr)
	enddef # }}}

	def Stop() # {{{2
		job_stop(this.GetJob(), 'kill')
	enddef # }}}
endclass # }}}
