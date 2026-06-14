vim9script

import 'log.vim'
import 'buffer.vim'
import 'autocmd.vim'

import 'haskell.vim/request.vim'
import 'haskell.vim/session.vim'

type Autocmd = autocmd.Autocmd

const group = 'haskell.vim'
const description = 'load buffer after restart with ghci.'

class LoadCommand implements request.Command
	var _filename: string
	def new(this._filename)
	enddef

	def Cmd(): string
		return $':load {this._filename}'
	enddef
endclass

class ReloadCommand implements request.Command
	def Cmd(): string
		return ':reload'
	enddef
endclass

def AutoLoad(client: session.Client, bs: list<buffer.Buffer>)
	var winEnter = Autocmd.new('WinEnter')
		.Desc(description)
		.Group(group)
		.Once()
		.Replace()
	var bufWinEnter = Autocmd.new('BufWinEnter')
		.Desc(description)
		.Group(group)
		.Once()
		.Replace()

	for b in bs->copy()->filter((_, b) => b.InWindow())
		winEnter = winEnter.Bufnr(b.bufnr).Callback(() => {
			client.Send(request.Discard.new(LoadCommand.new(b.name)))
		})
	endfor

	for b in bs->copy()->filter((_, b) => b.Hidden())
		bufWinEnter = bufWinEnter.Bufnr(b.bufnr).Callback(() => {
			client.Send(request.Discard.new(LoadCommand.new(b.name)))
		})
	endfor
enddef

export def Load(b: buffer.Buffer)
	var sess = session.Manager.Get(b)
	var client = sess.GetClient()

	if sess.CabalFileChanged()
		sess.Restart()
		AutoLoad(client, sess.GetBuffers())
	endif

	client.Send(request.Discard.new(LoadCommand.new(b.name)))
enddef

export def Reload(b: buffer.Buffer)
	var sess = session.Manager.Get(b)
	var client = sess.GetClient()

	if sess.CabalFileChanged()
		sess.Restart()
		AutoLoad(client, sess.GetBuffers())
	endif

	client.Send(request.Discard.new(ReloadRequest.new()))
enddef
