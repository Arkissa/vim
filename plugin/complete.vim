vim9script

import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

const group = 'CompleteAutoComplete'

Autocmd.new('InsertCharPre')
	.Group('CompleteAutoComplete')
	.Callback((): void => {
		if pumvisible() == 1 || v:char != '/'
			return
		endif

		var synAttr = synID(line('.'), col('.'), 0)
			->synIDtrans()
			->synIDattr('name')

		if synAttr == 'String'
			feedkeys("\<C-x>\<C-f>", 'n')
		endif
	})
