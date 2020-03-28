
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


  " ------- folding atx headers ------
  if match(cur_line, s:header_pattern) >= 0
    let s:header_level = strlen(substitute(cur_line, g:mkdd_header_pattern . '.*', '\1', ''))
    return '>' . s:header_level
  endif

  " ------- empty line -------
  if match(cur_line, '^\s*$') >= 0
      return (s:header_level)
  endif

  " ---------- Folding Lists -----------
  if cur_syntax_group =~? 'mkdListItem' && g:markdown_list_folding == 1

    let prv_indent = indent(a:lnum-1)
    let cur_indent = indent(a:lnum)
    let nxt_indent = indent(a:lnum+1)

    " initial list indent level / each new list starts after an empty line
    " or a header (consistent with pandoc)
    if match(prv_line, '^\s*$') >= 0 || match(prv_line, s:header_pattern) >= 0 || prv_line =~? 'Delimiter' || prv_line =~? 'mkdCode'
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
    if match(prv_line, '^\s*$') >= 0 || match(prv_line, s:header_pattern) >= 0 || prv_line =~? 'Delimiter' || prv_line =~? 'mkdCode'
      return b:list_ini_fold
    endif

    " return '>' . (b:list_ini_fold + (cur_indent-b:list_ini_indent)/&shiftwidth)
    return (b:list_ini_fold + (cur_indent-b:list_ini_indent)/&shiftwidth)

  endif

  " === Folding Code ===

  " folding fenced code blocks
  if match(cur_line, '^\s*```') >= 0
    if nxt_syntax_group ==? 'markdownFencedCodeBlock' || nxt_syntax_group =~? 'mkdCode' || nxt_syntax_group =~? 'mkdSnippet'
      return '> ' . (s:header_level + 1)
    endif
    return 's1'
  endif

  if cur_syntax_group =~? 'mkdSnippet'
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
  let is_texMathZone_boundry = cur_syntax_group =~? 'texMathZone' || cur_syntax_group =~? 'Delimeter'

  if is_texMathZone_boundry && prv_syntax_group !~? 'texMathZone' && nxt_syntax_group =~? 'texMathZone'
    return 'a1'
  endif

  if is_texMathZone_boundry && nxt_syntax_group !~? 'texMathZone' && prv_syntax_group =~? 'texMathZone' && nxt_syntax_group ==? ''
    " && nxt_syntax_group !~? 'mkdListItem'
    return 's1'
  endif

  if cur_syntax_group =~? 'texMathZone'
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
