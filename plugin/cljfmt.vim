" cljfmt.vim - A tool for formatting Clojure code
" Maintainer:  Venantius <http://venanti.us>
" Version:     0.2

let g:clj_fmt_required = 0

function s:RequireCljfmt()
    let l:cmd = "(require 'cljfmt.core)"
    try
        call fireplace#session_eval(l:cmd)
        let g:clj_fmt_required = 1
        return 1
    catch /^Clojure:.*/
        return 0
    endtry
endfunction

function s:CurrentBufferContents()
    let l:current_buffer_contents = join(getline(1,'$'), '\n')
    let l:escaped_buffer_contents = substitute(l:current_buffer_contents, '"', '\\"', 'g')
    return escaped_buffer_contents
endfunction

function s:GetReformatString()
    let l:bufcontents = s:CurrentBufferContents()
    return '(print (cljfmt.core/reformat-string "' . l:bufcontents . '" nil))'
endfunction

function s:FilterOutput(lines)
    let l:output = []
    for line in a:lines
        if line != "No matching autocommands"
            call add(l:output, line)
        endif
    endfor
    return l:output
endfunction

function s:GetFormattedFile()
    try
        redir => l:cljfmt_output
        silent! call fireplace#session_eval(s:GetReformatString())
        redir END
        return s:FilterOutput(split(l:cljfmt_output, "\n"))
    catch /^Clojure:.*/
        return ''
    endtry
endfunction

function! cljfmt#Format()
    try
        if !g:clj_fmt_required
            call s:RequireCljfmt()
        endif

        " save cursor position and many other things
        let l:curw = winsaveview()

        let formatted_output = s:GetFormattedFile()
        :0,substitute/\_.*/\=formatted_output/g

        " restore our cursor/windows positions
        call winrestview(l:curw)
    catch
        return ''
    endtry
endfunction

augroup vim-cljfmt
    autocmd!

    " code formatting on save
    if get(g:, "clj_fmt_autosave", 1)
        autocmd BufWritePost *.clj call cljfmt#Format()
    endif

augroup END

command! Cljfmt call cljfmt#Format()
