## TLS with http echo

kubectl run foo --image hashicorp/http-echo -- --text="<h1>Foo</h1>"
kubectl run bar --image hashicorp/http-echo -- --text="<h1>Bar</h1>"
kubectl expose po foo --name foo-svc --port 5678 
kubectl expose po bar --name bar-svc --port 5678 
kubectl expose po foo --name foo-svc-https --type NodePort --port=443 --target-port=5678 --protocol TCP 
<!-- foo-svc-https.default.svc.cluster.local -->

cat <<EOF | cfssl genkey - | cfssljson -bare server
{
  "hosts": [
    "foo-svc-https",
    "foo-svc-https.default.svc",
    "foo-svc-https.default.svc.cluster.local",
    "192.168.56.10",
    "10.96.0.0"
  ],
  "CN": "system:node:foo-svc-https.default.pod.cluster.local",
  "key": {
    "algo": "ecdsa",
    "size": 256
  },
  "names": [
    {
      "O": "system:nodes"
    }
  ]
}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: foo-svc-https.default
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl certificate approve foo-svc-https.default
kubectl get csr foo-svc-https.default -o jsonpath='{.status.certificate}' | base64 --decode > server.crt
kubectl create secret tls foo-secret --cert server.crt --key server-key.pem

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: foo
spec:
  selector:
    matchLabels:
      app: foo
  template:
    metadata:
      labels:
        app: foo
    spec:
      containers:
        - name: foo
          imagePullPolicy: Always
          image: hashicorp/http-echo
          args: ["--text=<h1>Foo</h1>"]
          volumeMounts:
            - mountPath: /etc/foo/ssl
              name: secret-volume
      volumes:
        - name: secret-volume
          secret:
            secretName: foo-secret
---
apiVersion: v1
kind: Service
metadata:
  name: foo-svc-https
  labels:
    run: foo-svc-https
spec:
  type: ClusterIP
  ports:
    - port: 443
      targetPort: 5678
      protocol: TCP
      name: https
  selector:
    run: foo
EOF

printenv | grep FOO
echo "$FOO_SVC_HTTPS_SERVICE_HOST foo-svc-https" >> /etc/hosts

curl --cacert /etc/foo/ssl/tls.crt https://foo-svc-https.default.svc.cluster.local 
curl --cacert /etc/foo/ssl/tls.crt foo-svc-https:443