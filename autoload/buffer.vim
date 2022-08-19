let s:save_cpo = &cpoptions
set cpoptions&vim

"*******************************************************
"* Function name: s:bf_get_buffers_list()
"* Function		: Get list of buffers
"*
"* Argument		: none
"*******************************************************
function! s:bf_get_buffers_list() abort
	return split(execute(":ls"), "\n")
endfunction

"*******************************************************
"* Function name: s:bf_get_mark_text()
"* Function		: Get text of mark
"*
"* Argument		: key : mark key
"*******************************************************
function! s:bf_get_mark_text(key) abort
	let l:temp = split(execute(":marks ".a:key), "\n")
	if len(l:temp) <= 1
		return ""
	endif
	let l:text = split(l:temp[1])
	
	" get text only (remove key, line, culum)
	call remove(l:text, 0, 2)

	return join(l:text)
endfunction

"*******************************************************
"* Function name: s:bf_select_cmd()
"* Function		: Get list of marks
"*
"* Argument		: none
"*******************************************************
function! s:bf_select_cmd(proc) range abort
	let l:pos = line(".")
	if l:pos > len(s:list)
		return
	endif

	silent! close
	let s:proc = a:proc

	if s:bf_mode == "BF_BUFFER"
		call s:bf_buffer_selected_handler(0, l:pos)
	elseif s:bf_mode == "BF_MARK"
		call s:bf_mark_selected_handler(0, l:pos)
	endif
endfunction

"*******************************************************
"* Function name: s:bf_open_window()
"* Function		: 
"*
"* Argument		: 
"*******************************************************
function! s:bf_open_window(list) abort

	" If the window is already open, jump to it
	let winnum = bufwinnr("-buffer-")
	if winnum != -1
		if winnr() != winnum
			" If not already in the window, jump to it
			exe winnum.'wincmd w'
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
	" Set the 'filetype' to 'mru'. This allows the user to apply custom
	" syntax highlighting or other changes to the MRU bufer.
	setlocal filetype=mru
	" Use fixed height and width for the MRU window
	setlocal winfixheight winfixwidth

	" Setup the cpoptions properly for the maps to work
	let old_cpoptions = &cpoptions
	set cpoptions&vim

	" Create mappings to select and edit a file from the MRU list
	nnoremap <buffer> <silent> <CR>
				\ :call <SID>bf_select_cmd('E')<CR>
	nnoremap <buffer> <silent> d
				\ :call <SID>bf_select_cmd('D')<CR>
	nnoremap <buffer> <silent> a
				\ :call <SID>bf_select_cmd('A')<CR>
	nnoremap <buffer> <silent> q :close<CR>

	" Restore the previous cpoptions settings
	let &cpoptions = old_cpoptions

	silent! 0put = a:list

	" Move the cursor to the beginning of the file
	normal! gg

	setlocal nomodifiable
endfunction

"*******************************************************
"* Function name: Bf_popup_menu_filter()
"* Function		: Filtering when filterling-menu is selected
"*
"* Argument		: winid : Window ID
"*				  key : input key code
"*******************************************************
function! Bf_popup_menu_filter(winid, key)

	" --------------------------------------
	"  Item shortcut key
	" --------------------------------------
	let l:index = stridx(s:item_shortcut_key, a:key)
	if l:index >= 0
		" *** When pressed shortcut key ***
		let s:proc = "E"
		call popup_close(a:winid, l:index + 1)
		return 1
	endif

	" --------------------------------------
	"  Operation shortcut key
	" --------------------------------------
	if stridx(s:proc_shortcut_key, a:key) >= 0
		if a:key == 'l'
			" *** When pressed 'l'(Enter) key ***
			let s:proc = "E"
			call win_execute(a:winid, 'let w:lnum = line(".")')
			call popup_close(a:winid, getwinvar(a:winid, 'lnum', 0))

		elseif a:key == 'd'
			" *** When pressed 'd'(delete) key ***
			let s:proc = "D"
			call win_execute(a:winid, 'let w:lnum = line(".")')
			call popup_close(a:winid, getwinvar(a:winid, 'lnum', 0))

		elseif a:key == 'a'
			" *** When pressed 'a'(add) key ***
			let s:proc = "A"
			call popup_close(a:winid, 0)

		elseif a:key == 'q'
			" *** When pressed 'q'(exit) key ***
			let s:proc = "Q"
			call popup_close(a:winid, 0)
		endif

		return 1
	endif

	" --------------------------------
	"  Other, pass to normal filter
	" --------------------------------
	let s:proc = "E"
	return popup_filter_menu(a:winid, a:key)

