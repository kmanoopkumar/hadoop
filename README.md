# hadoop
A script for creating users in LDAP, in a Kerberos enabled hadoop cluster. The script accepts user information from the file  /tmp/userenv. 
The script performs the following operations:
 1. It creates the user in  LDAP.
 2. Creates  Kerberos  principal in KDC and the users keytab and then generates the ticket using the keytab.
 3. Creates the users home directory, sets 5G space quota and changes the owner and group with the userame and group respectively.
 4. Adds the user to the LDAP group and the memberuid to the group.
