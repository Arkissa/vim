vim9script

import 'vim.vim'
import 'window.vim'
import 'buffer.vim'
import 'autocmd.vim'

type Ring = vim.Ring
type Window = window.Window
type Autocmd = autocmd.Autocmd
type Terminal = buffer.Terminal

enum Split # {{{1
	None(''),
	Vertical('vertical'),
	Horizontal('horizontal')

	var Value: string
endenum # }}}

enum Mod # {{{1
	None(''),
	Aboveleft('aboveleft'),
	Belowright('belowright'),
	Botright('botright'),
	Leftabove('leftabove'),
	Rightbelow('rightbelow'),
	Topleft('topleft')

	var Value: string
endenum # }}}

class Range # {{{1
	var start: number
	var end: number

	def new(start: number = 0, end: number = 0) # {{{2
		this.start = start
		this.end = end
	enddef # }}}

	def string(): string # {{{2
		return string((this.start, this.end))
	enddef # }}}
endclass # }}}

class TerminalCmdline # {{{1
	var split: Split = Split.None
	var mod: Mod = Mod.None
	var range: Range
	var tab: bool = false
	var bang: bool = false
	var count: number = 0
	var cmd: list<string> = []
	var options: dict<any> = {}
	var _line: string = null_string

	static def IsTerminalCmd(cmdline: string): bool # {{{2
		var line = cmdline
		for RemoveFn in [RemoveBar, RemoveRange, RemoveTab, RemoveMods, RemoveSplit]
			line = RemoveFn(line)
		endfor
		return line =~# '^\s*term\%[inal]\>'
	enddef # }}}

	def ParseRange(): TerminalCmdline # {{{2
		# Range must be parsed AFTER tab/split/mods are removed
		# Because at this point, any leading number is definitely a range, not a count
		# Examples:
		#   :10terminal bash      -> range=10 (after parsing: "10terminal bash")
		#   :vertical 10terminal  -> range=10 (after parsing vertical: "10terminal bash")
		#   :'<,'>terminal python -> range='<,'> (visual selection)
		var pattern = '^\s*\(''<\s*,\s*''>\|[%$.]\|\d\+\(,\d\+\)\?\)'
		var match = trim(matchstr(this._line, pattern))

		if match != ''
			if match =~ "^'<\\s*,\\s*'>$"
				this.range = Range.new(line("'<"), line("'>"))
			elseif match == '%'
				this.range = Range.new(1, line('$'))
			elseif match == '.'
				this.range = Range.new(line('.'), line('.'))
			elseif match == '$'
				this.range = Range.new(line('$'), line('$'))
			elseif match =~ ','
				var parts = split(match, ',')
				this.range = Range.new(str2nr(parts[0]), str2nr(parts[1]))
			else
				# Single number: it's a range
				this.range = Range.new(str2nr(match), str2nr(match))
			endif
			this._line = trim(substitute(this._line, pattern, '', ''))
		endif
		return this
	enddef # }}}

	def ParseOptions(): TerminalCmdline # {{{2
		var pattern = '++\w\+\(=\S\+\)\?'
		var order = 0
		while true
			var m = matchstr(this._line, pattern)
			if m == ''
				break
			endif
			var parts = split(m[2 :], '=')
			var opt_name = parts[0]

			if len(parts) == 2
				# ++opt=value form: store value directly, no order needed
				var opt_value: any
				if parts[1] =~ '^\d\+$'
					opt_value = str2nr(parts[1])
				else
					opt_value = parts[1]
				endif
				this.options[opt_name] = opt_value
			else
				# ++opt form (boolean): needs order tracking
				this.options[opt_name] = (order, true)
				order += 1
			endif

			this._line = substitute(this._line, pattern, '', '')
		endwhile
		this._line = trim(this._line)
		return this
	enddef # }}}

	def NormalizeCloseOptions(): TerminalCmdline # {{{2
		var mutually_exclusive = ['close', 'noclose', 'open']
		var last_found = (-1, '')
		# Find the option with maximum order
		for opt_name in mutually_exclusive
			if has_key(this.options, opt_name)
				var tuple_val: tuple<number, any> = this.options[opt_name]
				if last_found[0] < tuple_val[0]
					last_found = (tuple_val[0], opt_name)
				endif
			endif
		endfor

		if last_found[0] == -1
			return this
		endif

		# Remove all except the last one
		for opt in mutually_exclusive
			if opt != last_found[-1] && has_key(this.options, opt)
				remove(this.options, opt)
			endif
		endfor
		return this
	enddef # }}}

	def ParseTab(): TerminalCmdline # {{{2
		# Tab can have a count: :2tab terminal (open in 2nd tab page)
		var pattern = '^\s*\(\d\+\)\?\s*tab\>'
		var match = matchstr(this._line, pattern)
		if match != ''
			var count_match = matchstr(match, '^\s*\zs\d\+\ze')
			if count_match != ''
				this.count = str2nr(count_match)
			endif
			this.tab = true
			this._line = trim(substitute(this._line, pattern, '', ''))
		endif
		return this
	enddef # }}}

	def ParseSplit(): TerminalCmdline # {{{2
		# Split can have a count: :10split terminal (10 rows/cols)
		var patterns = [
			('^\s*\(\d\+\)\?\s*vert\%[ical]\>', Split.Vertical),
			('^\s*\(\d\+\)\?\s*hor\%[izontal]\>', Split.Horizontal),
			('^\s*\(\d\+\)\?\s*sp\%[lit]\>', Split.Horizontal)
		]
		for [pattern, split_type] in patterns
			var match = matchstr(this._line, pattern)
			if match != ''
				var count_match = matchstr(match, '^\s*\zs\d\+\ze')
				if count_match != ''
					this.count = str2nr(count_match)
				endif
				this.split = split_type
				this._line = trim(substitute(this._line, pattern, '', ''))
				break
			endif
		endfor
		return this
	enddef # }}}

	def ParseMod(): TerminalCmdline # {{{2
		# Mods do NOT accept count, they are pure position modifiers
		var mods = [
			('\<abo\%[veleft]\>', Mod.Aboveleft),
			('\<bel\%[owright]\>', Mod.Belowright),
			('\<bo\%[tright]\>', Mod.Botright),
			('\<lefta\%[bove]\>', Mod.Leftabove),
			('\<rightb\%[elow]\>', Mod.Rightbelow),
			('\<to\%[pleft]\>', Mod.Topleft)
		]
		for [pattern, mod_type] in mods
			if this._line =~# pattern
				this.mod = mod_type
				this._line = trim(substitute(this._line, pattern, '', ''))
				break
			endif
		endfor
		return this
	enddef # }}}

	def ParseCmd(): TerminalCmdline # {{{2
		this._line = substitute(this._line, '\<term\%[inal]\>', '', '')
		this._line = trim(this._line)
		if this._line != ''
			this.cmd = split(this._line)
		endif
		return this
	enddef # }}}

	def ParseBang(): TerminalCmdline # {{{2
		if this._line =~# '^\s*term\%[inal]!'
			this.bang = true

			this._line = substitute(trim(this._line), '^term\%[inal]\zs!\ze', '', '')
		endif
		return this
	enddef # }}}

	def new(cmdline: string) # {{{2
		this._line = trim(RemoveBar(cmdline))

		this.ParseTab()
			.ParseSplit()
			.ParseMod()
			.ParseRange()
			.ParseOptions()
			.NormalizeCloseOptions()
			.ParseBang()
			.ParseCmd()
	enddef # }}}

	static def RemoveRange(line: string): string # {{{2
		var result = line
		for pattern in ["^\\s*'<,'>", '^\s*[%$.]', '^\s*\d\+\(,\d\+\)\?']
			result = substitute(result, pattern, '', '')
		endfor
		return trim(result)
	enddef # }}}

	static def RemoveTab(line: string): string # {{{2
		return trim(substitute(line, '^\s*\(\d\+\)\?\s*tab\>', '', ''))
	enddef # }}}

	static def RemoveSplit(line: string): string # {{{2
		return trim(substitute(line, '^\s*\(\d\+\)\?\s*\(vert\%[ical]\|hor\%[izontal]\|sp\%[lit]\)\>', '', ''))
	enddef # }}}

	static def RemoveMods(line: string): string # {{{2
		var pattern = '\<\(abo\%[veleft]\|bel\%[owright]\|bo\%[tright]\|lefta\%[bove]\|rightb\%[elow]\|to\%[pleft]\)\>'
		return trim(substitute(line, pattern, '', 'g'))
	enddef # }}}

	static def RemoveBar(cmdline: string): string # {{{2
		# Terminal doesn't support bar, so it only appears after |
		# Everything after 'terminal' is its arguments (may contain |)
		# Split at the last | before 'terminal', return the last part
		var parts = split(cmdline, '|\ze[^|]*\<term\%[inal]\>')
		return trim(get(parts, -1, cmdline))
	enddef # }}}

	def string(): string # {{{2
		return string({
			split: this.split.Value,
			mod: this.mod.Value,
			range: this.range,
			tab: this.tab,
			cmd: this.cmd,
			options: this.options,
		})
	enddef # }}}
