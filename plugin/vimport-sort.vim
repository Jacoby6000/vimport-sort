" Vim plugin file
" Language:   All
" Maintainer: Jacob Barber
" URL:        https://github.com/jacoby6000/vimport-sort
" License:    MIT
" --------------------------------------------------------------------

if exists('g:loaded_vimport_sort') || &cp
  finish
endif
let g:loaded_vimport_sort = 1

" Sort imports
function! SortImports()
  let save_cursor = getpos(".")
  let curFiletype = &filetype
  let project_package = ""

  let errs = []

  if exists('g:import_sort_settings')
    if has_key(g:import_sort_settings, "project_package")
      let project_package = copy(g:import_sort_settings["project_package"])
    endif

    if has_key(g:import_sort_settings, curFiletype)
      let obj = g:import_sort_settings[curFiletype]

      if has_key(obj, "import_prefix")
        let import_prefix = copy(obj["import_prefix"])
      else
        call add(errs, "g:import_sort_groups['".curFiletype."']['import_prefix'] not set!")
      endif

      if has_key(obj, "import_groups")
        let import_groups = copy(obj["import_groups"])
      else
        call add(errs, "g:import_sort_groups['".curFiletype."']['import_groups'] not set!")
      endif
    else
      call add(errs, "g:import_sort_groups['".curFiletype."'] not set!")
    endif
  else
    call add(errs, "g:import_sort_settings is not set.")
  endif

  if len(errs) == 0
    call s:groupImportSort(import_prefix, import_groups, project_package)
  else
    for err in errs
      echo s:errorMsg(err)
    endfor
    echo s:errorMsg("Run ':h :SortImports' for set up information.")
  endif

  call setpos('.', save_cursor)
endfunction

function! s:errorMsg(err)
  return "vimport-sort| " . a:err
endfunction

function! s:groupImportSort(prefix_in, patterns_in, project_package_in)
  let curr = 1
  let first_line = -1
  let last_line = -1
  let trailing_newlines = 0

  let prefix = a:prefix_in
  let patterns = a:patterns_in
  let project_package = a:project_package_in

  " A catch all pattern for imports which didn't match the other cases.
  let prefix = "^".prefix
  call add(patterns, '.*')

  if (project_package != "")
    call add(patterns, project_package)
  endif

  let import_groups = []
  for x in patterns
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
      for pattern in patterns
        let regex = prefix . pattern
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

function! s:sortIgnoreCase(i1, i2)
  return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunction

command! SortImports call SortImports()
