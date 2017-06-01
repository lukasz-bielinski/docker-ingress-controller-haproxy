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
 sleep 30
 echo date


done
