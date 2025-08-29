vim9script

export class Buffer
	var bufnr: number
	var name: string

	def new(this.bufnr)
		this.name = bufname(bufnr)
	enddef

	def newName(this.name)
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

	def QuickfixItem(): dict<any>
		var [lnum, col] = this.LastCursorPosition()
		var line = getbufoneline(this.bufnr, lnum)

		return {
			bufnr: this.bufnr,
			col: col,
			lnum: lnum,
			end_col: 0,
			end_lnum: 0,
			nr: 0,
			text: line,
			valid: 1,
		}
	enddef

	def GetVar(name: string): any
		return getbufvar(this.bufnr, name)
	enddef

	def SetVar(name: string, value: any)
		return setbufvar(this.bufnr, name, value)
	enddef

	def SetLine(lnum: number, text: string)
		return setbufline(this.bufnr, lnum, text)
	enddef

	def LineCount(): number
		var info = getbufinfo(this.bufnr)[0]
		return info.linecount
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
endclass
