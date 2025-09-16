vim9script

export class Sign # {{{1
	var id: number # {{{2
	var lnum: number # {{{2
	var name: string # {{{2

	def new(this.id, this.lnum, this.name) # {{{2
	enddef # }}}
endclass # }}}

export class BufferInfo # {{{1
	var bufnr: number # {{{2
	var name: string # {{{2
	var changed: bool # {{{2
	var changedtick: number # {{{2
	var command: bool # {{{2
	var hidden: bool # {{{2
	var lastused: number # {{{2
	var listed: bool # {{{2
	var lnum: number # {{{2
	var linecount: number # {{{2
	var loaded: bool # {{{2
	const variables: dict<any> # {{{2
	const windows: list<number> # {{{2
	const popups: list<number> # {{{2
	const signs: list<Sign> # {{{2

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
	var bufnr: number # {{{2
	var name: string # {{{2

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

		var pos = marks[0].pos
		var lastLine = this.LineCount()
		return (pos[1] > lastLine ? lastLine : pos[1], pos[2])
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
	def SetLines(lines: list<string>)
		setbufline(this.bufnr, lines)
	enddef

	def Clear()
		setbufline(this.bufnr, [])
	enddef

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
		execute($'silent bdelete! {this.bufnr}')
	enddef # }}}

	def Delete() # {{{2
		execute($'silent bwipeout! {this.bufnr}')
	enddef # }}}
endclass # }}}

export class Prompt extends Buffer # {{{1
	static var _count: number = -1 # {{{2

	static def _Name(name: string = ''): string # {{{2
		_count += 1
		if _count == 0
			return name ? '(prompt)' : $'({name})'
		endif

		return name ? $'(prompt-{_count})' : $'({name}-{_count})'
	enddef # }}}

	def new(name: string = _Name()) # {{{2
		this.bufnr = bufadd(name)
		this.name = name

		this.SetVar('&buftype', 'prompt')
		execute('startinsert')
	enddef # }}}

	def newByBufnr(bufnr: number) # {{{2
		this.bufnr = bufnr
		this.name = _Name(bufname(bufnr))

		this.SetVar('&buftype', 'prompt')
		execute('startinsert')
	enddef # }}}

	def GetPrompt(): string # {{{2
		return prompt_getprompt(this.bufnr)
	enddef # }}}

	def SetPrompt(prompt: string) # {{{2
		prompt_setprompt(this.bufnr, prompt)
	enddef # }}}

	def SetCallback(F: func(Prompt, string)) # {{{2
		prompt_setcallback(this.bufnr, function(F, [this]))
	enddef # }}}

	def SetInterrupt(F: func(Prompt)) # {{{2
		prompt_setinterrupt(this.bufnr, function(F, [this]))
	enddef # }}}
endclass # }}}

export class Terminal extends Buffer # {{{1
	def new(cmd: string, opt: dict<any>) # {{{2
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
