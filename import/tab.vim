vim9script

import 'window.vim'
import 'buffer.vim'

type Window = window.Window
type Buffer = buffer.Buffer

export class TabInfo
	var tabnr: number
	var variables: dict<any>
	var windows: list<Window>

	def new(this.tabnr, this.variables, this.windows)
	enddef
endclass

export class Tabpage
	var tabnr: number

	static def TabList(): list<Tabpage>
		var tabs = []
		for i in range(tabpagenr('$'))
			tabs->add(Tabpage.newByTabnr(i))
		endfor

		return tabs
	enddef

	def new(pos: string = null_string)
		execute($'{pos}tabnew')
		this.tabnr = tabpagenr()
	enddef

	def newCurrent(what: string == null_string)
		this.tabnr = what == null_string ? tabpagenr() : tabpagenr(what)
	enddef

	def newByTabnr(nr: number)
		this.tabnr = nr
	enddef

	def SetVar(name: string, value: string): string
		return settabvar(this.tabnr, name, value)
	enddef

	def GetVar(name: string): string
		return settabvar(this.tabnr, name)
	enddef

	def BufList(): list<Buffer>
		var bufnrs = tabpagebuflist(this.tabnr)

		return bufnrs->mapnew((_, bufnr) => Buffer.newByBufnr(bufnr))
	enddef

	def WinList(): list<Window>
		return this.Info().windows
	enddef

	def CountWindow(): number
		return tabpagenr('$')
	enddef

	def CountBuffer(): number
		return this.BufList()->len()
	enddef

	def Info(): TabInfo
		var infos = gettabinfo(this.tabnr)
		if infos->empty()
			return null_object
		endif

		var info = infos[0]

		return TabInfo.new(
			this.tabnr,
			info.variables,
			info.windows->mapnew((_, winid) => Window.newByWinnr(winid)),
		)
	enddef
endclass
