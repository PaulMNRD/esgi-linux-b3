#!/bin/bash

# Définition des couleurs
RED='\033[31m'
LIGHT_BLUE='\033[94m'
GREEN='\033[32m'
NC='\033[0m' # No Color

# Fonction pour lister les groupes disponibles (préfixe '_')
list_groups() {
    # Récupère les groupes disponibles avec le préfixe '__'
    groups=$(getent group | awk -F: '$1 ~ /^__/ {print $1}')
    
    # Vérifie s'il y a des groupes disponibles
    if [[ -z "$groups" ]]; then
        echo -e "${RED}Aucun groupe disponible avec le préfixe '__'.${NC}"
        return 1
    fi

    # Affiche les groupes disponibles
    PS3="Sélectionnez un groupe : "
    select groupname in $groups; do
        # Vérifie si un groupe valide a été sélectionné
        if [[ -n "$groupname" ]]; then
            echo "$groupname" # Retourne uniquement le groupe sélectionné
            return 0
        else
            echo -e "${RED}Sélection invalide. Veuillez choisir un numéro valide.${NC}"
        fi
    done
}

# Crée un nouvel utilisateur avec des options supplémentaires
create_user() {
    echo -e "${LIGHT_BLUE}=== Création d'un utilisateur ===${NC}"
    read -rp "Nom de l'utilisateur : " username

    if id "$username" >/dev/null 2>&1; then
        echo -e "${RED}Erreur : L'utilisateur $username existe déjà.${NC}"
        return
    fi

    password=$(openssl rand -base64 12)

    sudo useradd -m -s /bin/bash "$username"
    echo "$username:$password" | sudo chpasswd
    echo -e "${GREEN}Utilisateur $username créé avec succès.${NC}"
    echo -e "Identifiants :"
    echo -e "Nom d'utilisateur : $username"
    echo -e "Mot de passe : $password"

    read -rp "Voulez-vous ajouter l'utilisateur à un groupe ? (y/n) : " add_group
    if [[ "$add_group" == "y" ]]; then
        groupname=$(list_groups)
        sudo usermod -aG "$groupname" "$username"
        echo -e "${GREEN}Utilisateur $username ajouté au groupe $groupname.${NC}"
    fi

    read -rp "Voulez-vous configurer un quota disque pour l'utilisateur ? (y/n) : " set_disk_quota
    if [[ "$set_disk_quota" == "y" ]]; then
        set_quota "$username"
    fi

    read -rp "Voulez-vous ajouter l'utilisateur au groupe sudo ? (y/n) : " add_sudo
    if [[ "$add_sudo" == "y" ]]; then
        sudo usermod -aG sudo "$username"
        echo -e "${GREEN}Utilisateur $username ajouté au groupe sudo.${NC}"
    fi

    echo -e "${GREEN}Actions supplémentaires terminées pour $username.${NC}"
}

# Configure un quota unique pour un utilisateur
set_quota() {
    local username="$1"
    if [[ -z "$username" ]]; then
        echo -e "${LIGHT_BLUE}=== Configuration des quotas ===${NC}"
        read -rp "Nom de l'utilisateur pour configurer un quota : " username

        if ! id "$username" >/dev/null 2>&1; then
            echo -e "${RED}Erreur : L'utilisateur $username n'existe pas.${NC}"
            return
        fi
    fi

    read -rp "Entrez la limite maximale de disque en Mo pour l'utilisateur : " limit
    if [[ "$limit" -gt 0 ]]; then
        limit_kb=$((limit * 1024)) # Convertir la limite en Ko
        # Configure uniquement le quota pour cet utilisateur
        sudo setquota -u "$username" "$limit_kb" "$limit_kb" 0 0 /
        echo -e "${GREEN}Quota de ${limit} Mo configuré pour l'utilisateur $username.${NC}"
    else
        echo -e "${RED}La limite doit être un entier supérieur à zéro.${NC}"
    fi
}

