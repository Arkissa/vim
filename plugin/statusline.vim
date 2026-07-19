vim9script

import autoload 'statusline.vim' as st

type Left = st.Left
type Right = st.Right
type Icon = st.Icon
type Builtin = st.Builtin

g:statusline = [
	Left.new([
		Builtin.Mode(),
		Builtin.BufName(),
		Builtin.Diags(),
	]),
	Right.new([
		Builtin.Git(),
		Builtin.FileType(),
		Builtin.Dir(),
		Icon.new('≡', Builtin.FileSize()),
		Builtin.LineCol(),
		Builtin.FilePercent(),
	]),
]
