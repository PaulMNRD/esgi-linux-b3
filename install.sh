#!/bin/bash

set -e

# Vérification des privilèges administratifs
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté avec des privilèges administratifs." >&2
    exit 1
fi

# Déclaration des variables globales
INSTALL_DIR="/usr/local/bin"
BACKUP_DIR="/backup/groups"

SCRIPTS=("gts_utilisateurs.sh" "gts_cron.sh" "gts_surveillance.sh" "gts_sauvegarde.sh" "gts_journalisation.sh" "gestions.sh")

RH_GROUP="__RH"
IT_GROUP="__IT"

# Copie et installation des scripts comme des commandes système
for script in "${SCRIPTS[@]}"; do
    base_name="${script%.sh}"  # Supprimer l'extension .sh
    cp "$script" "$INSTALL_DIR/$base_name"
    chmod 755 "$INSTALL_DIR/$base_name"
    echo "Commande $base_name installée avec succès."
done

# Assurer que le répertoire est bien dans le PATH (Normalement déjà dans /usr/local/bin)
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" > /etc/profile.d/gts_scripts.sh
    chmod +x /etc/profile.d/gts_scripts.sh
fi

# Création des groupes
groupadd -f "$RH_GROUP"
groupadd -f "$IT_GROUP"

# Installation de setquota si non installé
if ! command -v setquota &> /dev/null; then
    apt update && apt install -y quota
fi

# Création et configuration des répertoires backups
mkdir -p "$BACKUP_DIR" "$BACKUP_DIR/$RH_GROUP" "$BACKUP_DIR/$IT_GROUP"
chmod 755 "$BACKUP_DIR"
chmod 770 "$BACKUP_DIR/$RH_GROUP" "$BACKUP_DIR/$IT_GROUP"
chown ":$RH_GROUP" "$BACKUP_DIR/$RH_GROUP"
chown ":$IT_GROUP" "$BACKUP_DIR/$IT_GROUP"

# Attribution des permissions sudo pour le groupe __RH
cat > /etc/sudoers.d/$RH_GROUP <<EOL
%$RH_GROUP ALL=(ALL) NOPASSWD: /usr/sbin/useradd, /usr/sbin/usermod, /usr/sbin/groupadd, \
    /usr/sbin/userdel, /usr/sbin/setquota, /usr/bin/quota, /bin/chown, /bin/chmod, \
    /bin/mkdir, /usr/sbin/chpasswd, /usr/local/bin/gts_utilisateurs
EOL
chmod 440 /etc/sudoers.d/$RH_GROUP

# Attribution des permissions sudo pour le groupe __IT
cat > /etc/sudoers.d/$IT_GROUP <<EOL
%$IT_GROUP ALL=(ALL) NOPASSWD: /usr/bin/apt, /bin/chmod, /bin/chown, /bin/systemctl, \
    /usr/bin/tail /var/log/*, /usr/bin/cat /var/log/*, /etc/rsyslog.conf, /etc/rsyslog.d/*, \
    /usr/local/bin/gts_journalisation, /usr/bin/tee, /usr/bin/touch, /usr/bin/bash, /usr/bin/tail
EOL
chmod 440 /etc/sudoers.d/$IT_GROUP

# Permissions des commandes
chown ":$RH_GROUP" "$INSTALL_DIR/gts_utilisateurs"
chmod 750 "$INSTALL_DIR/gts_utilisateurs"

chmod 755 "$INSTALL_DIR/gts_cron" "$INSTALL_DIR/gts_surveillance" \
           "$INSTALL_DIR/gts_sauvegarde" "$INSTALL_DIR/gestions"

chown ":$IT_GROUP" "$INSTALL_DIR/gts_journalisation"
chmod 750 "$INSTALL_DIR/gts_journalisation"

# Rechargement immédiat pour prendre en compte les modifications
source /etc/profile

# Finalisation
cat <<EOF
Installation terminée avec succès !
- Les scripts sont maintenant accessibles comme des commandes système.
- Vous pouvez exécuter \`sudo gts_utilisateurs\` au lieu de \`sudo bash gts_utilisateurs.sh\`.
- Les groupes $RH_GROUP et $IT_GROUP ont leurs permissions sudo configurées.
- Redémarrer votre session pour garantir l'application complète des changements.
EOF
