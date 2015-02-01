" cljfmt.vim - A tool for formatting Clojure code
" Maintainer:  Venantius <http://venanti.us>
" Version:     0.1

let g:clj_fmt_required = 0

function s:RequireCljfmt()
    let cmd = "(require 'cljfmt.core)"
    try
        call fireplace#session_eval(cmd)
        let g:clj_fmt_required = 1
        return 1
    catch /^Clojure:.*/
        return 0
    endtry
endfunction

function s:GetReformatString()
    let filename = expand('%:p')
    return '(print (cljfmt.core/reformat-string (slurp "' . filename . '") nil))'
endfunction

function s:FilterOutput(lines)
    let output = []
    for line in a:lines
        if line != "No matching autocommands"
            call add(output, line)
        endif
    endfor
    return output
endfunction

function s:GetFormattedFile()
    try
        redir => cljfmt_output
        silent! call fireplace#session_eval(s:GetReformatString())
        redir END
        return s:FilterOutput(split(cljfmt_output, "\n"))
    catch /^Clojure:.*/
        return ''
    endtry
endfunction

function! cljfmt#Format()
    if !g:clj_fmt_required
        call s:RequireCljfmt()
    endif

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
        autocmd BufWritePost *.clj call cljfmt#Format()
    endif

augroup END
