" AdvancedDiffOptions.vim: Additional diff options and commands to manage them.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo-library.vim plugin
"
" Copyright: (C) 2011-2020 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_AdvancedDiffOptions') || (v:version < 700)
    finish
endif
let g:loaded_AdvancedDiffOptions = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration ---------------------------------------------------------------

if ! exists('g:AdvancedDiffOptions_Strategy')
    let g:AdvancedDiffOptions_Strategy = AdvancedDiffOptions#External#Vim
endif


"- commands --------------------------------------------------------------------

command! -bar DiffOptions call AdvancedDiffOptions#ShowDiffOptions()

command! -bar DiffIClear call AdvancedDiffOptions#ClearDiffOptions() | call AdvancedDiffOptions#ShowDiffOptions()

let g:AdvancedDiffOptions#Algorithms = ['myers', 'minimal', 'patience', 'histogram']
call ingo#plugin#cmdcomplete#MakeFirstArgumentFixedListCompleteFunc(g:AdvancedDiffOptions#Algorithms, '', 'AdvancedDiffOptionsAlgorithmCompleteFunc')
command! -bar -nargs=? -complete=customlist,AdvancedDiffOptionsAlgorithmCompleteFunc DiffAlgorithm if ! AdvancedDiffOptions#Algorithm(<q-args>) | echoerr ingo#err#Get() | endif

command! -bar -bang DiffIWhiteSpace execute 'set diffopt' . (<bang>0 ? '-' : '+') . '=iwhite' |
\   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()

command! -bar -bang DiffICase execute 'set diffopt' . (<bang>0 ? '-' : '+') . '=icase' |
\   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()

if v:version == 801 && has('patch393') || v:version > 801
    command! -bar -bang DiffIBlankLines execute 'set diffopt' . (<bang>0 ? '-' : '+') . '=iblank' |
    \   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()
    command! -bar -bang DiffIWhiteAll execute 'set diffopt' . (<bang>0 ? '-' : '+') . '=iwhiteall' |
    \   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()
    command! -bar -bang DiffIWhiteEol execute 'set diffopt' . (<bang>0 ? '-' : '+') . '=iwhiteeol' |
    \   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()
else
    command! -bar -bang DiffIBlankLines
    \   call AdvancedDiffOptions#ChangeDiffOpt(<bang>0, 'iblank', 'wl') |
    \   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()
    command! -bar -bang DiffIWhiteAll
    \   call AdvancedDiffOptions#ChangeDiffOpt(<bang>0, 'iwhiteall', 'wa') |
    \   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()
    command! -bar -bang DiffIWhiteEol
    \   call AdvancedDiffOptions#ChangeDiffOpt(<bang>0, 'iwhiteeol', 'w$') |
    \   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()
endif

command! -bang -nargs=? DiffIHunks
\   call AdvancedDiffOptions#ChangeDiffOpt(<bang>0, 'ihunk', '@@', <q-args>) |
\   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()

command! -bang -nargs=? DiffILines
\   call AdvancedDiffOptions#ChangeDiffOpt(<bang>0, 'ilines', 'l', <q-args>) |
\   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()

command! -bang -nargs=? DiffIRange
\   call AdvancedDiffOptions#ChangeDiffOpt(<bang>0, 'irange', 'a-b', <q-args>) |
\   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()

command! -bang -nargs=? DiffIPattern
\   call AdvancedDiffOptions#ChangeDiffOpt(<bang>0, 'ipattern', '/', <q-args>) |
\   diffupdate | call AdvancedDiffOptions#ShowDiffOptions()

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
