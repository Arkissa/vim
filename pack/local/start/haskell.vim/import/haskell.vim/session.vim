vim9script

import 'vim.vim'
import 'buffer.vim'

import 'haskell.vim/ghci.vim'
import 'haskell.vim/request.vim'

def Checksum(path: string): string
	return readfile(path)->join("\n")->sha256()
enddef

def FindCabalFile(root: string): string
	var files = globpath(root, '*.cabal', false, true)
	return files->empty() ? '' : files[0]
enddef

def GuessCmd(cmd: string, marker: string): ghci.Cmd
	if cmd ==# 'stack'
		return ghci.Cmd.Stack
	elseif cmd ==# 'cabal'
		return ghci.Cmd.Cabal
	elseif cmd ==# 'ghci'
		return ghci.Cmd.GHCi
	endif

	var file = fnamemodify(marker, ':t')
	if marker ==# ''
		return ghci.Cmd.GHCi
	elseif vim.Contains(['cabal.project', 'cabal.sandbox.config'], file)
		return ghci.Cmd.Cabal
	elseif file ==# 'stack.yaml'
		return ghci.Cmd.Stack
	endif

	return ghci.Cmd.Cabal
enddef

export class Client
	var _ghci: ghci.GHCi
	static const _notLive = 'ghci backend not running.'

	def new(this._ghci)
	enddef

	def Ping(): bool
		return this._ghci.Status() == 'run'
	enddef

	def Send(req: request.Request)
		if this._ghci.Status() != 'run'
			throw _notLive
		endif

		this._ghci.Send(req)
	enddef
endclass

class Session
	var _ghci: ghci.GHCi

	var root: string
	var _checksum: string
	var _cabalFile: string

	def new(this.root, marker: string)
		var cmd = GuessCmd(get(g:, 'haskell_vim_ghci_cmd', 'auto'), marker)
		this._ghci = ghci.GHCi.new(cmd)

		this._cabalFile = fnamemodify(marker, ':t') =~# '\.cabal$'
			? marker
			: FindCabalFile(this.root)

		this._checksum = this._CheckSum(this._cabalFile)
	enddef

	def _CheckSum(cabalFile: string): string
		if cabalFile == ''
			return ''
		endif

		return Checksum(cabalFile)
	enddef

	def CabalFileChanged(): bool
		return this._cabalFile != '' && this._CheckSum(this._cabalFile) != this._checksum
	enddef

	def GetBuffers(): list<buffer.Buffer>
		return getbufinfo()
			->map((_, bufinfo) => buffer.Buffer.newByBufnr(bufinfo.bufnr))
			->filter((_, b) => b.GetVar('&filetype') == 'haskell')
	enddef

	def GetClient(): Client
		return Client.new(this._ghci)
	enddef

	def GetChannel(): channel
		return this._ghci.GetChannel()
	enddef

	def Restart()
		this._ghci.Restart()
	enddef
endclass

export class Manager
	static var _sessions: dict<Session> = {}

	static def Get(b: buffer.Buffer): Session
		var root = ""
		for r in _sessions->keys()
			if vim.HasPrefix(fnamemodify(b.name, ':p'), r) && r->len() > root->len()
				root = r
			endif
		endfor

		if root != ''
			return _sessions[root]
		endif

		var marker = vim.FindMarks(b.name, ['cabal.project', 'cabal.sandbox.config', 'stack.yaml', '*.cabal'])
		root = marker ==# ''
			? fnamemodify(b.name, ':p:h')
			: fnamemodify(marker, ':p:h')
		root ..= '/'

		var session = Session.new(root, marker)
		_sessions[root] = session

		return session
	enddef
endclass
