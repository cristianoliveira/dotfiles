nmap("<leader>rff", ":Ack \"\"<Left>", "[R]efactor [f]ind [f]iles")
nmap("<leader>rfe", ":cfdo %s/<C-r>///g<left><left> | update", "Refactor [f]ind [e]dit")
nmap("<leader>rfc", ":cfdo %s/<C-r>///gc<left><left><left> | update", "Refactor [f]ind [c]hange")

nmap("<leader>rr", ":%s/<C-r>///g<left><left>")
vmap("<leader>rr", ":s/<C-r>///g<left><left>")
