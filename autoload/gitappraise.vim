function! gitappraise#enable()
  call gitappraise#disable()

  try
    let s:review = json_decode(system("git appraise show -json"))
  catch
    return
  endtry
  if !has_key(s:review, 'comments')
    return
  endif
  for c in s:review.comments
    if !has_key(c.comment.location, 'range') || !has_key(c.comment.location.range, 'startLine')
      continue
    endif
    let startLine = c.comment.location.range.startLine
    let endLine = startLine
    if has_key(c.comment.location.range, 'endLine')
      let endLine = c.comment.location.range.endLine
    endif
    call matchadd('GitAppraise', '\%' . startLine . 'l')
  endfor
  augroup GitAppraise
    au!
    au CursorMoved,CursorMovedI <buffer> call gitappraise#show_comment()
  augroup END
endfunction

function! gitappraise#disable()
  augroup GitAppraise
    au!
  augroup END
  if exists('s:review')
    unlet s:review
  endif
endfunction

function! gitappraise#add_comment()
  if !exists('s:review')
    return
  endif
  let msg = input('Message: ')
  if empty(msg)
    return
  endif
  call system(printf("git appraise comment -m %s -f %s -l %d %s",
  \ shellescape(msg),
  \ shellescape(substitute(expand('%'), '\\', '/', 'g')),
  \ line('.'),
  \ shellescape(s:review.revision)))
  call gitappraise#enable()
endfunction

function! gitappraise#show_comment()
  if !exists('s:review')
    return
  endif
  let l = line('.')
  let found = 0
  for c in s:review.comments
    if !has_key(c.comment.location, 'range') || !has_key(c.comment.location.range, 'startLine')
      continue
    endif
    let startLine = c.comment.location.range.startLine
    let endLine = startLine
    if has_key(c.comment.location.range, 'endLine')
      let endLine = c.comment.location.range.endLine
    endif
    if startLine <= l && l <= endLine
      if found == 0
        redraw
      endif
      echo strftime("%Y/%m/%d %H:%M:%S", c.comment.timestamp) . ' ' . c.comment.description
      let found += 1
    endif
  endfor
  if found == 0
    echo
    redraw
  endif
endfunction
