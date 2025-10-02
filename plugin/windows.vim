vim9script

import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

const clip = "/mnt/c/Windows/System32/clip.exe"
Autocmd.new('TextYankPost')
	.When(() => executable(clip) == 1)
	.Group('WSLYank')
	.Replace()
	.Callback(() => {
		if v:event.operator ==# 'y'
			system(clip, @0)
		endif
	})
