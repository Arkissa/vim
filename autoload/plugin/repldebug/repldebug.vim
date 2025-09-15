vim9script

import autoload 'vim.vim'
import autoload 'job.vim' as jb
import autoload 'window.vim'
import autoload 'terminal.vim'

type Ring = vim.Ring

export class Variable
	var Type: string
	var Name: string
	var Value: string

	def new(this.Type, this.Name, this.Value)
	enddef
endclass

class DebugVariable
	var _win: window.Window
	var _global: dict<Variable>
	var _local: dict<Variable>

	def SetGlobal(global: dict<Variable>)
		this._global = global
	enddef

	def SetLocal(local: dict<Variable>)
		this._local = local
	enddef

	def UpdateGlobal(global: dict<Variable>)
		for [k, v] in global.items()
			this._global[k] = v
		endfor
	enddef

	def UpdateLocal(local: dict<Variable>)
		for [k, v] in local.items()
			this._local[k] = v
		endfor
	enddef

	def Draw()
	enddef
endclass

export abstract class REPLDebug extends jb.Prompt
	static var _Session: Ring
	static var _Breakpints: dict<list<string>>
	static var _OrginBuffer: buffer.Buffer
	static var _CodeWindow: window.Window
	static var _PromptWindow: window.Window
	static var _Stack: window.Window
	static var _Pty: window.Window
	static var _Signs: list<string>

	abstract def Callback(chan: channel, msg: string) # {{{2
	abstract def Prompt(): string # {{{2

	def GotoLine()
	enddef

	def OpenStackWindow(): buffer.Buffer
		_Stack = _Stack ?? window.Window.new('REPLDebug-Stack')
		return _Stack.GetBuffer()
	enddef

	def OpenVariablesWindow(): buffer.Buffer
		_Variables = _Variables ?? window.Window.new('REPLDebug-Variables')
		return _Variable.GetBuffer()
	enddef

	def Run()
		_CodeWindow = window.Window.newCurrent()
		_PromptWindow = window.Window.new()
		super.Run()
		_PromptWindow.SetBuffer(this.prompt)
		_Pty = window.Window.newByBufer(terminal.Terminal.new('NONE', {
			pty: true,
		}))
	enddef
endclass
