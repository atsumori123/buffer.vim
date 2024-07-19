let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" get_mark_text()
"-------------------------------------------------------
function! s:get_mark_text(key) abort
	let temp = split(execute(":marks ".a:key), "\n")
	if len(temp) <= 1
		return ""
	endif
	let text = split(temp[1])

	" get text only (remove key, line, culum)
	call remove(text, 0, 2)

	return join(text)
endfunction

"-------------------------------------------------------
" get_unused_key()
"-------------------------------------------------------
function! s:get_unused_key() abort
	let markrement_char = [
	\	  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	\	  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
	\ ]

	let unused_key = 'A'
	for key in markrement_char
		if stridx(s:used_keys, key) == -1
			let unused_key = key
			break
		endif
	endfor

	return unused_key
endfunction

"-------------------------------------------------------
" action_selected_buffer()
"-------------------------------------------------------
function! s:action_selected_buffer(pos) abort
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
" action_delete_buffer()
"-------------------------------------------------------
function! s:action_delete_buffer(pos) abort
	let bnr = split(getline(a:pos))
	setlocal modifiable
	normal! dd
	normal! 0
	setlocal nomodifiable
	execute 'bdelete! '.bnr[0]
endfunction

"-------------------------------------------------------
" action_selected_mark()
"-------------------------------------------------------
function! s:action_selected_mark(pos) abort
	let key = split(getline(a:pos))
	silent! close
	execute "'".key[0]
endfunction

"-------------------------------------------------------
" action_delete_mark()
"-------------------------------------------------------
function! s:action_delete_mark(pos) abort
	let key = split(getline(a:pos))
	setlocal modifiable
	normal! dd
	normal! 0
	setlocal nomodifiable
	execute ":delmarks ".key[0]
	let s:used_keys = substitute(s:used_keys, key[0], "", "gc")
endfunction

"-------------------------------------------------------
" action_add_mark()
"-------------------------------------------------------
function! s:action_add_mark() abort
	silent! close
	execute ":mark ".s:get_unused_key()
	call s:open_mark_list()
endfunction

"-------------------------------------------------------
" action_nop()
"-------------------------------------------------------
function! s:action_nop() abort

endfunction

"-------------------------------------------------------
" action_xxxxx_handler()
"-------------------------------------------------------
function! s:action_selected_handler() abort
	call s:action_selected(line('.'))
endfunction

function! s:action_delete_handler() abort
	call s:action_delete(line('.'))
endfunction

function! s:action_add_handler() abort
	call s:action_add()
endfunction

"-------------------------------------------------------
" open_buffer()
"-------------------------------------------------------
function! s:open_buffer(list) abort
	" If the window is already open, jump to it
	let winnum = bufwinnr("-buffer-")
	if winnum != -1
		if winnr() != winnum
			" If not already in the window, jump to it
			exe winnum.'wincmd w'
			return
		endif
	else
		" Open a new window at the bottom
		exe 'silent! botright 8 split -buffer-'
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

	" Create mappings to select and edit a file from the MRU list
	nnoremap <buffer> <silent> <CR> :call <SID>action_selected_handler()<CR>
	nnoremap <buffer> <silent> d :call <SID>action_delete_handler()<CR>
	nnoremap <buffer> <silent> a :call <SID>action_add_handler()<CR>
	nnoremap <buffer> <silent> q :close<CR>

	" Restore the previous cpoptions settings
	let &cpoptions = old_cpoptions

	silent! 0put = a:list
	silent! $delete _
	normal! gg
	normal! 0

	syn match bufferKey '^  .[A-Z|[0-9] '
	syn match bufferText '\*.*$'
	hi! def link bufferKey Function
	hi! def link bufferText Directory

	setlocal nomodifiable
endfunction

"-------------------------------------------------------
" open_buffer_list()
"-------------------------------------------------------
function! s:open_buffer_list() abort
	" get buffer list
	let wk_list = split(execute(":ls"), "\n")
	call map(wk_list, 'substitute(substitute(v:val, "\"", "", "g"), " 行 .*$", "", "")')
	if len(wk_list) == 0
		echohl WarningMsg | echomsg "Buffer list is empty" | echohl None
		return
	endif

	let list = []
	for s in wk_list
		let temp = split(s)
		if temp[2] != "+"
			call insert(temp, " ", 2)
		endif
		call add(list, printf("%4s %s %3s %s   %-16s  (%s)",
	  		\ temp[0],
	  		\ s:current_bufno == temp[0] ? "*" : " ",
			\ temp[1],
	  		\ temp[2],
	  		\ strpart(temp[3], strridx(temp[3], "\\")+1, strlen(temp[3])),
	  		\ temp[3]))
	endfor

	call s:open_buffer(list)
endfunction

