vim9script

&l:makeprg = filereadable("makefile") || filereadable("Makefile")
	? 'make'
	: 'go build'
