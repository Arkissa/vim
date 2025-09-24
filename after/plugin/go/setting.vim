vim9script

g:go_highlight_types = 1
g:go_highlight_fields = 1
g:go_highlight_functions = 1
g:go_highlight_function_calls = 1
g:go_highlight_operators = 1
g:go_highlight_extra_types = 1
g:go_highlight_build_constraints = 1
g:go_highlight_generate_tags = 1

g:LspAddServer([{
	name: 'gopls',
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
				# '-tools/',
				'-common/redisx/',
			],
			workspaceFiles: [
				'app/**',
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
				QF1002: false, QF1003: false, any: false, SA4: false,
				ST1020: false, ST1003: false, ST1001: false,
				ST1021: false, ST1022: false,
				ST1000: false, S1033: false, S1028: false, # temporary
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
		}
	}
}])
