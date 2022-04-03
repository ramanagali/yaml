# distroless image
kubectl run web --image kyos0109/nginx-distroless


#1. Debugging a Pod with ephc

kubectl run pod1 --image=pause:3.6 --restart=Never
kubectl debug -it pod1 --image=busybox --target=pod1


#2. Debugging with copy of Pod

kubectl run pod2 --image=busybox --restart=Never -- sleep 1d
kubectl debug pod2 -it --image=ubuntu --share-process --copy-to=pod2-debug --container=pod2-debug-c


#3. Copy a Pod - change its command

kubectl run pod3 --image=busybox -- false
kubectl debug pod3 -it --copy-to=pod3-debug --container=app3 -- sh 


#4. Copy a Pod - change its image
kubectl run pod4 --image=busybox --restart=Never -- sleep 1d
kubectl debug pod4 -it --copy-to=pod4-debug --set-image=*=ubuntu


#5. Debug a node 
kubectl debug node/node01 -it --image=ubuntu


