let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" selected_buffer
"-------------------------------------------------------
function! s:selected_buffer(pos) abort
	let bnr = split(getline(a:pos))
	silent! close
	let winnum = bufwinnr(bnr[0] + 0)
	if winnum != -1
		execute winnum.'wincmd w'
	else
		execute 'buffer '.bnr[0]
	endif
endfunction

"-------------------------------------------------------
" delete_buffer
"-------------------------------------------------------
function! s:delete_buffer(pos) abort
	if line('$') <= 1
		echohl WarningMsg | echomsg "Cannot delete because number of buffers is 1" | echohl None
		return
	endif

	let bnr1 = split(getline(a:pos))[0]
	let bnr2 = split(getline(a:pos == 1 ? a:pos + 1 : a:pos - 1))[0]

	setlocal modifiable
	normal! dd
	normal! 0
	setlocal nomodifiable

	if !getbufinfo(str2nr(bnr1, 10))[0].hidden
		wincmd p
		execute "b".bnr2
		wincmd p
	endif
	execute 'bdelete! '.bnr1
endfunction

"-------------------------------------------------------
" set_keymap
"-------------------------------------------------------
function! s:set_keymap() abort
	nnoremap <buffer> <silent> <CR> :call <SID>selected_buffer(line('.'))<CR>
	nnoremap <buffer> <silent> d :call <SID>delete_buffer(line('.'))<CR>
	nnoremap <buffer> <silent> q :close<CR>
endfunction

"-------------------------------------------------------
" open_window
"-------------------------------------------------------
function! s:open_window(list) abort
	" If the window is already open, jump to it
	let winnum = bufwinnr("-buffer_list-")
	if winnum != -1
		if winnr() != winnum
			" If not already in the window, jump to it
			exe winnum.'wincmd w'
			return
		endif
	else
		" Open a new window at the bottom
		exe 'silent! botright 8 split -buffer_list-'
	endif

	setlocal modifiable
	silent! %delete _

	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal nobuflisted
	setlocal nowrap
	setlocal nonumber
	setlocal foldcolumn=0
	setlocal filetype=buffer
	setlocal winfixheight winfixwidth

	" Setup the cpoptions properly for the maps to work
	let old_cpoptions = &cpoptions
	set cpoptions&vim

	" Restore the previous cpoptions settings
	let &cpoptions = old_cpoptions

	silent! 0put = a:list
	silent! $delete _
	normal! gg
	normal! 0

	syn match bufferKey '^  .[A-Z|[0-9] '
	syn match bufferText '\*.*$'
	hi! def link bufferKey Function
	hi! def link bufferText Label

	setlocal nomodifiable
endfunction

"-------------------------------------------------------
" bf_buffers#buffers
"-------------------------------------------------------
function! bf_buffers#buffers() abort
	" get buffer list
	let ls = split(execute(":ls"), "\n")
	call map(ls, 'substitute(v:val, "\"", "", "g")')
	call map(ls, 'substitute(v:val," 行 .*$", "", "")')

	" make menu list
	let list = []
	for s in ls
		let temp = split(s)
		if len(temp) != 4 | call insert(temp, "", 2) | endif
		call add(list, printf("%4s %s %3s %s   %-16s  (%s)",
							\ temp[0],
							\ stridx(temp[1], 'a') >= 0 ? '*' : ' ',
							\ temp[1],
							\ temp[2],
							\ fnamemodify(temp[3], ":t"), temp[3]))
	endfor
	call s:open_window(list)
	call s:set_keymap()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
