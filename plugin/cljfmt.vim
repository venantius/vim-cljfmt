" cljfmt.vim - A tool for formatting Clojure code
" Maintainer:  Venantius <http://venanti.us>
" Version:     0.6

let g:clj_fmt_required = 0
let fireplace#skip = 'synIDattr(synID(line("."),col("."),1),"name") =~? "comment\\|string\\|char\\|regexp"'

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

function! s:FilterOutput(lines, ...)
    let l:output = []
    let l:join_result = 1

    if a:0 == 1 && !a:1
        let l:join_result = 0
    endif

    for line in a:lines
        if line != "No matching autocommands" && line != "Keine passenden Autokommandos"
            call add(l:output, line)
        endif
    endfor
    if l:join_result
        return join(l:output, "\n")
    else
        return l:output
    endif
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
    return s:FilterOutput(split(l:cljfmt_output, "\n"), 0)
endfunction

function! s:replaceBuffer(content) abort
  let content = type(a:content) == v:t_list ? a:content : split(a:content, "\n")

  if getline(1, '$') != content
    %del
    call setline(1, content)
  endif
endfunction

function! cljfmt#Format()
    let g:clj_fmt_required = s:RequireCljfmt()

    " If cljfmt.core has already been required, or was successfully imported
    " above
    if g:clj_fmt_required
        " save cursor position and many other things
        let l:curw = winsaveview()

        try
            call s:replaceBuffer(s:GetFormattedFile())
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

function! s:CljfmtRange(bang, line1, line2, count, args) abort
  if a:args !=# ''
    let expr = a:args
  else
    if a:count ==# 0
      let open = '[[{(]'
      let close = '[]})]'
      let [line1, col1] = searchpairpos(open, '', close, 'bcrn', g:fireplace#skip)
      let [line2, col2] = searchpairpos(open, '', close, 'rn', g:fireplace#skip)
      if !line1 && !line2
        let [line1, col1] = searchpairpos(open, '', close, 'brn', g:fireplace#skip)
        let [line2, col2] = searchpairpos(open, '', close, 'crn', g:fireplace#skip)
      endif
      while col1 > 1 && getline(line1)[col1-2] =~# '[#''`~@]'
        let col1 -= 1
      endwhile
    else
      let line1 = a:line1
      let line2 = a:line2
      let col1 = 1
      let col2 = strlen(getline(line2))
    endif
    if !line1 || !line2
      return ''
    endif
    let expr = getline(line1)[col1-1 : -1] . "\n"
            \ . join(map(getline(line1+1, line2-1), 'v:val . "\n"'))
            \ . getline(line2)[0 : col2-1]

  let g:clj_fmt_required = s:RequireCljfmt()
  if g:clj_fmt_required
      let escaped_contents = substitute(expr, '"', '\\"', 'g')
      let l:preformatted = s:GetReformatString(escaped_contents)

      redir => l:formatted_content
      silent! call fireplace#session_eval(l:preformatted)
      redir END

      let content = s:FilterOutput(split(l:formatted_content, "\n"), 0)
      exe line1.','.line2.'delete _'
      call append(a:line1 - 1, content)
      exe a:line1
  endif
  return ''
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
command! -buffer -bang -range=0 -nargs=? CljfmtRange :exe s:CljfmtRange(<bang>0, <line1>, <line2>, <count>, <q-args>)
