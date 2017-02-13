#!/bin/bash

source /tmp/userenv
SHAPASS=`slappasswd -s $PASSWD`

cat  > /tmp/${USERID}.ldif << EOF
dn: uid=$USERID,ou=People,dc=dlx,dc=idc,dc=ge,dc=com
uid: $USERID
cn: $USERID
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
shadowLastChange: 16610
loginShell: /bin/bash
uidNumber: $VUID
gidNumber: $GROUP
homeDirectory: /home/$USERID
gecos: $NAME,$EMPLOYEEID,$EMAIL
userPassword: $SHAPASS
employeeNumber: $EMPLOYEEID
mail: $EMAIL

EOF
echo "Displaying user information:"
cat /tmp/$USERID.ldif

#echo "Is all information correct ?"
#select yn in "Yes" "No"; do
#    case $yn in
ldapadd  -H ldaps://ldap.company.dept.domain.com -D uid=anoop,ou=People,dc=company,dc=dept,dc=domain,dc=com -W -f /tmp/${USERID}.ldif
              #if [ $? -eq 0 ]; then
              #echo "LDAP ACCOUNT CRETAED SUCCESSFULLY
        #else
              #echo "LDAP ACCOUNT CREATION FAILED"
              #fi
        #No ) exit;;
    #esac
#done
if [ $? -eq 0 ]; then
    echo "LDAP ACCOUNT CREATED SUCCESSFULLY"
else
    echo "LDAP ACCOUNT CREATION FAILED"
fi
echo " ################## PERFORMING KERBEROS TASKS -- PLEASE WAIT ####################"
#PASSWORD=${USERID}123
echo "Creating Kerberos Prinicipal"
mkdir /home/$USERID
chown -R $USERID: /home/$USERID
kadmin.local -q "addprinc        $USERID@COMPANY.DEPT.DOMAIN.COM"
kadmin.local -q "ktadd -k /home/$USERID/$USERID.keytab $USERID@COMPANY.DEPT.DOMAIN.COM"
chmod a+r /home/$USERID/$USERID.keytab
klist -kte /home/$USERID/$USERID.keytab
kinit -kt /home/$USERID/$USERID.keytab $USERID@COMPANY.DEPT.DOMAIN.COM
klist
echo -n  "CREATING HDFC HOME DIRECTORY AND SETTING SPAE QUOTA FOR USER"
kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs@COMPANY.DEPT.DOMAIN.COM
hdfs dfs -mkdir -p /user/$USERID
hdfs dfs -chmod 770 /user/$USERID
hdfs dfs -chown $USERID:$USERID /user/$USERID
hdfs dfs -setSpaceQuota 5g /user/$USERID
#if [ $? -eq 0 ]; then
#    echo "ALL KERBEROS TASKS PERFORMED SUCCESSFULLY
#else
#    echo "KERBEROS TASKS FAILED"
#fi

echo "    #####     ADDING USER INTO LDAP GROUP ###########"
echo "    #####     PLEASE WAIT ###############"

cat  > /tmp/${GROUPNAME}.ldif << EOF
dn: cn=$GROUPNAME,ou=Group,dc=company,dc=dept,dc=domain,dc=com
changetype: modify
add: member
member: uid=$USERID,ou=People,dc=company,dc=dept,dc=domain,dc=com

EOF
echo "######### ADDING MEMBERID TO GROUP"
ldapmodify  -H ldaps://ldap.company.dept.domain.com -D uid=anoop,ou=People,dc=company,dc=dept,dc=domain,dc=com -W -f /tmp/${GROUPNAME}.ldif

cat  > /tmp/${GROUPNAME}1.ldif << EOF
dn: cn=$GROUPNAME,ou=Group,dc=company,dc=dept,dc=domain,dc=com
changetype: modify
add: memberUid
memberUid: $USERID

EOF

echo "######### ADDING MEMBERUID TO GROUP"

ldapmodify  -H ldaps://ldap.company.dept.domain.com -D uid=anoop,ou=People,dc=company,dc=dept,dc=domain,dc=com -W -f /tmp/${GROUPNAME}1.ldif
