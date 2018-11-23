" Find the related spec for any file you open.
function! s:RelatedSpec()
  let l:fullpath = expand("%:p")
  let l:filepath = expand("%:h")
  let l:fname = expand("%:t")
  let l:filepath_without_app = substitute(l:filepath, "app/", "", "")
  let l:filepath_without_app = substitute(l:filepath_without_app, "assets/", "", "")

  " Possible names for the spec/test for the file we're looking at
  let l:test_names = [substitute(l:fname, ".js$", ".spec.js", "")]

  " Possible paths
  let l:test_paths = ["spec", "fast_spec", "test", ""]

  for test_name in l:test_names
    for path in l:test_paths
      let l:spec_path = path . "/" . l:filepath_without_app . "/" . test_name
      let l:full_spec_path = substitute(l:fullpath, l:filepath . "/" . l:fname, l:spec_path, "")
      if filereadable(l:spec_path)
        return l:full_spec_path
      end
    endfor

    let l:spec_path = l:filepath_without_app . "/" . test_name
    let l:full_spec_path = substitute(l:fullpath, l:filepath . "/" . l:fname, l:spec_path, "")
    return l:full_spec_path
  endfor
endfunction

" Find the file being tested when looking at a spec
function! s:FileRelatedToSpec()
  let l:fullpath = expand("%:p")
  let l:filepath = expand("%:h")
  let l:fname = expand("%:t")

  let l:related_file = substitute(l:filepath, "fast_spec/", "", "")
  let l:related_file = substitute(l:related_file, "spec/", "", "")

  let l:related_file_names = [substitute(l:fname, ".spec.js$", ".js", "")]

  for related_file_name in l:related_file_names
    let l:full_file_path = substitute(l:fullpath, l:filepath . "/" . l:fname, "" . l:related_file . "/" . related_file_name, "")
    if filereadable(l:full_file_path)
      return l:full_file_path
    end
  endfor
endfunction

" If looking at a regular file, find the related spec
" If looking at a spec, find the related file
function! s:RelatedSpecOrFile()
  let l:fname = expand("%:t")
  if match(l:fname, ".spec") != -1
    let l:result = s:FileRelatedToSpec()
  else
    let l:result = s:RelatedSpec()
  endif
return l:result
endfunction

function! s:SpecRelativeOpen()
  let l:spec_path = s:RelatedSpecOrFile()
  echo l:spec_path
  execute ":e " . l:spec_path
endfunction

function! s:SpecRelativeOpenSplit()
  let l:spec_path = s:RelatedSpecOrFile()
  execute ":botright vsp " . l:spec_path
endfunction

command! SpecRelativeOpenSplit call s:SpecRelativeOpenSplit()
command! SpecRelativeOpen call s:SpecRelativeOpen()

nnoremap <silent> <leader>sr :SpecRelativeOpenSplit<CR>
nnoremap <silent> <leader>so :SpecRelativeOpen<CR>
