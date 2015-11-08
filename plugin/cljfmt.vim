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
    catch
      redir END
      throw v:exception
    endtry
    redir END
    return s:FilterOutput(split(l:cljfmt_output, "\n"))
endfunction

function! s:DeclareCurrentNS()
    let ns = fireplace#ns()
    let cmd = "(ns " . ns . ")"
    call fireplace#session_eval(cmd)
endfunction

function! cljfmt#Format()
    if !g:clj_fmt_required
        let g:clj_fmt_required = s:RequireCljfmt()
    endif

    try
        call s:DeclareCurrentNS()
    catch /.*/
        return 0
    endtry

    " If cljfmt.core has already been required, or was successfully imported
    " above
    if g:clj_fmt_required
        " save cursor position and many other things
        let l:curw = winsaveview()

        let formatted_output = s:GetFormattedFile()
        :0,substitute/\_.*/\=formatted_output/g

        " restore our cursor/windows positions
        call winrestview(l:curw)
    end
endfunction

function! cljfmt#AutoFormat()
    if expand('%:t') != "project.clj"
        call cljfmt#Format()
    endif
    silent! write
endfunction

augroup vim-cljfmt
    autocmd!

    " code formatting on save
    if get(g:, "clj_fmt_autosave", 1)
        autocmd BufWritePost *.clj call cljfmt#AutoFormat()
    endif
augroup END

command! Cljfmt call cljfmt#Format()
command! CljfmtRequire call s:RequireCljfmt()
