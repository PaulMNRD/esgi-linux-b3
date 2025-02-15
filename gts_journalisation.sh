#!/bin/bash

source ./utils.sh

RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[94m'
NC='\033[0m' # No Color

LOG_FILE_CENTRAL="/var/log/syslog-central.log"
ROTATION_CONFIG="/etc/logrotate.d/global-log-rotation"
CRITICAL_SERVICES=("apache2" "sshd" "mysql")

# Vérification et installation de rsyslog
function verifier_installer_rsyslog() {
    echo -e "${BLUE}Vérification de l'installation de rsyslog...${NC}"
    if ! dpkg -s rsyslog &> /dev/null; then
        echo -e "${RED}rsyslog n'est pas installé. Installation en cours...${NC}"
        sudo apt update && sudo apt install -y rsyslog
        echo -e "${GREEN}rsyslog installé avec succès.${NC}"
    else
        echo -e "${GREEN}rsyslog est déjà installé.${NC}"
    fi
    read -rp "Appuyez sur [Entrée] pour continuer..."
}

# Configuration de la journalisation centralisée
function configurer_journalisation_centralisee() {
    echo -e "${BLUE}Configuration de la journalisation centralisée...${NC}"
    if grep -q "$LOG_FILE_CENTRAL" /etc/rsyslog.conf; then
        echo -e "${GREEN}La journalisation centralisée est déjà configurée.${NC}"
    else
        echo "*.*    $LOG_FILE_CENTRAL" | sudo tee -a /etc/rsyslog.conf > /dev/null
        sudo touch "$LOG_FILE_CENTRAL"
        sudo chown syslog:__IT "$LOG_FILE_CENTRAL"
        sudo chmod 640 "$LOG_FILE_CENTRAL"
        echo -e "${GREEN}Journalisation centralisée configurée avec succès.${NC}"
    fi
    read -rp "Appuyez sur [Entrée] pour continuer..."
}

# Mise en place de la rotation des journaux
configurer_rotation_journaux() {
    rotation_config="$ROTATION_CONFIG"
    taille_max="50M"
    nombre_archives=5

    echo -e "${BLUE}Configuration de la rotation générale des journaux...${NC}"

    if [ ! -f "$rotation_config" ]; then
        sudo bash -c "cat > $rotation_config" <<EOL
/var/log/*.log {
    daily
    size $taille_max
    rotate $nombre_archives
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
EOL
        echo -e "${GREEN}Rotation des journaux configurée avec succès : Journalière, Taille max $taille_max, Archives max $nombre_archives.${NC}"
    else
        echo -e "${YELLOW}La rotation des journaux est déjà configurée.${NC}"
    fi

    read -rp "Appuyez sur [Entrée] pour continuer..."
}


# Activation de la journalisation avancée pour les services critiques
function configurer_journalisation_services_critiques() {
    echo -e "${BLUE}Configuration de la journalisation avancée pour les services critiques...${NC}"
    for service in "${CRITICAL_SERVICES[@]}"; do
        service_log="/var/log/${service}.log"
        if ! grep -q "$service_log" /etc/rsyslog.d/"${service}".conf 2>/dev/null; then
            sudo bash -c "cat > /etc/rsyslog.d/${service}.conf" <<EOL
if \$programname == '$service' then $service_log
& stop
EOL
            sudo touch "$service_log"
            sudo chown syslog:__IT "$service_log"
            sudo chmod 640 "$service_log"
            echo -e "${GREEN}Journalisation pour $service configurée.${NC}"
        else
            echo -e "${GREEN}Journalisation pour $service déjà configurée.${NC}"
        fi
    done
    read -rp "Appuyez sur [Entrée] pour continuer..."
}

# Redémarrage du service rsyslog
function redemarrer_rsyslog() {
    echo -e "${BLUE}Redémarrage du service rsyslog...${NC}"
    sudo systemctl restart rsyslog
    echo -e "${GREEN}rsyslog redémarré avec succès.${NC}"
    read -rp "Appuyez sur [Entrée] pour continuer..."
}

# Vérification de la configuration des journaux
function verifier_configuration_journaux() {
    echo -e "${BLUE}Vérification des journaux...${NC}"
    log_text="Test log entry - $(date)"
    logger "$log_text"

    if sudo tail -n 20 "$LOG_FILE_CENTRAL" | grep -q "$log_text"; then
        echo -e "${GREEN}La journalisation fonctionne correctement.${NC}"
    else
        echo -e "${RED}Erreur : La journalisation ne fonctionne pas correctement.${NC}"
    fi
    read -rp "Appuyez sur [Entrée] pour continuer..."
}

# Menu principal
function afficher_menu() {
    while true; do
        clear
        echo -e "${BLUE}=============================="
        echo -e "  Configuration de la Journalisation Système"
        echo -e "==============================${NC}"
        echo "1. Vérification et installation de rsyslog"
        echo "2. Configuration de la journalisation centralisée"
        echo "3. Mise en place de la rotation des journaux"
        echo "4. Journalisation avancée pour les services critiques"
        echo "5. Redémarrage du service rsyslog"
        echo "6. Vérification de la configuration des journaux"
        echo "7. Quitter"
        echo -e "${BLUE}==============================${NC}"
        echo
        read -rp "Choisissez une option [1-7] : " choix

        case $choix in
            1) verifier_installer_rsyslog ;;
            2) configurer_journalisation_centralisee ;;
            3) configurer_rotation_journaux ;;
            4) configurer_journalisation_services_critiques ;;
            5) redemarrer_rsyslog ;;
            6) verifier_configuration_journaux ;;
            7) clear; exit 0 ;;
            *) afficher_erreur "Option invalide. Veuillez réessayer." ;;
        esac
    done
}

# Lancement du menu
afficher_menu