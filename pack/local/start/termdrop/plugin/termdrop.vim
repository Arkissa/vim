vim9script

import 'vim.vim'
import 'buffer.vim'
import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

def g:Tapi_Drop(bufnr: number, a: string)
	var arglist = a->split('\s\+')
	echom a

	var opts = arglist
		->copy()
		->filter((_, arg) => arg =~# '^--')
		->map((_, arg) => arg->substitute('^--', '', ''))

	var args = arglist
		->copy()
		->filter((_, arg) => arg !~# '^--')

	var cmd = ['drop']
	var token: string

	for opt in opts
		if opt == 'tab'
			cmd = cmd->insert('tab', 0)
		elseif opt =~# "^token="
			token = opt->substitute('token=', '', '')
		elseif vim.ContainsOf(['ff', 'fileformat', 'enc', 'encoding', 'bin', 'binary', 'nobin', 'nobinary', 'bad', 'edit'], (_, o) => opt =~# $'^{o}')
			cmd = cmd->add($"++{opt}")
		endif
	endfor

	var drop = cmd->extend(args)->join(' ')
	execute(drop)
	var b = buffer.Buffer.newCurrent()
	b.SetVar('&bufhidden', 'wipe')

	if token->empty()
		return
	endif

	Autocmd.new('BufWipeout')
		.Group("termdrop")
		.Bufnr(b.bufnr)
		.Once()
		.Callback(() => {
			term_sendkeys(bufnr, token .. "\n")
		})
enddef

const bin = expand("<script>:h:h") .. '/bin'

$PATH = $'{bin}:{$PATH}'
$EDITOR = $'{bin}/drop --wait'
$VISUAL = $EDITOR
$VIM_TAPI_DROP = get(funcref(g:Tapi_Drop), 'name')
