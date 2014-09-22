" AdvancedDiffOptions/External.vim: Advanced diff filtering via external command.
"
" DEPENDENCIES:
"   - ingo/compat.vim autoload script
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.001	23-Sep-2014	file creation from
"				autoload/AdvancedDiffOptions.vim

let s:diffFilterExternal = {
\   'filters': []
\}
function! s:diffFilterExternal.translateDiffOpts( diffOptName, diffOptArg, isVimSuitabilityCheckPass ) dict
    if a:diffOptName ==# 'ilines'
	call add(self.filters, '/' . escape((a:isVimSuitabilityCheckPass ? 'doesnotmatch' : a:diffOptArg), '/') . '/s/.*//' . self.substFlags)
	return ''
    elseif a:diffOptName ==# 'irange'
	call add(self.filters, (a:isVimSuitabilityCheckPass ? '/doesnotmatch/' : a:diffOptArg) . 's/.*//' . self.substFlags)
	return ''
    elseif a:diffOptName ==# 'ipattern'
	call add(self.filters, 's/' . escape((a:isVimSuitabilityCheckPass ? 'doesnotmatch' : a:diffOptArg), '/') . '//g' . self.substFlags)
	return ''
    else
	return []
    endif
endfunction
function! s:diffFilterExternal.getCommand( fname_in, fname_new ) dict
    if empty(self.filters)
	return ''
    else
	" Clear out, but not delete the filtered lines, so that the overall
	" numbering isn't disturbed.
	let l:clearExpressions =
	\   join(
	\	map(
	\	    self.filters,
	\	    'self.filterArgument . (empty(self.filterArgument) ? "" : " ") . ingo#compat#shellescape(v:val, 1)'
	\	)
	\   )

	" Assumption: Commands can be chained (on success) via "&&".
	return printf('%s %s %s && %s %s %s && ',
	\   self.cmd,
	\   l:clearExpressions,
	\   ingo#compat#shellescape(a:fname_in, 1),
	\   self.cmd,
	\   l:clearExpressions,
	\   ingo#compat#shellescape(a:fname_new, 1)
	\)
    endif
endfunction


let AdvancedDiffOptions#External#Sed = copy(s:diffFilterExternal)
let AdvancedDiffOptions#External#Sed.substFlags = ''
let AdvancedDiffOptions#External#Sed.cmd = 'sed -i'
let AdvancedDiffOptions#External#Sed.filterArgument = '-e'

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
