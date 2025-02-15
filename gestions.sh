#!/bin/bash

# Définition des couleurs
RED='\033[31m'
LIGHT_BLUE='\033[94m'
GREEN='\033[32m'
NC='\033[0m' # No Color

# Fonction pour afficher le menu principal
function menu_principal() {
    clear
    echo -e "${LIGHT_BLUE}=============================="
    echo -e "  Gestion des Scripts"
    echo -e "==============================${NC}"
    echo "1. Gestion des utilisateurs"
    echo "2. Gestion des tâches CRON"
    echo "3. Gestion de la journalisation"
    echo "4. Gestion des sauvegardes"
    echo "5. Surveillance du système"
    echo "6. Quitter"
    echo -e "${LIGHT_BLUE}==============================${NC}"
    echo
    echo -n "Veuillez choisir une option [1-6] : "
}

# Boucle principale pour le menu
while true; do
    menu_principal
    read -r choix
    case $choix in
        1) gts_utilisateurs ;;
        2) gts_cron ;;
        3) gts_journalisation ;;
        4) gts_sauvegarde ;;
        5) gts_surveillance ;;
        6) clear; exit 0 ;;
        *) echo -e "${RED}Option invalide. Veuillez réessayer.${NC}" ;;
    esac
done
