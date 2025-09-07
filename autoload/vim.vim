vim9script

export def Cmd(s: list<string>): string
	return s->join(' ')
enddef

export def Option(s: list<string>): string
	return s->join(',')
enddef

export abstract class Void
	def string(): string
		return 'void'
	enddef
endclass

class SingleVoid extends Void
endclass

export const void = SingleVoid.new()

export class Exception
	var _exception: string
	def new(this._exception)
	enddef

	def string(): string
		return this._exception
	enddef
endclass

export class Promise
	var _F: func
	var _once: bool
	var _return = {}

	def new(this._F, ...args: list<any>)
		timer_start(0, (_) => {
				try
					var val = call(this._F, args)
					this._return['val'] = val
				catch /E1186\|E1031/
					this._return['val'] = void
				catch
					this._return['val'] = Exception.new(v:exception)
				endtry
			})
	enddef

	def Await(): any
		if !this._once
			this._once = true
		else
			throw "Await can only be called once."
		endif

		while !has_key(this._return, 'val')
			:sleep 50m
		endwhile

		var val = this._return.val

		if type(val) == type(null_object) && instanceof(val, Exception)
			throw this._return.val->string()
		endif

		return val
	enddef
endclass
