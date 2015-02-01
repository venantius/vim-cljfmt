" cljfmt.vim - A tool for formatting Clojure code
" Maintainer:  Venantius <http://venanti.us>
" Version:     0.1

function RequireCljfmt()
    let cmd = "(require 'cljfmt.core)"
    try
        call fireplace#session_eval(cmd)
        return 1
    catch /^Clojure:.*/
        return 0
    endtry
endfunction

function s:GetReformatString()
    let filename = expand('%:p')
    return '(print (cljfmt.core/reformat-string (slurp "' . filename . '") nil))'
endfunction

function s:GetFormattedFile()
    try
        redir => cljfmt_output
        silent! call fireplace#session_eval(s:GetReformatString())
        " call fireplace#session_eval("(print 5)")
        redir END
        return split(cljfmt_output, "\n")[1:]
    catch /^Clojure:.*/
        return ''
    endtry
endfunction

function! cljfmt#Format()
    " save cursor position and many other things
    let l:curw=winsaveview()

    let formatted_output = s:GetFormattedFile()
    :0,substitute/\_.*/\=formatted_output/g

    " restore our cursor/windows positions
    call winrestview(l:curw)
endfunction

augroup vim-cljfmt
    autocmd!

    " code formatting on save
    if get(g:, "clj_fmt_autosave", 1)
        autocmd BufWritePre *.clj call cljfmt#Format()
    endif

augroup END
