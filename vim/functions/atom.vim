fun! GitPullRefresh()
  set noconfirm
  !git pull
  bufdo e!
  set confirm
endfun

nmap <leader>gr call GitPullRefresh()

" Refactor helper for making a old function into a arrow function
nmap <leader>rf dwlli => <ESC>

function! s:open_atom(file)
  if get(g:, 'open_atom_silent_simojo_atom', 1)
    redraw!
    echo "Vimmerウルルン滞在記: Vim が... Atom に... 出合った..."
    echo ""
    echo "                     #    #                                                    "
    echo "###############      #    #                                                    "
    echo "      #             #    ######                        #                       "
    echo "      #             #    #   #      #    #####          #              #       "
    echo "      #            ## # # # #        ####    #          #               #      "
    echo "      #           # # #    #                #           #               #      "
    echo "      #  #       #  # #  ## ##          #  #            #               #      "
    echo "      #   #         # ###  #  ##         ##             ###            #       "
    echo "      #    #        # #    #             #              #  ##          #       "
    echo "      #     #       # # #######          #              #    #         #  #    "
    echo "      #     #       # #    #             #              #             #    #   "
    echo "      #             # #  # # #          #               #             #    ##  "
    echo "      #             # # #  #  #         #               #          # #  ###  # "
    echo "      #             #  #   #   #       #                #           ####     # "
    echo "      #             #    # #          #                 #                      "
    echo "      #             #     #                                                    "
  endif
  let f = len(a:file) > 0 ? fnamemodify(a:file, ':p') : expand('%:p')
  if has("win32") || has("win64")
    silent exec "!start cmd /c call atom " . shellescape(f)
  else
    silent exec "!atom " . shellescape(f) " &"
  endif
endfunction

command! -nargs=? -complete=file OpenAtom call s:open_atom(<q-args>)

