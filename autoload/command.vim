vim9script

import './quickfix.vim'
import './log.vim'
import './job.vim' as jb
import './vim.vim'

export enum NArgs
	Zero('0'),
	One('1'),
	Star('*'),
	Quest('?'),
	Plus('+')

	var Value: string
endenum

export enum Count
	Zero('0'),
	N('N')

	var Value: string
endenum

export enum Range
	Empty(''),
	Persent('%'),
	N('N')

	var Value: string
endenum

export class Mods
	var silent: bool
	var unsilent: bool
	var sandbox: bool
	var browse: bool
	var confirm: bool
	var hide: bool
	var noautocmd: bool
	var noswapfile: bool
	var horizontal: bool
	var vertical: bool
	var keepalt: bool
	var keepjumps: bool
	var keepmarks: bool
	var keeppatterns: bool
	var split: string
	var tab: bool
	var verbose: bool

	def new(
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
	enddef
endclass

export class Attr
	var name: string
	var args: string
	var fargs: list<string>
	var bang: bool
	var line1: number
	var line2: number
	var count: number
	var range: number
	var reg: string
	var mods: Mods

	def new(
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
	enddef
endclass

export enum Addr
	Lines('lines'),
	Arguments('arguments'),
	Buffers('buffers'),
	Loaded_buffers('loaded_buffers'),
	Windows('windows'),
	Tabs('tabs'),
	Quickfix('quickfix'),
	Other('other')

	var Value: string
endenum

export class Command
	var _attr: list<string> = []
	var _mods: bool
	var _overlay: bool
	var _name: string
	var _F: func(Attr)
	static var _CommandInternalFunctions = {}
	var _CompleteFunctions: func()

	def new(this._name)
	enddef

	static def InternalFunction(cmdName: string): func(Attr)
		return _CommandInternalFunctions[cmdName]
	enddef

	def Bang(): Command
		add(this._attr, '-bang')
		return this
	enddef

	def Overlay(): Command
		this._overlay = true
		return this
	enddef

	def Register(): Command
		add(this._attr, '-register')
		return this
	enddef

	def Bar(): Command
		add(this._attr, '-bar')
		return this
	enddef

	def Buffer(): Command
		add(this._attr, '-buffer')
		return this
	enddef

	def KeepScript(): Command
		add(this._attr, '-keepscript')
		return this
	enddef

	def NArgs(n: NArgs = NArgs.Zero): Command
		add(this._attr, $'-nargs={n.Value}')
		return this
	enddef

	def Count(n: Count = Count.N): Command
		add(this._attr, $'-count=${n.Value}')
		return this
	enddef

	def Range(n: Range = Range.N): Command
		var range = n != Range.Empty ? $'-range={n.Value}' : '-range'
		add(this._attr, range)
		return this
	enddef

	def Addr(a: Addr): Command
		add(this._attr, $'-addr={a.Value}')
		return this
	enddef

	def Complete()
	enddef

	def Command(cmd: string)
		execute($'command{this._overlay ? '!' : ''} {join(this._attr, ' ')} {this._name} {cmd}')
	enddef

	def Callback(F: func(Attr))
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
					mods == "horizontal",
					mods == "vertical",
					mods == "keepalt",
					mods == "keepjumps",
					mods == "keepmarks",
					mods == "keeppatterns",
					index(["aboveleft", "belowright", "botright", "leftabove"], mods) != -1 ? mods : "",
					mods == "tab",
					mods == "verbose",
				)
			)
			timer_start(0, (_) => call(Command.InternalFunction("%s"), [attr]))
		}
		END

		execute(printf(s->join("\n"), c, join(this._attr, " "), this._name, this._name, this._name))
	enddef
endclass

export abstract class Execute extends jb.Job
	var _attr: Attr
	var _attrD: dict<any>

	abstract def Cmd(): string
	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)
	def CloseCb(qf: quickfix.Quickfixer, chan: channel)
		qf.Close() # Prevent quickfix typographical errors
	enddef

	def Attr(attr: Attr, location: bool = false): Execute
		this._attr = attr
		this._location = location
		return this
	enddef

	def ExitCb(qf: quickfix.Quickfixer, job: job, code: number)
		if this.Status() == 'fail'
			log.Error('Error: Job is failed on exit callback.')
			return
		endif

		vim.Promise.new(() => {
			qf.Window()
			if this._attr.bang
				qf.JumpFirst()
			endif
		})

		if !this._attr.mods.silent
			:redraw
			:echo $'Job ({this.Info().process}) Exit Code: {code}'
		endif
	enddef

	def Run()
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
	enddef
endclass

export abstract class ErrorFormat extends Execute
	abstract def Cmd(): string
	abstract def Efm(): string

	def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)
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
	enddef
endclass
