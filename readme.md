helm install --set serviceType=NodePort --name wp-k8s stable/wordpress


## 1
https://github.com/GoogleCloudPlatform/gke-network-policy-demo

kubectl apply -f ./manifests/hello-app/
kubectl get pods

**without network policy**
kubectl logs --tail 10 -f $(kubectl get pods -oname -l app=hello)
kubectl logs --tail 10 -f $(kubectl get pods -oname -l app=not-hello)

**apply netpolicy**
kubectl apply -f ./manifests/network-policy.yaml

**check now?**
kubectl logs --tail 10 -f $(kubectl get pods -oname -l app=hello)
kubectl logs --tail 10 -f $(kubectl get pods -oname -l app=not-hello)

**delete and apply different netpolicy**
kubectl delete -f ./manifests/network-policy.yaml
kubectl create -f ./manifests/network-policy-namespaced.yaml

**check now hello client logs**
kubectl logs --tail 10 -f $(kubectl get pods -oname -l app=hello)

**deploy hello client in hello-apps namespace**
kubectl -n hello-apps apply -f ./manifests/hello-app/hello-client.yaml

**now it will work**
kubectl logs --tail 10 -f -n hello-apps $(kubectl get pods -o name -l app=hello -n hello-apps)

## 2 
https://github.com/networkpolicy/examples/tree/master/gettingstarted


# 3

kubectl run foo --image hashicorp/http-echo -- --text="<h1>Foo</h1>"
kubectl run bar --image hashicorp/http-echo -- --text="<h1>Bar</h1>"
kubectl expose po foo --name foo-svc --port 5678 
kubectl expose po bar --name bar-svc --port 5678 
kubectl expose po foo --name foo-svc-https --type NodePort --port=443 --target-port=5678 --protocol TCP 
<!-- foo-svc-https.default.svc.cluster.local -->
