vim9script

if exists("b:did_ftplugin")
  finish
endif

execute($"runtime! {$VIMRUNTIME}/ftplugin/haskell.vim")

import 'vim.vim'
import 'buffer.vim'
import 'keymap.vim'
import 'autocmd.vim'
import 'command.vim'

import 'haskell.vim/load.vim'
import 'haskell.vim/type.vim'
import 'haskell.vim/show.vim'
import 'haskell.vim/session.vim'
import 'haskell.vim/completion.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Autocmd = autocmd.Autocmd

const b = buffer.Buffer.newCurrent()

const group = 'haskell.vim'
const _session = session.Manager.Get(b)
const _completion = completion.HaskellComplete.new(_session.GetClient())

def Omnifunc(first: number, base: string): any
	return _completion.Func(first, base)
enddef

def IncludeExpr(): string
	var files = findfile(tr(v:fname, '.', '/'), '.;')
	if files == ""
		return v:fname
	endif

	return files
enddef

Autocmd.new('BufWritePost')
	.Desc("when write post a haskell buffer will be reload in ghci.")
	.Group(group)
	.Bufnr(b.bufnr)
	.Replace()
	.Callback(() => {
		load.Reload(buffer.Buffer.newCurrent())
	})

Autocmd.new('BufWinEnter')
	.Desc("first load a new haskell file in ghci.")
	.Group(group)
	.Once()
	.Bufnr(b.bufnr)
	.Replace()
	.Callback(() => {
		load.Load(buffer.Buffer.newCurrent())
	})

Bind.new(Mods.n)
	.Buffer(b.bufnr)
	.NoRemap()
	.Callback('<LEADER>k', () => {
		var client = _session.GetClient()
		var lines = type.Type.new(client)
			.Query(type.Mode.Type, type.TypeExpr.newExpr(expand('<cword>')))

		show.Preview.Show(lines)
	})

var cpo_save = &cpo
:set cpo&vim

&l:omnifunc = Omnifunc
:setlocal includeexpr=IncludeExpr()

if !vim.Contains(&complete, '.')
	:setlocal complete+=.
endif

&cpo = cpo_save
