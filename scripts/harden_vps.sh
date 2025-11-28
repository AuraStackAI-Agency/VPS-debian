#!/bin/bash

# ==========================================
# VPS Hardening Script - Enterprise Grade
# Auteur: Auto-Healing Agent
# ==========================================

set -e

echo "🔒 Démarrage du durcissement du VPS..."

# 1. Mise à jour du système
echo "📦 Mise à jour des paquets..."
apt-get update && apt-get upgrade -y

# 2. Installation des outils de sécurité
echo "🛡️ Installation de UFW et Fail2Ban..."
apt-get install -y ufw fail2ban unattended-upgrades

# 3. Configuration UFW (Pare-feu)
echo "🧱 Configuration du Pare-feu..."
ufw default deny incoming
ufw default allow outgoing
# Autoriser SSH (Attention: changer le port si nécessaire)
ufw allow 22/tcp
# Autoriser HTTP/HTTPS pour N8N/Webhooks
ufw allow 80/tcp
ufw allow 443/tcp
# Autoriser Port Docker spécifiques si besoin (ex: 5678 pour n8n webhook si exposé direct)
# ufw allow 5678/tcp 

echo "   Activation du Pare-feu..."
ufw --force enable

# 4. Configuration Fail2Ban
echo "🚫 Configuration de Fail2Ban..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Activer la protection SSH par défaut
sed -i 's/backend = auto/backend = systemd/' /etc/fail2ban/jail.local

systemctl restart fail2ban
systemctl enable fail2ban

# 5. Durcissement SSH
echo "🔑 Durcissement SSH..."
SSH_CONFIG="/etc/ssh/sshd_config"
# Backup config
cp $SSH_CONFIG "$SSH_CONFIG.bak"

# Désactiver Root Login
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' $SSH_CONFIG
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' $SSH_CONFIG

# Désactiver Auth Mot de passe (Clés uniquement)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG

# Désactiver X11 Forwarding
sed -i 's/X11Forwarding yes/X11Forwarding no/' $SSH_CONFIG

echo "   Redémarrage SSH..."
systemctl restart ssh

# 6. Mises à jour automatiques de sécurité
echo "🔄 Activation des mises à jour de sécurité auto..."
dpkg-reconfigure -plow unattended-upgrades

echo "✅ Durcissement terminé avec succès !"
echo "⚠️  NOTE: Assurez-vous d'avoir testé votre clé SSH avant de fermer la session actuelle."
