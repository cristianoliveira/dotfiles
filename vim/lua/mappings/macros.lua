-- Edit macros
nmap('<leader>q1', ':let @1="')
nmap('<leader>q2', ':let @2="')
nmap('<leader>q3', ':let @3="')

-- Paste current macro
nmap('<leader>qp', '"qp')
nmap('<leader>qq', ':let @1="<C-r><C-r>q')
