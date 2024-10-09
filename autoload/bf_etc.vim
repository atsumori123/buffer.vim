let s:save_cpo = &cpoptions
set cpoptions&vim

"---------------------------------------------------------------
" etc#display_in_center
"---------------------------------------------------------------
function! bf_etc#display_in_center() abort
	let dic = getwininfo(win_getid())
	let pos = getcurpos()
	let x = pos[4]
	let center_x = dic[0].width / 2 - 4

	if x <= center_x
		return
	else
		let zl = x - center_x
		execute "normal! 0"
		execute "normal! ".zl."zl"
		call setpos(".", pos)
		execute "normal! zz"
	endif
endfunction

"---------------------------------------------------------------
" etc#replace
"---------------------------------------------------------------
function! bf_etc#replace(range) abort
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
