vim9script noclear

if exists('b:did_ftplugin')
	finish
endif

b:did_ftplugin = 1
b:undo_ftplugin = 'setlocal list< wrap< bufhidden< buflisted< relativenumber<'

&l:list = false
&l:wrap = false
&l:bufhidden = 'wipe'
&l:buflisted = false
&l:relativenumber = false
