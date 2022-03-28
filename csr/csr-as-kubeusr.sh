# create cert keys
openssl genrsa -out venkat.key 2048

# gen csr
openssl req -new -key venkat.key -out venkat.csr -subj "/CN=venkat/O=eng"\n

# openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls.key -out tls.crt -subj "/CN=learnwithgvr.com" -days 365
# openssl req -x509 -new -nodes -keyout tls-ingress.key -out tls-ingress.crt -subj "/CN=learnwithgvr.com" -days 365

# raise CSR
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: dev-csr
spec:
  request: $(cat venkat.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

# approve csr
kubectl get csr
kubectl certificate approve venkat

# download approved cert
kubectl get csr venkat -o yaml
kubectl get csr venkat -o jsonpath='{.status.certificate}'| base64 -d > venkat-usr.crt

#create role & rolebidning for venkat
kubectl create role developer --verb=create --verb=get --verb=list --verb=update --verb=delete --resource=pods
kubectl create rolebinding developer-binding-venkat --role=developer --user=venkat


#kubeconfig venkat
kubectl config set-credentials venkat --client-key=venkat.key --client-certificate=venkat-usr.crt --embed-certs=true
kubectl config set-context venkat --cluster=kubernetes --user=venkat
kubectl config use-context venkat
