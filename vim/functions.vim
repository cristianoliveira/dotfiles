fun! GitPullRefresh()
  set noconfirm
  !git pull
  bufdo e!
  set confirm
endfun

nmap <leader>gr call GitPullRefresh()