endclass # }}}

class TerminalManager # {{{1
	static const group = 'TerminalManager'
	static const _NameLimit = 15
	var _terms = Ring.new()
	var _win = window.Window.new()
	var _termcmdinfo: TerminalCmdline

	def GetCmdOptions(key: string, default: any): any # {{{2
		if this._termcmdinfo == null_object
			return default
		endif
		if !has_key(this._termcmdinfo.options, key)
			return default
		endif
		var val = this._termcmdinfo.options[key]
		# If it's a tuple (order, value), extract the value
		if type(val) == v:t_tuple
			return val[1]
		endif
		return val
	enddef # }}}

	def GetCmdPos(): string # {{{2
		if this._termcmdinfo == null_object
			return ""
		endif

		return trim($'{this._termcmdinfo.split.Value} {this._termcmdinfo.mod.Value}')
	enddef # }}}

	def GetCmdBang(): bool # {{{2
		return this._termcmdinfo != null_object && this._termcmdinfo.bang
	enddef # }}}

	def new() # {{{2
		Autocmd.new('CmdlineLeavePre')
			.Group(group)
			.Callback(() => {
				var cmdline = getcmdline()
				if !TerminalCmdline.IsTerminalCmd(cmdline)
					return
				endif

				this._termcmdinfo = TerminalCmdline.new(cmdline)
			})

		Autocmd.new('TerminalOpen')
			.Group(group)
			.Callback(() => {
				this._Curwin()
				var bufnr = expand("<abuf>")->str2nr()
				var term = Terminal.newByBufnr(bufnr)
				this._terms.Push(term)

				term.SetVar('&bufhidden', 'hide')
				job_setoptions(term.GetJob(), {
					exit_cb: function(this._OnClose, [bufnr])})
				if expand("<amatch>") =~# $'^!{$SHELL}'
					this._Drop(this._terms.Peek())
				endif

				if this._win.IsOpen() && !this.GetCmdOptions('close', false)
					this._win.SetBuf(bufnr)
					this._win.Execute('startinsert')
				endif
			})

		Autocmd.new('TerminalWinOpen')
			.Group(group)
			.Callback(() => {
				var win = Window.newCurrent()

				var bufnr = win.GetBufnr()
				if !this._win.IsOpen()
					this._win = win
					this._WinAutocmd(this._win.winnr)
					this._win.SetBuf(win.GetBufnr())

					if this.GetCmdBang()
						this._win.SetVar('&winfixwidth', true)
					endif
					return
				endif

				if !this.GetCmdOptions('close', false)
					win.Close()
				endif
			})
	enddef # }}}

	def _OnClose(bufnr: number, job: job, code: number) # {{{2
		if !this._terms->empty()
			this._terms.DeleteBy((a, b): bool => {
				return a == b.bufnr
			}, bufnr)

			this.SlideRight()
			var term = Terminal.newByBufnr(bufnr)
			if term.IsExists()
				term.Delete()
			endif
		endif

		if this._terms->empty()
			this._CloseWindow()
		endif
	enddef # }}}

	def ListTerminals(): list<Terminal> # {{{2
		return _terms->ToList<Terminal>()
	enddef # }}}

	def Current(): Terminal # {{{2
		return _terms.Peek()
	enddef # }}}

	def Toggle(bang: bool, pos: string, count: number) # {{{2
		if this._win.IsOpen()
			this._win.Close()
			return
		endif

		this._WinOpen(this._win, pos, count)
		if bang
			this._win.SetVar('&winfixwidth', true)
		endif

		var term: Terminal
		if this._terms->empty()
			term = Terminal.new($SHELL, {
				hidden: true,
				term_kill: 'term',
			})

			job_setoptions(term.GetJob(), {
				exit_cb: function(this._OnClose, [term.bufnr]),
			})
		else
			term = this._terms.Peek()
		endif

		this._win.SetBuf(term.bufnr)
	enddef # }}}

	def _TerminalName(name: string): string # {{{2
		return name->strchars() > _NameLimit ? $'{name->strcharpart(0, _NameLimit)}…' : name
	enddef # }}}

	def StatusLineTerminals(): string # {{{2
		var str = []

		for term in this._terms.ToList<Terminal>()
			str->add(term.bufnr != this._terms.Peek().bufnr
				? this._TerminalName(term.name)
				: $'[{this._TerminalName(term.name)}]'
			)
		endfor

		return str->join(' ')
	enddef # }}}

	def _Drop(term: Terminal) # {{{2
		term.SendKeys($"source {$MYVIMDIR}shell/vim-terminal-integration.sh\n")
		term.SendKeys("clear\n")
		term.Wait(100)
	enddef # }}}

	def _WinAutocmd(winnr: number) # {{{2
		const winGroup = 'TerminalWinAutocmd'
		Autocmd.new('WinClosed')
			.Group(winGroup)
			.Pattern([winnr->string()])
			.Once()
			.Callback(function(Autocmd.Delete, [[{group: winGroup}], true]))

		Autocmd.new('BufWinEnter')
			.Group(winGroup)
			.Pattern([winnr->string()])
			.Callback((opt: autocmd.EventArgs) => {
				var w = opt.data
				w.SetVar('&statusline', '%{%terminal#Manager.StatusLineTerminals()%}')
				w.SetVar('&number', false)
				w.SetVar('&signcolumn', 'no')
				w.SetVar('&relativenumber', false)
				w.SetVar('&hidden', false)
				w.SetVar('&winfixbuf', true)
			})
	enddef # }}}

	def _WinOpen(win: Window, pos: string = '', count: number = 0) # {{{2
		win.SetPos(this.GetCmdPos() ?? pos)
		win.Resize(this.GetCmdOptions('rows', this.GetCmdOptions('cols', count)))
		win.Open()

		this._WinAutocmd(win.winnr)
	enddef # }}}

	def _Curwin() # {{{2
		if this.GetCmdOptions('curwin', false)
			if !this._win.IsOpen()
				this._WinOpen(this._win)
			endif

			win_gotoid(this._win.winnr)
		endif
	enddef # }}}

	def SlideRight() # {{{2
		this._terms.SlideRight()
		if !this._terms->empty() && this._win.IsOpen()
			this._win.SetBuf(this._terms.Peek().bufnr)
			this._win.Execute('startinsert')
		endif
	enddef # }}}

	def SlideLeft() # {{{2
	  	this._terms.SlideLeft()
		if !this._terms->empty() && this._win.IsOpen()
			this._win.SetBuf(this._terms.Peek().bufnr)
			this._win.Execute('startinsert')
		endif
	enddef # }}}

	def KillCurrentTerminal() # {{{2
		if !this._terms->empty()
			this._terms.Peek().Stop()
		endif
	enddef # }}}

	def KillAllTerminals() # {{{2
		this._terms.ForEach((term) => {
			term.Stop()
		})
	enddef # }}}

	def _CloseWindow() # {{{2
		if this._win.IsOpen()
			this._win.Close()
		endif
	enddef # }}}
endclass # }}}

export const Manager = TerminalManager.new()
