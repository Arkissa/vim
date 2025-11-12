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
const FlushEvents = ['BufEnter', 'CursorHold']
const ClearEvents = ['InsertEnter', 'CmdwinEnter', 'CmdlineEnter', 'BufLeave', 'CursorMoved']

prop_type_add(BlameHoverPropTypeName, {
	highlight: BlameHoverVirtulTextHighlight,
	combine: true,
	priority: 100,
	override: true,
})

class Blame
    var sha: string
    var abbrev_sha: string
    var author: string
    var author_mail: string
    var author_tz: string
    var author_time: number
    var committer: string
    var committer_time: number
    var committer_mail: string
    var committer_tz: string
    var summary: string

	static var _notCommitted: Blame

	def new(
		sha: string = '',
		abbrev_sha: string = '',
		author: string = '',
		author_mail: string = '',
		author_tz: string = '',
		author_time: number = 0,
		committer: string = '',
		committer_time: number = 0,
		committer_mail: string = '',
		committer_tz: string = '',
		summary: string = '',
	)
		this.sha = sha
		this.abbrev_sha = abbrev_sha
		this.author = author
		this.author_mail = author_mail
		this.author_tz = author_tz
		this.author_time = author_time
		this.committer = committer
		this.committer_time = committer_time
		this.committer_mail = committer_mail
		this.committer_tz = committer_tz
		this.summary = summary
	enddef

	def SetSha(v: string)
		this.sha = v
	enddef

	def SetAbbrevSha(v: string)
		this.abbrev_sha = v
	enddef

	def SetAuthor(v: string)
		this.author = v
	enddef

	def SetAuthorMail(v: string)
		this.author_mail = v
	enddef

	def SetAuthorTz(v: string)
		this.author_tz = v
	enddef

	def SetAuthorTime(v: string)
		this.author_time = v->str2nr()
	enddef

	def SetCommitter(v: string)
		this.committer = v
	enddef

	def SetCommitterTime(v: string)
		this.committer_time = v->str2nr()
	enddef

	def SetCommitterMail(v: string)
		this.committer_mail = v
	enddef

	def SetCommitterTz(v: string)
		this.committer_tz = v
	enddef

	def SetSummary(v: string)
		this.summary = v
	enddef

	static def NotCommitted(file: string): Blame
		var time = localtime()
		if _notCommitted != null_object
			_notCommitted.author_time = time
			_notCommitted.committer_time = time
			_notCommitted.summary = $'Version of {file}'

			return _notCommitted
		endif

		_notCommitted = Blame.new(
			repeat('0', 40),
			repeat('0', 8),
			'Not Committed Yet',
			'<not.committed.yet>',
			'+0000',
			time,
			'Not Committed Yet',
			time,
			'<not.committed.yet>',
			'+0000',
			$'Version of {file}',
		)

		return _notCommitted
	enddef

	def string(): string
		var str = [$'{this.author}, {strftime("%Y-%m-%d %H:%M", this.author_time)}']
		if this.abbrev_sha != '00000000'
			str = str + [$'- {this.summary}']
		endif

		return str->join()
	enddef
endclass

final blame = Blame.new()
final handlers = vim.Ring.new([
	('\v\zs[0-9a-f]{40}\ze\s+\d+\s+\d+\s+\d+$', (m) => {
		blame.SetSha(m)
		blame.SetAbbrevSha(m[0 : 7])
	}),
	('\vauthor \zs.+$', blame.SetAuthor),
	('\vauthor-mail\s\<\zs[^>]+\>$', blame.SetAuthorMail),
	('\vauthor-time \zs\d+$', blame.SetAuthorTime),
	('\vauthor-tz \zs[+-]\d{4}$', blame.SetAuthorTz),
	('\vcommitter \zs.+$', blame.SetCommitter),
	('\vcommitter-mail\s\<\zs[^>]+\>$', blame.SetCommitterMail),
	('\vcommitter-time \zs\d+$', blame.SetCommitterTime),
	('\vcommitter-tz \zs[+-]\d{4}$', blame.SetCommitterTz),
	('\vsummary \zs.+$', blame.SetSummary),
])

def HandlerBlameLine(line: string)
	if line ==# ''
		return
	endif

	var cur = handlers.Peek()
	var re = cur[0]
	var Fn = cur[1]
	var m = matchstr(line, re)
	if m !=# ''
		Fn(m)
		handlers.SlideRight()
	endif
enddef

def ShowVirtualText(ch: channel, line: string)
	HandlerBlameLine(line)
enddef

def RemoveVirtualText(bufnr: number, lnum: number)
	const props = prop_list(1, {
		bufnr: bufnr,
		end_lnum: -1,
		types: [BlameHoverPropTypeName],
	})

	if props->empty()
		return
	endif

	const p = {type: BlameHoverPropTypeName, bufnr: bufnr, all: true}
	for prop in props
		prop_remove(p, prop.lnum, prop.lnum)
	endfor

enddef

var buf: number

def Done(_: job, code: number)
	var b = blame
	buf = bufnr()
	if code != 0
		b = Blame.NotCommitted(bufname(buf))
	endif

	var lnum = line('.')
	var prop = {
		type: BlameHoverPropTypeName,
		bufnr: buf,
		text: b->string(),
		text_wrap: 'wrap',
		text_padding_left: 5,
		text_align: 'after',
	}

	prop_add(lnum, 0, prop)

	Autocmd.newMulti(ClearEvents)
		.Group(BlameHoverGroup)
		.Once()
		.Replace()
		.Bufnr(buf)
		.Callback(() => {
			vim.NapCall(RemoveVirtualText, buf, lnum)
		})
enddef

def RunBlame()
	if &buftype != '' || &readonly || !&modifiable
		return
	endif

	const fname = bufname()
	if fname->empty()
		return
	endif

	const lnum = line('.')
	const cmd = $'git --no-pager blame -b --incremental -w -p -L {lnum},+1 {fname}'
	var job = Job.new(cmd, {
		out_cb: ShowVirtualText,
		exit_cb: Done,
		drop: 'auto',
		silent: true,
	})

	job.Run()
enddef

Autocmd.newMulti(FlushEvents)
	.Group(BlameHoverGroup)
	.Desc('git blame hover flush event.')
	.Callback((attr) => {
		if bufloaded(buf) && buf != attr.buf
			return
		endif

		var lnum = line('.')
		const props = prop_list(lnum, {
			bufnr: attr.buf,
			end_lnum: lnum,
			types: [BlameHoverPropTypeName]})

		if !props->empty()
			return
		endif

		var co = Coroutine.new(RunBlame)
		co.SetDelay(get(g:, 'git_blame_delay', 100))

		AsyncIO.Run(co)
	})
