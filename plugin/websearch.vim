vim9script

import 'keymap.vim'
import 'command.vim'

import autoload 'dist/vim9.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type NArgs = command.NArgs
type Command = command.Command

const askURLs = {
	google: 'https://www.google.com/search?udm=50&q=',
	chatgpt: 'https://chatgpt.com/?q='
}

const searchURLs = {
	google: 'https://www.google.com/search?q=',
	duckduckgo: 'https://duckduckgo.com/?q='
}

const askURL = get(askURLs, get(g:, 'ask_engine') ?? 'google')
const searchURL = get(searchURLs, get(g:, 'search_engine') ?? 'google')
const ask_prompt = get(g:, 'ask_prompt', '')

def WebSearch(s: string)
	var content = s
	if content == ""
		content = input('Web Search: ', '')
		if content == ""
			return
		endif
	endif

	vim9.Open(searchURL .. content)
enddef

def Ask(range: number, s: string)
	var content = s
	if content == ""
		content = input('Ask: ', '')
		if content == ""
			return
		endif
	endif

	if range > 0
		var lines = getregion(getcharpos("'<"), getcharpos("'>"), {type: visualmode()})
		lines->add(content)

		content = lines->join("\r\n")
	endif

	content = $'{content}\r\n{ask_prompt}'

	vim9.Open(askURL .. uri_encode(content))
enddef

Command.new('WebSearch')
	.NArgs(NArgs.Star)
	.Callback((attr) => {
		WebSearch(attr.args)
	})

Command.new('Ask')
	.NArgs(NArgs.Star)
	.Range('%')
	.Callback((attr) => {
		Ask(attr.range, attr.args)
	})

Bind.new(Mods.n).Map("<Leader><CR>", Bind.Cmd("WebSearch"))
Bind.new(Mods.x).Map("<Leader><CR>", ":Ask<CR>")
