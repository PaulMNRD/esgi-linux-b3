#!/bin/bash

source ./utils.sh

RED='\033[31m'
BLUE='\033[94m'
GREEN='\033[32m'
NC='\033[0m' # No Color


# Fonction pour afficher le menu principal
function menu_principal() {
    clear
    echo -e "${BLUE}=============================="
    echo -e "  Gestion des tâches CRON"
    echo -e "==============================${NC}"
    echo "1. Afficher les tâches cron actuelles"
    echo "2. Ajouter une tâche cron"
    echo "3. Supprimer une tâche cron"
    echo "4. Quitter"
    echo -e "${BLUE}==============================${NC}"
    echo
    echo -n "Veuillez choisir une option [1-4] : "
}

# Fonction pour afficher les tâches cron actuelles
function afficher_taches_cron() {
    clear
    echo -e "${BLUE}=== Tâches cron actuelles ===${NC}"
    cron_taches=$(crontab -l 2>/dev/null)

    if [[ -z "$cron_taches" ]]; then
        echo "Aucune tâche cron configurée."
    fi
    crontab -l 2>/dev/null

    echo -e "${BLUE}=============================${NC}"
    echo
    read -rp "Appuyez sur [Entrée] pour revenir au menu."
}

# Fonction pour ajouter une tâche cron
function ajouter_tache_cron() {
    clear
    echo -e "${BLUE}=== Ajouter une tâche cron ===${NC}"
    echo "Format : minute heure jour mois jour_de_la_semaine commande"
    echo "Exemple : 0 8 * * 1 echo \"Bonjour\" >> /var/log/rapport.txt"

    while true; do
        echo -e "${BLUE}================================${NC}"
	echo
        read -rp "Entrez votre commande cron (q pour annuler): " commande_cron

        if [[ "$commande_cron" == "q" ]]; then
            return  # Retour au menu principal
        fi

	if [[ -z "$commande_cron" ]]; then
            echo -e "${RED}Erreur : aucune commande saisie. Veuillez réessayer.${NC}"
            continue
        fi

	if (crontab -l 2>/dev/null; echo "$commande_cron") | crontab -; then
            echo -e "${GREEN}Tâche ajoutée avec succès.${NC}"
            read -rp "Appuyez sur [Entrée] pour revenir au menu."
            return
        else
            echo -e "${RED}Erreur lors de l'ajout de la tâche. Veuillez réessayer.${NC}"
        fi
    done
}

# Fonction pour supprimer une tâche cron
function supprimer_tache_cron() {
    clear
    echo -e "${BLUE}=== Supprimer une tâche cron ===${NC}"

    cron_taches=$(crontab -l 2>/dev/null)
    if [[ -z "$cron_taches" ]]; then
        echo "Aucune tâche cron configurée."
	echo -e "${BLUE}================================${NC}"
	echo
        read -rp "Appuyez sur [Entrée] pour revenir au menu."
        return
    fi

    echo "Voici vos tâches cron actuelles :"
    crontab -l | nl

    while true; do
        echo -e "${BLUE}================================${NC}"
	echo
        read -rp "Entrez le numéro de la tâche à supprimer (q pour annuler): " numero

        if [[ "$numero" == "q" ]]; then
            return  # Retour au menu principal
        fi

	nombre_taches=$(echo "$cron_taches" | wc -l)
	if ! [[ "$numero" =~ ^[0-9]+$ ]] || (( numero < 1 || numero > nombre_taches )); then
            echo -e "${RED}Erreur : vous devez entrer un numéro valide.${NC}"
            continue
        fi

	if crontab -l | sed "${numero}d" | crontab -; then
            echo -e "${GREEN}Tâche supprimée avec succès.${NC}"
            read -rp "Appuyez sur [Entrée] pour revenir au menu."
            return
        else
            echo -e "${GREEN}Erreur lors de la suppression de la tâche. Veuillez réessayer.${NC}"
        fi
    done
}

# Boucle principale pour le menu
while true; do
    menu_principal
    read -r choix
    case $choix in
        1) afficher_taches_cron ;;
        2) ajouter_tache_cron ;;
        3) supprimer_tache_cron ;;
        4) clear; exit 0 ;;
        *) afficher_erreur "Option invalide. Veuillez réessayer." ;;
    esac
done
