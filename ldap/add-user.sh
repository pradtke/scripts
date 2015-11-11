#!/bin/bash
# Simple script for adding users to Simple AD using standard ldap tools, rather than having to join the domain and use Samba tooling.
# Example usage:
#    add-user.sh  -b 'dc=corp,dc=example,dc=com' -h 192.168.0.195 -w 'AdminPassword' -f Homer -l Simpson -p 'UserPassword' -u 'hsimpson'
#
# Don't run this on a shared server - the passwords are leaked on the command lines.
#
# Users created with this command can change their passwords with `smbpassword`. This doesn't require the host to be domain joined. Example
#     smbpasswd -r 192.168.0.195 -U hsimpson
#
while getopts "f:l:w:b:p:u:h:m:" opt; do
  case $opt in
    b)
      BASE_DN=$OPTARG
      ;;
    f)
      FIRST=$OPTARG
      ;;
    l)
      LAST=$OPTARG
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
# User attributes
PASSWORD=${PASSWORD:?"Need PASSWORD for user"}
USERNAME=${USERNAME:?"Need USERNAME for user"}
FIRST=${FIRST:?"Need FIRST name"}
LAST=${LAST:?"Need LAST name for user"}
MAIL=$USERNAME@cirrusidentity.com
CN="$FIRST $LAST"
#Simple AD wants passwords in AD format
P_ENCODED=$(echo -n "\"$PASSWORD\"" | iconv -f UTF8 -t UTF16LE | base64 -w 0)
echo "dn: CN=$CN,CN=Users,$BASE_DN
objectClass: top
objectClass: organizationalPerson
objectClass: user
objectClass: posixAccount
objectClass: inetOrgPerson
cn: $CN
instanceType: 4
name: $CN
userAccountControl: 512
sAMAccountName: $USERNAME
uid: $USERNAME
homeDirectory: /home/$USERNAME
givenname: $FIRST
sn: $LAST
mail: $MAIL
objectCategory: CN=Person,CN=Schema,CN=Configuration,$BASE_DN
distinguishedName: CN=$CN,CN=Users,$BASE_DN
unicodePwd:: $P_ENCODED" | \
ldapadd -h $HOST -p 389 -x -D "CN=Administrator,CN=Users,$BASE_DN" -w $ADMIN_PASS || exit $?
