#! /bin/bash

if [[ ! -f /root/.gnupg/gpg.conf ]]; then
  /opt/gpg.conf.sh
fi

# If the repository GPG keypair doesn't exist, create it.
if [[ ! -f /opt/aptly/aptly.sec ]] || [[ ! -f /opt/aptly/aptly.pub ]]; then
  echo "Generating new gpg keys"
  cp -a /dev/urandom /dev/random
  /opt/gpg_batch.sh
  # If your system doesn't have a lot of entropy this may, take a long time
  # Google how-to create "artificial" entropy if this gets stuck
  gpg --batch --gen-key /opt/gpg_batch
else
  echo "No need to generate new gpg keys"
fi

# Export the GPG Public key
if [[ ! -f /opt/aptly/public/aptly_repo_signing.key ]]; then
  mkdir -p /opt/aptly/public
  gpg --export --armor > /opt/aptly/public/aptly_repo_signing.key
fi

# Import Ubuntu keyrings if they exist
if [[ -f /usr/share/keyrings/ubuntu-archive-keyring.gpg ]]; then
  gpg --list-keys
  gpg --no-default-keyring                                     \
      --keyring /usr/share/keyrings/ubuntu-archive-keyring.gpg \
      --export |                                               \
  gpg --no-default-keyring                                     \
      --keyring trustedkeys.gpg                                \
      --import
fi

# Import Debian keyrings if they exist
if [[ -f /usr/share/keyrings/debian-archive-keyring.gpg ]]; then
  gpg --list-keys
  gpg --no-default-keyring                                     \
      --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
      --export |                                               \
  gpg --no-default-keyring                                     \
      --keyring trustedkeys.gpg                                \
      --import
fi

# Aptly looks in /root/.gnupg for default keyrings
ln -sf /root/.gnupg/secring.gpg /opt/aptly/aptly.sec
ln -sf /root/.gnupg/pubring.gpg /opt/aptly/aptly.pub 

# Generate Nginx Config
/opt/nginx.conf.sh

# Start Supervisor
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
