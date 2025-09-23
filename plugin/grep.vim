vim9script

if !exists("g:GrepConfig") || g:GrepConfig->empty()
	finish
endif

import '../autoload/command.vim'
import '../autoload/autocmd.vim'
import '../autoload/keymap.vim'

type Bind = keymap.Bind
type NArgs = command.NArgs
type Command = command.Command
type Autocmd = autocmd.Autocmd
type Complete = command.Complete

const group = 'Grep'

var obj: command.Execute
var cache: dict<command.Execute> = {}
var grepConfig: list<dict<any>> = g:GrepConfig

def RegisterKeymap(bind: Bind, kvs: dict<any>)
	for [k, v] in kvs->items()
		if type(v) == type(null_function)
			bind.ScriptCmd(k, v)
		else
			bind.Map(k, v)
		endif
	endfor
enddef

def RegisterByFt(exe: command.Execute, keymaps: tuple<Bind, dict<any>> = null_tuple)
	obj = exe
	if keymaps != null_tuple
		var [bind, maps] = keymaps
		RegisterKeymap(bind.Buffer(), maps)
	endif
enddef

for conf in g:GrepConfig
	import autoload $'{conf.name}.vim'

	if has_key(conf, 'Init') && type(conf['Init']) == type(null_function)
		call(conf['Init'], [])
	endif

	var module = fnamemodify(conf.name, ':t:r')
	cache[module] = eval($'{module}.Grep.{has_key(conf, 'args') ? 'new(conf.args)' : 'new()'}')

	if has_key(conf, 'ft')
		Autocmd.new('FileType')
			.Group(group)
			.Pattern(type(conf.ft) == type(null_string) ? [conf.ft] : (conf.ft ?? ['*']))
			.Callback(funcref(RegisterByFt, [cache[module], has_key(conf, 'keymaps') ? conf.keymaps : null_tuple]))
	elseif has_key(conf, 'keymaps')
		var [bind: Bind, maps: dict<any>] = conf.keymaps
		RegisterKeymap(bind, maps)
	endif
endfor

Command.new("Grep")
	.Bar()
	.Bang()
	.NArgs(command.NArgs.Star)
	.Callback((attr) => {
		if obj != null_object
			obj.Attr(attr).Run()
		else
			echoerr 'No defined Grep.'
		endif
	})

Command.new('GrepChange')
	.NArgs(command.NArgs.One)
	.Complete(Complete.CustomList, (A, L, P): list<string> => {
		return cache->keys()
	})
	.Callback((attr) => {
		if has_key(cache, attr.args)
			obj = cache[attr.args]
		else
			echoerr $'unknown Grep {attr.args}'
		endif
	})
