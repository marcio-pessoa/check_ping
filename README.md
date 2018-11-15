# check_ping

O check_ping.sh é um script escrito em bash e é usado como substituto para o 
plugin oficial do Nagios check_ping. A diferença entre entre este script e o 
plugin oficial é que este script fornece suporte a definição do endereço IP de 
origem, esse recurso é útil para que um host multi-homed possa chegar cada um
dos links individualmente. Dessa forma o check_ping.sh é útil para ser usado 
em equipamentos como firewalls, onde multiplos links Internet podem ser 
testados com relação ao tempo de resposta e pacotes perdidos.
