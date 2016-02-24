" AdvancedDiffOptions/Internal.vim: Advanced diff filtering internally in Vim.
"
" DEPENDENCIES:
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.001	25-Sep-2014	file creation
let s:save_cpo = &cpo
set cpo&vim

let AdvancedDiffOptions#Internal#Vim = {
\   'patterns': [],
\   'ranges': []
\}
function! s:Add( isVimSuitabilityCheckPass, list, expr )
    if ! a:isVimSuitabilityCheckPass
	call add(a:list, a:expr)
    endif
endfunction
function! AdvancedDiffOptions#Internal#Vim.translateDiffOpts( diffOptName, diffOptArg, isVimSuitabilityCheckPass ) dict
    if a:diffOptName ==# 'ilines'
	call s:Add(a:isVimSuitabilityCheckPass, self.patterns, '.*\%(' . a:diffOptArg . '\).*')
	return ''
    elseif a:diffOptName ==# 'irange'
	call s:Add(a:isVimSuitabilityCheckPass, self.ranges, a:diffOptArg)
	return ''
    elseif a:diffOptName ==# 'ipattern'
	call s:Add(a:isVimSuitabilityCheckPass, self.patterns, a:diffOptArg)
	return ''
    else
	return []
    endif
endfunction
function! AdvancedDiffOptions#Internal#Vim.getCommand( fname_in, fname_new ) dict
    if empty(self.patterns) && empty(self.ranges)
	return ''
    endif

    for l:fname in [a:fname_in, a:fname_new]
	let l:lines = readfile(l:fname)

	let l:lastLnum = len(l:lines)
	for l:range in self.ranges
	    let [l:startLnum, l:endLnum] = map(
	    \   matchlist(l:range, '^\(\d*\|\$\)\%(,\(\d*\|\$\)\)\?')[1:2],
	    \   'v:val ==# "$" ? l:lastLnum : v:val'
	    \)

	    if empty(l:startLnum)
		throw 'AdvancedDiffOptions: Only numerical ranges and "$" supported by the Internal strategy: ' . l:range
	    elseif empty(l:endLnum)
		let l:endLnum = l:startLnum
	    endif

	    if l:startLnum <= l:lastLnum && l:endLnum <= l:lastLnum
		for l:i in range(l:startLnum - 1, l:endLnum - 1)
		    let l:lines[l:i] = ''
		endfor
	    endif
	endfor

	for l:pattern in self.patterns
	    call map(l:lines, 'substitute(v:val, l:pattern, "", "g")')
	endfor

	call writefile(l:lines, l:fname)
    endfor

    return ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
