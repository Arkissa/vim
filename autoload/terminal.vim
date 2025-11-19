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

export class TerminalCmdline # {{{1
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
		var line = trim(cmdline)
		for RemoveFn in [RemoveRange, RemoveTab, RemoveSplit, RemoveMods, RemoveCount]
			line = RemoveFn(line)
		endfor
		return line =~# '^\s*term\%[inal]\>'
	enddef # }}}

	def ParseRange(): TerminalCmdline # {{{2
		var pattern = "^\\s*\\('< *,\\s*'>\\|[%$.]\\|\\d\\+,\\d\\+\\)"
		var match = matchstr(this._line, pattern)
		var single_num_pattern = '^\s*\d\+'
		
		# Special case: single number might be range or count for split
		if match == '' && this._line =~ single_num_pattern
			var temp_match = matchstr(this._line, single_num_pattern)
			var after_num = substitute(this._line, single_num_pattern .. '\s*', '', '')
			# If followed by mod or split keywords, it's a count, not a range
			# Otherwise it's a range
			var is_count_for_split = after_num =~# '^\(sp\%[lit]\|vert\%[ical]\|hor\%[izontal]\|'
				.. 'abo\%[veleft]\|bel\%[owright]\|bo\%[tright]\|'
				.. 'lefta\%[bove]\|rightb\%[elow]\|to\%[pleft]\)\>'
			if is_count_for_split
				# It's a count for split, not a range - don't consume it here
			else
				# It's a range
				match = temp_match
				pattern = single_num_pattern
			endif
		endif
		
		if match != ''
			match = trim(match)
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
				this.range = Range.new(str2nr(match), str2nr(match))
			endif
			this._line = trim(substitute(this._line, pattern, '', ''))
		endif
		return this
	enddef # }}}

	def ParseOptions(): TerminalCmdline # {{{2
		var pattern = '++\w\+\(=\S\+\)\?'
		while true
			var m = matchstr(this._line, pattern)
			if m == ''
				break
			endif
			var parts = split(m[2 :], '=')
			if len(parts) == 2
				# Try to convert numeric values
				if parts[1] =~ '^\d\+$'
					this.options[parts[0]] = str2nr(parts[1])
				else
					this.options[parts[0]] = parts[1]
				endif
			else
				this.options[parts[0]] = true
			endif
			this._line = substitute(this._line, pattern, '', '')
		endwhile
		this._line = trim(this._line)
		return this
	enddef # }}}

	def NormalizeCloseOptions(): TerminalCmdline # {{{2
		var mutually_exclusive = ['close', 'noclose', 'open']
		var last_found = ''

		for key in keys(this.options)
			if vim.Contains(mutually_exclusive, key)
				last_found = key
			endif
		endfor

		if last_found != ''
			return this
		endif

		for opt in mutually_exclusive
			if opt != last_found && has_key(this.options, opt)
				unlet! this.options[opt]
			endif
		endfor
		return this
	enddef # }}}

	def ParseTab(): TerminalCmdline # {{{2
		if this._line =~# '^\s*tab\>'
			this.tab = true
			this._line = trim(substitute(this._line, '^\s*tab\>', '', ''))
		endif
		return this
	enddef # }}}

	def ParseSplit(): TerminalCmdline # {{{2
		if this._line =~# '\<vert\%[ical]\>'
			this.split = Split.Vertical
			this._line = trim(substitute(this._line, '\<vert\%[ical]\>', '', ''))
		elseif this._line =~# '\<hor\%[izontal]\>'
			this.split = Split.Horizontal
			this._line = trim(substitute(this._line, '\<hor\%[izontal]\>', '', ''))
		elseif this._line =~# '\<sp\%[lit]\>'
			this.split = Split.Horizontal
			this._line = trim(substitute(this._line, '\<sp\%[lit]\>', '', ''))
		endif
		return this
	enddef # }}}

	def ParseMod(): TerminalCmdline # {{{2
		if this._line =~# '\<abo\%[veleft]\>'
			this.mod = Mod.Aboveleft
			this._line = substitute(this._line, '\<abo\%[veleft]\>', '', '')
		elseif this._line =~# '\<bel\%[owright]\>'
			this.mod = Mod.Belowright
			this._line = substitute(this._line, '\<bel\%[owright]\>', '', '')
		elseif this._line =~# '\<bo\%[tright]\>'
			this.mod = Mod.Botright
			this._line = substitute(this._line, '\<bo\%[tright]\>', '', '')
		elseif this._line =~# '\<lefta\%[bove]\>'
			this.mod = Mod.Leftabove
			this._line = substitute(this._line, '\<lefta\%[bove]\>', '', '')
		elseif this._line =~# '\<rightb\%[elow]\>'
			this.mod = Mod.Rightbelow
			this._line = substitute(this._line, '\<rightb\%[elow]\>', '', '')
		elseif this._line =~# '\<to\%[pleft]\>'
			this.mod = Mod.Topleft
			this._line = substitute(this._line, '\<to\%[pleft]\>', '', '')
		endif
		this._line = trim(this._line)
		return this
	enddef # }}}

	def ParseCount(): TerminalCmdline # {{{2
		var match = matchstr(this._line, '^\d\+\>')
		if match != ''
			this.count = str2nr(match)
			this._line = trim(substitute(this._line, '^\d\+\>', '', ''))
		endif
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
		endif
		return this
	enddef # }}}

	def new(cmdline: string) # {{{2
		this._line = trim(cmdline)

		this.ParseRange()
			.ParseTab()
			.ParseMod()
			.ParseCount()
			.ParseSplit()
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
		return trim(substitute(line, '^\s*tab\>', '', ''))
	enddef # }}}

	static def RemoveSplit(line: string): string # {{{2
		return trim(substitute(line, '^\s*\(vert\%[ical]\|hor\%[izontal]\|sp\%[lit]\)\>', '', ''))
	enddef # }}}

	static def RemoveMods(line: string): string # {{{2
		var pattern = $'^\s*\(abo\%[veleft]\|bel\%[owright]\|bo\%[tright]\|lefta\%[bove]\|rightb\%[elow]\|to\%[pleft]\)\>'
		return trim(substitute(line, pattern, '', ''))
	enddef # }}}

	static def RemoveCount(line: string): string # {{{2
		return trim(substitute(line, '^\s*\d\+\>', '', ''))
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

