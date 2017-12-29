cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}
trap cleanup SIGINT SIGTERM

while [ 1 ]
do
  sleep 30
  echo date


done
