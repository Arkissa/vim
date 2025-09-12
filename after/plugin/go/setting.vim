vim9script

g:go_highlight_types = 1
g:go_highlight_fields = 1
g:go_highlight_functions = 1
g:go_highlight_function_calls = 1
g:go_highlight_operators = 1
g:go_highlight_extra_types = 1
g:go_highlight_build_constraints = 1
g:go_highlight_generate_tags = 1

if executable('gopls')
	g:LspAddServer([{
		name: 'golang',
		filetype: ['go', 'gomod', 'gohtmltmpl', 'gotexttmpl'],
		path: 'gopls',
		workspaceConfig: {
			gopls: {
				directoryFilters: [
					'-**/node_modules',
					'-3rd/',
					'-**/bin',
					'-**/logs',
					'-app/deploy',
					'-proto/',
					'-docs/',
					'-tools/',
				],
				completionBudget: '50ms',
				codelenses: {
					tests: true,
					tidy: true,
					upgrade_dependency: true,
					vendor: true,
				},
				usePlaceholders: true,
				gofumpt: true,
				analyses: {
					shadow: false, unusedparams: false, SA5008: false,
					QF1002: false, QF1003: false, any: false, S1002: true,
					S1005: true, S1008: true, S1011: true, S1016: true,
					S1021: true, S1025: true, S1029: true, ST1020: false,
					ST1003: false, ST1001: false, ST1017: true, SA1000: true,
					SA1002: true, SA1003: true, SA1007: true, SA1010: true,
					SA1014: true, SA1015: true, SA1017: true, SA1018: true,
					SA1020: true, SA1021: true, SA1023: true, SA1024: true,
					SA1026: true, SA1029: true, SA1030: true, SA4006: true,
					SA4010: true, SA5007: true, SA5010: true, SA9003: true,
					ST1005: true,
					S1033: false, # temporary
					S1028: false, # temporary
				},
				staticcheck: true,
				hints: {
					assignVariableTypes: true,
					compositeLiteralFields: true,
					constantValues: true,
					rangeVariableTypes: true,
					parameterNames: true,
					functionTypeParameters: true
				},
				semanticTokens: false,
			}
		}
	}])
endif