endfunction

"*******************************************************
"* Function name: s:bf_buffer_selected_handler()
"* Function		: Handler processing when selected of buffer menu
"*
"* Argument		: winid : Window ID
"*				  result: Number of selected item
"*******************************************************
function! s:bf_buffer_selected_handler(winid, result)

	if a:result < 0
		return
	endif

	let l:str = s:list[a:result - 1]
	let l:param = split(l:str)

	if s:proc == "E"
		" selected buffer
		let l:winnum = bufwinnr(l:param[0] + 0)
		if l:winnum != -1
			execute l:winnum.'wincmd w'
		else
			execute 'buffer '.l:param[0]
		endif
	elseif s:proc == "D"
		" delete buffer
		execute 'bdelete! '.l:param[0]
		call s:bf_buffer()
	endif
endfunction

"*******************************************************
"* Function name: bf_buffer()
"* Function		: 
"*
"* Argument		: none
"*******************************************************
function! s:bf_buffer() abort
	let s:bf_mode = "BF_BUFFER"

	" get buffer list
	let l:list = s:bf_get_buffers_list()
	call map(l:list, 'substitute(substitute(v:val, "\"", "", "g"), " 行 .*$", "", "")')
	if len(l:list) == 0
		echohl WarningMsg | echomsg "Buffer list is empty" | echohl None
		return
	endif

	let s:list = []
	for str in l:list
		let l:temp = split(str)
		if l:temp[2] != "+"
			call insert(l:temp, " ", 2)
		endif
		let l:name = strpart(l:temp[3], strridx(l:temp[3], "\\")+1, strlen(l:temp[3]))
		call add(s:list, printf("%4s %3s %s   %-16s  (%s)", l:temp[0], l:temp[1], l:temp[2], l:name, l:temp[3]))
	endfor

	let s:item_shortcut_key = ""
	let s:proc_shortcut_key = "ldq"
	if s:supported_popup
		let s:proc = "Q"
		call popup_menu(s:list, #{
					\ filter: 'Bf_popup_menu_filter',
					\ callback: 's:bf_buffer_selected_handler',
					\ border: [0,0,0,0],
					\ padding: [1,5,1,5]
					\ })
   else
	   call s:bf_open_window(s:list)
   endif
endfunction

"*******************************************************
"* Function name: get_unused_key()
"* Function		: Get unused mark key
"*
"* Argument		: none
"* Return value	: Unused mark key
"*******************************************************
function! s:get_unused_key() abort
	let l:markrement_char = [
	\	  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	\	  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
	\ ]

	let l:Unusedkey = 'A'
	for key in markrement_char
		if stridx(s:item_shortcut_key, key) == -1
			let l:Unusedkey = key
			break
		endif
	endfor

	return l:Unusedkey
endfunction

"*******************************************************
"* Function name: bf_mark_selected_handler()
"* Function		: Handler processing when selected of marks menu
"*
"* Argument		: winid : window ID
"*				  result: Number of selected item
"*******************************************************
function s:bf_mark_selected_handler(winid, result)

	if a:result == -1
		return
	endif

	if s:proc == "E"
		let markcmd = "'".strpart(s:item_shortcut_key, a:result - 1, 1)
		echo markcmd
		execute (markcmd)

	elseif s:proc == "D"
		let markcmd = ":delmarks ".strpart(s:item_shortcut_key, a:result - 1, 1)
		echo markcmd
		execute (markcmd)
		call s:bf_mark()

	elseif s:proc == "A"
		let markcmd = ":mark ".s:get_unused_key()
		echo markcmd
		execute (markcmd)
		call s:bf_mark()
	endif
endfunction

"*******************************************************
"* Function name: bf_mark()
"* Function		: Select a mark
"*
"* Argument		: menu : ID of display menu
"*******************************************************
function! s:bf_mark() abort
	let s:bf_mode = "BF_MARK"
	
	" make marks menu
	let s:list = []
	let s:item_shortcut_key = ""
	let s:proc_shortcut_key = "ladq"
	let l:all_marks = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

	let l:current_bnr = bufnr('%')
	for id in range(len(l:all_marks))
		let l:key = l:all_marks[id]
	    let [ l:bnr, l:lnum ] = getpos("'".l:key)[0:1]
		if l:lnum
			let s:item_shortcut_key .= l:all_marks[id]
			let l:asta = l:bnr == l:current_bnr ? "*" : " "
			let l:text = s:bf_get_mark_text(l:key)
	    	call add(s:list, printf(" %s %s  %6d    %s", l:asta, l:key, l:lnum, l:text))
		endif
	endfor

	if len(s:list) == 0
		echohl WarningMsg | echomsg "Marks list is empty" | echohl None
		return
	endif

	if s:supported_popup
		let s:proc = "Q"
		let s:proc_shortcut_key = "ladq"
		call popup_menu(s:list, #{
					\ filter: 'Bf_popup_menu_filter',
					\ callback: 's:bf_mark_selected_handler',
					\ border: [0,0,0,0],
					\ padding: [1,5,1,5]
					\ })
	else
		call s:bf_open_window(s:list)
	endif
