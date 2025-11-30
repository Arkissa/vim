vim9script

import 'vim.vim'

const version = '2.0'

final protocol_id = vim.IncID.new()

class Request
	var id: number
	var _method: string
	var _params: dict<any>
	const version = version

	def new(this._method, this._params)
		this.id = protocol_id.ID()
	enddef

	def Serialize(): string
		return json_encode({
			jsonrpc: version,
			id: this.id,
			method: this._method,
			params: this._params,
		})
	enddef
endclass

class Response
	var id: number
	var result: any
	var error: Error = null_object
	const version = version

	def new(resp: string)
		var dict = json_decode(resp)
		if get(dict, 'jsonrpc', '') != this.version
			throw 'Unable to deserialize JSON that is not jsonrpc 2.0'
		endif

		var error = get(dict, 'error', null_object)
		if error != null_object
			this.error = Error.new(error)
			return
		endif

		this.id = get(dict, 'id', -1)
		if this.id == -1
			throw 'Incorrect ID'
		endif

		this.result = get(dict, 'result', null)
	enddef

	def Serialize(): string
		return json_encode({
			jsonrpc: version,
			id: this.id,
			method: this._method,
			params: this._params,
		})
	enddef
endclass

class Error
	var code: ErrorCode
	var message: string
	var data: any

	def new(dict: dict<any>)
		var code = get(dict, 'code', -1)
		if vim.Contains([-32700, -32600, -32601, -32602, -32603], code) || (code <= -32000 && code >= -32099)
			this.code = code
		else
			throw $'Incorrect code: {code}'
		endif

		this.message = get(dict, 'message', '')
		this.data = get(dict, 'data', null)
	enddef

	def newByJson(s: string)
		var dict = json_decode(s)
		var code = get(dict, 'code', -1)
		if vim.Contains([-32700, -32600, -32601, -32602, -32603], code) || (code <= -32000 && code >= -32099)
			this.code = code
		else
			throw $'Incorrect code: {code}'
		endif

		this.message = get(dict, 'message', '')
		this.data = get(dict, 'data', null)
	enddef
endclass
