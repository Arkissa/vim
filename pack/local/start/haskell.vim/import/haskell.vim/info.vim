vim9script

export class InfoRequest extends request.Complete
	var _expr: string

	def new(this._expr)
	enddef

	def Cmd(): string
		return $':info {this._expr}'
	enddef

	def Body(timeout: number = -1): list<string>
		return super.Body(timeout)->split("\n")
	enddef
endclass
