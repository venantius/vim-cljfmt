" cljfmt.vim - A tool for formatting Clojure code
" Maintainer:  Venantius <http://venanti.us>
" Version:     0.3

let g:clj_fmt_required = 0

function! s:RequireCljfmt()
    let l:cmd = "(require 'cljfmt.core)"
    try
        call fireplace#session_eval(l:cmd)
        let g:clj_fmt_required = 1
        return 1
    catch /^Clojure:.*/
        return 0
    endtry
endfunction

function! s:GetCurrentBufferContents()
    " Escape newlines
    let l:temp = []
    for l:line in getline(1, '$')
        let l:line = substitute(l:line, '\\n', '\\\\n', 'g')
        call add(l:temp, l:line)
    endfor
    let l:escaped_buffer_contents = join(l:temp, '\n')

    " Take care of escaping quotes
    let l:escaped_buffer_contents = substitute(l:escaped_buffer_contents, '"', '\\"', 'g')
    return escaped_buffer_contents
endfunction

function! s:GetReformatString(CurrentBufferContents)
    return '(print (cljfmt.core/reformat-string "' . a:CurrentBufferContents . '" nil))'
endfunction

function! s:FilterOutput(lines)
    let l:output = []
    for line in a:lines
        if line != "No matching autocommands"
            call add(l:output, line)
        endif
    endfor
    return join(l:output, "\n")
endfunction

function! s:GetFormattedFile()
    let l:bufcontents = s:GetCurrentBufferContents()
    redir => l:cljfmt_output
    try
        silent! call fireplace#session_eval(s:GetReformatString(l:bufcontents))
    catch /^Clojure:.*/
        redir END
        return s:GetReformatString()
    endtry
    redir END
    return s:FilterOutput(split(l:cljfmt_output, "\n"))
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
        autocmd BufWritePre *.clj call cljfmt#Format()
    endif

augroup END

command! Cljfmt call cljfmt#Format()