class V2 # {{{1
	static const group = 'TerminalManager'
	static const _NameLimit = 15
	var _terms = Ring.new()
	var _win = window.Window.new()
	var _pos: string
	var _count: number
	var _termcmdinfo: TerminalCmdline

	def GetCmdOptions(key: string, default: any): any # {{{2
		if this._termcmdinfo == null_object
			return default
		endif

		return get(this._termcmdinfo.options, key, default)
	enddef # }}}

	def GetCmdPos(): string # {{{2
		if this._termcmdinfo == null_object
			return ""
		endif

		return $'{this._termcmdinfo.split.Value} {this._termcmdinfo.mod.Value}'
	enddef # }}}

	def GetCmdBang(): bool
		return this._termcmdinfo != null_object && this._termcmdinfo.bang
	enddef

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

					this._pos = this.GetCmdPos() ?? this._pos
					this._count = this.GetCmdOptions('rows', this.GetCmdOptions('cols', this._count))
					if this.GetCmdBang()
						this._win.LockSize()
					endif
					return
				endif

				if this.GetCmdOptions('close', false)
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
		else
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
			this._win.LockSize()
		endif

		var term: Terminal
		if this._terms->empty()
			term = Terminal.new($SHELL, {
				hidden: true,
				term_kill: 'term',
				exit_cb: this._OnClose,
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
		Autocmd.new('WinClosed')
			.Group(group)
			.Pattern([winnr->string()])
			.Once()
			.Callback(function(Autocmd.Delete, [[{group: V2.group}], true]))

		Autocmd.new('BufWinEnter')
			.Group(group)
			.Pattern([winnr->string()])
			.Callback((opt: autocmd.EventArgs) => {
				var w = opt.data
				w.SetVar('&statusline', '%{%terminal#Manager.StatusLineTerminals()%}')
				w.SetVar('&number', false)
				w.SetVar('&signcolumn', 'no')
				w.SetVar('&relativenumber', false)
				w.SetVar('&hidden', false)
			})
	enddef # }}}

	def _WinOpen(win: Window, pos: string = '', count: number = 0) # {{{2
		this._pos = this._pos ?? pos
		this._count = this._count ?? count
		win.SetPos(this._pos)
		win.Resize(this._count)
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

export const Manager = V2.new()
