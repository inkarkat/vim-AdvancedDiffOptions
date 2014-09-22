" AdvancedDiffOptions.vim: Additional diff options and commands to manage them.
"
" DEPENDENCIES:
"   - ingo/collections.vim autoload script
"   - ingo/compat.vim autoload script
"   - external "diff" command, accessible through the PATH
"   - external "sed" command, accessible through the PATH
"
" Copyright: (C) 2011-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.009	05-Aug-2014	Globally remove the pattern for 'ipattern'.
"	008	08-Aug-2013	Move escapings.vim into ingo-library.
"	007     21-Feb-2013     Move to ingo-library.
"	006	24-Jan-2013	Rename :DiffIRegexp to :DiffILines, as it's more
"				consistent with :DiffIBlankLines and less
"				misleading whether only the match or the entire
"				matching line is ignored.
"				Rename to AdvancedDiffOptions.vim.
"	005	28-Sep-2011	Add :DiffIClear command.
"	004	28-Sep-2011	Factor out ingodiffoptions#DiffCmd() for use in
"				ingodiff.vim's :DiffCreate commands.
"	003	11-Jul-2011	Implement short diff option name that can be
"				included in the statusline.
"	002	07-Jul-2011	ENH: Add :DiffIgnoreRegexp (replacement for
"				renamed :DiffIgnoreHunks) and :DiffIgnoreRange
"				that rely on pre-filtering of what "diff" sees.
"	001	07-Jul-2011	ENH: Add :DiffIgnoreBlankLines and
"				:DiffIgnoreRegexp commands that employ a custom
"				'diffexpr' to pass arbitrary diff arguments.
"			    	file creation
let s:save_cpo = &cpo
set cpo&vim

function! AdvancedDiffOptions#ShowDiffOptions()
    echo &diffopt . (empty(g:diffopt) ? '' : (empty(&diffopt) ? '' : ',') . join(g:diffopt, ','))
endfunction

if ! exists('g:diffopt')
    let g:diffopt = []
endif
let s:diffOptNameToShort = {
\   'icase' : 'i',
\   'iwhite' : 'ws'
\}
function! s:ApplyDiffOpt()
    if empty(g:diffopt)
	" TODO: Save and restore previous diffexpr.
	set diffexpr=
    else
	set diffexpr=AdvancedDiffOptions#DiffExpr()
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
    return filter(split(&diffopt, ','), 'v:val[0] ==# "i"') + g:diffopt
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
function! s:TranslateDiffOpts( diffOpt, isVimSuitabilityCheckPass )
    let [l:diffOptName, l:diffOptArg] = matchlist(a:diffOpt, '^\([^=]\+\)\%(=\(.*\)\)\?$')[1:2]

    if l:diffOptName ==# 'icase'
	return '-i'
    elseif l:diffOptName ==# 'iwhite'
	return '-b'
    elseif l:diffOptName ==# 'iblankline'
	return '-b -B'
    elseif l:diffOptName ==# 'ihunk'
	return '-I ' . (a:isVimSuitabilityCheckPass ? 'doesnotmatch' : ingo#compat#shellescape(l:diffOptArg, 1))
    elseif l:diffOptName ==# 'ilines'
	call add(s:sedFilter, '/' . escape((a:isVimSuitabilityCheckPass ? 'doesnotmatch' : l:diffOptArg), '/') . '/s/.*//')
	return ''
    elseif l:diffOptName ==# 'irange'
	call add(s:sedFilter, (a:isVimSuitabilityCheckPass ? '/doesnotmatch/' : l:diffOptArg) . 's/.*//')
	return ''
    elseif l:diffOptName ==# 'ipattern'
	call add(s:sedFilter, 's/' . escape((a:isVimSuitabilityCheckPass ? 'doesnotmatch' : l:diffOptArg), '/') . '//g')
	return ''
    else
	return ingo#compat#shellescape(a:diffOpt, 1)
    endif
endfunction
function! AdvancedDiffOptions#DiffCmd( diffOptions, fname_in, fname_new, ... )
    let l:isVimSuitabilityCheckPass = s:IsVimSuitabilityCheckPass(a:fname_in, a:fname_new)
    let s:sedFilter = []

    let l:diffArgs = map(
    \	a:diffOptions,
    \	's:TranslateDiffOpts(v:val, l:isVimSuitabilityCheckPass)'
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

    if ! empty(s:sedFilter)
	" Clear out, but not delete the filtered lines, so that the overall
	" numbering isn't disturbed.
	let l:sedClearExpressions =
	\   join(
	\	map(
	\	    s:sedFilter,
	\	    '"-e " . ingo#compat#shellescape(v:val, 1)'
	\	)
	\   )

	" Assumption: Commands can be chained (on success) via "&&".
	let l:diffCmd = printf('sed -i %s %s && sed -i %s %s && ',
	\   l:sedClearExpressions,
	\   ingo#compat#shellescape(a:fname_in, 1),
	\   l:sedClearExpressions,
	\   ingo#compat#shellescape(a:fname_new, 1)
	\) . l:diffCmd
    endif
"****D echomsg l:diffCmd
    return l:diffCmd
endfunction
function! AdvancedDiffOptions#DiffExpr()
    silent execute '!' . AdvancedDiffOptions#DiffCmd(s:GetAllDiffOptions(), v:fname_in, v:fname_new, v:fname_out)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
