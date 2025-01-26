#!/bin/bash

RED='\033[31m'
NC='\033[0m' # No Color

# Fonction pour afficher un message d'erreur et attendre une action de l'utilisateur
function afficher_erreur() {
    echo -e "${RED}$1${NC}"
    read -rp "Appuyez sur [Entrée] pour continuer..."
}