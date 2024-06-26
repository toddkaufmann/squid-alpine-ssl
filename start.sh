#!/bin/sh

set -e

CHOWN=$(/usr/bin/which chown)
SQUID=$(/usr/bin/which squid)

prepare_folders() {
	echo "Preparing folders..."
	mkdir -p /etc/squid-cert/
	mkdir -p /var/cache/squid/
	mkdir -p /var/log/squid/
	"$CHOWN" -R squid:squid /etc/squid-cert/
	"$CHOWN" -R squid:squid /var/cache/squid/
	"$CHOWN" -R squid:squid /var/log/squid/
}

initialize_cache() {
	echo "Creating cache folder..."
	if "$SQUID" -z; then
	    echo ' ... success'
	else
	    echo "  ... FAIL to create cache, $?"
	fi
	sleep 5
}

create_cert() {
	if [ ! -f /etc/squid-cert/private.pem ]; then
		echo "Creating certificate..."
		openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
			-extensions v3_ca -keyout /etc/squid-cert/private.pem \
			-out /etc/squid-cert/private.pem \
			-subj "/CN=$CN/O=$O/OU=$OU/C=$C" -utf8 -nameopt multiline,utf8

		openssl x509 -in /etc/squid-cert/private.pem \
			-outform DER -out /etc/squid-cert/CA.der

		openssl x509 -inform DER -in /etc/squid-cert/CA.der \
			-out /etc/squid-cert/CA.pem
	else
		echo "Certificate found..."
	fi
}

clear_certs_db() {
	echo "Clearing generated certificate db..."
	rm -rfv /var/lib/ssl_db/
	/usr/lib/squid/ssl_crtd -c -s /var/lib/ssl_db
	"$CHOWN" -R squid.squid /var/lib/ssl_db
}

run() {
	echo "Starting squid..."
	prepare_folders
	create_cert
	# ssl_crtd DNE
	# clear_certs_db
	initialize_cache
	# exec "$SQUID" -NYCd 1 -f /etc/squid/squid.conf
	for tries in 1 1 20 30 40 5; do 
	    if "$SQUID" -NYCd 1 -f /etc/squid/squid.conf; then
		echo ============================================
		echo "Normal exit  ?"
		sleep $tries
	    else
		sq_st=$?
		echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
		echo "ABNORMAL exit - status $sq_st, try again in a bit"
		sleep $(echo "$tries * 10" | bc)
	    fi
	    echo One more time ...
	done
}

run
