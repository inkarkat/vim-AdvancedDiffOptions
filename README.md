ADVANCED DIFF OPTIONS
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Vim provides a nice diff-mode; parameters like case- or whitespace-
insensitivity can be controlled through the 'diffopt' option. However, because
that option controls both the difference filtering itself as well as the
visual appearance within Vim, modifying that option on the fly with `:set`
isn't very comfortable.

This plugin provides a set of :DiffI... commands that enable you to quickly
toggle the built-in diff filtering options, and adds advanced options for
filtering blank lines, complete change hunks, lines, ranges, or patterns of
text.

### HOW IT WORKS

When there's a corresponding command-line option for the "diff" tool, this is
passed. The filtering of lines, ranges, and patterns is implemented by
preprocessing the buffers through the external "sed" command.

### RELATED WORKS

- spotdiff.vim ([vimscript #5509](http://www.vim.org/scripts/script.php?script_id=5509)) also selectively diffs parts of two buffers
  by filtering certain lines via a custom 'diffexpr', similar to how
  :DiffIRange works.

USAGE
------------------------------------------------------------------------------

    :DiffOptions            List the currently active diff options.

    :DiffAlgorithm          Show the currently active diff algorithm (for the
                            internal diff).
    :DiffAlgorithm {algorithm}
                            Set the algorithm for the internal diff to
                            {algorithm}, one of myers, minimal, patience, history;
                            cp. 'diffopt'.

    :DiffIClear             Clear all "ignore ..." diff options.

    :DiffIWhiteSpace[!]     Ignore changes in whitespace. [!] for undo.

    :DiffICase[!]           Ignore changes in case. [!] for undo.

    :DiffIWhiteAll[!]       Ignore all white space changes. [!] for undo.

    :DiffIWhiteEol[!]       Ignore white space changes at end of line. [!] for
                            undo.

    :DiffIBlankLines[!]     Ignore changes where lines are all blank. [!] for
                            undo.

    :DiffIHunks[!] [{expr}] Ignore change hunks whose lines _all_ match {expr}.
                            [!] for undo.

                            The following filters go beyond the capabilities of
                            the diff command itself; they work by preprocessing
                            the compared files before sending them to diff.

    :DiffILines[!] [{expr}] Do not consider any (whole) lines that match {expr} in
                            the diff (like grep). [!] for undo.

    :DiffIRange[!] [{range}]
                            Do not consider any lines that match the lines
                            specified by {range} in the diff. [!] for undo.
                            Note that Vim will still highlight additional lines at
                            the end of the longer buffer.

    :DiffIPattern[!] [{expr}]
                            Do not consider any text that matches {expr} in the
                            diff (globally, not just the first match). Other text
                            around the matches still contributes to the diff, so
                            in contrast to :DiffILines, this lets you
                            selectively ignore parts of a line.
                            [!] for undo, i.e. removing {expr}, or all previously
                            given patterns.
                            Note that if the amount of ignored lines different
                            between files, other (later) lines will be mistakenly
                            highlighted as changed.
                            Note that Vim will still highlight the ignored changes
                            (should there be another change in the line that is
                            not covered by {expr}), because it determines that on
                            its own.

### EXAMPLE

Filter all diff hunks that only consist of comments in a Perl script:

    :DiffIHunks ^#

Ignore any differences after a line matching "EOF":

    :DiffIRange /^EOF$/,$

Ignore type differences of "char const" vs. "char" in a C program:

    :DiffIPattern [ ]const

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-AdvancedDiffOptions
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim AdvancedDiffOptions*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.040 or
  higher.
- misc.vim plugin ([vimscript #4597](http://www.vim.org/scripts/script.php?script_id=4597)), version 1.17 or higher (optional).
- External command "diff" or equivalent for listing of differences.
- External command "sed" for some advanced filters (optional).

CONFIGURATION
------------------------------------------------------------------------------

Some advanced filters require preprocessing of the compared files. The plugin
now offers several different strategies for this, each with slight differences
in supported syntax. The default is using a separate instance of Vim:

    let g:AdvancedDiffOptions_Strategy = AdvancedDiffOptions#External#Vim

With that, you can use the familiar syntax for ranges and regular expressions,
but the processing is the slowest.
If you have the sed tool on your system, you can use that instead:

    let g:AdvancedDiffOptions_Strategy = AdvancedDiffOptions#External#Sed

This is faster, but note that the tool uses a different regular expression
syntax.
The fastest option is processing of the diff files inside the current Vim
instance; no external tool launch (other than diff itself) is required. Note
that this currently only supports a subset of numerical ranges (e.g. 23,42)
and "$", and that regular expression are evaluated line by line and cannot
reference other lines. Also, no detection of the file encoding is done.

    let g:AdvancedDiffOptions_Strategy = AdvancedDiffOptions#Internal#Vim

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-AdvancedDiffOptions/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 2.10    26-Jul-2020
- Add :DiffAlgorithm command to query or set the algorithm used by the
  internal diff.
- Save original 'diffexpr'. Remove "internal" from 'diffopt' when setting
  'diffexpr'.
- Don't include "internal" in AdvancedDiffOptions#GetShortDiffOptions(), as
  it's more an implementation detail. Same for "indent-heuristic" (which also
  starts with i and is therefore picked up).
- Add :DiffIWhiteAll, :DiffIWhiteEol for the new built-in 'diffopt' values
  added in Vim 8.1.393. Implement :DiffIBlankLines in terms of the "iblank"
  'diffopt' value if supported.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.040!__

##### 2.00    25-Sep-2014
- Refactor the plugin to handle different strategies to preprocess the
  compared files (used by some advanced filters).
- Offer preprocessing through an externally launched Vim instance, and
  internally in the current Vim, in addition to the existing external sed
  tool. Change the default to external Vim, because that offers the fullest
  feature set, and no need to switch regular expression dialects as with sed.
  Thanks to Marcelo Montu for suggesting this and sending prototype patches
  for both external and internal Vim processing!

##### 1.00    05-Aug-2014
- First published version.

##### 0.01    07-Jul-2011
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2011-2020 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