endfunction

"*******************************************************
"* Function name: bf_close_proc()
"* Function		: Close proc.
"*
"* Argument		: none
"*******************************************************
function! s:bf_close_proc() abort
	" If close window is QuickFix, close the QuickFix window
	if &buftype == 'quickfix'
		cclose
	elseif &buftype != '' && len(getwininfo()) >= 2
		close
	else
		let list = split(execute(":ls"), "\n")
		call map(list, 'str2nr(matchstr(v:val, "^ *[0-9]* "))')
		let active_buf = filter(copy(list), 'v:val != bufnr("%") && bufwinnr(v:val) > 0')
		let hidden_buf = filter(copy(list), 'v:val != bufnr("%") && getbufvar(v:val, "&modifiable") && bufwinnr(v:val) < 0')
		if len(hidden_buf)
			execute 'buffer'.hidden_buf[0]
			execute 'bdelete! '.s:close_buffer_no
		elseif len(active_buf) >= 2
			close
			execute 'bdelete! '.s:close_buffer_no
		elseif len(bufname(bufnr("%"))) || getbufvar(bufnr("%"), "&mod")
			enew
			execute 'bdelete! '.s:close_buffer_no
		endif
	endif
endfunction

"*******************************************************
"* Function name: bf_close_selected_handler()
"* Function		: Handler processing when selected of marks menu
"*
"* Argument		: winid : window ID
"*				  result: Number of selected item
"*******************************************************
function! s:bf_close_selected_handler(id, result)

	if a:result == 1
		"Selected Save
		let s:filename = ''
		if bufname("%") == ""
			let s:filename = input('input filename ? ', getcwd().'\', 'file') 
			echo "\r"
			if s:filename == ''
				return
			endif
			if strpart(s:filename,strlen(s:filename)-1, 1) == '\'
				echohl WarningMsg | echomsg 'Error: Filename ' . s:filename. " is directory name" | echohl None
				return
			endif
		endif
		silent! execute 'write '.s:filename
		call s:bf_close_proc()

	elseif a:result == 2
		"Selected Cancel

	elseif a:result == 3
		"Selected Discard
		call s:bf_close_proc()
	endif
endfunction

"*******************************************************
"* Function name: bf_close()
"* Function		: Buffer close process
"*
"* Argument		: none
"*******************************************************
function! s:bf_close() abort
	let s:bf_mode = "BF_CLOSE"

	" Get current buffer number
	let s:close_buffer_no = bufnr('%')

	" Check buffer modified
	let s:item_shortcut_key = "wcd"
	let s:proc_shortcut_key = "l"
	if getbufinfo(s:close_buffer_no)[0].changed
		if s:supported_popup
			" If changed, select the termination process
			call popup_menu(['w : Write', 'c : Cancel', 'd : Discard'], #{
						\ filter: 'Bf_popup_menu_filter',
						\ callback: 's:bf_close_selected_handler',
						\ border: [0,0,0,0],
						\ padding: [1,5,1,5]
						\ })
		else
"			echohl WarningMsg | echomsg 'No changes saved.'| echohl None
"			let l:key = input("Please select operation of terminate. [s:Save, c:Cancel, d:Discard ] ? ")
			echohl WarningMsg | echomsg 'No changes saved. Please select operation. [w:Write, c:Cancel, d:Discard ] ? '| echohl None
"			echo "Please select operation of terminate. [s:Save, c:Cancel, d:Discard ] ? "
			let l:key = nr2char(getchar())
			if !empty(l:key)
				call s:bf_close_selected_handler(0, stridx(s:item_shortcut_key, l:key)+1)
			endif
		endif
	else
		"If no changed, close the file
		call s:bf_close_proc()
	endif
endfunction

"---------------------------------------------------
" buffer#start()
"---------------------------------------------------
function! buffer#start(mode) abort
	let s:supported_popup = v:version >= 802 ? 0 : 0

	if a:mode == "b"
		call s:bf_buffer()
	elseif a:mode == "m"
		call s:bf_mark()
	elseif a:mode == "c"
		call s:bf_close()
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
