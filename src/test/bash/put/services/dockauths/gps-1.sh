# Adds a service
source `dirname $0`/../../../functions.sh '' '' $*

curl $copts -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json' -H "Authorization:Basic $EXCHANGE_ORG/$EXCHANGE_USER:$EXCHANGE_PW" -d '{
  "registry": "registry.ng.bluemix.net",
  "token": "blahblah1"
}' $EXCHANGE_URL_ROOT/v1/orgs/$EXCHANGE_ORG/services/bluehorizon.network-services-gps_1.2.3_amd64/dockauths/1 | $parse
