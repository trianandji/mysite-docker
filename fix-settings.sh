#!/bin/sh

SETTINGS_FILE="/var/www/html/web/sites/default/settings.php"

if [ -f "$SETTINGS_FILE" ]; then
  echo "Patching database host in settings.php..."

  # Replace existing 'host' => 'localhost' with 'db'
  sed -i "s/'host' => *'localhost'/'host' => 'db'/g" "$SETTINGS_FILE"

  # If no host line exists, insert after 'driver' line
  if ! grep -q "'host'" "$SETTINGS_FILE"; then
    sed -i "/'driver' => 'mysql',/a \  'host' => 'db'," "$SETTINGS_FILE"
  fi

else
  echo "settings.php not found at $SETTINGS_FILE"
fi

# Execute the passed command (usually apache2-foreground)
exec "$@"

