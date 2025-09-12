vim9script

import autoload 'buffer.vim'
import autoload 'lsp/diag.vim'

def g:StatusLineBufName(): string
	var buf = buffer.Buffer.new()
	if empty(buf.name)
		return "(No Name)"
	endif

	return fnamemodify(buf.name, ':t')
enddef

const modeMap = {
	'n': 'NORMAL', 'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL', 'V': 'V-LINE', "\<C-v>": 'V-BLOCK',
	'c': 'COMMAND', 's': 'SELECT', 'S': 'S-LINE', "\<C-s>": 'S-BLOCK', 't': 'TERMINAL'
}

def g:StatusLineMode(): string
	return get(modeMap, mode(), '')
enddef

def g:StatusLineDir(): string
	var str = substitute(expand('%:p:h'), $'^{getcwd()}\(.*\)', '.\1', '') ?? '.'
	if str =~ '^\.'
		return str
	endif

	return fnamemodify(str, ':~:.')
enddef

def g:StatusLineGit(): string
	if exists_compiled('*g:FugitiveStatusline')
		return g:FugitiveStatusline()
	else
		return ""
	endif
enddef

def g:StatusLineDiags(): string
	var errCount = diag.DiagsGetErrorCount(bufnr())
	var str = []

	if errCount.Hint > 0
		str->add($'H:{errCount.Hint}')
	endif

	if errCount.Info > 0
		str->add($'I:{errCount.Info}')
	endif

	if errCount.Warn > 0
		str->add($'W:{errCount.Warn}')
	endif

	if errCount.Error > 0
		str->add($'E:{errCount.Error}')
	endif

	return str->join(' ')
enddef

&statusline = '%< [%{%StatusLineBufName()%}%m]%( %{%StatusLineDiags()%} %)%= %(%{%FugitiveStatusline()%} 󰤃 %)%(%y 󰤃%) %{%StatusLineDir()%} ≡ %3P %3l:%-3c '
