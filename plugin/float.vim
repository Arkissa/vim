vim9script

def PopupWindow(bufnr: number): number
	return popup_create(bufnr, {
		pos: "center",
		minwidth: ceil(&co * 0.7),
		minheight: ceil(&lines * 0.75),
	})
enddef
