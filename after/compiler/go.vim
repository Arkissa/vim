vim9script

if filereadable("makefile") || filereadable("Makefile")
	:CompilerSet makeprg=make
else
	:CompilerSet makeprg=go\ build
endif
