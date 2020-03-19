

" ------- Folding -------
" if g:markdown_enable_folding
setlocal foldmethod=expr
setlocal foldexpr=fold#FoldLevelOfLine(v:lnum)
" endif

