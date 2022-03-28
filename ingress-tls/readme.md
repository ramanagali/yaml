
k run caddy --image caddy
k expose po caddy --name caddy-svc --port 80

openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls.key -out tls.crt -subj "/CN=learnwithgvr.com" -days 365
k create secret tls sec-gvr --cert tls.crt --key tls.key