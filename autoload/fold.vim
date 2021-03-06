
" indent('.') / indent(line(.))
" synIDattr(synID(line('.'), 1, 1), 'name')
" foldlevel('.') / foldlevel(line('.'))

" help:
"   http://vimdoc.sourceforge.net/htmldoc/fold.html#folds
"   http://vimdoc.sourceforge.net/htmldoc/usr_41.html

" {{{ FOLDING

let s:header_pattern = g:mkdd_header_pattern

if !exists('b:list_ini_indent')
  let b:list_ini_indent = 0
endif

if !exists('b:list_ini_fold')
  let b:list_ini_fold = 0
endif


function! fold#FoldLevelOfLine(lnum)

  " stop if file has one line only
  if line('$') <= 1
    return -1
  endif

  let cur_line = getline(a:lnum)
  let nxt_line = getline(a:lnum + 1)
  let prv_line =  getline(a:lnum - 1)

  let prv_syntax_group = synIDattr(synID(a:lnum - 1, 1, 1), 'name')
  let cur_syntax_group = synIDattr(synID(a:lnum, 1, 1), 'name')
  let nxt_syntax_group = synIDattr(synID(a:lnum + 1, 1, 1), 'name')

  if (cur_syntax_group =~? 'mkdxListItem' ||  cur_syntax_group =~? 'mkdListItem' ||  cur_syntax_group =~? 'markdownList' || cur_syntax_group =~? 'VimwikiListTodo' || cur_syntax_group =~? 'VimwikiList')
    let cur_syntax_group = 'mkddListItem'
  endif

  if (cur_syntax_group =~? 'mkdxListItemDone'  || cur_syntax_group =~? 'mkdListItemDone'  || cur_syntax_group =~? 'markdownListDone' || cur_syntax_group =~? 'VimwikiCheckBoxDone')
    let cur_syntax_group = 'mkddListItemDone'
  endif

  " ┌───────────────────────────────────┐
  " │ folding of makdown title sections │
  " └───────────────────────────────────┘

  if match(cur_line, '^-\{2,}\s*$') >= 0
    " cur_line =~ '^-\{2,}\s*$'
    return '0'
  endif

  " ------- folding atx headers ------
  if (cur_syntax_group =~? 'markdownHeadingDlimiter' || cur_syntax_group =~? 'markdownHead' || cur_syntax_group =~? 'mkdxHead' || cur_syntax_group =~? 'VimwikiHeaderChar')
  " if match(cur_line, s:header_pattern) >= 0
    let s:header_level = strlen(substitute(cur_line, g:mkdd_header_pattern . '.*', '\1', ''))
    return '>' . s:header_level
  endif

  " " ---- net line is list itme ----
  " if nxt_syntax_group  =~? 'mkdListItem' && match(prv_line, '^\s*$') < 0 && cur_syntax_group !~? 'mkdListItem'
  "   " let b:list_ini_indent = cur_indent
  " ...
  " let b:list_ini_fold = foldlevel(a:lnum-1) " s:header_level " (s:header_level + 1)
  " endif

  " ---------- Folding Lists -----------
  if (cur_syntax_group =~? 'mkddListItem' || cur_syntax_group =~? 'mkddListItemDone') && g:markdown_list_folding == 1

    let prv_indent = indent(a:lnum-1)
    let cur_indent = indent(a:lnum)
    let nxt_indent = indent(a:lnum+1)

    " initial list indent level / each new list starts after an empty line
    " or a header (consistent with pandoc)
    if match(prv_line, '^\s*$') >= 0 || match(prv_line, s:header_pattern) >= 0 || prv_line =~? 'Delimiter' || prv_line =~? 'mkdCode' || prv_line =~? 'markdownCode' || prv_line =~? 'mkdxCode'
    " if prv_syntax_group !~? 'mkdListItem'
      let b:list_ini_indent = cur_indent
      let b:list_ini_fold =  s:header_level " (s:header_level + 1)
      " return b:list_ini_fold
    endif

    let cur_fold_diff = (cur_indent - prv_indent)/&shiftwidth
    let nxt_fold_diff =  (nxt_indent - cur_indent)/&shiftwidth

    " following sublist
    if nxt_fold_diff > 0
      return '>' . (b:list_ini_fold + (nxt_indent-b:list_ini_indent)/&shiftwidth)
    endif

    " initial list fold in case no sublist following
    if match(prv_line, '^\s*$') >= 0 || match(prv_line, s:header_pattern) >= 0 || prv_line =~? 'Delimiter' || prv_line =~? 'mkdCode' || prv_line =~? 'markdownCode' || prv_line =~? 'mkdxCode'
      return b:list_ini_fold
    endif

    " return '>' . (b:list_ini_fold + (cur_indent-b:list_ini_indent)/&shiftwidth)
    return (b:list_ini_fold + (cur_indent-b:list_ini_indent)/&shiftwidth)

  endif

  " === Folding Code ===

  " folding fenced code blocks
  if match(cur_line, '^\s*```') >= 0
    if nxt_syntax_group ==? 'markdownFencedCodeBlock' || nxt_syntax_group =~? 'mkdCode' || nxt_syntax_group =~? 'mkdSnippet' || nxt_syntax_group =~? 'markdownCode' || nxt_syntax_group =~? 'textSnip' || nxt_syntax_group =~? 'VimwikiPre' || nxt_syntax_group =~? 'Error'
      return '> ' . (s:header_level + 1)
    endif
    return 's1'
  endif

  if (cur_syntax_group =~? 'mkdSnippet' || cur_syntax_group =~? 'markdownCode'  || cur_syntax_group =~? 'Error' || cur_syntax_group =~? 'Comment' || cur_syntax_group =~? 'textSnip' || cur_syntax_group =~? 'VimwikiPre')
    " && nxt_syntax_group !~? 'textSnipTEX'
    return '='
  endif

  " folding code blocks
  if match(cur_line, '^\s\{4,}') >= 0
    if cur_syntax_group ==? 'markdownCodeBlock'
      if prv_syntax_group !=? 'markdownCodeBlock'
        return 'a1'
      endif
      if nxt_syntax_group !=? 'markdownCodeBlock'
        return 's1'
      endif
    endif
    return '='
  endif

  " === Folding Math ===
  let is_texMathZone_boundry = cur_syntax_group =~? 'texMathZone' || cur_syntax_group =~? 'Delimeter' || cur_syntax_group =~? 'VimwikiMath'

    " return '> ' . (s:header_level + 1)

  if is_texMathZone_boundry && (prv_syntax_group !~? 'texMathZone' || prv_syntax_group !~? 'VimwikiMath' || prv_syntax_group !~? 'textSnipTEX') && (nxt_syntax_group =~? 'texMathZone' || nxt_syntax_group =~? 'textSnipTEX')
    " return 'a1'
    return '> ' . (s:header_level + 1)
  endif

  if is_texMathZone_boundry && (nxt_syntax_group !~? 'texMathZone' || nxt_syntax_group !~? 'textSnipTEX') && (prv_syntax_group =~? 'texMathZone' || prv_syntax_group =~? 'textSnipTEX')
    " && nxt_syntax_group !~? 'mkdListItem'
    return 's1'
  endif

  if cur_syntax_group =~? 'texMathZone' || cur_syntax_group =~? 'textSnipTEX'
    return '='
  endif

  " === Folding HTML comments ===
  if cur_syntax_group =~? 'htmlComment' && prv_syntax_group !~? 'htmlComment'
    return 'a1'
  endif

  if nxt_syntax_group =~? 'htmlComment'
    return '='
  endif

  if prv_syntax_group =~? 'htmlComment' && cur_line !~? 'htmlComment'
    return 's1'
  endif

  " ------- empty line -------
  if match(cur_line, '^\s*$') >= 0
    " TODO: find syntax-group of last not empty line
    if prv_syntax_group =~? 'textSnip'
      return '='
    endif
      return (s:header_level)
  endif


  " folding setex headers
  if (match(cur_line, '^.*$') >= 0)
    if (match(nxt_line, '^=\+$') >= 0)
      return '>1'
    endif
    if (match(nxt_line, '^-\+$') >= 0)
      return '>2'
    endif
  endif

  return '='

endfunction


function! s:find_pattern_backw(rx_item, lnum) "{{{
  let lnum = (a:lnum - 1)
  let line = getline(lnum)

  while lnum > 1
    let line = getline(lnum)
    if line =~? a:rx_item
      break
    endif
    let lnum -= 1
  endwhile

  " let fold_lev = foldlevel(lnum)
  " return [lnum, fold_lev, line]

  return lnum
endfunction "}}}

" function! FindPattern(rx_item, lnum)
"   return s:find_pattern_backw(a:rx_item, a:lnum)
" endfunction

function! s:SyntaxGroupOfLineIs(lnum, pattern)
  let stack = synstack(a:lnum, a:cnum)
  if len(stack) > 0
    return synIDattr(stack[0], 'name') =~? a:pattern
  endif
  return 0
endfunction

" }}}

" vim:foldmethod=indent
