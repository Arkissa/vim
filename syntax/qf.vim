if exists('b:current_syntax')
	finish
endif

syn keyword qfError E contained
syn keyword qfWarn W contained
syn keyword qfInfo I contained
syn keyword qfNote N contained

syn match qfFileName "^\(\(E\|W\|I\|H\)\s\)\{0,1}[^│]*" nextgroup=qfSeparator1 contains=qfError,qfWarn,qfInfo,qfNote
syn match qfSeparator1 "│" contained nextgroup=qfLineNr
syn match qfLineNr "[^│]*" contained nextgroup=qfSeparator2
syn match qfSeparator2 "│" contained nextgroup=qfText
syn match qfText ".*" contained

" Hide file name and line number for help outline (TOC).
if has_key(w:, 'qf_toc') || get(w:, 'quickfix_title') =~# '\<TOC$'
	setlocal conceallevel=3 concealcursor=nc
	syn match Ignore "^[^│]*│[^│]*│ " conceal
endif

hi def link qfFileName Directory
hi def link qfLineNr LineNr
hi def qfSeparator1 guifg=#B4BEFE
hi def qfSeparator2 guifg=#B4BEFE
hi def link qfText Normal

hi def link qfError LspDiagSignErrorText
hi def link qfWarn LspDiagSignWarningText
hi def link qfInfo LspDiagSignInfoText
hi def link qfNote LspDiagSignHintText

let b:current_syntax = 'qf'
