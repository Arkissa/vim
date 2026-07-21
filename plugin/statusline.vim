vim9script

import 'window.vim'
import 'autocmd.vim'

import autoload 'statusline.vim' as st

type Left = st.Left
type Right = st.Right
type Icon = st.Icon
type Builtin = st.Builtin
type Text = st.Text

type Autocmd = autocmd.Autocmd

class TerminalMode implements st.Provider
	def string(): string
		var win = window.Window.newByWinnr(g:statusline_winid)
		if win.GetBuffer().GetVar('&buftype') != 'terminal' || mode() != 't'
			return ''
		endif

		return $'-- TERMINAL --'
	enddef
endclass

g:statusline = [
	Left.new([
		TerminalMode.new()
	]),
	Right.new([
		Text.new('%-12(%l,%c%V%)'),
		Builtin.FilePercent(),
	]),
]

Autocmd.new('WinResized')
	.Group(g:myvimrc_group)
	.Desc('Refresh Residual statusline.')
	.Command('set laststatus=0')
