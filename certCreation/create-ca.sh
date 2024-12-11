openssl req -new -x509 -keyout ca.key -out ca.crt -days 365 \
   -subj '/CN=ca.kafka.cluster/OU=TEST/O=junaud/L=STOCKHOLM/C=SWE' \
   -passin pass:changeit -passout pass:changeit

openssl req -new -x509 -keyout client-ca.key -out client-ca.crt -days 365 \
   -subj '/CN=ca.kafka.client/OU=TEST/O=junaud/L=STOCKHOLM/C=SWE' \
   -passin pass:changeit -passout pass:changeit
