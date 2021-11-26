#!/bin/bash

msg_no_variable() {
	echo "Veuillez entrer un nom de domaine, ex : sfa.com"
}


main() {
	echo "openssl genrsa 2048 > $1.key"
	echo "openssl req -new -key $1.key > $1.csr"
	echo "cat $1.csr"
	echo "cat $1.key"
	echo "sed 's/^#//' $1.conf"
}


[[ ! -z "$1" ]] && main $1 || msg_no_variable



