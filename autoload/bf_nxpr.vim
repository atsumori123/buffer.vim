let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" bf_nxpr#next_prev
"---------------------------------------------------------------
function! bf_nxpr#next_prev(direction) abort
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

let &cpoptions = s:save_cpo
unlet s:save_cpo