"-------------------------------------------------------
" open_mark_list()
"-------------------------------------------------------
function! s:open_mark_list() abort
	" make marks menu
	let list = []
	let s:used_keys = ""
	let all_marks = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

	let cbnr = bufnr('%')
	for i in range(len(all_marks))
		let key = all_marks[i]
	    let [ bnr, line ] = getpos("'".key)[0:1]
		if line
			let temp = printf("   %s %s %6d    %s",
				\ key,
				\ bnr == cbnr ? "*" : " ",
				\ line,
				\ s:get_mark_text(key))
			call add(list, temp)
			let s:used_keys .= key
		endif
	endfor

	call s:open_buffer(list)
endfunction

"---------------------------------------------------
" buffer_close()
"---------------------------------------------------
function! s:buffer_close() abort
	" Check buffer modified
	if getbufinfo(s:current_bufno)[0].changed
		echohl WarningMsg
		echomsg 'No changes saved. Please select operation. [w:Write, c:Cancel, d:Discard ] ? '
		echohl None
		let key = nr2char(getchar())
		if key == 'w'
			let filename = ''
			if bufname("%") == ""
				let filename = input('input filename ? ', getcwd().'\', 'file')
				if empty(filename) | return | endif
			endif
			silent! execute 'write '.filename
		elseif key == 'd'

		else
			return
		endif
	endif

	" list up buffers exclude special buffer
	let bufs = filter(range(1, bufnr('$')), '
			\ buflisted(v:val)
			\ && getbufvar(v:val, "&buftype") == ""
			\ && v:val != s:current_bufno
			\ ')

	" close buffer
	if &buftype == 'quickfix'
		" current window is QuickFix
		execute printf("%s", len(bufs) ? "cclose" : "bdelete")
	elseif &buftype != ''
		" current window is special buffer
		bdelete
	else
		" list up hidden buffers
		let hidden_bufs = filter(copy(bufs),'len(getbufinfo(v:val)[0].windows) == 0')

		if len(hidden_bufs)
			execute 'buffer'.hidden_bufs[0]
		endif
		if buflisted(s:current_bufno)
			execute 'bdelete! '.s:current_bufno
		endif
	endif
endfunction

"---------------------------------------------------
" buffer#start()
"---------------------------------------------------
function! buffer#start(mode) abort
	let s:current_bufno = bufnr('%')
	if a:mode == "b"
		let s:action_selected = function('s:action_selected_buffer')
		let s:action_delete = function('s:action_delete_buffer')
		let s:action_add = function('s:action_nop')
		call s:open_buffer_list()

	elseif a:mode == "m"
		let s:action_selected = function('s:action_selected_mark')
		let s:action_delete = function('s:action_delete_mark')
		let s:action_add = function('s:action_add_mark')
		call s:open_mark_list()

	elseif a:mode == "c"
		let s:action_selected = function('s:action_nop')
		let s:action_delete = function('s:action_nop')
		let s:action_add = function('s:action_nop')
		call s:buffer_close()
	endif
endfunction

"---------------------------------------------------------------
" buffer#bnext_bprev
"---------------------------------------------------------------
function! buffer#bnext_bprev(direction) abort
	if &buftype == 'quickfix'
		let qfnum = getqflist({'nr':'$'}).nr
		let qfid = getqflist({'nr':0}).nr
		if a:direction == 'bnext'
			if qfid >= qfnum
				echohl WarningMsg | echomsg 'qflist: top of stack' | echohl None
				return
			endif
			silent cnewer
		else
			if qfid <= 1
				echohl WarningMsg | echomsg 'qflist: bottom of stack' | echohl None
				return
			endif
			silent colder
		endif
		echo "\r"
		setlocal modifiable
	else
		if !empty(&buftype) | return | endif
		execute a:direction
		if &buftype == 'quickfix'
			execute a:direction
		endif
	endif
endfunction

"---------------------------------------------------------------
" buffer#display_in_center
"---------------------------------------------------------------
function! buffer#display_in_center() abort
	let pos = getcurpos()
	let x = pos[4]
	let cx = &columns / 2 - 4

	if x <= cx
		return
	else
		let zl = x - cx
		execute "normal! 0"
		execute "normal! ".zl."zl"
		call setpos(".", pos)
		execute "normal! zz"
	endif
endfunction

"---------------------------------------------------------------
" buffer#replace
"---------------------------------------------------------------
function! buffer#replace(range) abort
	if a:range
		let temp = @@
		silent normal gvy
		let target_pattern = @@
		let @@ = temp
	else
		let target_pattern = expand('<cword>')
	endif

	let esc_chars = '^$.*[]/~\'
	let target_pattern = escape(target_pattern, esc_chars)
	let replace_pattern = input(printf('"%s" --> ', target_pattern))
	if empty(replace_pattern) | return | endif
	let replace_pattern = escape(replace_pattern, esc_chars)
	let start = input("Input replace start line (default:1) ? ")
	if empty(start) | let start = 1 | endif

	if a:range
		exe start.",$s/".target_pattern."/".replace_pattern."/gc"
	else
		exe start.",$s/\\<".target_pattern."\\>/".replace_pattern."/gc"
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
