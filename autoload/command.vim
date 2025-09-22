vim9script

import './quickfix.vim'
import './log.vim'
import './job.vim' as jb
import './vim.vim'

type Coroutine = vim.Coroutine

export enum NArgs # {{{1
	Zero('0'), # {{{2
	One('1'), # {{{2
	Star('*'), # {{{2
	Quest('?'), # {{{2
	Plus('+') # {{{2

	var Value: string # {{{2
endenum # }}}

export enum Range # {{{1
	Empty(''), # {{{2
	Persent('%'), # {{{2
	N('N') # {{{2

	var Value: string
endenum # }}}

export class Mods # {{{1
	var silent: bool # {{{2
	var unsilent: bool # {{{2
	var sandbox: bool # {{{2
	var browse: bool # {{{2
	var confirm: bool # {{{2
	var hide: bool # {{{2
	var noautocmd: bool # {{{2
	var noswapfile: bool # {{{2
	var horizontal: bool # {{{2
	var vertical: bool # {{{2
	var keepalt: bool # {{{2
	var keepjumps: bool # {{{2
	var keepmarks: bool # {{{2
	var keeppatterns: bool # {{{2
	var split: string # {{{2
	var tab: bool # {{{2
	var verbose: bool # {{{2

	def new( # {{{2
		this.silent,
		this.unsilent,
		this.sandbox,
		this.browse,
		this.confirm,
		this.hide,
		this.noautocmd,
		this.noswapfile,
		this.horizontal,
		this.vertical,
		this.keepalt,
		this.keepjumps,
		this.keepmarks,
		this.keeppatterns,
		this.split,
		this.tab,
		this.verbose,
	)
	enddef # }}}
endclass # }}}

export class Attr # {{{1
	var name: string # {{{2
	var args: string # {{{2
	var fargs: list<string> # {{{2
	var bang: bool # {{{2
	var line1: number # {{{2
	var line2: number # {{{2
	var count: number # {{{2
	var range: number # {{{2
	var reg: string # {{{2
	var mods: Mods # {{{2

	def new( # {{{2
		this.name,
		this.args,
		this.fargs,
		this.bang,
		this.line1,
		this.line2,
		this.count,
		this.range,
		this.reg,
		this.mods,
	)
	enddef # }}}
endclass # }}}

export enum Addr # {{{1
	Lines('lines'), # {{{2
	Arguments('arguments'), # {{{2
	Buffers('buffers'), # {{{2
	Loaded_buffers('loaded_buffers'), # {{{2
	Windows('windows'), # {{{2
	Tabs('tabs'), # {{{2
	Quickfix('quickfix'), # {{{2
	Other('other') # {{{2

	var Value: string
endenum # }}}

export enum Complete # {{{1
	Arglist('arglist'), # {{{2
	Augroup('augroup'), # {{{2
	Behave('behave'), # {{{2
	Breakpoint('breakpoint'), # {{{2
	Buffer('buffer'), # {{{2
	Color('color'), # {{{2
	Command('command'), # {{{2
	Compiler('compiler'), # {{{2
	Cscope('cscope'), # {{{2
	DiffBuffer('diff_buffer'), # {{{2
	Dir('dir'), # {{{2
	DirInPath('dir_in_path'), # {{{2
	Environment('environment'), # {{{2
	Event('event'), # {{{2
	Expression('expression'), # {{{2
	File('file'), # {{{2
	FileInPath('file_in_path'), # {{{2
	Filetype('filetype'), # {{{2
	Function('function'), # {{{2
	Help('help'), # {{{2
	Highlight('highlight'), # {{{2
	History('history'), # {{{2
	Keymap('keymap'), # {{{2
	Locale('locale'), # {{{2
	Mapclear('mapclear'), # {{{2
	Mapping('mapping'), # {{{2
	Menu('menu'), # {{{2
	Messages('messages'), # {{{2
	Option('option'), # {{{2
	Packadd('packadd'), # {{{2
	Retab('retab'), # {{{2
	Runtime('runtime'), # {{{2
	Scriptnames('scriptnames'), # {{{2
	ShellCmd('shellcmd'), # {{{2
	ShellCmdLine('shellcmdline'), # {{{2
	Sign('sign'), # {{{2
	Syntax('syntax'), # {{{2
	Syntime('syntime'), # {{{2
	Tag('tag'), # {{{2
	TagListfiles('tag_listfiles'), # {{{2
	User('user'), # {{{2
	Var('var'), # {{{2
	Custom('custom'), # {{{2
	CustomList('customlist') # {{{2

	var Value: string
endenum # }}}

