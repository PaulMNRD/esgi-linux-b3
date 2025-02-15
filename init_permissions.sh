#!/bin/bash

# Définition du groupe RH
GROUPE_RH="__RH"

# Liste des scripts concernés
SCRIPTS=("gts_utilisateurs.sh" "gts_cron.sh" "gts_surveillance.sh" "gts_sauvegarde.sh" "gts_journalisation.sh" "gts_main.sh")

# Création du groupe RH s'il n'existe pas déjà
if ! getent group "$GROUPE_RH" > /dev/null; then
    echo "Création du groupe $GROUPE_RH."
    sudo groupadd "$GROUPE_RH"
else
    echo "Le groupe $GROUPE_RH existe déjà."
fi

# Attribution des permissions aux scripts
for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        # Modification du propriétaire pour le groupe RH
        sudo chown "$GROUPE_RH":"$GROUPE_RH" "$script"

        # droit d'execution
        sudo chmod 111 "$script"

        echo "Permissions mises à jour sur $script."
    else
        echo "Le fichier $script n'existe pas."
    fi
done

echo "Initialisation terminée. Seuls les membres du groupe $GROUPE_RH peuvent exécuter les scripts sans les modifier."
exit 0
