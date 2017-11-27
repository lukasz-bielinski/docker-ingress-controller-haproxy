# docker-ingress-controller-haproxy
Purpose of this project is to expose k8s service without using internal k8s load balancer.
How it works

1) expose k8s service on vip and not use internal k8s lb
2) create haproxy lb on vip with k8s service
3) put dynamically pods ips as haproxy backend

i am using k8s service for retrieving pods ip, as i wanted to be sure that pods are in proper state. 
whole is inspired by gce lb/f5 plugin for openshift
