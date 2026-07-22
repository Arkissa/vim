vim9script

export interface CompleteFunc
	def First(): number
	def Complete(base: string): any
endinterface

var cmps: list<CompleteFunc> = []

def CallByIdx(idx: number, first: number, base: string): any
	var cmp = cmps[idx]
	if first == 1
		return cmp.First()
	endif

	return cmp.Complete(base)
enddef

export def Func(cmp: CompleteFunc): func(number, string): any
	cmps->add(cmp)
	return funcref(CallByIdx, [cmps->len() - 1])
enddef

export const kinds = {
	Text: '󰦨',
	Method: '',
	Function: '󰡱',
	Constructor: '',
	Field: '',
	Variable: '',
	Class: '',
	Interface: '',
	Module: '',
	Property: '',
	Unit: '󰊱',
	Value: '',
	Enum: '',
	Keyword: '',
	Snippet: '',
	Color: '',
	File: '',
	Reference: '',
	Folder: '󰣞',
	EnumMember: '',
	Constant: '',
	Struct: '',
	Event: '',
	Operator: '',
	TypeParameter: '',
	Buffer: ''
}
