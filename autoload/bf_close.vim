let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------
" bf_close#close
"---------------------------------------------------
function! bf_close#close() abort
	let bnr = bufnr('%')

	" Check buffer modified
	if getbufinfo(bnr)[0].changed
		echohl WarningMsg | echomsg 'No changes saved. Please select operation. [w:Write, c:Cancel, d:Discard ] ? ' | echohl None
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
			\ && v:val != bnr
			\ ')

	if &buftype == 'quickfix'
		" current window is QuickFix
		cclose

	elseif &buftype != ''
		" current window is special buffer
		bdelete

	else
		" list up hidden buffers
		let hidden_bufs = filter(copy(bufs),'len(getbufinfo(v:val)[0].windows) == 0')

		if len(hidden_bufs)
			execute 'buffer'.hidden_bufs[0]
		endif

		if !len(bufs)
			cclose
		endif

		execute 'bdelete! '.bnr
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
