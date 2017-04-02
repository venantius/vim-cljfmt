" cljfmt.vim - A tool for formatting Clojure code
" Maintainer:  Venantius <http://venanti.us>
" Version:     0.6

let g:clj_fmt_required = 0

function! s:RequireCljfmt()
    let l:cmd = "(require 'cljfmt.core)"
    try
        silent! call fireplace#session_eval(l:cmd)
        return 1
    catch /^Clojure: class java.io.FileNotFoundException*/
        echom "vim-cljfmt: Could not locate cljfmt/core__init.class or cljfmt/core.clj on classpath."
        return 0
    catch /^Fireplace:.*/
        echom v:exception
        return 0
    endtry
endfunction

function! s:GetCurrentBufferContents()
    " Escape newlines
    let l:temp = []
    for l:line in getline(1, '$')
        let l:line = substitute(l:line, '\', '\\\\', 'g')
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
        if line != "No matching autocommands" && line != "Keine passenden Autokommandos"
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
        throw "fmterr"
    catch
      redir END
      throw v:exception
    endtry
    redir END
    return s:FilterOutput(split(l:cljfmt_output, "\n"))
endfunction

function! cljfmt#Format()
    let g:clj_fmt_required = s:RequireCljfmt()

    " If cljfmt.core has already been required, or was successfully imported
    " above
    if g:clj_fmt_required
        " save cursor position and many other things
        let l:curw = winsaveview()

        try
            let formatted_output = s:GetFormattedFile()
            :0,substitute/\_.*/\=formatted_output/g
        catch "fmterr"
            echoerr "Cljfmt: Failed to format file, likely due to a syntax error."
        endtry

        " restore our cursor/windows positions
        call winrestview(l:curw)
    endif
endfunction

function! cljfmt#AutoFormat()
    silent! write
    if expand('%:t') != "project.clj" && expand('%:t') != "profiles.clj"
        silent! call cljfmt#Format()
    endif
endfunction

augroup vim-cljfmt
    autocmd!

    " code formatting on save
    if get(g:, "clj_fmt_autosave", 1)
        autocmd BufWritePre *.clj call cljfmt#AutoFormat()
        autocmd BufWritePre *.cljc call cljfmt#AutoFormat()
        autocmd BufWritePre *.cljs call cljfmt#AutoFormat()

    endif
augroup END

command! Cljfmt call cljfmt#Format()
command! CljfmtRequire call s:RequireCljfmt()
