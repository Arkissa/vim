vim9script

import 'vim.vim'

import 'termdrop/termdrop.vim' as drop

const optNames = ['ff', 'fileformat', 'enc', 'encoding', 'bin', 'binary', 'nobin', 'nobinary', 'bad', 'edit']

def g:Tapi_Drop(bufnr: number, a: string)
	var arglist = a->split('\s\+')

	var flags = arglist
		->copy()
		->filter((_, arg) => arg =~# '^--')
		->map((_, arg) => arg->substitute('^--', '', ''))

	var files = arglist
		->copy()
		->filter((_, arg) => arg !~# '^--')

	var opts = []
	var token: string
	var mods = drop.Mods.Default

	for flag in flags
		if flag == 'tab'
			mods = drop.Mods.Tab
		elseif flag =~# "^token="
			token = flag->substitute('token=', '', '')
		elseif vim.ContainsOf(optNames, (_, o) => flag =~# $'^{o}')
			opts->add($"++{flag}")
		endif
	endfor

	drop.Drop(drop.Arg.new(bufnr, opts, files, token, mods))
enddef

const bin = expand("<script>:h:h") .. '/bin'

$PATH = $'{bin}:{$PATH}'
$EDITOR = $'{bin}/drop --wait'
$VISUAL = $EDITOR
$VIM_TAPI_DROP = get(funcref(g:Tapi_Drop), 'name')
