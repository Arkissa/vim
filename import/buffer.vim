vim9script

export class Sign
	var id: number
	var lnum: number
	var name: string

	def new(this.id, this.lnum, this.name)
	enddef
endclass

export class BufferInfo
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

	def new(
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
	enddef
endclass

export class Buffer
	var bufnr: number
	var name: string

	def new(this.name)
		this.bufnr = bufadd(this.name)
	enddef

	def newCurrent()
		this.bufnr = bufnr()
		this.name = bufname(this.bufnr)
	enddef

	def newByBufnr(this.bufnr)
		this.name = bufname(this.bufnr)
	enddef

	def LastCursorPosition(): tuple<number, number>
		var marks = getmarklist(this.bufnr)->filter((_, m) => m.mark == "'\"")
		if marks == null_list
			return (1, 1)
		endif

		var [_, lnum, col, _] = marks[0].pos
		return (lnum, col)
	enddef

	def GetVar(name: string): any
		return getbufvar(this.bufnr, name)
	enddef

	def GetOneLine(lnum: number): string
		return getbufoneline(this.bufnr, lnum)
	enddef

	def GetLines(lnum: number, end: number): list<string>
		return getbufline(lnum, end != -1 ? end : '$')
	enddef

	def SetVar(name: string, value: any)
		setbufvar(this.bufnr, name, value)
	enddef

	def SetLine(text: string, lnum: number)
		setbufline(this.bufnr, lnum, text)
	enddef

	def SetLines(lines: list<string>)
		setbufline(this.bufnr, lines)
	enddef

	def Clear()
		setbufline(this.bufnr, [])
	enddef

	def AppendLine(text: string, lnum: number = this.LineCount() - 1)
		appendbufline(this.bufnr, lnum, text)
	enddef

	def GetLinePosition(): number
		var info = this.GetInfo()
		if info is null_object
			return 0
		endif

		return info.lnum
	enddef

	def LineCount(): number
		var info = this.GetInfo()
		if info is null_object
			return 1
		endif

		return info.linecount
	enddef

	def IsDirectory(): bool
		return isdirectory(this.name)
	enddef

	def IsLoaded(): bool
		return bufloaded(this.bufnr) == 1
	enddef

	def IsExists(): bool
		return bufexists(this.bufnr) == 1
	enddef

	def Load(): number
		return bufload(this.bufnr)
	enddef

	def WinID(): number
		return bufwinid(this.bufnr)
	enddef

	def Winnr(): number
		return bufwinnr(this.bufnr)
	enddef

	def InPopupWindow(): bool
		return this.GetInfo() isnot null_object && info.popups != null_list
	enddef

	def InWindow(): bool
		return this.GetInfo() isnot null_object && info.windows != null_list
	enddef

	def Listed(): bool
		return buflisted(this.bufnr)
	enddef

	def GetInfo(): BufferInfo
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
	enddef

	def Readable(): bool
		return filereadable(this.name) == 1
	enddef

	def Unload()
		execute($'silent bunload! {this.bufnr}')
	enddef

	def Delete()
		execute($'silent bwipeout! {this.bufnr}')
	enddef
endclass

export class Prompt extends Buffer
	static var _count: number = -1

	static def _Name(name: string = ''): string
		_count += 1
		if _count == 0
			return name ? '(prompt)' : $'({name})'
		endif

		return name ? $'(prompt-{_count})' : $'({name}-{_count})'
	enddef

	def new(name: string = _Name())
		this.bufnr = bufadd(name)
		this.name = name

		this.SetVar('&buftype', 'prompt')
		this.SetVar('&bufhidden', 'wipe')
	enddef

	def newByBufnr(bufnr: number)
		this.bufnr = bufnr
		this.name = _Name(bufname(bufnr))

		this.SetVar('&buftype', 'prompt')
		this.SetVar('&bufhidden', 'wipe')
	enddef

	def GetPrompt(): string
		return prompt_getprompt(this.bufnr)
	enddef

	def SetPrompt(prompt: string)
		prompt_setprompt(this.bufnr, prompt)
	enddef

	def SetCallback(F: func(string))
		prompt_setcallback(this.bufnr, F)
	enddef

	def SetInterrupt(F: func())
		prompt_setinterrupt(this.bufnr, F)
	enddef
endclass

export class Terminal extends Buffer
	def new(cmd: string, opt: dict<any>)
		opt.hidden = true
		this.bufnr = term_start(cmd, opt)
		this.name = bufname(this.bufnr)
		this.SetVar("&buflisted", false)
		this.SetVar("&relativenumber", false)
		this.SetVar("&number", false)
	enddef

	def GetJob(): job
		return term_getjob(this.bufnr)
	enddef

	def GetLine(row: number): string
		return term_getline(this.bufnr, row)
	enddef

	def GetSize(): number
		return term_getsize(this.bufnr)
	enddef

	def GetTitle(): string
		return term_gettitle(this.bufnr)
	enddef

	def SendKeys(k: string)
		term_sendkeys(this.bufnr, k) == 0
	enddef

	def SetAPI(s: string)
		term_setapi(this.bufnr, s)
	enddef

	def SetRestore(c: string)
		term_setrestore(this.bufnr, c)
	enddef

	def Wait(time: number)
		term_wait(this.bufnr, time)
	enddef

	def Status(): string
		return term_getstatus(this.bufnr)
	enddef

	def Stop()
		job_stop(this.GetJob(), 'kill')
	enddef
endclass
