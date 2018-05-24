" Vim plugin file
" Language:   All
" Maintainer: Jacob Barber
" URL:        https://github.com/jacoby6000/vimport-sort
" License:    MI
" --------------------------------------------------------------------

if exists('g:loaded_vimport_sort') || &cp
  finish
endif
let g:loaded_vimport_sort = 1

" Sort imports
function! SortImports()
  let save_cursor = getpos(".")
  let curFiletype = &filetype

  if exists('g:import_sort_groups')
    if has_key(g:import_sort_groups, curFiletype)
      let sort_group_patterns = copy(g:import_sort_groups)
    else
      echoerr ("Vimport-sort| g:import_sort_groups[".curFiletype."] not set! Run ':h :SortImports' for set up information.")
    endif
  else
    echoerr "Vimport-sort| g:import_sort_groups not set! Run ':h :SortImports' for set up information."
    return
  endif

  if exists('g:import_sort_groups')
    let import_prefix = copy(g:import_prefix)
  else
    echoerr "Vimport-sort| g:import_sort_groups not set! Run ':h :SortImports' for set up information."
    return
  endif

  call s:groupImportSort(import_prefix, sort_group_patterns)

  call setpos('.', save_cursor)
endfunction

function! s:groupImportSort(prefix, patterns)
  let curr = 1
  let first_line = -1
  let last_line = -1
  let trailing_newlines = 0

  " A catch all pattern for imports which didn't match the other cases.
  call add(sort_group_patterns, '.*')

  let import_groups = []
  for x in sort_group_patterns
    call add(import_groups, [])
  endfor

  " loop over lines in buffer
  while curr <= line('$')

    let line = getline(curr)

    if line =~ prefix
      if first_line == -1
        let first_line = curr
      endif

      let iterator = 0
      for sort_group_pattern in sort_group_patterns
        let regex = prefix.' '.sort_group_pattern
        if line =~ regex
          call add(import_groups[iterator], line)
          let iterator += 1
          break
        endif

        let iterator += 1
      endfor

      let trailing_newlines = 0
    elseif empty(line)
      let trailing_newlines = trailing_newlines + 1
    elseif first_line != -1
      let last_line = curr - trailing_newlines - 1
      " break out when you have found the first non-import, non-empty line
      break
    endif

    let curr = curr + 1
  endwhile

  call cursor(first_line, 0)
  let to_delete = last_line - first_line

  if to_delete > 0
    execute 'd'to_delete
  endif

  for lines in reverse(import_groups)
    call s:sortAndPrint(lines)
  endfor

  if first_line != -1
    " remove extra blank line at top
    execute 'delete'
  endif

  call cursor(last_line + 2, 0)
  if empty(getline(line(".")))
    execute 'delete'
  endif

endfunction

function! s:sortAndPrint(imports)
  if len(a:imports) > 0
    call sort(a:imports, "s:sortIgnoreCase")
    call append(line("."), "")
    call append(line("."), a:imports)
  endif
endfunction

" this useless function exists purely so the sort() ignores case
" this is needed so scalaz/Scalaz appears next to each other
function! s:sortIgnoreCase(i1, i2)
  return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunction

command! SortScalaImports call SortScalaImports()
