vim9script

enum NodeKind
	Section,
	Pair,
	Comment,
	Blank
endenum

class Pos
	var lnum: number
	var col: number

	def new(this.lnum, this.col)
	enddef

	def string(): string
		return printf('L%d,C%d', this.lnum, this.col)
	enddef
endclass

class Range
	var start: Pos
	var end: Pos

	def new(this.start, this.end)
	enddef

	def string(): string
		var linePart = ''
		if this.start.lnum == this.end.lnum
			linePart = printf('L%d', this.start.lnum)
		else
			linePart = printf('L%d-L%d', this.start.lnum, this.end.lnum)
		endif

		var colPart = ''
		if this.start.col == this.end.col
			colPart = printf('C%d', this.start.col)
		else
			colPart = printf('C%d-C%d', this.start.col, this.end.col)
		endif

		return linePart .. ',' .. colPart
	enddef
endclass

class ConfigNode
	var kind: NodeKind
	var range: Range

	def new(this.kind, this.range)
	enddef

	def string(): string
		return printf('%s @ %s', string(this.kind), this.range->string())
	enddef
endclass

class SectionNode extends ConfigNode
	var name: string
	var subsection: string
	var items: list<ConfigNode>

	def new(range: Range, this.name, this.subsection)
		this.kind = NodeKind.Section
		this.range = range
		this.items = []
	enddef

	def AddItem(node: ConfigNode)
		this.items->add(node)
	enddef

	def string(): string
		var header = printf('Section[%s "%s"] @ %s', this.name, this.subsection, this.range->string())
		var parts: list<string> = [header]
		for item in this.items
			parts->add('  ' .. item->string())
		endfor
		return join(parts, "\n")
	enddef
endclass

class PairNode extends ConfigNode
	var key: string
	var value: string

	def new(range: Range, this.key, this.value)
		this.kind = NodeKind.Pair
		this.range = range
	enddef

	def string(): string
		return printf('Pair %s = %s @ %s', this.key, this.value, this.range->string())
	enddef
endclass

class CommentNode extends ConfigNode
	var text: string

	def new(range: Range, this.text)
		this.kind = NodeKind.Comment
		this.range = range
	enddef

	def string(): string
		return printf('Comment %s @ %s', this.text, this.range->string())
	enddef
endclass

class BlankNode extends ConfigNode
	def new(range: Range)
		this.kind = NodeKind.Blank
		this.range = range
	enddef

	def string(): string
		return printf('Blank @ %s', this.range->string())
	enddef
endclass

class ConfigAst
	var nodes: list<ConfigNode>

	def new()
		this.nodes = []
	enddef

	def AddNode(node: ConfigNode)
		this.nodes->add(node)
	enddef

	def string(): string
		var parts: list<string> = []
		for node in this.nodes
			parts->add(node->string())
		endfor
		return join(parts, "\n")
	enddef
endclass

# --- internal helpers -----------------------------------------------------

def MakeRange(lnum: number, line: string): Range
	var start = Pos.new(lnum, 1)
	var colEnd = strlen(line)
	if colEnd <= 0
		colEnd = 1
	endif
	var end = Pos.new(lnum, colEnd)
	return Range.new(start, end)
enddef

def MakeCommentRange(lnum: number, line: string, ccol: number): Range
	if ccol <= 0
		return MakeRange(lnum, line)
	endif
	var start = Pos.new(lnum, ccol)
	var colEnd = strlen(line)
	if colEnd < ccol
		colEnd = ccol
	endif
	var end = Pos.new(lnum, colEnd)
	return Range.new(start, end)
enddef

def DecodeKey(raw: string): string
	return raw->trim()->tolower()
enddef

def DecodeValue(raw: string): string
	var s = raw->trim()
	if s ==# ''
		return s
	endif

	if s =~# '^".*"$'
		# strip surrounding quotes
		s = s[1 : strlen(s) - 2]
		# handle escapes similar to git-config
		s = substitute(s, '\\', "\x00", 'g')
		s = substitute(s, '\"', '"', 'g')
		s = substitute(s, '\n', "\n", 'g')
		s = substitute(s, "\x00", '\\', 'g')
	endif

	return s
enddef

