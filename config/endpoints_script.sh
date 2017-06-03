#ip_List=$(curl -s  192.168.1.150:8080/api/v1/namespaces/default/endpoints/nginx-1 |  jq  --arg kind Pod '.subsets[] |select(.addresses[].targetRef.kind == $kind).addresses[].ip ' |sort |uniq )
#port_List=$(curl -s  192.168.1.150:8080/api/v1/namespaces/default/endpoints/nginx-1 |  jq '.subsets[].ports[].port' )
#protocol_List=$(curl -s  192.168.1.150:8080/api/v1/namespaces/default/endpoints/nginx-1 |  jq '.subsets[].ports[].protocol' )

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}
trap cleanup SIGINT SIGTERM

KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)

while [ 1 ]
do
 sleep 3
 IPS=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN"  https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/default/endpoints/nginx-1 |  jq  --arg kind Pod '.subsets[] |select(.addresses[].targetRef.kind == $kind).addresses[].ip ' |sort |uniq )
 PORTS=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN"  https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/default/endpoints/nginx-1 |  jq '.subsets[].ports[].port' )
 #PORTS="81 443"
 svc="nginx-1"
 #IPS="192.168.1.12 192.168.33"
 echo $IPS
 echo ""
 echo $PORTS
 echo ""

 cat /config/haproxy.tmpl > /config/test.cfg
 echo -e "\n" >>/config/test.cfg

 for port in $PORTS; do
   echo -e  "frontend front_"$svc"_$port\n    bind *:$port\n    mode tcp\n    default_backend backend_"$svc"_$port\n " >> /config/test.cfg
   echo -e  "backend backend_"$svc"_$port\n    mode tcp\n    balance roundrobin  " >> /config/test.cfg
   for ip in $IPS; do
     echo -e  "    server $ip \t $ip:$port \t inter 1s fastinter 1s check " >> /config/test.cfg
   done
   echo -e " \n" >> /config/test.cfg
 done

diff -q /config/test.cfg /config/haproxy.cfg 1>/dev/null
if [[ $? == "0" ]]
then
  echo "haproxy config has NOT changed"
else
  echo "haproxy config has changed"
  cp /config/test.cfg /config/haproxy.cfg
  #haproxy -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/run/haproxy.sock
  haproxy  -W -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/run/haproxy.sock
fi



 ##reload haproxy
 #   ./haproxy -f /etc/hapee-1.7/hapee-lb.cfg -p /run/hapee-1.7-lb.pid -x /var/run/hapee-lb.sock

done
