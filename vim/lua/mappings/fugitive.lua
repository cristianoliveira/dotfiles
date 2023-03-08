-- Open "UI" to compose commit.
nnoremap('<leader>GG', ':G<space>')
nnoremap('<leader>GF', ':G<space><space>%<left><left>')

nnoremap('<leader>git', ':G<CR>')

nnoremap('<leader>gst', ':G ss <CR>')
nnoremap('<leader>gsa', ':G sa <CR>')

nnoremap('<leader>glg', ':G l --abbrev-commit --format=\'%h -- %s [%cD by %an]\' <CR>')
nnoremap('<leader>gbm', ':G blame <CR>')

nnoremap('<leader>gcm', ':G cm<CR>')
nnoremap('<leader>gamd', ':G amd<CR>')

-- All commands below are applied to the current file.
nnoremap('<leader>gaf', ':G add % <CR>')
nnoremap('<leader>gap', ':G add % -p <CR>')
nnoremap('<leader>gch', ':G checkout % <CR>')
nnoremap('<leader>grs', ':G reset % <CR>')
