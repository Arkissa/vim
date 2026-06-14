vim9script

import 'buffer.vim'
import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

const group = "TerminalDrop"

interface Droper
	def Run()
endinterface

export enum Mods
	Tab,
	Default

	def string(): string
		if this == Tab
			return "tab"
		else
			return "default"
		endif
	enddef
endenum

export class Arg
	var opts: list<string>
	var files: list<string>
	var token: string
	var mods: Mods
	var termbufnr: number

	def new(this.termbufnr, this.opts, this.files, token: string = "", mods: Mods = Mods.Default)
		this.mods = mods
		this.token = token
	enddef
endclass

class DefaultDrop implements Droper
	var drop: string

	def new(opts: list<string>, files: list<string>)
		this.drop = ["drop"]->extend(opts)->extend(files)->join(' ')
	enddef

	def Run()
		execute(this.drop)
	enddef
endclass

class TabDrop implements Droper
	var drop: string

	def new(opts: list<string>, files: list<string>)
		this.drop = ["tab", "drop"]->extend(opts)->extend(files)->join(' ')
	enddef

	def Run()
		execute(this.drop)
	enddef
endclass

export def Drop(arg: Arg)
	var droper: Droper

	if arg.mods == Mods.Tab
		droper = TabDrop.new(arg.opts, arg.files)
	else
		droper = DefaultDrop.new(arg.opts, arg.files)
	endif

	droper.Run()
	var b = buffer.Buffer.newCurrent()
	b.SetVar('&bufhidden', 'wipe')

	if arg.token->empty()
		return
	endif

	Autocmd.new('BufWipeout')
		.Group(group)
		.Bufnr(b.bufnr)
		.Once()
		.Callback(() => {
			term_sendkeys(arg.termbufnr, arg.token .. "\n")
		})
enddef
