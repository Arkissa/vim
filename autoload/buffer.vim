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

	def new()
		this.bufnr = bufnr()
		this.name = bufname(this.bufnr)
	enddef

	def newByBufnr(this.bufnr)
		this.name = bufname(this.bufnr)
	enddef

	def newByName(this.name)
		this.bufnr = bufadd(this.name)
	enddef

	def LastCursorPosition(): tuple<number, number>
		var marks = getmarklist(this.bufnr)->filter((_, m) => m.mark == "'\"")
		if marks is null_list
			return (1, 1)
		endif

		var pos = marks[0].pos
		var lastLine = this.LineCount()
		return (pos[1] > lastLine ? lastLine : pos[1], pos[2])
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
		return setbufvar(this.bufnr, name, value)
	enddef

	def SetLine(lnum: number, text: string)
		return setbufline(this.bufnr, lnum, text)
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
			return 0
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
			info.variables,
			info.windows,
			info.popups,
			has_key(info, "signs") ? map(info.signs, (_, sign) => Sign.new(sign.id, sign.lnum, sign.name)) : null_list
		)
	enddef

	def Readable(): bool
		return filereadable(this.name) == 1
	enddef
endclass
