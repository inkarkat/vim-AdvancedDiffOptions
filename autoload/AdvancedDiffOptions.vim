" AdvancedDiffOptions.vim: Additional diff options and commands to manage them.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"   - external "diff" command, accessible through the PATH
"
" Copyright: (C) 2011-2020 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

function! AdvancedDiffOptions#ShowDiffOptions()
    echo &diffopt . (empty(g:diffopt) ? '' : (empty(&diffopt) ? '' : ',') . join(g:diffopt, ','))
endfunction

function! AdvancedDiffOptions#Algorithm( arguments )
    let l:diffOptions = ingo#option#SplitAndUnescape(&diffopt)

    let l:message = ''
    if ! empty(&diffexpr)
	let l:message = 'Using external diff: ' . &diffexpr
    elseif index(l:diffOptions, 'internal') == -1
	let l:message = 'Using external diff'
    endif
    if ! empty(l:message)
	if empty(a:arguments)
	    echo l:message
	    return 1
	else
	    call ingo#err#Set(l:message)
	    return 0
	endif
    endif

    let l:currentAlgorithm = filter(l:diffOptions, 'v:val =~# "^algorithm:"')

    if empty(a:arguments)
	let l:algorithm = get(l:currentAlgorithm, 0, 'default')
	echo printf('Using %s algorithm', substitute(l:algorithm, '^algorithm:', '', ''))
	return 1
    endif

    for l:algorithm in l:currentAlgorithm
	execute 'set diffopt-=' . l:algorithm
    endfor
    try
	execute 'set diffopt+=algorithm:' . a:arguments
	return 1
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#err#SetVimException()
	return 0
    endtry
endfunction

if ! exists('g:diffopt')
    let g:diffopt = []
endif
let s:diffOptNameToShort = {
\   'icase' : 'i',
\   'iwhite' : 'ws'
\}
let s:save_diffexpr = ''
let s:save_isInternalDiff = ingo#option#Contains(&diffopt, 'internal')
function! s:ApplyDiffOpt()
    if empty(g:diffopt)
	let &diffexpr = s:save_diffexpr

	if s:save_isInternalDiff
	    set diffopt+=internal
	endif
    else
	if &diffexpr !~# '^AdvancedDiffOptions'
	    let s:save_diffexpr = &diffexpr
	    let s:save_isInternalDiff = ingo#option#Contains(&diffopt, 'internal')
	endif
	set diffexpr=AdvancedDiffOptions#DiffExpr()
	set diffopt-=internal
    endif
endfunction
function! AdvancedDiffOptions#ChangeDiffOpt( isRemove, diffOptName, diffOptShortName, ... )
    let l:diffOpt = a:diffOptName . (a:0 ? '=' . a:1 : '')

    if a:isRemove
	if a:0
	    let l:diffOptExpr = '^' . a:diffOptName . '=\V' . escape(a:1, '\') . (empty(a:1) ? '' : '\$')
	endif
	call filter(g:diffopt, (a:0 ? 'v:val !~# l:diffOptExpr' : 'v:val !=# l:diffOpt'))
    else
	if index(g:diffopt, l:diffOpt) == -1
	    call add(g:diffopt, l:diffOpt)
	endif
    endif

    call s:ApplyDiffOpt()

    let s:diffOptNameToShort[a:diffOptName] = a:diffOptShortName
endfunction
function! AdvancedDiffOptions#ClearDiffOptions()
    let &diffopt = join(filter(split(&diffopt, ','), 'v:val[0] !=# "i"'), ',')
    let g:diffopt = []
endfunction
function! s:GetAllDiffOptions()
    " The built-in 'diffopt' values that are relevant to diff creation all start
    " with the letter "i".
    return filter(split(&diffopt, ','), 'v:val[0] ==# "i" && v:val !=# "internal" && v:val !=# "indent-heuristic"') + g:diffopt
endfunction
function! AdvancedDiffOptions#GetShortDiffOptions()
"******************************************************************************
"* PURPOSE:
"   Build a short string that represents all currently active diff options.
"   This can be included in the statusline.
"   Arguments to the diff options are omitted, and multiple occurrences of the
"   same diff option are condensed into a single short name, e.g.
"   "ilines=foo,ilines=bar" shows up as "l".
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   None.
"* RETURN VALUES:
"   String representing all currently active diff options.
"******************************************************************************
    return join(
    \	sort(
    \	    map(
    \		ingo#collections#Unique(
    \		    map(s:GetAllDiffOptions(), 'substitute(v:val, "=.*$", "", "")')
    \		),
    \		'get(s:diffOptNameToShort, v:val, v:val)'
    \	    )
    \	),
    \	','
    \)
