# VPS Debian - Documentation Technique

> Infrastructure AI/Automation pour aurastackai.com

## 📋 Table des matières

- [Caractéristiques Système](#caractéristiques-système)
- [Audit & Sécurité](#audit--sécurité)
- [Services Docker](#services-docker)
- [Services Systemd](#services-systemd)
- [Workflows n8n Actifs](#workflows-n8n-actifs)
- [Configuration MCP (Model Context Protocol)](#configuration-mcp)
- [Modèles IA Disponibles](#modèles-ia-disponibles)

---

## 🛡️ Audit & Sécurité

Un audit complet de l'infrastructure a été réalisé le 28/11/2025.
👉 **[Consulter le Rapport d'Audit Complet](./AUDIT_REPORT.md)**

### Actions de Durcissement
Un script d'automatisation est disponible pour appliquer les bonnes pratiques de sécurité (UFW, Fail2Ban, SSH Hardening).

```bash
# Appliquer le durcissement
chmod +x scripts/harden_vps.sh
sudo ./scripts/harden_vps.sh
```

---

## 🖥️ Caractéristiques Système

### Système d'exploitation
- **OS**: Debian GNU/Linux
- **Kernel**: 6.1.0-40-cloud-amd64
- **Architecture**: x86_64

### Ressources Matérielles

#### CPU
- **Modèle**: Intel Core Processor (Haswell, no TSX)
- **Cœurs**: 12 vCPUs
- **Architecture**: 1 thread par cœur, 1 cœur par socket

#### RAM
- **Total**: 45 GB
- **Disponible**: ~41 GB
- **Swap**: 4 GB

#### Stockage
- **Capacité totale**: 296 GB
- **Utilisé**: 95 GB (34%)
- **Disponible**: 189 GB
- **Système de fichiers**: /dev/sda1

---

## 🐳 Services Docker

### Conteneurs Actifs

| Nom | Image | Description | Statut |
|-----|-------|-------------|--------|
| `n8n-main-prod` | n8nio/n8n:latest | Instance principale n8n | Running |
| `n8n-worker-1-prod` | n8nio/n8n:latest | Worker n8n #1 (mode queue) | Running |
| `n8n-worker-2-prod` | n8nio/n8n:latest | Worker n8n #2 (mode queue) | Running |
| `n8n-postgres-prod` | postgres:16-alpine | Base de données PostgreSQL | Running (healthy) |
| `n8n-redis-prod` | redis:7-alpine | Cache Redis pour n8n | Running (healthy) |
| `ollama` | ollama/ollama:latest | Serveur LLM local | Running |
| `qdrant` | qdrant/qdrant:latest | Vector database | Running |
| `nocodb` | nocodb/nocodb:latest | No-code database | Running |
| `tww3-http-server` | tww3-http-server:latest | Serveur HTTP projet TWW3 | Running |
| `infra-scanner` | python:3.11-slim | Scanner infrastructure | Running |

### Architecture n8n

**Mode de déploiement**: Queue mode avec Redis
- 1 instance principale (main)
- 2 workers pour exécution distribuée
- PostgreSQL pour persistance
- Redis pour coordination

---

## ⚙️ Services Systemd

### Services AI/Automation

| Service | Description | État |
|---------|-------------|------|
| `qwen-orchestrator.service` | Orchestrateur Qwen 2.5 Coder 3B - Gestionnaire VPS | Running |
| `qwen-workflow-creator.service` | Créateur de workflows Qwen | Running |
| `ollama.service` | Service Ollama LLM | Running |

### Services MCP

| Service | Description | État |
|---------|-------------|------|
| `mcp-sandbox.service` | Validateur MCP Sandbox | Running |
| `mcp-secure.service` | Wrapper HTTP MCP sécurisé v3 | Running |
| `mcp-wrapper-secure.service` | Wrapper HTTP MCP v3 (Sandbox + Whitelist) | Running |

---

## 🔄 Workflows n8n Actifs

### 1. MCP Task Executor
**ID**: `d9T0kjgdnTALQhU7` | **Nœuds**: 7

**Description**: Exécute des tâches MCP via webhook avec validation d'approbation

**Flux**:
1. Réception webhook de tâche MCP
2. Validation de l'approbation
3. Vérification des permissions
4. Exécution de la commande MCP
5. Formatage et retour du résultat

**Cas d'usage**: Automatisation sécurisée de commandes système via MCP

---

### 2. 📄 Extraction Devis Signés - 100% Local
**ID**: `MXmDVXcHxkHXveOU` | **Nœuds**: 9

**Description**: Extraction automatique de données de devis PDF en utilisant Ollama (LLM local)

**Flux**:
1. Surveillance du dossier devis (trigger fichier local)
2. Extraction de texte du PDF
3. Extraction de données structurées via Ollama
4. Insertion dans PostgreSQL (table devis + lignes)
5. Déplacement du fichier vers dossier "processed"

**Technologies**:
- LLM: Ollama Chat Model (local)
- Stockage: PostgreSQL
- Traitement: 100% local (aucun cloud)

**Cas d'usage**: Digitalisation automatique de devis papier avec respect RGPD

---

### 3. Audit Vocal Client
**ID**: `U0zPY5ayFp1PyRHG` | **Nœuds**: 18

**Description**: Audit conversationnel via Telegram avec transcription audio et analyse IA

**Flux**:
1. Réception message vocal Telegram
2. Téléchargement et sauvegarde temporaire de l'audio
3. Transcription via Faster-Whisper (STT local)
4. Suppression audio (conformité RGPD)
5. Requête des 5 derniers messages (mémoire contextuelle)
6. Insertion du nouveau message en base
7. Construction du contexte avec historique
8. Analyse Qwen avec détection d'intention
9. Décision: question suivante ou génération rapport

**Technologies**:
- STT: Faster-Whisper (local)
- LLM: Qwen via API
- Stockage: PostgreSQL
- Messagerie: Telegram Bot

**Cas d'usage**: Audit conversationnel client avec mémoire et génération de rapport automatique

---

### 4. Qwen Workflow Generator
**ID**: `brB9ll0clnw4LGxG` | **Nœuds**: 8

**Description**: Génération automatique de workflows n8n via Qwen

**Flux**:
1. Réception webhook avec description du workflow souhaité
2. Génération JSON du workflow via Qwen
3. Parsing et validation du JSON
4. Vérification de validité
5. Import automatique dans n8n
6. Retour du résultat (succès ou erreur)

**Cas d'usage**: Création automatique de workflows n8n par description en langage naturel

---

## 🔌 Configuration MCP (Model Context Protocol)

> 📖 **Documentation complète**: Voir [MCP-CONFIGURATION.md](./MCP-CONFIGURATION.md) pour tous les détails

### MCP Locaux - Qwen 2.5 Coder 3B

Les serveurs MCP suivants sont configurés et actifs pour l'orchestrateur Qwen :

#### 1. Memory MCP
```javascript
{
  'command': 'npx',
  'args': ['-y', '@modelcontextprotocol/server-memory']
}
```
**Fonction**: Graphe de connaissance persistant pour mémorisation contextuelle

---

#### 2. Sequential Thinking MCP
```javascript
{
  'command': 'npx',
  'args': ['-y', '@modelcontextprotocol/server-sequential-thinking']
}
```
**Fonction**: Raisonnement séquentiel pour problèmes complexes

---

#### 3. Filesystem MCP
```javascript
{
  'command': 'npx',
  'args': [
    '-y', 
    '@modelcontextprotocol/server-filesystem',
    '/opt/qwen-agent',
    '/opt/workflows',
    '/opt/vps-inventory',
    '/tmp',
    '/var/log'
  ]
}
```
**Fonction**: Lecture/écriture de fichiers sur le VPS

**Accès autorisés**:
- `/opt/qwen-agent` - Code de l'orchestrateur
- `/opt/workflows` - Templates de workflows
- `/opt/vps-inventory` - Historique VPS
- `/tmp` - Fichiers temporaires
- `/var/log` - Logs système

---

#### 4. n8n MCP
```javascript
{
  'command': 'npx',
  'args': ['n8n-mcp'],
  'env': {
    'MCP_MODE': 'stdio',
    'N8N_API_URL': 'https://n8n.aurastackai.com/api/v1',
    'LOG_LEVEL': 'error',
    'DISABLE_CONSOLE_OUTPUT': 'true'
  }
}
```
**Fonction**: Gestion complète des workflows n8n (création, modification, validation)

**Capacités**:
- Lister workflows
- Créer/modifier workflows
- Valider configurations
- Détecter erreurs de configuration

---

### MCP Distant - Windows 10

**VPS MCP Server v3** permet l'accès distant au VPS depuis Claude Desktop (Windows 10).

**7 outils disponibles**:
- `execute_command` - Commandes SSH
- `list_docker_containers` - Monitoring Docker
- `check_docker_logs` - Logs conteneurs
- `restart_docker_container` - Redémarrage
- `check_system_resources` - Ressources système
- `diagnose_vps` - Diagnostic complet
- `query_postgres` - Requêtes PostgreSQL

📖 **Configuration détaillée**: Voir [MCP-CONFIGURATION.md](./MCP-CONFIGURATION.md#-mcp-pour-accès-distant-au-vps-windows-10)

---

### Configuration Ressources

#### Qwen Orchestrator Service
- **Limite mémoire**: 4 GB (MemoryMax=4G)
- **Mémoire utilisée**: ~455 MB
- **CPU quota**: 400%
- **Temps démarrage**: Infinity (chargement du modèle)

#### Qwen Workflow Creator Service
- **Limite mémoire**: 4 GB (MemoryMax=4G)
- **Mémoire utilisée**: ~190 MB
- **Mode**: Auto-restart

---

## 🤖 Modèles IA Disponibles

### Ollama Models

| Modèle | Taille | Usage |
|--------|--------|-------|
| `qwen2.5-coder:3b-instruct` | 1.9 GB | Orchestration VPS, workflows n8n |
| `mistral:7b-instruct-v0.3-q4_K_M` | 4.4 GB | Analyse générale |
| `llama3.2-vision:11b` | 7.8 GB | Vision multimodale |
| `llava:7b` | 4.7 GB | Vision + texte |
| `nomic-embed-text:latest` | 274 MB | Embeddings texte |

### Caractéristiques Qwen 2.5 Coder 3B

- **Optimisé pour**: CPU only (pas de GPU)
- **Performance**: 20-30 tokens/sec sur CPU
- **RAM requise**: ~2 GB
- **Spécialités**: 
  - Orchestration VPS
  - Génération de code
  - Validation de workflows
  - Détection d'erreurs de configuration

---

## 📊 Monitoring et Logs

### Logs Systemd
```bash
# Logs Qwen orchestrator
journalctl -u qwen-orchestrator -f

# Logs Qwen workflow creator
journalctl -u qwen-workflow-creator -f

# Logs Ollama
journalctl -u ollama -f
```

### Logs Docker
```bash
# Logs n8n main
docker logs -f n8n-main-prod

# Logs n8n workers
docker logs -f n8n-worker-1-prod
docker logs -f n8n-worker-2-prod
```

---

## 🔐 Sécurité

### Bonnes Pratiques
- ✅ Credentials stockés dans variables d'environnement
- ✅ Accès filesystem MCP limité par whitelist
- ✅ Services MCP en mode sandbox
- ✅ Suppression automatique données audio (RGPD)
- ✅ Base de données PostgreSQL isolée
- ✅ Redis protégé en réseau interne Docker
- ✅ VPS MCP Server v3: authentification SSH par clé

### Services Sécurisés
- `mcp-sandbox.service` - Validation MCP en environnement isolé
- `mcp-secure.service` - Wrapper HTTP sécurisé
- `mcp-wrapper-secure.service` - Double couche sandbox + whitelist

---

## 📝 Notes

### Performance CPU
- **VPS**: CPU only, pas de GPU
- **Qwen 2.5 Coder 3B**: Choisi spécifiquement pour performance CPU
- **Temps de réponse**: Optimisé pour transcription audio temps réel
- **Pas de timeout**: Configuration adaptée aux workflows n8n

### Évolutivité
- **n8n**: Mode queue avec 2 workers (scalable horizontalement)
- **Redis**: Coordination distribuée
- **PostgreSQL**: Gestion transactionnelle des workflows
- **Ollama**: Supporte multiple modèles simultanés

---

**Dernière mise à jour**: 2025-11-16  
**Mainteneur**: Christophe @ AuraStackAI
