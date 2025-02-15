#!/bin/bash

# Définition des couleurs
RED='\033[31m'
LIGHT_BLUE='\033[94m'
GREEN='\033[32m'
NC='\033[0m' # No Color

clear
# Fonction pour surveiller l'espace disque
disk_usage() {
    echo -e "${LIGHT_BLUE}===== Espace disque disponible =====${NC}"
    df -h | grep -E '^(/dev|tmpfs|overlay)'
    echo ""
}

# Fonction pour lister les processus actifs
list_processes() {
    echo -e "${LIGHT_BLUE}===== Liste des processus actifs =====${NC}"
    ps aux --sort=-%mem | head -15
    echo ""
}

# Fonction pour surveiller l'utilisation de la mémoire
memory_usage() {
    echo -e "${LIGHT_BLUE}===== Utilisation de la mémoire =====${NC}"
    free -h
    echo ""
}

# Boucle du menu interactif
while true; do
    echo -e "${LIGHT_BLUE}============================${NC}"
    echo -e "1) Surveillance de l'espace disque"
    echo -e "2) Suivi des processus actifs"
    echo -e "3) Surveillance de l'utilisation de la mémoire"
    echo -e "4) Quitter"
    echo -e "${LIGHT_BLUE}============================${NC}"
    read -p "Choisissez une option : " choix

    case $choix in
        1) disk_usage ;;
        2) list_processes ;;
        3) memory_usage ;;
        4) echo -e "${GREEN}Sortie du programme.${NC}"; exit 0 ;;
        *) echo -e "${RED}Option invalide. Veuillez réessayer.${NC}"; sleep 1 ;;
    esac
done
