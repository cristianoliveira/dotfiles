nmap("<leader>rff", ":Ack \"\"<Left>", "[R]efactor [f]ind [f]iles")

local left = "<left>"
for _ = 0, 11 do
  left = left .. "<left>"
end
nmap("<leader>rfe", ":cfdo %s/<C-r>///g | update ".. left, "Refactor [f]ind [e]dit")
nmap("<leader>rfc", ":cfdo %s/<C-r>///gc | update " .. left, "Refactor [f]ind [c]hange")

nmap("<leader>rr", ":%s/<C-r>///g<left><left>")
vmap("<leader>rr", ":s/<C-r>///g<left><left>")

nmap("<leader>rcm", ":g/<C-r>/normal ", "Refactor [f]ind [c]hange")
