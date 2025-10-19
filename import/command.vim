vim9script

import 'log.vim'
import 'job.vim' as jb
import 'vim.vim'
import 'autocmd.vim'
import 'quickfix.vim'

type Autocmd = autocmd.Autocmd
type Coroutine = vim.Coroutine

export enum NArgs
	Zero('0'),
	One('1'),
	Star('*'),
	Quest('?'),
	Plus('+')

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

export enum Complete
	Arglist('arglist'),
	Augroup('augroup'),
	Behave('behave'),
	Breakpoint('breakpoint'),
	Buffer('buffer'),
	Color('color'),
	Command('command'),
	Compiler('compiler'),
	Cscope('cscope'),
	DiffBuffer('diff_buffer'),
	Dir('dir'),
	DirInPath('dir_in_path'),
	Environment('environment'),
	Event('event'),
	Expression('expression'),
	File('file'),
	FileInPath('file_in_path'),
	Filetype('filetype'),
	Function('function'),
	Help('help'),
	Highlight('highlight'),
	History('history'),
	Keymap('keymap'),
	Locale('locale'),
	Mapclear('mapclear'),
	Mapping('mapping'),
	Menu('menu'),
	Messages('messages'),
	Option('option'),
	Packadd('packadd'),
	Retab('retab'),
	Runtime('runtime'),
	Scriptnames('scriptnames'),
	ShellCmd('shellcmd'),
	ShellCmdLine('shellcmdline'),
	Sign('sign'),
	Syntax('syntax'),
	Syntime('syntime'),
	Tag('tag'),
	TagListfiles('tag_listfiles'),
	User('user'),
	Var('var'),
	Custom('custom'),
	CustomList('customlist')

	var Value: string
endenum

export class Command
	var _attr: list<string> = []
	var _mods: bool
	var _overlay: bool
	var _name: string
	var _F: func(Attr)
	static var _CommandInternalFunctions: dict<func> = {}
	static var _CompleteFunctions: dict<func(string, string, number): list<string>> = {}

	static def Delete(cmd: string, buffer: bool = false)
		execute($'delcommand{buffer ? ' -buffer' : ''} {cmd}')
		_CommandInternalFunctions->remove(cmd)
		_CompleteFunctions->remove(cmd)
	enddef

	def new(this._name)
	enddef

	static def InternalFunction(cmdName: string): func
		return _CommandInternalFunctions[cmdName]
	enddef

	static def InternalComplete(cmdName: string): func(string, string, number): list<string>
		return _CompleteFunctions[cmdName]
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

	def Count(n: number = -1): Command
		add(this._attr, $'-count{n > -1 ? '=' .. n->string() : ''}')
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

	def Complete(cmp: Complete, F: func(string, string, number): any = null_function): Command
		var str = $'-complete={cmp.Value}'
		if cmp.Value =~# '^custom'
			_CompleteFunctions[this._name] = F
			str ..= $',Command.InternalComplete("{this._name}")'
		endif

		add(this._attr, str)
		return this
	enddef

	def Command(cmd: string)
		execute($'command{this._overlay ? '!' : ''} {join(this._attr, ' ')} {this._name} {cmd}')
	enddef

	def Callback(F: func)
		var f = typename(F)
		if ['func(Attr)', 'func(any)', 'func()']->index(f) == -1
			throw $'Command Callback: only register func() or func(Attr) type function but got {f}.'
		endif

		if _CommandInternalFunctions->has_key(this._name) && !this._overlay
			throw $'E174: Command already exists: use .Overlay() to replace it: {this._name}'
		endif

		var c = 'command'
		if this._overlay
			c ..= '!'
		endif

		_CommandInternalFunctions[this._name] = F

		if f == 'func()'
			execute($'{c} {join(this._attr, " ")} {this._name} call(Command.InternalFunction("{this._name}"), [])')
			return
		endif

		var cmd	=<< trim END
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

		execute(printf(cmd->join("\n"), c, join(this._attr, " "), this._name, this._name, this._name))
	enddef
endclass

export abstract class Execute extends jb.Quickfixer
	var _attr: Attr
	var _attrD: dict<any>

	abstract def Cmd(): string
	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)

	def CloseCb(qf: quickfix.Quickfixer, chan: channel)
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

		if this._attr.bang
			qf.JumpFirst()
		endif

		if this._attr != null_object && exists($'#QuickFixPost#{this._attr.name}')
			Autocmd.Do('', 'QuickFixPost', this._attr.name)
		endif

		var info = this.Info()
		if !this._attr.mods.silent
			var lable: string
			if code > 0
				lable = 'Failure:'
			elseif code == 0
				lable = 'Success:'
			else
				lable = 'Complete:'
			endif

			:redraw
			echo $'{lable} !{info.cmd->join(' ')} (job/{info.process})'
		endif
	enddef

	def Expandcmd(cmd: string): string
		var param = expandcmd(this._attr.args)
		var sep = '\$\*'

		var expandedCmd: string
		if cmd =~ sep
			expandedCmd = substitute(cmd, sep, param, '')
		else
			expandedCmd = $'{trim(cmd)} {param}'
		endif

		return expandedCmd
	enddef

	def Run()
		if this._attr != null_object && exists($'#QuickFixPre#{this._attr.name}')
			Autocmd.Do('', 'QuickFixPre', this._attr.name)
		endif

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
			title: info == null_dict ? info.cmd->join(' ') : this.Cmd()
		})
	enddef
endclass

export abstract class JsonFormat extends Execute
	abstract def Cmd(): string
	abstract def Decode(text: string): quickfix.QuickfixItem

	def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)
		if this.Status() == 'fail'
			log.Error('Error: Job is failed on output callback.')
			return
		endif

		var info = this.Info()

		qf.SetList([this.Decode(msg)], quickfix.Action.A, {
			title: info == null_dict ? info.cmd : this.Cmd()
		})
	enddef

	def Run()
		this._opt->extend({
			out_mode: 'json',
			err_mode: 'json',
		}, 'force')

		super.Run()
	enddef
endclass
