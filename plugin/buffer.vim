let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=1 BF call buffer#start(<f-args>)
command! -nargs=0 BN call buffer#bnext_bprev('bnext')
command! -nargs=0 BP call buffer#bnext_bprev('bprev')
command! -nargs=0 ZC call buffer#display_in_center()
command! -nargs=0 OpenPreview call buffer#open_preview()
command! -nargs=0 -range Replace call buffer#replace(<range>)


augroup buffer_events
	autocmd!
	autocmd BufWinLeave * if &buftype == 'quickfix' | call buffer#close_preview() | endif
augroup END


let &cpoptions = s:save_cpo
unlet s:save_cpo
