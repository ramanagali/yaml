
openssl genrsa -out gvr.key 2048
openssl req -new -key gvr.key -out gvr.csr -subj "/CN=gvr/O=eng"\n

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: gvr-csr
spec:
  groups:
  - system:authenticated
  request: $(cat myuser.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl certificate approve gvr-csr

kubectl get csr gvr-csr -o jsonpath='{.status.certificate}' | base64 --decode > gvr.crt

kubectl config set-credentials gvr --client-certificate=gvr.crt --client-key=gvr.key
