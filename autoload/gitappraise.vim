function! gitappraise#enable()
  let resolved = 0
  if exists('g:AppraiseResolved')
    let resolved = g:AppraiseResolved
  endif

  call gitappraise#disable()

  try
    let s:review = json_decode(system("git appraise show -json"))
  catch
    return
  endtry

  if resolved == 0 && s:review.resolved == 0
    return
  endif

  if !exists("s:signs")
    let s:signs = []
  endif

  if !has_key(s:review, 'comments')
    return
  endif

  for signid in s:signs
      exe 'sign unplace ' . signid
  endfor
  let s:signs = []

  call setqflist([])

  let signID = 90000
  for c in s:review.comments
    if resolved == 0 && get(c.comment,'resolved',0)
      continue
    endif

    let startLine = 1
    if has_key(c.comment.location, 'range') && has_key(c.comment.location.range, 'startLine')
      let startLine = c.comment.location.range.startLine
    endif

    let comm = gitappraise#fmt_comment(c)
    let output = printf("%s:%d: %s", c.comment.location.path, startLine, comm)
    caddexpr output

    let endLine = startLine
    if has_key(c.comment.location, 'range') && has_key(c.comment.location.range, 'endLine')
      let endLine = c.comment.location.range.endLine
    endif
    while startLine <= endLine
      let s:signs += [signID]
      if get(c.comment,'resolved',0)
        exe 'sign place ' . signID . ' name=appraiseResolvedComment line=' . startLine . ' file=' . c.comment.location.path
      else
        exe 'sign place ' . signID . ' name=appraiseComment line=' . startLine . ' file=' . c.comment.location.path
      endif
      let startLine += 1
      let signID += 1
    endwhile
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
  if exists('s:signs')
    for signid in s:signs
        exe 'sign unplace ' . signid
    endfor
    unlet s:signs
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
  let resolved = 0
  if exists('g:AppraiseResolved')
    let resolved = g:AppraiseResolved
  endif

  if resolved == 0 && s:review.resolved == 0
    return
  endif

  let l = line('.')
  let found = 0
  let lastMessage = ''
  for c in s:review.comments
    if resolved == 0 && get(c.comment,'resolved',0)
      continue
    endif
    if !has_key(c.comment.location, 'range') || !has_key(c.comment.location.range, 'startLine')
      let lastMessage = gitappraise#fmt_comment(c)
      let found += 1
      continue
    endif
    let startLine = c.comment.location.range.startLine
    let endLine = startLine
    if has_key(c.comment.location.range, 'endLine')
      let endLine = c.comment.location.range.endLine
    endif
    if startLine <= l && l <= endLine
      let lastMessage = gitappraise#fmt_comment(c)
      let found += 1
    endif
  endfor
  if found != 0
    echo lastMessage
    redraw
  endif
  if found == 0
    echo
    redraw
  endif
endfunction

function! gitappraise#fmt_comment(c)
      let date = strftime("%Y/%m/%d %H:%M:%S", a:c.comment.timestamp)
      let resolved = ''
      if get(a:c.comment,'resolved',0)
        let resolved = ' (resolved)'
      endif

      return date . ' ' . a:c.comment.author . ' ' . a:c.comment.description . resolved
endfunction