endfunction

function! s:IsVimSuitabilityCheckPass( fname_in, fname_new )
"******************************************************************************
"* PURPOSE:
"   Vim first invokes 'diffexpr' with dummy file contents of "line1" and
"   "line2" as a check whether the diff output is usable. We must not apply any
"   filtering during this check pass, or Vim declares our 'diffexpr' unsuitable:
"   E97: Cannot create diffs
"* ASSUMPTIONS / PRECONDITIONS:
"   Current diff files are set in v:fname_in and v:fname_out.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   None.
"* RETURN VALUES:
"   Flag whether the suitability check was detected.
"******************************************************************************
    return
    \	getfsize(a:fname_in) <= 6 &&
    \	getfsize(a:fname_new) <= 6 &&
    \	readfile(a:fname_in, 0, 1)[0] ==# 'line1' &&
    \	readfile(a:fname_new, 0, 1)[0] ==# 'line2'
endfunction
function! s:TranslateDiffOpts( diffOpt, isVimSuitabilityCheckPass, filter )
    let [l:diffOptName, l:diffOptArg] = matchlist(a:diffOpt, '^\([^=]\+\)\%(=\(.*\)\)\?$')[1:2]

    let l:filterResult = a:filter.translateDiffOpts(l:diffOptName, l:diffOptArg, a:isVimSuitabilityCheckPass)
    if type(l:filterResult) == type('')
	return l:filterResult
    elseif l:diffOptName ==# 'icase'
	return '-i'
    elseif l:diffOptName ==# 'iwhite'
	return '-b'
    elseif l:diffOptName ==# 'iblank'
	return '-B'
    elseif l:diffOptName ==# 'iwhiteall'
	return '-w'
    elseif l:diffOptName ==# 'iwhiteeol'
	return '-Z'
    elseif l:diffOptName ==# 'ihunk'
	return '-I ' . (a:isVimSuitabilityCheckPass ? 'doesnotmatch' : ingo#compat#shellescape(l:diffOptArg, 1))
    else
	return ingo#compat#shellescape(a:diffOpt, 1)
    endif
endfunction
function! AdvancedDiffOptions#DiffCmd( diffOptions, fname_in, fname_new, ... )
    let l:isVimSuitabilityCheckPass = s:IsVimSuitabilityCheckPass(a:fname_in, a:fname_new)
    let l:filter = deepcopy(g:AdvancedDiffOptions_Strategy)

    let l:diffArgs = map(
    \	a:diffOptions,
    \	's:TranslateDiffOpts(v:val, l:isVimSuitabilityCheckPass, l:filter)'
    \)

    let l:diffCmd = printf('diff -a %s %s %s',
    \	join(l:diffArgs),
    \	ingo#compat#shellescape(a:fname_in, 1),
    \	ingo#compat#shellescape(a:fname_new, 1)
    \)
    " Assumption: File redirection works with ">"; don't want to parse the
    " 'shellredir' setting.
    if a:0
	let l:fname_out = a:1
	let l:diffCmd .= ' > ' . ingo#compat#shellescape(l:fname_out, 1)
    endif

    let l:filterCmd = ''
    try
	let l:filterCmd = l:filter.getCommand(a:fname_in, a:fname_new)
    catch /^AdvancedDiffOptions:/
	call ingo#msg#CustomExceptionMsg('AdvancedDiffOptions')
    endtry

    let l:diffCmd = l:filterCmd . l:diffCmd
"****D echomsg '****' l:diffCmd
    return l:diffCmd
endfunction
function! AdvancedDiffOptions#DiffExpr()
    let l:diffCmd = AdvancedDiffOptions#DiffCmd(s:GetAllDiffOptions(), v:fname_in, v:fname_new, v:fname_out)
    silent execute '!' . l:diffCmd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
