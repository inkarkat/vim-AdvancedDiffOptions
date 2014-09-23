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
"   2.00.002	24-Sep-2014	Introduce full templating to accommodate the
"				syntax differences between sed and Vim.
"   2.00.001	23-Sep-2014	file creation from
"				autoload/AdvancedDiffOptions.vim

let s:diffFilterExternal = {
\   'filters': []
\}
function! s:diffFilterExternal.translateDiffOpts( diffOptName, diffOptArg, isVimSuitabilityCheckPass ) dict
    if a:diffOptName ==# 'ilines'
	call add(self.filters, printf(
	\   self.templateFilterRange,
	\   '/' . escape((a:isVimSuitabilityCheckPass ? 'doesnotmatch' : a:diffOptArg), '/') . '/'
	\))
	return ''
    elseif a:diffOptName ==# 'irange'
	call add(self.filters, printf(
	\   self.templateFilterRange,
	\   (a:isVimSuitabilityCheckPass ? '/doesnotmatch/' : a:diffOptArg)
	\))
	return ''
    elseif a:diffOptName ==# 'ipattern'
	call add(self.filters, printf(
	\   self.templateFilterPattern,
	\   escape((a:isVimSuitabilityCheckPass ? 'doesnotmatch' : a:diffOptArg), '/')
	\))
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
	return printf('%s %s %s %s && %s %s %s %s && ',
	\   self.cmd,
	\   l:clearExpressions,
	\   self.additionalExpressions,
	\   ingo#compat#shellescape(a:fname_in, 1),
	\   self.cmd,
	\   l:clearExpressions,
	\   self.additionalExpressions,
	\   ingo#compat#shellescape(a:fname_new, 1)
	\)
    endif
endfunction


let AdvancedDiffOptions#External#Sed = copy(s:diffFilterExternal)
let AdvancedDiffOptions#External#Sed.templateFilterRange = '%ss/.*//'
let AdvancedDiffOptions#External#Sed.templateFilterPattern = 's/%s//g'
let AdvancedDiffOptions#External#Sed.cmd = 'sed -i'
let AdvancedDiffOptions#External#Sed.additionalExpressions = ''
let AdvancedDiffOptions#External#Sed.filterArgument = '-e'

let AdvancedDiffOptions#External#Vim = copy(s:diffFilterExternal)
let AdvancedDiffOptions#External#Vim.substTemplate = 'silent! %se'
let AdvancedDiffOptions#External#Vim.templateFilterRange = 'g%ss/.*//e'
let AdvancedDiffOptions#External#Vim.templateFilterPattern = '%%s/%s//ge'
let AdvancedDiffOptions#External#Vim.cmd = 'vim -N -u NONE -n -i NONE -es -c ' . ingo#compat#shellescape('set nomore', 1)
let AdvancedDiffOptions#External#Vim.additionalExpressions = '-c wq'
let AdvancedDiffOptions#External#Vim.filterArgument = '-c'

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
