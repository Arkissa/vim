vim9script

g:LspAddServer([
    {
	name: 'python',
	filetype: ['python'],
	path: 'basedpyright-langserver',
	args: ["--stdio"],
	workspaceConfig: {
	    python: {
		autoSearchPaths: true,
		useLibraryCodeForTypes: true,
		analysis: {
		    diagnosticMode: 'workspace',
		    typeCheckingMode: 'recommended',
		    inlayHints: {
			variableTypes: true,
			callArgumentNames: true,
			functionReturnTypes: true,
			genericTypes: true,
		    }
		}
	    }
	},
	syncInit: true,
    },
])
