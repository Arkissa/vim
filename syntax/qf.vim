vim9script

if exists('b:current_syntax')
	finish
endif

# Complete line pattern
syn match qfFileName "^\([EWIN]\s\)\?\f\+\s\d\+\(-\d\+\)\?\(:\d\+\(-\d\+\)\?\)\?\s" nextgroup=qfText contains=qfLevelTag,qfLineCol

# Pattern Level Tag
syn match qfLevelTag "^[EWIN]\s" contained contains=qfError,qfWarn,qfInfo,qfNote
# Level Tag keywords (E, W, I, N)
syn keyword qfError E contained
syn keyword qfWarn W contained
syn keyword qfInfo I contained
syn keyword qfNote N contained

# Line and column: lnum[-end_lnum][:col[-end_col]]
syn match qfLineCol "\d\+\(-\d\+\)\?\(:\d\+\(-\d\+\)\?\)\?" contained
syn match qfText ".*" contained

hlset([
	{name: 'qfError', default: true, linksto: 'LspDiagSignErrorText'},
	{name: 'qfWarn', default: true, linksto: 'LspDiagSignWarningText'},
	{name: 'qfInfo', default: true, linksto: 'LspDiagSignInfoText'},
	{name: 'qfNote', default: true, linksto: 'LspDiagSignHintText'},
	{name: 'qfFileName', default: true, linksto: 'XtermFg4'},
	{name: 'qfLineCol', default: true, linksto: 'Number'},
])

&l:conceallevel = 2
&l:concealcursor = 'nvc'

def SyntaxAnsiColors(prefix: string, code_offset: number, xterm_type: string): list<dict<any>>
	var highlights: list<dict<any>> = []
	for color in range(0, 15)
		var code = code_offset + color
		if color >= 8
			code = code_offset + 60 + (color - 8)
		endif
		execute($'syn region {prefix}{color} matchgroup=Conceal start="\e\[\([0-9]\+;\)*{code}m" matchgroup=Conceal end="\e\[0\{{0,2}}m" concealends')
		highlights->add({name: $'{prefix}{color}', linksto: $'XtermColor{xterm_type}{color}', default: true})
	endfor
	return highlights
enddef

def GetRGBComponents(color: number): list<number>
	var idx = color - 16
	var r = idx / 36
	var g = (idx % 36) / 6
	var b = idx % 6
	return [r, g, b]
enddef

# Fallback: conceal any unhandled ANSI escape sequences
# This must be defined LAST so it has lowest priority
syn region AnsiFallback matchgroup=Conceal start="\e\[[0-9;]*m" end="\e\[0\{0,2}m" concealends

def MapRGBToAnsi(r: number, g: number, b: number): number
	if abs(r - g) <= 1 && abs(g - b) <= 1 && abs(r - b) <= 1
		var avg = (r + g + b) / 3
		if avg <= 1
			return 0  # Black
		elseif avg >= 4
			return 15  # Bright white
		elseif avg >= 2
			return 7  # White
		else
			return 8  # Gray
		endif
	endif

	var has_red = r >= 3
	var has_green = g >= 3
	var has_blue = b >= 3

	# Mixed colors
	if has_red && has_green && has_blue
		return 15  # White
	elseif has_red && has_green
		return r >= 4 || g >= 4 ? 11 : 3  # Yellow (bright or normal)
	elseif has_red && has_blue
		return r >= 4 || b >= 4 ? 13 : 5  # Magenta
	elseif has_green && has_blue
		return g >= 4 || b >= 4 ? 14 : 6  # Cyan
	elseif has_red
		return r >= 4 ? 9 : 1  # Red
	elseif has_green
		return g >= 4 ? 10 : 2  # Green
	elseif has_blue
		return b >= 4 ? 12 : 4  # Blue
	else
		return 0  # Black/dark
	endif
enddef

