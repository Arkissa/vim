vim9script

if !exists("g:grep_config") || g:grep_config->empty()
	finish
endif

# type check
var grepConfig: dict<any> = copy(g:grep_config)
var greps: list<dict<any>> = get(grepConfig, 'greps', [])

import 'command.vim'
import 'autocmd.vim'
import 'keymap.vim'
import autoload 'greps/grepprg.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
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

if get(grepConfig, 'auto_open', false)
	Autocmd.new('QuickFixCmdPost')
		.Group(group)
		.Pattern(['Grep'])
		.Callback((attr) => {
			var qf = attr.data
			if !qf.IsEmpty()
				qf.Open()
			endif
		})
endif

for conf in greps
	import autoload $'{conf.module}.vim'

	if has_key(conf, 'Init') && type(conf['Init']) == v:t_func
		call(conf.Init, [])
	endif

	var Constructor = eval($'{fnamemodify(conf.module, ':t:r')}.Grep.new')
	var obj: grepprg.Grepprg = has_key(conf, 'args')
		? Constructor(conf.args)
		: Constructor()

	var fts = ['*']
	if has_key(conf, 'ft')
		fts = type(conf.ft) == v:t_string ? [conf.ft] : (conf.ft ?? fts)
	endif

	fts = uniq(copy(fts))

	if has_key(conf, 'keymaps')
		var bind: Bind = get(conf.keymaps, 'bind', null_object) ?? Bind.new(Mods.n).Buffer().NoRemap()

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
