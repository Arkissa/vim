vim9script

abstract class Lint extends command.ErrorFormat
	abstract def Cmd(): string
	abstract def Efm(): string
endclass
