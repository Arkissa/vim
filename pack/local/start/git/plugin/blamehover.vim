vim9script noclear

if exists('g:loaded_git_blame') || &compatible
  finish
endif

g:loaded_git_blame = true

if !executable('git')
	finish
endif

import 'vim.vim'
import 'job.vim' as jb
import 'autocmd.vim'
import 'log.vim'

type Job = jb.Job
type Autocmd = autocmd.Autocmd
type Coroutine = vim.Coroutine

const AsyncIO = vim.AsyncIO
const BlameHoverGroup = 'git_blame_hover'
const BlameHoverPropTypeName = 'git_blame_proto_type'
const BlameHoverVirtulTextHighlight = 'Comment'
const FlushEvents = ['BufEnter', 'CursorHold', 'WinResized']
const ClearEvents = ['InsertEnter', 'BufLeave', 'CursorMoved']
const VirtualTextID = rand() % 10000 + 60000

final cache: dict<any> = {}

prop_type_add(BlameHoverPropTypeName, {
	highlight: BlameHoverVirtulTextHighlight,
	priority: 100,
	combine: true,
	override: true,
})

def HandlerBlameLine(raw: string): dict<string>
	var pat = '\v^([0-9a-f]{7,40})\s+\((.{-})\s+(\d{4})-\d{2}-\d{2}\s+(\d{2}:\d{2}:\d{2})\s+([+-]\d{4})\s+\d+\)'
	var m = matchlist(raw, pat)
	if len(m) == 0
		return {}
	endif
	return {
		'commit': m[1],
		'author': m[2],
		'year':   m[3],
		'time':   m[4],
		'tz':     m[5],
	}
enddef

def FormatBlame(blame: dict<string>): string
	if blame->empty()
		return ''
	endif

	return $'{blame.author}, {blame.year} {blame.time} {blame.tz}'
enddef

def CallbackShowVirtualText(ch: channel, line: string)
	RemoveVirtualText()

	const blame = FormatBlame(HandlerBlameLine(line))
	if blame->empty()
		return
	endif

	const bufnr = bufnr()
	const lnum = line('.')

	cache[bufnr] = lnum

	prop_add(lnum, 0, {
		type: BlameHoverPropTypeName,
		id: VirtualTextID,
		bufnr: bufnr,
		text: blame,
		text_align: 'after',
		text_padding_left: 3,
		text_wrap: 'wrap',
	})

	Autocmd.newMulti(ClearEvents)
		.Group(BlameHoverGroup)
		.Once()
		.Callback(() => {
			AsyncIO.Run(Coroutine.new(RemoveVirtualText))
		})
enddef

def RemoveVirtualText()
	var bufnr = bufnr()
	if !has_key(cache, bufnr)
		return
	endif

	var lnum = cache[bufnr]
	prop_clear(lnum, lnum, {
		id: VirtualTextID,
		type: BlameHoverPropTypeName,
		both: true,
	})
	remove(cache, bufnr)
enddef

def Blame()
	if &buftype != ''
		return
	endif

	const bufnr = bufnr()
	const lnum = line('.')
	if has_key(cache, bufnr) && lnum == cache[bufnr]
		return
	endif

	const fname = bufname()
	if fname->empty()
		return
	endif

	const cmd = $'git --no-pager blame -L {lnum},{lnum} {fname}'
	var job = Job.new(cmd, {
		out_cb: CallbackShowVirtualText,
		drop: 'auto',
		silent: true,
	})

	job.Run()
enddef

Autocmd.newMulti(FlushEvents)
	.Group(BlameHoverGroup)
	.Callback(() => {
		var co = Coroutine.new(Blame)
		co.SetDelay(get(g:, 'git_blame_delay', 100))

		AsyncIO.Run(co)
	})
