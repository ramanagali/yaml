kubeadm certs check-expiration

# step1: create server cert
cat <<EOF | cfssl genkey - | cfssljson -bare server
{
    "hosts": [
        "hello-world-svc",
        "hello-world-svc.default.svc",
        "hello-world-svc.default.svc.cluster.local",
        "10.98.46.237",
        "192.168.87.218"
    ],
    "CN": "hello-world-svc.default.svc.cluster.local",
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOF

#step2: create csr
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: hello-world-svc.default
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: learnwithgvr.io/serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

# approve it
kubectl certificate approve hello-world-svc.default

##step3: create CA
cat <<EOF | cfssl gencert -initca - | cfssljson -bare ca
{
  "CN": "Learn with GVR",
  "key": {
    "algo": "rsa",
    "size": 2048
  }
}
EOF

##step4: sign the certificate of step1
kubectl get csr hello-world-svc.default -o jsonpath='{.spec.request}' | base64 --decode | \
  cfssl sign -ca ca.pem -ca-key ca-key.pem -config sign-config.json - | \
  cfssljson -bare ca-signed-server

##step5: upload the signed certificate step4 - ca-signed-server.pem
kubectl get csr hello-world-svc.default -o json | \
  jq '.status.certificate = "'$(base64 ca-signed-server.pem | tr -d '\n')'"'

kubectl get csr hello-world-csr -o json | \
  jq '.status.certificate = "'$(base64 ca-signed-server.pem | tr -d '\n')'"' | \
  kubectl replace --raw /apis/certificates.k8s.io/v1/certificatesigningrequests/hello-world-svc.default/status -f -

## step6: Download the cert
kubectl get csr hello-world-svc.default -o jsonpath='{.status.certificate}' | base64 --decode > server.crt

## step7: create hello-world secret (with signed cert)
kubectl create secret tls hw-server --cert server.crt --key server-key.pem

## step8: create gvr-serving-ca
kubectl create configmap gvr-serving-ca --from-file ca.crt=ca.pem

# ref
https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/
https://serverfault.com/questions/9708/what-is-a-pem-file-and-how-does-it-differ-from-other-openssl-generated-key-file