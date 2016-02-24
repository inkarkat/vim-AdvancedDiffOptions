" AdvancedDiffOptions/External.vim: Advanced diff filtering via external command.
"
" DEPENDENCIES:
"   - ingo/compat.vim autoload script
"   - external "sed" command, accessible through the PATH
"   - external "vim" command, accessible through the PATH, or found through
"     vim-misc.
"   - xolox/misc/os.vim autoload script (optional)
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.003	25-Sep-2014	FIX: Postprocessing removes "%" from "%s".
"				Optionally use xolox#misc#os#find_vim() from
"				the vim-misc plugin.
"   2.00.002	24-Sep-2014	Introduce full templating to accommodate the
"				syntax differences between sed and Vim.
"   2.00.001	23-Sep-2014	file creation from
"				autoload/AdvancedDiffOptions.vim
let s:save_cpo = &cpo
set cpo&vim

let s:diffFilterExternal = {
\   'filters': [],
\   'filterPostProcessing': ''
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
    endif

    if ! empty(self.filterPostProcessing)
	call map(self.filters, 'self.filterPostProcessing(v:val)')
    endif

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
endfunction


let AdvancedDiffOptions#External#Sed = copy(s:diffFilterExternal)
let AdvancedDiffOptions#External#Sed.templateFilterRange = '%ss/.*//'
let AdvancedDiffOptions#External#Sed.templateFilterPattern = 's/%s//g'
let AdvancedDiffOptions#External#Sed.cmd = 'sed -i'
let AdvancedDiffOptions#External#Sed.additionalExpressions = ''
let AdvancedDiffOptions#External#Sed.filterArgument = '-e'

let AdvancedDiffOptions#External#Vim = copy(s:diffFilterExternal)
let AdvancedDiffOptions#External#Vim.templateFilterRange = 'g%ss/.*//e'
let AdvancedDiffOptions#External#Vim.templateFilterPattern = '%%s/%s//ge'
function! s:VimFilterPostProcessing( filter )
    " We only need the :global command when the range starts with a /pattern/;
    " else, remove it, as :g500,$ is incorrect.
    return (a:filter !~# '^g' || a:filter =~# '^g[[:alnum:]\\"|]\@![\x00-\xFF]' ? a:filter : a:filter[1:])
endfunction
let AdvancedDiffOptions#External#Vim.filterPostProcessing = function('s:VimFilterPostProcessing')
let s:vimExecutable = 'vim'
silent! let s:vimExecutable = xolox#misc#os#find_vim('vim')
let AdvancedDiffOptions#External#Vim.cmd = s:vimExecutable . ' -N -u NONE -n -i NONE -es' .
\   ' --cmd ' . ingo#compat#shellescape('set nomodeline') .
\   ' -c ' . ingo#compat#shellescape('set nomore nofoldenable', 1)  " Note: Especially folding set up by modelines may interfere with batch processing.
let AdvancedDiffOptions#External#Vim.additionalExpressions = '-c wq'
let AdvancedDiffOptions#External#Vim.filterArgument = '-c'

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
