#!/bin/bash

if [ "${USER:-}" != 'root' ]; then
  echo "Please run as root; sudo ${0} ${*}" &> /dev/stderr
  exit 1
fi

install_java()
{
  wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
  add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
  apt install -qq -y adoptopenjdk-11-hotspot
}

install_scala()
{
  if [ ! -s scala-2.13.1.deb ]; then
    wget https://downloads.lightbend.com/scala/2.13.1/scala-2.13.1.deb
  fi
  dpkg -i scala-2.13.1.deb
}

install_sbt()
{
  echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
  curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
  apt-get update
  apt-get install sbt
}

install_postgresql()
{
  local ipaddr=${1:-null}

  if [ -z "$(command -v psql)" ]; then
    echo 'Installing postgresql' &> /dev/stderr
    apt install -qq -y postgresql
  else
    echo 'PostgreSQL already installed' &> /dev/stderr
  fi
  if [ "${ipaddr:-null}" != 'null' ]; then
    if [ -d "/etc/postgresql/10/main/" ]; then
      echo "Updating access controls for ${ipaddr}" &> /dev/stderr
      echo "host all all ${ipaddr}/32 trust" >> /etc/postgresql/10/main/pg_hba.conf
      sed -i -e "s/^#listen_addresses.*/listen_addresses = '${ipaddr}'/" /etc/postgresql/10/main/postgresql.conf
      systemctl restart postgresql
    else
      echo 'No directory: ${dir}; manually update "pg_hba.conf" and "postgresql.conf"' &> /dev/stderr
    fi
  else
    echo 'No IP address provided; skipping access control' &> /dev/stderr
  fi
}

exchange_config()
{
  local root_password=${1:-password}
  local username=${2:-username}
  local password=${3:-}
  local log_level=${4:-DEBUG}

  echo '{"api":{"db":{"jdbcUrl":"jdbc:postgresql://localhost/postgres","user":"'${username}'","password":"'${password}'"},"logging":{"level":"'${log_level}'"},"root":{"password":"'${root_password}'"}}}' > /etc/horizon/exchange/config.json
}

exchange_keys()
{
  local root_password=${1:-${EXCHANGE_ROOTPW}}

  EXCHANGE_KEY_PW=${root_password} make key-gen
}

###
### MAIN
###

install_java

install_scala

install_sbt

install_postgresql $(hostname -I | awk '{ print $1 }')

exchange_config ${1:-${EXCHANGE_ROOTPW:-password}}
