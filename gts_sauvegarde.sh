#!/bin/bash

source ./utils.sh

RED='\033[31m'
BLUE='\033[94m'
GREEN='\033[32m'
NC='\033[0m' # No Color

BACKUP_DIR="/backup/groups"

# Fonction pour afficher le menu principal
function menu_principal() {
  clear
  echo -e "${BLUE}=============================="
  echo -e "  Gestion des sauvegardes"
  echo -e "==============================${NC}"
  echo "1. Sauvegarde manuelle"
  echo "2. Sauvegarde automatique"
  echo "3. Quitter"
  echo -e "${BLUE}==============================${NC}"
  echo
  echo -n "Veuillez choisir une option [1-3] : "
}

function obtenir_groupes_utilisateur() {
  # Récupère les groupes de l'utilisateur, filtre ceux ayant des dossiers dans $BACKUP_DIR
  groupes=($(groups | tr ' ' '\n' | grep -E "^($(ls "$BACKUP_DIR" | tr '\n' '|')$)"))

  # Vérifie si des groupes valides ont été trouvés
  if [[ ${#groupes[@]} -eq 0 ]]; then
    afficher_erreur "Aucun dossier de sauvegarde trouvé pour les groupes: $(groups)"
    return 1
  fi
}


# Fonction pour afficher les groupes disponibles
function afficher_groupes() {
  echo -e "Groupes disponibles:"
  obtenir_groupes_utilisateur || return 1

  for i in "${!groupes[@]}"; do
    echo "$((i + 1)). ${groupes[$i]}"
  done
}

# Fonction pour choisir un groupe
function choisir_groupe() {
  afficher_groupes || return 1

  if [[ ${#groupes[@]} -eq 1 ]]; then
    groupe="${groupes[0]}"
    return
  fi

  while true; do
    echo -e "${BLUE}================================${NC}"
    echo
    read -rp "Entrez le numéro du groupe  (q pour annuler): " choix

    if [[ "$choix" == "q" ]]; then
      return 1 # Retour au menu principal
    fi

    if [[ ! "$choix" =~ ^[0-9]+$ ]] || (( choix < 1 || choix > ${#groupes[@]} )); then
      echo -e "${RED}Choix invalide.${NC}"
      continue
    fi

    groupe="${groupes[$((choix - 1))]}"
    echo -e "${GREEN}Groupe sélectionné : $groupe${NC}"
    return
  done
}

#Fonction pour le choix du chemin du fichier ou dossier à sauvegarder
function choisir_chemin() {
  choisir_groupe || return 1

  while true; do
    echo -e "${BLUE}================================${NC}"
    echo
    read -rp "Entrez le chemin du fichier ou dossier à sauvegarder (q pour annuler): " chemin

    if [[ "$chemin" == "q" ]]; then
      return 1 # Retour au menu principal
    fi

    if [[ ! -e "$chemin" ]]; then
      echo -e "${RED}Le fichier ou dossier spécifié n'existe pas.${NC}"
      continue
    fi

    destination="$BACKUP_DIR/$groupe"
    return
  done
}

# Fonction pour effectuer une sauvegarde manuelle
function sauvegarde_manuelle() {
  clear
  echo -e "${BLUE}=== Sauvegarde manuelle ===${NC}"
  choisir_chemin || return

  cp -r "$chemin" "$destination" && \
    echo -e "${GREEN}Sauvegarde effectuée avec succès dans $destination.${NC}" || \
    echo -e "${RED}Erreur lors de la sauvegarde.${NC}"
  read -rp "Appuyez sur [Entrée] pour revenir au menu."
}

function sauvegarde_auto() {
  clear
  echo -e "${BLUE}=== Sauvegarde automatique ===${NC}"
  choisir_chemin || return

  echo -e "${BLUE}================================${NC}"
  echo "Veuillez saisir un moment cron. Format: \"minute(0-59) heure(0-23) jour_mois(1-31) mois(1-12) jour_semaine(0-7)\""
  echo "Tips n°1: * pour répéter à chaque fois."
  echo "Tips n°2: 0 et 7 représentent des dimanches"
  echo
  read -rp "Saisie (q pour annuler) : " cron_moment

  if [[ "$cron_moment" == "q" ]]; then
    return
  fi

  cron_command="$cron_moment cp -r \"$(realpath "$chemin")\" \"$destination\""

  if (crontab -l 2>/dev/null; echo "$cron_command") | crontab -; then
    echo -e "${GREEN}Sauvegarde automatique ajoutée avec succès dans $destination.${NC}"
  else
    echo -e "${RED}Erreur lors de l'ajout de la sauvegarde automatique.${NC}"
  fi
  read -rp "Appuyez sur [Entrée] pour revenir au menu."
  return
}

# Boucle principale
while true; do
  menu_principal
  read -r choix
  case $choix in
    1) sauvegarde_manuelle ;;
    2) sauvegarde_auto ;;
    3) clear; exit 0 ;;
    *) afficher_erreur "Option invalide. Veuillez réessayer." ;;
  esac
done