export class Command # {{{1
	var _attr: list<string> = [] # {{{2
	var _mods: bool # {{{2
	var _overlay: bool # {{{2
	var _name: string # {{{2
	var _F: func(Attr) # {{{2
	static var _CommandInternalFunctions: dict<func(Attr)> = {} # {{{2
	static var _CompleteFunctions: dict<func(string, string, number): list<string>> = {} # {{{2

	def new(this._name) # {{{2
	enddef # }}}

	static def InternalFunction(cmdName: string): func(Attr) # {{{2
		return _CommandInternalFunctions[cmdName]
	enddef # }}}

	static def InternalComplete(cmdName: string): func(string, string, number): list<string> # {{{2
		return _CompleteFunctions[cmdName]
	enddef # }}}

	def Bang(): Command # {{{2
		add(this._attr, '-bang')
		return this
	enddef # }}}

	def Overlay(): Command # {{{2
		this._overlay = true
		return this
	enddef # }}}

	def Register(): Command # {{{2
		add(this._attr, '-register')
		return this
	enddef # }}}

	def Bar(): Command # {{{2
		add(this._attr, '-bar')
		return this
	enddef # }}}

	def Buffer(): Command # {{{2
		add(this._attr, '-buffer')
		return this
	enddef # }}}

	def KeepScript(): Command # {{{2
		add(this._attr, '-keepscript')
		return this
	enddef # }}}

	def NArgs(n: NArgs = NArgs.Zero): Command # {{{2
		add(this._attr, $'-nargs={n.Value}')
		return this
	enddef # }}}

	def Count(n: number = -1): Command # {{{2
		add(this._attr, $'-count{n > -1 ? '=' .. n->string() : ''}')
		return this
	enddef # }}}

	def Range(n: Range = Range.N): Command # {{{2
		var range = n != Range.Empty ? $'-range={n.Value}' : '-range'
		add(this._attr, range)
		return this
	enddef # }}}

	def Addr(a: Addr): Command # {{{2
		add(this._attr, $'-addr={a.Value}')
		return this
	enddef # }}}

	def Complete(cmp: Complete, F: func(string, string, number): any = null_function): Command # {{{2
		var str = $'-complete={cmp.Value}'
		if cmp.Value =~# '^custom'
			_CompleteFunctions[this._name] = F
			str ..= $',Command.InternalComplete("{this._name}")'
		endif

		add(this._attr, str)
		return this
	enddef # }}}

	def Command(cmd: string) # {{{2
		execute($'command{this._overlay ? '!' : ''} {join(this._attr, ' ')} {this._name} {cmd}')
	enddef # }}}

	def Callback(F: func(Attr)) # {{{2
		if _CommandInternalFunctions->has_key(this._name) && !this._overlay
			throw $'E174: Command already exists: use .Overlay() to replace it: {this._name}'
		endif

		var c = 'command'
		if this._overlay
			c ..= '!'
		endif

		_CommandInternalFunctions[this._name] = F

		var s =<< trim END
		%s %s %s {
			var mods = <q-mods>
			var spt = ''
			if indexof(["aboveleft", "belowright", "botright", "leftabove"], (_, m) => mods =~# m) != -1
				spt = mods->split(' ')[0]
			endif
			var attr = Attr.new(
				"%s",
				<q-args>,
				[<f-args>],
				!empty(<q-bang>),
				<line1>,
				<line2>,
				<count>,
				<range>,
				"<reg>",
				Mods.new(
					mods == "silent",
					mods == "unsilent",
					mods == "sandbox",
					mods == "browse",
					mods == "confirm",
					mods == "hide",
					mods == "noautocmd",
					mods == "noswapfile",
					mods =~ "horizontal",
					mods =~ "vertical",
					mods == "keepalt",
					mods == "keepjumps",
					mods == "keepmarks",
					mods == "keeppatterns",
					spt,
					mods == "tab",
					mods == "verbose",
				)
			)
			call(Command.InternalFunction("%s"), [attr])
		}
		END

		execute(printf(s->join("\n"), c, join(this._attr, " "), this._name, this._name, this._name))
	enddef # }}}
endclass # }}}

export abstract class Execute extends jb.Quickfixer # {{{1
	var _attr: Attr # {{{2
	var _attrD: dict<any> # {{{2

	abstract def Cmd(): string # {{{2
	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string) # {{{2

	def CloseCb(qf: quickfix.Quickfixer, chan: channel) # {{{2
		qf.Close() # Prevent quickfix typographical errors
	enddef # }}}

	def Attr(attr: Attr, location: bool = false): Execute # {{{2
		this._attr = attr
		this._location = location
		return this
	enddef # }}}

	def ExitCb(qf: quickfix.Quickfixer, job: job, code: number) # {{{2
		if this.Status() == 'fail'
			log.Error('Error: Job is failed on exit callback.')
			return
		endif

		vim.AsyncIO.Run(Coroutine.new(() => {
			qf.Window()
			if this._attr.bang
				qf.JumpFirst()
			endif
		}))

		if !this._attr.mods.silent
			:redraw
			:echo $'Job ({this.Info().process}) Exit Code: {code}'
		endif
	enddef # }}}

	def Run() # {{{2
		var param = expandcmd(this._attr.args)
		var cmd = this.Cmd()
		var sep = '\$\*'

		var expandedCmd: string
		if cmd =~ sep
			expandedCmd = substitute(cmd, sep, param, '')
		else
			expandedCmd = $'{trim(cmd)} {param}'
		endif

		this._cmd = expandedCmd

		super.Run()
	enddef # }}}
endclass # }}}

export abstract class ErrorFormat extends Execute # {{{1
	abstract def Cmd(): string # {{{2
	abstract def Efm(): string # {{{2

	def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string) # {{{2
		if this.Status() == 'fail'
			log.Error('Error: Job is failed on output callback.')
			return
		endif

		var info = this.Info()

		qf.SetList([], quickfix.Action.A, {
			efm: this.Efm(),
			lines: [msg],
			title: info == null_dict ? info.cmd : this.Cmd()
		})
	enddef # }}}
endclass # }}}