# Classify a single line into: blank / full_comment / section / pair
# Also split out inline comment (outside double quotes) as trailing text.
# ccol is 1-based column of the comment start (including '#' or ';'), 0 if none.
def ClassifyLine(line: string): dict<any>
	var trimmed = line->trim()
	if trimmed ==# ''
		return { kind: 'blank', code: '', comment: '', ccol: 0 }
	endif

	# whole-line comment
	if line =~# '^\s*[#;]'
		return { kind: 'full_comment', code: '', comment: line, ccol: 1 }
	endif

	var in_string = false
	var escaped = false
	var i = 0
	var len = strlen(line)
	var comment_start = -1

	while i < len
		var ch = line[i]
		if escaped
			escaped = false
		elseif ch ==# '\\'
			escaped = true
		elseif ch ==# '"'
			in_string = !in_string
		elseif !in_string && (ch ==# '#' || ch ==# ';')
					&& (i == 0 || line[i - 1] =~# '\s')
			comment_start = i + 1  # 1-based col for comment
			break
		endif
		i += 1
	endwhile

	var code = line
	var comment = ''
	var ccol = 0
	if comment_start >= 1
		if comment_start == 1
			return { kind: 'full_comment', code: '', comment: line, ccol: 1 }
		endif
		code = line[0 : comment_start - 2]
		comment = line[comment_start - 1 :]
		ccol = comment_start
	endif

	var code_trim = code->trim()
	if code_trim ==# ''
		# nothing but comment
		return { kind: 'full_comment', code: '', comment: line, ccol: 1 }
	endif

	if code =~# '^\s*\['
		return { kind: 'section', code: code, comment: comment, ccol: ccol }
	endif

	return { kind: 'pair', code: code, comment: comment, ccol: ccol }
enddef

def ParseSectionHeader(line: string, lnum: number): SectionNode
	const pat = '^\s*\[\s*\([A-Za-z0-9_.-]\+\)\s*\("\(.*\)"\s*\)\?\]\s*$'
	var m = matchlist(line, pat)
	if len(m) == 0
		throw 'Invalid gitconfig section header at line ' .. lnum
	endif

	var name = m[1]
	var subsection = ''
	if len(m) >= 4
		subsection = m[3]
	endif

	name = name->tolower()
	subsection = subsection->trim()

	var range = MakeRange(lnum, line)
	return SectionNode.new(range, name, subsection)
enddef

def ParseKeyValue(line: string, lnum: number): PairNode
	const eqPat = '^\s*\(\S\+\)\s*=\s*\(.*\)$'

	var keyText = ''
	var valueText = ''

	if line =~# eqPat
		var m = matchlist(line, eqPat)
		keyText = m[1]
		valueText = m[2]
	else
		throw 'Invalid gitconfig key-value at line ' .. lnum
	endif

	var key = DecodeKey(keyText)
	var value = DecodeValue(valueText)

	var range = MakeRange(lnum, line)
	return PairNode.new(range, key, value)
enddef

# --- public API -----------------------------------------------------------

export def ParseLines(lines: list<string>): ConfigAst
	var ast = ConfigAst.new()
	var currentSection: SectionNode
	var hasSection = false
	var lnum = 0

	for line in lines
		lnum += 1
		var info = ClassifyLine(line)
		var kind = info.kind
		var code = info.code
		var comment = info.comment
		var ccol = info.ccol

		if kind ==# 'blank'
			var br = MakeRange(lnum, line)
			var bn = BlankNode.new(br)
			if hasSection
				currentSection.AddItem(bn)
			else
				ast.AddNode(bn)
			endif
			continue
		endif

		if kind ==# 'full_comment'
			var cr = MakeCommentRange(lnum, line, ccol)
			var cn = CommentNode.new(cr, comment)
			if hasSection
				currentSection.AddItem(cn)
			else
				ast.AddNode(cn)
			endif
			continue
		endif

		if kind ==# 'section'
			if hasSection
				ast.AddNode(currentSection)
			endif
			currentSection = ParseSectionHeader(code, lnum)
			hasSection = true

			if comment !=# ''
				var cr2 = MakeCommentRange(lnum, line, ccol)
				var cn2 = CommentNode.new(cr2, comment)
				currentSection.AddItem(cn2)
			endif
			continue
		endif

		# pair
		var pair = ParseKeyValue(code, lnum)
		if hasSection
			currentSection.AddItem(pair)
			if comment !=# ''
				var cr3 = MakeCommentRange(lnum, line, ccol)
				var cn3 = CommentNode.new(cr3, comment)
				currentSection.AddItem(cn3)
			endif
		else
			ast.AddNode(pair)
			if comment !=# ''
				var cr4 = MakeCommentRange(lnum, line, ccol)
				var cn4 = CommentNode.new(cr4, comment)
				ast.AddNode(cn4)
			endif
		endif
	endfor

	if hasSection
		ast.AddNode(currentSection)
	endif

	return ast
enddef

export def ParseBuffer(bufnr: number): ConfigAst
	const lines = getbufline(bufnr, 1, '$')
	return ParseLines(lines)
enddef
