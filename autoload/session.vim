vim9script

import './log.vim'

var sep = has('win') ? '\' : '/'

export class Session
	static def _GetCacheDir(): string
		if has('win')
			return getenv('LOCALAPPDATA')
		elseif has_key(environ(), 'XDG_CACHE_HOME')
			return getenv('XDG_CACHE_HOME')
		else
			return expand('~/.cache')
		endif
	enddef

	static def _Join(...paths: list<string>): string
		return paths
			->map((_, path) => trim(simplify(path), sep, 2))
			->join(sep)
	enddef

	static def All(dir: string): list<string>
		return globpath(dir, '**/Session.vim', false, true)
	enddef

	static def Save(dir: string, sessionName: string, silent: bool)
		var d = _Join(dir ?? _Join(_GetCacheDir(), 'vim-simple-session'), sessionName)
		if !d->isdirectory()
			mkdir(d, 'p')
		endif

		var session = fnameescape(_Join(d, 'Session.vim'))

		execute($'mksession! {session}')

		if !silent
			:redraw
			:echo $'Session saved {session}'
		endif
	enddef

	static def Load(dir: string, sessionName: string, silent: bool)
		var d = dir ?? _Join(_GetCacheDir(), 'vim-simple-session')
		var sname = sessionName ?? fnamemodify(getcwd(), ':t')
		var sessions = All(d)->filter((_, name) => name =~# $'\/{sname}\/')

		if empty(sessions)
			if !silent
				:redraw
				log.Error($'Load Session error: {sname} not found in {fnamemodify(d, ':~:.')}')
			endif

			return
		endif

		var session = sessions[0]
		if !filereadable(session)
			if !silent
				:redraw
				log.Error($"Load Session error: can't read {fnamemodify(session, ':~:.')}")
			endif

			return
		endif

		if getbufvar(bufnr(), '&modified')
			:write
		endif

		execute('silent! %bw')
		execute($'silent! source {session}')
	enddef
endclass
