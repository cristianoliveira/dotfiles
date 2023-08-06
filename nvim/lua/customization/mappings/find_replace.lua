nmap("<leader>rfe", ":cfdo %s/<C-r>///g<left><left> | update")
nmap("<leader>rfc", ":cfdo %s/<C-r>///gc<left><left><left> | update")
nmap("<leader>rfd", ":cfdo %s/<C-r>//<C-r>\"/gc | update")

nmap("<leader>rr", ":%s/<C-r>///g<left><left>")
vmap("<leader>rr", ":s/<C-r>///g<left><left>")
