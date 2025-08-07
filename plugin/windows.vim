vim9script

var clip = "/mnt/c/Windows/System32/clip.exe"
if executable(clip)
    augroup WSLYank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | system(clip, @0) | endif
    augroup END
endif