# Ajoute un utilisateur à un groupe
assign_user_to_group() {
    echo -e "${LIGHT_BLUE}=== Affectation d'un utilisateur à un groupe ===${NC}"
    read -rp "Nom de l'utilisateur : " username

    # Vérifie si l'utilisateur existe
    if ! id "$username" >/dev/null 2>&1; then
        echo -e "${RED}Erreur : L'utilisateur $username n'existe pas.${NC}"
        return 1
    fi

    # Liste les groupes disponibles
    groupname=$(list_groups)
    if [[ $? -ne 0 || -z "$groupname" ]]; then
        echo -e "${RED}Aucun groupe sélectionné. Opération annulée.${NC}"
        return 1
    fi

    # Ajoute l'utilisateur au groupe sélectionné
    if sudo usermod -aG "$groupname" "$username"; then
        echo -e "${GREEN}Utilisateur $username ajouté avec succès au groupe $groupname.${NC}"
    else
        echo -e "${RED}Erreur : Impossible d'ajouter $username au groupe $groupname.${NC}"
        return 1
    fi
}

delete_user() {
    echo -e "${LIGHT_BLUE}=== Suppression d'un utilisateur ===${NC}"
    read -rp "Nom de l'utilisateur à supprimer : " username

    if ! id "$username" >/dev/null 2>&1; then
        echo -e "${RED}Erreur : L'utilisateur $username n'existe pas.${NC}"
        return
    fi

    sudo userdel -r "$username"
    echo -e "${GREEN}Utilisateur $username supprimé avec succès.${NC}"
}

# Crée un groupe avec préfixe '__'
create_group() {
    echo -e "${LIGHT_BLUE}=== Création d'un groupe ===${NC}"
    read -rp "Nom du groupe : " groupname

    groupname="__$groupname"

    if getent group "$groupname" >/dev/null; then
        echo -e "${RED}Erreur : Le groupe $groupname existe déjà.${NC}"
        return
    fi

    sudo groupadd "$groupname"
    echo -e "${GREEN}Groupe $groupname créé avec succès.${NC}"
}
# Liste les utilisateurs avec le quota unique
list_users() {
    echo -e "${LIGHT_BLUE}=== Liste des utilisateurs ===${NC}"
    printf "%20s %10s %10s %10s %20s\n" "Utilisateur" "Sudo" "Taille Disque" "Quota" "Groupes"
    awk -F: '($3 >= 1000 && $1 != "nobody") {print $1}' /etc/passwd | while read -r user; do
        sudo_status="Non"
        if groups "$user" | grep -q sudo; then
            sudo_status="Oui"
        fi
        disk_usage=$(du -sh "/home/$user" 2>/dev/null | awk '{print $1}')
        [ -z "$disk_usage" ] && disk_usage="N/A"
        quota=$(sudo quota -u "$user" 2>/dev/null | awk '/\/dev/ {print $3}')
        if [[ "$quota" == "No" || -z "$quota" ]]; then
            quota="No Quota"
        else
            quota=$((quota / 1024)) # Convert blocks to MB
            quota="${quota} MB"
        fi
        user_groups=$(id -Gn "$user" | tr ' ' '\n' | grep '^__' | tr '\n' ' ')
        [ -z "$user_groups" ] && user_groups="Aucun"
        printf "%20s %10s %10s %10s %20s\n" "$user" "$sudo_status" "$disk_usage" "$quota" "$user_groups"
    done
}

while true; do
    echo -e "${LIGHT_BLUE}============================${NC}"
    echo -e "1. Créer un utilisateur"
    echo -e "2. Supprimer un utilisateur"
    echo -e "3. Créer un groupe"
    echo -e "4. Affecter un utilisateur à un groupe"
    echo -e "5. Configurer les quotas disque pour un utilisateur"
    echo -e "6. Configurer sudo pour un utilisateur"
    echo -e "7. Lister les utilisateurs"
    echo -e "8. Quitter"
    echo -e "${LIGHT_BLUE}============================${NC}"
    read -rp "Choisissez une option : " choice

    case $choice in
        1) create_user ;;
        2) delete_user ;;
        3) create_group ;;
        4) assign_user_to_group ;;
        5) set_quota "" ;;
        6) configure_sudo ;;
        7) list_users ;;
        8) echo -e "${GREEN}Au revoir !${NC}" ; exit 0 ;;
        *) echo -e "${RED}Option invalide, veuillez réessayer.${NC}" ;;
    esac
done
