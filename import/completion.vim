vim9script

export interface CompleteFunc
	def First(): number
	def Complete(base: string): any
endinterface

export class Complete
	var _cmp: CompleteFunc

	def new(this._cmp)
		if this._cmp == null_object
			throw 'Complete.new(): argument must not be null_object'
		endif
	enddef

	def Func(first: number, base: string): any
		if first == 1
			return this._cmp.First()
		endif

		return this._cmp.Complete(base)
	enddef
endclass
