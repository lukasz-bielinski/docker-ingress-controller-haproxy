echo "https://github.com/lukasz-bielinski/docker-ingress-controller-haproxy"
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
CONFIGURATION_TYPE="${CONFIGURATION_TYPE:-dynamic}"


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

haproxy  -W -D -f /config/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/run/haproxy.sock


if [ $CONFIGURATION_TYPE == static ]; then
  echo "executing haproxy with static_endpoints"
  static_endpoints
fi

if [ $CONFIGURATION_TYPE == dynamic ]; then
  echo "executing haproxy with dynamic_endpoints"
  KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
  dynamic_endpoints
fi

if [ $CONFIGURATION_TYPE == static_galera ]; then
  echo "executing haproxy with static_galera"
  static_endpoints_galera
fi
