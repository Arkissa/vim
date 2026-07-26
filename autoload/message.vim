vim9script

import 'window.vim'

type Window = window.Window

export class Message
	var _win: Window

	static const name = '[Message]'

	def new()
		this._win = Window.new('keepjumps botright')
	enddef

	static def Alias(cmd: string): string
		var cmdline_alias = get(g:, 'message_cmdline_alias', {})

		for [raw, alias] in cmdline_alias->items()
			if cmd =~# $'^{raw} '
				return cmd->substitute($'^{raw}', alias, '')
			endif
		endfor

		return cmd
	enddef

	static def Execute(cmd: string): list<string>
		try
			var result = execute('legacy ' .. cmd)->split("\n")
			return cmd =~# '^h\(elp\)\{0,1} '
				? result[: 0]
				: result
		catch
			return v:exception->substitute($'legacy {cmd}', cmd, '')->split("\n")
		endtry
	enddef

	static def CustemComplete(A: string, L: string, P: number): list<any>
		return []
	enddef

	def Callback()
		var cmd = input(':', '', 'command')
		if empty(cmd)
			return
		endif

		if cmd =~# '^mc\(lose\)\{0,1}$'
			if this._win.IsOpen()
				this._win.Close()
				return
			else
				return
			endif
		endif

		cmd = Message.Alias(cmd)
		defer histadd(':', cmd)
		var output = Message.Execute(cmd)
		if empty(output)
			return
		endif

		var last_win_id = win_getid()
		if !this._win.IsOpen()
			this._win.Open(name)
			win_gotoid(last_win_id)

			this._win.SetVar('&winfixbuf', true)
			this._win.SetVar('&number', false)
			this._win.SetVar('&signcolumn', 'no')
			this._win.SetVar('&winfixheight', true)
			this._win.SetVar('&winfixwidth', true)
		endif
		var b = this._win.GetBuffer()
		b.SetVar('&buftype', 'nofile')
		b.SetVar('&bufhidden', 'wipe')


		:redraw!

		b.Clear()
		b.SetLines(output, 1)
		b.SetVar('&modified', false)
		this._win.Resize(min([len(output), float2nr(&lines * 0.5)]))
	enddef
endclass