def BuildNumberRangePattern(numbers: list<number>): string
	# Convert list of numbers to optimized regex pattern
	# e.g., [16, 17, 18, 52, 53, 54] -> "1[6-8]|5[2-4]"
	if numbers->empty()
		return ''
	endif
	# Sort numbers
	var sorted = numbers->copy()->sort('n')
	# Group consecutive numbers
	var ranges: list<list<number>> = []
	var start = sorted[0]
	var prev = sorted[0]
	for num in sorted[1 : ]
		if num == prev + 1
			prev = num
		else
			ranges->add([start, prev])
			start = num
			prev = num
		endif
	endfor
	ranges->add([start, prev])
	# Convert ranges to regex patterns
	var patterns: list<string> = []
	for [range_start, range_end] in ranges
		if range_start == range_end
			patterns->add(string(range_start))
		else
			# Try to build compact pattern for range
			var start_str = string(range_start)
			var end_str = string(range_end)
			if start_str->len() == end_str->len() && start_str[ : -2] == end_str[ : -2]
				# Same prefix, only last digit differs
				# e.g., 52-54 -> "5[2-4]"
				var prefix = start_str[ : -2]
				var start_digit = start_str[-1 : ]
				var end_digit = end_str[-1 : ]
				patterns->add($'{prefix}[{start_digit}-{end_digit}]')
			else
				# Fall back to enumeration for complex ranges
				for n in range(range_start, range_end)
					patterns->add(string(n))
				endfor
			endif
		endif
	endfor

	return patterns->join('\|')
enddef

def SyntaxXtermColors(prefix: string, code: number, xterm_type: string): list<dict<any>>
	var highlights: list<dict<any>> = []

	# 0-15: Map to corresponding ANSI colors
	for color in range(0, 15)
		execute($'syn region {prefix}{color} matchgroup=Conceal start="\e\[\([0-9]\+;\)*{code};5;{color}m" matchgroup=Conceal end="\e\[0\{{0,2}}m" concealends')
		highlights->add({name: $'{prefix}{color}', linksto: $'XtermColor{xterm_type}{color}', default: true})
	endfor

	# 16-231: RGB cube - group by ANSI color mapping
	var rgb_groups: dict<list<number>> = {}
	for color in range(16, 231)
		var [r, g, b] = GetRGBComponents(color)
		var ansi = MapRGBToAnsi(r, g, b)
		if !rgb_groups->has_key(string(ansi))
			rgb_groups[string(ansi)] = []
		endif
		rgb_groups[string(ansi)]->add(color)
	endfor

	# Create syntax regions for each ANSI group
	for ansi_str in rgb_groups->keys()
		var ansi = str2nr(ansi_str)
		var colors = rgb_groups[ansi_str]
		var pattern = BuildNumberRangePattern(colors)
		execute($'syn region {prefix}RGB{ansi} matchgroup=Conceal start="\e\[\([0-9]\+;\)*{code};5;\({pattern}\)m" matchgroup=Conceal end="\e\[0\{{0,2}}m" concealends')
		highlights->add({name: $'{prefix}RGB{ansi}', linksto: $'XtermColor{xterm_type}{ansi}', default: true})
	endfor

	# 232-255: Grayscale - simplified with regex ranges
	# 232-237 -> Black (0)
	execute($'syn region {prefix}GrayBlack matchgroup=Conceal start="\e\[\([0-9]\+;\)*{code};5;23[2-7]m" matchgroup=Conceal end="\e\[0\{{0,2}}m" concealends')
	highlights->add({name: $'{prefix}GrayBlack', linksto: $'XtermColor{xterm_type}0', default: true})

	# 238-249 -> Gray (8)
	execute($'syn region {prefix}GrayMedium matchgroup=Conceal start="\e\[\([0-9]\+;\)*{code};5;\(23[89]\|24[0-9]\)m" matchgroup=Conceal end="\e\[0\{{0,2}}m" concealends')
	highlights->add({name: $'{prefix}GrayMedium', linksto: $'XtermColor{xterm_type}8', default: true})

	# 250-255 -> Bright White (15)
	execute($'syn region {prefix}GrayWhite matchgroup=Conceal start="\e\[\([0-9]\+;\)*{code};5;25[0-5]m" matchgroup=Conceal end="\e\[0\{{0,2}}m" concealends')
	highlights->add({name: $'{prefix}GrayWhite', linksto: $'XtermColor{xterm_type}15', default: true})

	return highlights
enddef

hlset([
	SyntaxAnsiColors('ansiFg', 30, 'Fg'),
	SyntaxAnsiColors('ansiBg', 40, 'Bg'),
	SyntaxXtermColors('XtermFg', 38, 'Fg'),
	SyntaxXtermColors('XtermBg', 48, 'Bg'),
]->flattennew())

b:current_syntax = 'qf'
