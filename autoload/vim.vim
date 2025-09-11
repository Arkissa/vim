vim9script

export def Cmd(s: list<string>): string # {{{1
	return s->join(' ')
enddef

export def Option(s: list<string>): string # {{{1
	return s->join(',')
enddef

export abstract class Void # {{{1
	def string(): string # {{{2
		return 'void'
	enddef
endclass

class SingleVoid extends Void # {{{1
endclass

export const void = SingleVoid.new() # {{{1

export class Exception # {{{1
	var _exception: string # {{{2
	def new(this._exception) # {{{2
	enddef

	def string(): string # {{{2
		return this._exception
	enddef
endclass

export class Promise # {{{1
	var _F: func # {{{2
	var _once: bool # {{{2
	var _return = {} # {{{2

	def new(this._F, ...args: list<any>) # {{{2
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

	def Await<T>(): T # {{{2
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
