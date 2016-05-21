" ============================================================================
" File:        bufnav.vim
" Description: Buffer navigation. Skips qf buffers. Protects some plugin 
"              windows from beeing left with :bnext, :bprev
" Maintainer:  Alex Drozdov <alex.drozdov at gmail dot com>
" Last Change: 22 May, 2016
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
"
" ============================================================================
"
" SECTION: Script init stuff {{{1
"============================================================
if exists("loaded_bufnav")
    finish
endif
if v:version < 700
    echoerr "BufNav: this plugin requires vim >= 7. DOWNLOAD IT! You'll thank me later!"
    finish
endif
let loaded_bufnav = 1


" SECTION: Implementation {{{1
"============================================================

"Function: s:BufNavAllowedBuffer() function {{{2
"This function checks if buffer supports navigation and
"can be left for some other buffer. This preserves from
"changing buffer in such plugin windows as: NERDTree, 
"QuickFix, TagBar, etc...
"
"Args:
"bufn: buffer number to test
"
"Returns:
"1 for ordinary buffer, 0 for known plugin buffers
function! s:BufNavAllowedBuffer(bufn)
    let skip_types = ['nerdtree', 'tagbar', 'qf']
    return index(skip_types, getbufvar(a:bufn, "&filetype")) < 0
endfunction

"Function: s:BufNavSelectableBuffer() function {{{2
"This function checks if buffer supports navigation and
"can be selected as current. This preserves from
"selecting unlisted buffers and known plugin buffers 
"
"Args:
"bufn: buffer number to test
"
"Returns:
"1 for ordinary buffer, 0 for unlisted and known plugin buffers
function! s:BufNavSelectableBuffer(bufn, in_help)
    let skip_types = ['nerdtree', 'tagbar', 'qf']
    let file_type = getbufvar(a:bufn, "&filetype") 
    if a:bufn != 0 &&
\            bufexists(a:bufn) &&
\            bufloaded(a:bufn) &&
\            buflisted(a:bufn) &&
\            ((file_type == 'help') == a:in_help) &&
\            (index(skip_types, file_type) < 0)
        return 1
    endif
    return 0
endfunction

"Function: s:BufNavInfLoop() function {{{2
"This function tests buffer iteration for infinite loop occured
"
"Args:
"start: iteration start buffer number
"new: next expected buffer number
"loop_overflow: flag for iteration overflow or underflow
"incr: iteration direction
"
"Returns:
"1 as iteration stop condition, 0 otherwise
function! s:BufNavInfLoop(start, new, loop_overflow, incr)
    if ! a:loop_overflow
        return 0
    endif
    if ((a:start <= a:new) && (0 < a:incr)) || ((a:new <= a:start) && (a:incr < 0))
        return 1
    endif
    return 0
endfunction

"Function: g:BufNavNext() function {{{2
"This function selects next suitable buffer
"
"Args:
"incr: direction
function! g:BufNavNext(incr)
    let current = bufnr("%")
    if ! s:BufNavAllowedBuffer(current)
        return
    endif

    let last = bufnr("$")
    let new = current + a:incr
    let in_help = (&filetype == 'help')
    let loop_overflow = 0
    while ! s:BufNavInfLoop(current, new, loop_overflow, a:incr)
        if s:BufNavSelectableBuffer(new, in_help)
            execute ":buffer ".new
            break
        else
            let new = new + a:incr
            if new < 1
                let new = last
                let loop_overflow = 1
            elseif new > last
                let new = 1
                let loop_overflow = 1
            endif
        endif
    endwhile
endfunction

"Function: g:BufNavFirst() function {{{2
"This function selects first suitable buffer
function! g:BufNavFirst()
    let current = bufnr("%")
    if ! s:BufNavAllowedBuffer(current)
        return
    endif

    let last = bufnr("$")
    let new = 1
    let in_help = (&filetype == 'help')
    while new <= last
        if s:BufNavSelectableBuffer(new, in_help)
            execute ":buffer ".new
            break
        else
            let new = new + 1
        endif
    endwhile
endfunction

"Function: g:BufNavLast() function {{{2
"This function selects last suitable buffer
function! g:BufNavLast()
    let current = bufnr("%")
    if ! s:BufNavAllowedBuffer(current)
        return
    endif

    let new = bufnr("$")
    let in_help = (&filetype == 'help')
    while new > 0
        if s:BufNavSelectableBuffer(new, in_help)
            execute ":buffer ".new
            break
        else
            let new = new - 1
        endif
    endwhile
endfunction

"Function: g:BufNavClose() function {{{2
"This function tries to close current buffer and select
"nearest left one. For the first buffer selects next right
"to it. Do nothing if current buffer is the only one suitable buffer
function! g:BufNavClose()
    let current = bufnr("%")
    if ! s:BufNavAllowedBuffer(current)
        return
    endif

    if 1 < current
        let incr = -1
    else
        let incr = 1
    endif

    let last = bufnr("$")
    let new = current + incr
    let in_help = (&filetype == 'help')
    let loop_overflow = 0
    while ! s:BufNavInfLoop(current, new, loop_overflow, incr)
        if s:BufNavSelectableBuffer(new, in_help)
            execute ":buffer ".new
            execute "bd #"
            break
        else
            let new = new + incr
            if new < 1
                let new = last
                let loop_overflow = 1
            elseif new > last
                let new = 1
                let loop_overflow = 1
            endif
        endif
    endwhile
endfunction

" SECTION: Key mapping {{{1
"============================================================
" " Move to the next buffer
nmap <leader>k :call g:BufNavNext(1)<CR>
"
" " Move to the previous buffer
nmap <leader>j :call g:BufNavNext(-1)<CR>
"
" " Move to the first buffer
nmap <leader>h :call g:BufNavFirst()<CR>
"
" " Move to the last buffer
nmap <leader>l :call g:BufNavLast()<CR>
"
" " Close the current buffer and move to the previous one
nmap <leader>bq :call g:BufNavClose()<CR>

" vim: set sw=4 sts=4 et fdm=marker:
