vim9script

if !exists("g:GrepConfig") || g:GrepConfig->empty()
	finish
endif

# type check
var grepConfig: dict<any> = copy(g:GrepConfig)
var greps: list<dict<any>> = get(grepConfig, 'greps', [])

import 'command.vim'
import 'autocmd.vim'
import 'keymap.vim'

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
	var Map: func
	for [k, v] in kvs->items()
		Map = type(v) == v:t_func
			? bind.Callback
			: bind.Map

		Map(k, v)
	endfor
enddef

if has_key(grepConfig, 'autoOpen') && remove(grepConfig, 'autoOpen')
	def AutoOpen(attr: any)
		attr.data.Window()
	enddef

	Autocmd.new('QuickFixCmdPost')
		.Group(group)
		.Pattern(['Grep'])
		.Callback(AutoOpen)
endif

for conf in greps
	import autoload $'{conf.module}.vim'

	if has_key(conf, 'Init') && type(conf['Init']) == v:t_func
		call(conf.Init, [])
	endif

	var Constructor = eval($'{fnamemodify(conf.module, ':t:r')}.Grep.new')
	var obj: command.Execute = has_key(conf, 'args')
		? Constructor(conf.args)
		: Constructor()

	var fts = ['*']
	if has_key(conf, 'ft')
		fts = type(conf.ft) == v:t_string ? [conf.ft] : (conf.ft ?? fts)
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
		return greps->mapnew((_, conf) => fnamemodify(conf.module, ':t:r'))
	})
	.Callback((attr) => {
		var i = greps->indexof((_, conf) => fnamemodify(conf.module, ':t:r') == attr.args)
		if i == -1
			echoerr $'unknown Grep {attr.args}'
		endif

		var conf = greps[i]
		var ft = '*'
		if has_key(conf, 'ft')
			ft = type(conf.ft) == v:t_string ? conf.ft : conf.ft[0]
		endif

		cache.current = cache[ft]
	})
