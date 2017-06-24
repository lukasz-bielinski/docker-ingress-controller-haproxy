source /config/functions

gen_cert ${VIP}


cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}
trap cleanup SIGINT SIGTERM

INTERVAL_VRRP_SCRIPT_CHECK="${INTERVAL_VRRP_SCRIPT_CHECK:-1}"
ADVERT="${ADVERT:-1}"
PRIORITY="${PRIORITY:-100}"
STATE="${STATE:-BACKUP}"
HAPROXY_CHECK_TIMEOUT="${HAPROXY_CHECK_TIMEOUT:-1}"
STATS_PORT="${STATS_PORT:-1937}"
STATS_USER="${STATS_USER:-myUser}"
STATS_PASSWORD="${STATS_PASSWORD:-myPassword}"

echo "=> Configuring Keepalived"
sed -i -e "s/<--INTERVAL-->/${INTERVAL_VRRP_SCRIPT_CHECK}/g" /config/keepalived.conf
sed -i -e "s/<--ROUTERID-->/${ROUTERID}/g" /config/keepalived.conf
sed -i -e "s/<--VROUTERID-->/${VROUTERID}/g" /config/keepalived.conf

sed -i -e "s/<--VIP-->/${VIP}/g" /config/keepalived.conf
sed -i -e "s/<--MASK-->/${MASK}/g" /config/keepalived.conf
sed -i -e "s/<--STATE-->/${STATE}/g" /config/keepalived.conf
sed -i -e "s/<--INTERFACE-->/${INTERFACE}/g" /config/keepalived.conf
sed -i -e "s/<--PRIORITY-->/${PRIORITY}/g" /config/keepalived.conf
sed -i -e "s/<--ADVERT-->/${ADVERT}/g" /config/keepalived.conf
sed -i -e "s/<--AUTHPASS-->/${AUTHPASS}/g" /config/keepalived.conf

sed -i -e "s/<--NOTIFIEMAILTO-->/${NOTIFIEMAILTO}/g" /config/keepalived.conf
sed -i -e "s/<--NOTIFIEMAILFROM-->/${NOTIFIEMAILFROM}/g" /config/keepalived.conf
sed -i -e "s/<--SMTPSERV-->/${SMTPSERV}/g" /config/keepalived.conf

sed -i -e "s/<--VIP-->/${VIP}/g" /config/haproxy.tmpl
sed -i -e "s/<--STATS_PORT-->/${STATS_PORT}/g" /config/haproxy.tmpl
sed -i -e "s/<--STATS_USER-->/${STATS_USER}/g" /config/haproxy.tmpl
sed -i -e "s/<--STATS_PASSWORD-->/${STATS_PASSWORD}/g" /config/haproxy.tmpl

sed -i -e "s/<--VIP-->/${VIP}/g" /config/endpoints_script.sh


echo "starting keepalived"
keepalived  --log-console -f /config/keepalived.conf

KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
haproxy  -W -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/run/haproxy.sock


while [ 1 ]
do
 sleep 3
 IPS=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN"  https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/endpoints/$SERVICE |  jq  --arg kind Pod '.subsets[] |select(.addresses[].targetRef.kind == $kind).addresses[].ip ' |sort |uniq )
 PORTS=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN"  https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/endpoints/$SERVICE |  jq '.subsets[].ports[].port' )
 svc="$SERVICE"
 echo $IPS
 echo ""
 echo $PORTS
 echo ""

 cat /config/haproxy.tmpl > /config/test.cfg
 echo -e "\n" >>/config/test.cfg

 for port in $PORTS; do
   echo -e  "frontend front_"$svc"_$port\n    bind ${VIP}:$port\n    mode tcp\n    default_backend backend_"$svc"_$port\n " >> /config/test.cfg
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
  haproxy  -W -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/run/haproxy.sock
  #haproxy  -W -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf  -x /var/run/haproxy.sock
fi



 ##reload haproxy
 #   ./haproxy -f /etc/hapee-1.7/hapee-lb.cfg -p /run/hapee-1.7-lb.pid -x /var/run/hapee-lb.sock

done
