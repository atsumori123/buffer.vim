let s:save_cpo = &cpoptions
set cpoptions&vim

execute 'noremap <silent> <Plug>BFTools.Buffers :<C-U>call bf_buffers#buffers()'
execute 'noremap <silent> <Plug>BFTools.Marks :<C-U>call bf_marks#marks()'
execute 'noremap <silent> <Plug>BFTools.Next :<C-U>call bf_nxpr#next_prev("bnext")'
execute 'noremap <silent> <Plug>BFTools.Prev :<C-U>call bf_nxpr#next_prev("bprev")'
execute 'noremap <silent> <Plug>BFTools.Close :<C-U>call bf_close#close()'
execute 'noremap <silent> <Plug>BFTools.Preview :<C-U>call bf_preview#open()'
execute 'noremap <silent> <Plug>BFTools.HrCenter :<C-U>call bf_etc#display_in_center()'
command! -nargs=0 -range Replace call bf_etc#replace(<range>)

augroup buffer_events
	autocmd!
	autocmd BufWinLeave * if &buftype == 'quickfix' | call bf_preview#close() | endif
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
