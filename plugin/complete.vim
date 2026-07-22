vim9script

import 'vim.vim'
import 'autocmd.vim'

import autoload 'completion.vim'

type Autocmd = autocmd.Autocmd

const DocumentFiletypes = [
	'',
	'asciidoc',
	'changelog',
	'debchangelog',
	'debcopyright',
	'docbk',
	'docbksgml',
	'docbkxml',
	'gemtext',
	'gitcommit',
	'gitconfig',
	'gitrebase',
	'godoc',
	'groff',
	'help',
	'help_it',
	'help_ru',
	'html',
	'mail',
	'man',
	'manual',
	'markdown',
	'mediawiki',
	'nroff',
	'org',
	'pandoc',
	'plaintex',
	'quarto',
	'rmd',
	'rst',
	'scdoc',
	'text',
	'tex',
	'texinfo',
	'tutor',
	'typst',
	'xhtml',
]

def IsStringOrComment(lnum: number, col: number): bool
	for id in synstack(lnum, col)
		var name = id->synIDattr('name')
		var linked = id->synIDtrans()->synIDattr('name')
		if name =~? 'string\|comment'
				|| linked ==# 'String'
				|| linked ==# 'Comment'
			return true
		endif
	endfor

	return false
enddef

class FilePath implements completion.CompleteFunc
	def First(): number
		var line = getline('.')->strpart(0, col('.') - 1)
		var pos = line->match('\f*/\f*$')
		if pos < 0
			return -3
		endif

		if vim.Contains(DocumentFiletypes, &filetype)
			return pos
		endif

		if !exists('g:syntax_on')
			return -3
		endif

		if IsStringOrComment(line('.'), pos + 1)
			return pos
		endif

		return -3
	enddef

	def Complete(base: string): any
		return getcompletion(base, 'file')->map((_, path) => {
			return {
				word: substitute(path, '/$', '', ''),
				abbr: path =~# '/$'
					? fnamemodify(path, ':h:t') .. '/'
					: fnamemodify(path, ':t')}
		})->matchfuzzy(base, {key: 'word'})
	enddef
endclass

Autocmd.new('VimEnter')
	.Group(g:myvimrc_group)
	.Once()
	.Callback(() => {
		&complete = $'F{completion.Func(FilePath.new())->string()->escape(',')},{&complete}'
	})
