#!/bin/bash
# Simple script for adding Service to Simple AD using standard ldap tools, rather than having to join the domain and use Samba tooling.
# Example usage:
#    add-service-account.sh  -b 'dc=corp,dc=example,dc=com' -h 192.168.0.195 -w 'AdminPassword' -p 'ServicePassword' -u 'my-service-name'
#
# Don't run this on a shared server - the passwords are leaked on the command lines.
#
# You probably need to create the services tree before your first run.
#
# ldapadd  -h 192.168.0.195 -p 389 -x -D CN=Administrator,CN=Users,dc=corp,dc=example,dc=com -w password
# dn: CN=Services,dc=corp,dc=example,dc=com
# objectClass: top
# objectClass: container
# cn: Services
#
while getopts "w:b:p:u:h:m:" opt; do
  case $opt in
    b)
      BASE_DN=$OPTARG
      ;;
    w)
      ADMIN_PASS=$OPTARG
      ;;
    m)
      MAIL=$OPTARG
      ;;
    p)
      PASSWORD=$OPTARG
      ;;
    u)
      USERNAME=$OPTARG
      ;;
    h)
      HOST=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

BASE_DN=${BASE_DN:?"Need BASE_DN. Example 'dc=corp,dc=example,dc=com'"}
HOST=${HOST:?"Need HOST"}
ADMIN_PASS=${ADMIN_PASS:?"Need ADMIN_PASS"}
# Account attributes
PASSWORD=${PASSWORD:?"Need PASSWORD for service account"}
USERNAME=${USERNAME:?"Need USERNAME for service account"}
CN=$USERNAME
#Simple AD wants passwords in AD format
P_ENCODED=$(echo -n "\"$PASSWORD\"" | iconv -f UTF8 -t UTF16LE | base64 -w 0)
echo "dn: CN=$CN,CN=Services,$BASE_DN
objectClass: top
objectClass: organizationalPerson
objectClass: user
objectClass: posixAccount
objectClass: inetOrgPerson
cn: $CN
instanceType: 4
name: $CN
userAccountControl: 66048
sAMAccountName: $USERNAME
uid: $USERNAME
homeDirectory: /home/$USERNAME
objectCategory: CN=Person,CN=Schema,CN=Configuration,$BASE_DN
distinguishedName: CN=$CN,CN=Services,$BASE_DN
unicodePwd:: $P_ENCODED" | \
ldapadd -h $HOST -p 389 -x -D "CN=Administrator,CN=Users,$BASE_DN" -w $ADMIN_PASS || exit $?
