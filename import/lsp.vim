vim9script

final lspConfig = {}

const option = {
    autoComplete: true,
    autoHighlight: true,
    autoHighlightDiags: true,
    completionMatcher: 'fuzzy',
	completionTextEdit: true,
    diagSignErrorText: '✘',
    diagSignWarningText: '',
    diagSignHintText: '',
    diagSignInfoText: '',
	snippetSupport: true,
    keepFocusInDiags: true,
    keepFocusInReferences: true,
	ignoreMissingServer: false,
	outlineOnRight: true,
	outlineWinSize: 50,
    popupBorder: true,
    popupBorderHighlight: 'Title',
    popupBorderHighlightPeek: 'Title',
    popupBorderSignatureHelp: true,
    popupHighlight: 'Normal',
    semanticHighlight: true,
    showDiagInBalloon: true,
    showDiagInPopup: true,
    showDiagWithSign: true,
    showInlayHints: true,
    showSignature: true,
	condensedCompletionMenu: true,
	filterCompletionDuplicates: true,
	useBufferCompletion: true,
    useQuickfixForLocations: true,
    usePopupInCodeAction: true,
    bufferCompletionTimeout: 100,
    customCompletionKinds: true,
    completionKinds: {
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
    },
}

export def Config(): list<dict<any>>
	if !has_key(g:, 'LspWorkspace')
		return lspConfig->values()
	endif

	for workspace in g:LspWorkspace->keys()
		if !has_key(lspConfig, workspace)
			continue
		endif

		var conf = lspConfig[workspace]
		var workspaceConfig = get(conf, 'workspaceConfig', {
			[workspace]: {}
		})

		lspConfig[workspace].workspaceConfig = extend(workspaceConfig, g:LspWorkspace[workspace], 'force')
	endfor

	return lspConfig->values()
enddef

export def Option(): dict<any>
	return get(g:, 'LspOption', option)
enddef

def g:LspSetConfig(name: string, conf: dict<any>)
	conf.name = name
	lspConfig[name] = conf
enddef
