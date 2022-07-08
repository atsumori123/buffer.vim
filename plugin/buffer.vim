let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=1 BF call buffer#start(<f-args>)

let &cpoptions = s:save_cpo
unlet s:save_cpo
