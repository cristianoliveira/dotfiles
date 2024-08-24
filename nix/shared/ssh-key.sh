ssh-keygen -t rsa -b 4096 -C "contato@cristianoliveira.com.br"

echo "---------------------------"
cat ~/.ssh/id_rsa.pub
echo "---------------------------"

echo "Copy and add the content above to https://github.com/settings/ssh/new"
