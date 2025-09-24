vim9script

if !exists("g:GrepConfig") || g:GrepConfig->empty()
	finish
endif

# type check
var grepConfig: list<dict<any>> = g:GrepConfig

import '../autoload/command.vim'
import '../autoload/autocmd.vim'
import '../autoload/keymap.vim'

type Bind = keymap.Bind
type NArgs = command.NArgs
type Command = command.Command
type Autocmd = autocmd.Autocmd
type Complete = command.Complete

const group = 'Grep'

var cache: dict<command.Execute> = {
	current: null_object
}

def RegisterKeymap(bind: Bind, kvs: dict<any>)
	for [k, v] in kvs->items()
		if type(v) == type(null_function)
			bind.ScriptCmd(k, v)
		else
			bind.Map(k, v)
		endif
	endfor
enddef

for conf in g:GrepConfig
	import autoload $'{conf.module}.vim'

	if has_key(conf, 'Init') && type(conf['Init']) == type(null_function)
		call(conf.Init, [])
	endif

	var obj: command.Execute = eval($'{fnamemodify(conf.module, ':t:r')}.Grep.{has_key(conf, 'args') ? 'new(conf.args)' : 'new()'}')

	var fts = ['*']
	if has_key(conf, 'ft')
		fts = type(conf.ft) == type(null_string) ? [conf.ft] : (conf.ft ?? fts)
	endif

	uniq(fts)

	if has_key(conf, 'keymaps') && has_key(conf.keymaps, 'bind')
		var bind: Bind = conf.keymaps.bind

		Autocmd.new('FileType')
			.Group(group)
			.Pattern(fts)
			.Callback(funcref(RegisterKeymap, [bind, conf.keymaps->filter((k, _) => k != 'bind')]))
	endif

	fts->foreach((_, ft) => {
		cache[ft] = obj
	})
endfor

Command.new("Grep")
	.Bar()
	.Bang()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		if cache.current != null_object
			cache.current.Attr(attr).Run()
		elseif has_key(cache, &filetype)
			cache.current = cache[&filetype]
			cache.current.Attr(attr).Run()
		elseif has_key(cache, '*')
			cache.current = cache['*']
			cache.current.Attr(attr).Run()
		else
			echoerr 'No defined Grep.'
		endif
	})

Command.new('GrepChange')
	.NArgs(command.NArgs.One)
	.Complete(Complete.CustomList, (A, L, P): list<string> => {
		return grepConfig->mapnew((_, conf) => fnamemodify(conf.module, ':t:r'))
	})
	.Callback((attr) => {
		var i = grepConfig->indexof((_, conf) => fnamemodify(conf.module, ':t:r') == attr.args)
		if i == -1
			echoerr $'unknown Grep {attr.args}'
		endif

		var conf = grepConfig[i]
		var ft = '*'
		if has_key(conf, 'ft')
			ft = type(conf.ft) == type(null_string) ? conf.ft : conf.ft[0]
		endif

		cache.current = cache[ft]
	})
