vim9script

import 'log.vim'
import 'buffer.vim'

import 'haskell.vim/ghci.vim'
import 'haskell.vim/config.vim'

const type = 'HaskellType'

def PreviewResponse(lines: list<string>)
	var b = buffer.Buffer.new(type)
	b.SetVar('&bufhidden', 'wipe')
	b.SetVar('&buftype', 'nofile')
	b.SetVar('&swapfile', false)

	b.Load()
	b.Clear()

	b.SetLines(lines, 1)
	b.SetVar('&modified', false)

	execute($'pbuffer {b.bufnr}')
enddef

export class TypeRequest extends ghci.Request
	var _expr: string

	def new(this._expr)
	enddef

	def Cmd(): string
		return $':type {this._expr}'
	enddef

	def Complete(response: string)
		PreviewResponse(response->split("\n"))
	enddef
endclass

class TypeAtRequest extends ghci.Request
	var _line: number
	var _col: number
	var _endline: number
	var _endcol: number

	var _expr: string
	var _filename: string

	def new(this._filename, this._line, this._col, this._endline, this._endcol, this._expr)
	enddef

	def Cmd(): string
		return $':type-at {this._filename} {this._line} {this._col} {this._endline} {this._endcol} {this._expr}'
	enddef

	def Complete(response: string)
		PreviewResponse(response->split("\n"))
	enddef
endclass
