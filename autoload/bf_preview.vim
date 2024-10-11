let s:save_cpo = &cpoptions
set cpoptions&vim

let s:org_bufnr = []
let s:save_line = ""

"-------------------------------------------------------
" Get bufnr
"-------------------------------------------------------
function! s:get_bufnr() abort
	let list = split(execute(":ls"), "\n")
	let bnr_list = []
	for bnr in list
		call add(bnr_list, split(bnr, ' ')[0])
	endfor
	return bnr_list
endfunction

"-------------------------------------------------------
" Open the preview buffer
"-------------------------------------------------------
function! s:open_preview(path, lnum) abort
	if exists('g:lock_file_history') | let g:lock_file_history = 1 | endif
	execute "pedit +".a:lnum.' '.a:path
	if exists('g:lock_file_history') | let g:lock_file_history = 0 | endif
endfunction

"---------------------------------------------------------------
" Open preview
"---------------------------------------------------------------
function! bf_preview#open() abort
	if &buftype != 'quickfix'
		return
	endif

	let line = getline('.')
	if line == s:save_line
		call bf_preview#close()
		return
	endif
	let s:save_line = line

	let w = split(line, '|')
"	silent! wincmd P
	if &previewwindow
		" already exists prview window
		let bnr = bufnr('%')
		call s:open_preview(w[0], split(w[1], ' ')[0])
		if bnr != bufnr('%') && match(s:org_bufnr, bnr) < 0
			silent! execute 'bdelete! '.bnr
		endif
		silent! wincmd p
	else
		" open preview window
		let s:org_bufnr = s:get_bufnr()
		call s:open_preview(w[0], split(w[1], ' ')[0])
	endif
endfunction

"---------------------------------------------------------------
" Close preview
"---------------------------------------------------------------
function! bf_preview#close() abort
	silent! wincmd P
	if &previewwindow
		let bnr = bufnr('%')
		wincmd p
		silent! pclose
		if match(s:org_bufnr, bnr) < 0
			silent! execute 'bdelete! '.bnr
		endif
		let s:org_bufnr = []
		let s:save_line = ""
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
