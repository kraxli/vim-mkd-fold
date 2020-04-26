
if exists('g:mkd_fold_ftp_markdown') | finish | else | let g:mkd_fold_ftp_markdown = 1 | endif

" ------- Folding -------
" if g:markdown_enable_folding
setlocal foldmethod=expr
setlocal foldexpr=fold#FoldLevelOfLine(v:lnum)
" endif

