vim9script

export abstract class Clipboard
	var name = 'clipboard'
	abstract def Available(): bool
	abstract def Copy(reg: string, type: string, str: list<string>)
	abstract def Paste(reg: string): tuple<string, list<string>>

	def Provider(): dict<any>
		return {
			available: this.Available,
			copy: {
				"+": this.Copy,
				"*": this.Copy
			},
			paste: {
				"+": this.Paste,
				"*": this.Paste
			}
		}
	enddef
endclass

export class Kitty extends Clipboard
	def new()
		this.name = 'kitty'
	enddef

	def	Available(): bool
		return !empty($KITTY_WINDOW_ID) && executable('kitten')
	enddef

	def Copy(reg: string, type: string, str: list<string>)
		var args = "kitten clipboard"

		if reg == "*"
			args ..= " -p"
		endif

		system(args, str)
	enddef

	def Paste(reg: string): tuple<string, list<string>>
		var args = ["kitten", "clipboard", "--mime", "text/plain;charset=utf-8", "-g"]

		if reg == "*"
			args->add("-p")
		endif

		return (visualmode() ?? 'v', systemlist(args))
	enddef
endclass

export class Wayland extends Clipboard
	def new()
		this.name = 'wayland'
	enddef

	def	Available(): bool
	   return has('wayland_clipboard') && !empty(v:wayland_display) && executable('wl-copy') && executable('wl-paste')
	enddef

	def Copy(reg: string, type: string, str: list<string>)
		var args = "wl-copy"

		if reg == "*"
			args ..= " -p"
		endif

		system(args, str)
		# clean dirty control code return from wl-copy.
		:redraw!
	enddef

	def Paste(reg: string): tuple<string, list<string>>
		var args = ["wl-paste", "--type", "text/plain;charset=utf-8", "--no-newline"]

		if reg == "*"
			args->add("-p")
		endif

		return (visualmode() ?? 'v', systemlist(args))
	enddef
endclass
