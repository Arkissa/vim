vim9script

import 'buffer.vim'

import 'haskell.vim/session.vim'
import 'haskell.vim/request.vim'

export class TypeExpr
	var expr: string
	var filename: string
	var pos: tuple<number, number, number, number>

	def new(this.expr, this.filename, this.pos)
	enddef

	def newExpr(this.expr)
	enddef
endclass

class CompleteExpention extends request.Complete
	var _matchs = [
		'error: [GHC-31891]'
	]

	def Body(timeout: number = -1): list<string>
		var response = super.Body(timeout)
		for match in this._matchs
			if response =~# match
				throw $'request faild: {match}'
			endif
		endfor

		return response->split("\n")
	enddef
endclass

class TypeRequest extends CompleteExpention
	var _expr: string

	def new(arg: TypeExpr)
		this._expr = arg.expr
	enddef

	def Cmd(): string
		return $':type {this._expr}'
	enddef

	def Body(timeout: number = -1): list<string>
		try
			return super.Body(timeout)
		catch
			return []
		endtry
	enddef
endclass

class TypeAtRequest extends CompleteExpention
	var _arg: TypeExpr

	def new(this._arg)
	enddef

	def Cmd(): string
		var [line, col, endline, endcol] = this._arg.pos
		return $':type-at {this._arg.filename} {line} {col} {endline} {endcol} {this._arg.expr}'
	enddef

	def Body(timeout: number = -1): list<string>
		try
			return super.Body(timeout)
		catch
			return []
		endtry
	enddef
endclass

export enum Mode
	Type,
	TypeAt
endenum

export class Type
	var _client: session.Client

	def new(this._client)
	enddef

	def Query(mode: Mode, arg: TypeExpr): list<string>
		var RequestConstructor = eval($'{mode.name}Request.new')
		var req = RequestConstructor(arg)

		this._client.Send(req)
		return req.Body()
	enddef
endclass
