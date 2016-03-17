nnoremap <Plug>(git-appraise-accept) :<C-u>call gitappraise#accept()
nnoremap <Plug>(git-appraise-comment) :<C-u>call gitappraise#comment()
nnoremap <Plug>(git-appraise-enable) :<C-u>call gitappraise#enable()

command! -nargs=0 GitAppraise call gitappraise#enable()
command! -nargs=0 GitAppraiseAddComment call gitappraise#add_comment()

highlight default GitAppraise term=underline ctermbg=DarkGreen guibg=DarkGreen
