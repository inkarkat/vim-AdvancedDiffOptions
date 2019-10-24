" AdvancedDiffOptions.vim: Additional diff options and commands to manage them.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo-library.vim plugin
"
" Copyright: (C) 2011-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.10.012	25-Mar-2019	Add :DiffIWhiteAll, :DiffIWhiteEol for the new
"                               built-in 'diffopt' values added in Vim 8.1.393.
"                               Implement :DiffIBlankLines in terms of the
"                               "iblank" 'diffopt' value if supported.
"   2.10.011	18-Feb-2019	Add :DiffAlgorithm command.
"   2.00.010	23-Sep-2014	Factor out filtering of the files to
"				g:AdvancedDiffOptions_Strategy configuration.
"   1.00.008	24-Jan-2013	ENH: Add :DiffIPattern to ignore only certain
"				parts of a line (vs. :DiffILines which ignores
"				the entire line if the passed regexp matches).
"				FIX: Have to double backslashes ("foo\\bar") in
"				regular expressions. Need to drop the -bar in
"				those commands taking a regexp.
"				Rename to AdvancedDiffOptions.vim.
"				Split off separate help file.
"	007	24-Jan-2013	Rename :DiffIRegexp to :DiffILines, as it's more
"				consistent with :DiffIBlankLines and less
"				misleading whether only the match or the entire
"				matching line is ignored.
"	006	28-Sep-2011	Add :DiffIClear command.
"	005	11-Jul-2011	Implement short diff option name that can be
"				included in the statusline.
"	004	09-Jul-2011	Automatically :diffupdate after changing the
"				diff options. Note that this isn't effective in
"				diff buffers created by a :Diff...Create
"				command; for these, you still need to invoke the
"				custom update command bound to the buffer-local
"				"du" mapping.
"	003	07-Jul-2011	Shorten :DiffIgnore... to :DiffI...; it's easier
"				to recognize, type and command-complete.
"	002	07-Jul-2011	ENH: Add :DiffIgnoreRegexp (replacement for
"				renamed :DiffIgnoreHunks) and :DiffIgnoreRange
"				that rely on pre-filtering of what "diff" sees.
"	001	07-Jul-2011	ENH: Add :DiffIgnoreBlankLines and
"				:DiffIgnoreRegexp commands that employ a custom
"				'diffexpr' to pass arbitrary diff arguments.
"				Add :DiffOptions to list all currently active
"				diff options, both built-in (&diffopt) and
"				custom (g:diffopt).
"			    	file creation

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
call ingo#plugin#cmdcomplete#MakeFixedListCompleteFunc(g:AdvancedDiffOptions#Algorithms, 'AdvancedDiffOptionsAlgorithmCompleteFunc')
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
