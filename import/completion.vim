vim9script

export abstract class CompleteFunc
	abstract def First(): number
	abstract def Complete(base: string): any

	def Func(first: number, base: string): any
		if first == 1
			return this.First()
		endif

		return this.Complete(base)
	enddef
endclass

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
