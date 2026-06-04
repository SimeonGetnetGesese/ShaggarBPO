#!/bin/bash
# Wait for Tomcat/H2 to be ready and update admin password
sleep 10

# Update admin password using H2 shell
java -cp /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/h2-*.jar org.h2.tools.Shell \
  -url "jdbc:h2:~/.teedy/db/docs" \
  -user "sa" \
  -password "" \
  << EOF
UPDATE USER SET PASSWORD = '\$2a\$10\$W4ZBJpr4utME7yyrr5zgyuFTw05drWgnYQUywS.hegt0zZaY37QN.' WHERE LOGIN = 'admin';
COMMIT;
EXIT;
EOF

echo "Admin password updated successfully"
