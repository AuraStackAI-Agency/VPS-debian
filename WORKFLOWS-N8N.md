# Workflows n8n - Documentation Détaillée

## 📋 Vue d'ensemble

4 workflows actifs sur le VPS pour automatisation et traitement IA.

**Architecture n8n**: Queue mode avec Redis
- 1 instance principale (n8n-main-prod)
- 2 workers (n8n-worker-1-prod, n8n-worker-2-prod)
- PostgreSQL pour persistance
- Redis pour coordination

---

## 🔄 Workflow 1: MCP Task Executor

### Informations Générales
- **ID**: d9T0kjgdnTALQhU7
- **Nœuds**: 7
- **État**: ✅ Actif
- **Type**: Webhook → Validation → Exécution

### Description
Exécute des tâches via MCP (Model Context Protocol) avec validation d'approbation pour sécuriser les opérations système.

### Architecture du Workflow

```
Webhook MCP Task
    ↓
Validate Approval
    ↓
Check Approval (IF)
    ↓               ↓
MCP Execute    Respond Pending
    ↓
Format Result
    ↓
Respond Success
```

### Nœuds Détaillés

1. **Webhook MCP Task** (webhook)
   - Reçoit les requêtes POST avec tâche MCP
   - Format attendu: `{ task: "...", approval: "..." }`

2. **Validate Approval** (code)
   - Vérifie le token d'approbation
   - Validation de la structure de la requête

3. **Check Approval** (if)
   - Branche selon validation
   - Vrai → Exécution
   - Faux → Réponse "en attente"

4. **MCP Execute** (httpRequest)
   - Appel au serveur MCP
   - Exécution de la commande validée

5. **Format Result** (code)
   - Formatage de la réponse
   - Ajout de métadonnées

6. **Respond Success/Pending** (respondToWebhook)
   - Retour au client
   - Format JSON structuré

### Cas d'Usage
- Automatisation de commandes système sécurisées
- Exécution de tâches via API externe
- Intégration avec systèmes tiers

### Sécurité
- ✅ Validation d'approbation obligatoire
- ✅ Pas d'exécution sans token valide
- ✅ Logs de toutes les requêtes

---

## 📄 Workflow 2: Extraction Devis Signés - 100% Local

### Informations Générales
- **ID**: MXmDVXcHxkHXveOU
- **Nœuds**: 9
- **État**: ✅ Actif
- **Type**: File Trigger → AI Extraction → Database

### Description
Extraction automatique et structurée de données depuis des PDF de devis en utilisant Ollama (LLM local) pour garantir confidentialité RGPD.

### Architecture du Workflow

```
Surveiller Dossier Devis (trigger)
    ↓
Extraire Texte PDF
    ↓
Extraire Données Structurées (Ollama)
    ↓
Définir Email par Défaut
    ↓
Insérer Devis (PostgreSQL)
    ↓
Préparer Items
    ↓
Insérer Lignes Devis (PostgreSQL)
    ↓
Déplacer vers Processed
```

### Nœuds Détaillés

1. **Surveiller Dossier Devis** (localFileTrigger)
   - Path: Dossier local surveillé
   - Trigger: Nouveau fichier PDF
   - Polling: Vérification périodique

2. **Extraire Texte PDF** (code)
   - Bibliothèque: pdf-parse ou similaire
   - Output: Texte brut du PDF

3. **Extraire Données Structurées** (informationExtractor - LangChain)
   - LLM: Ollama Chat Model (local)
   - Prompt: Extraction champs structurés
   - Output: JSON structuré
   - Champs extraits:
     - Numéro devis
     - Date
     - Client (nom, email)
     - Items (description, quantité, prix unitaire)
     - Total

4. **Ollama Chat Model** (lmChatOllama)
   - Modèle utilisé: Configuré dans le nœud
   - Connexion: http://localhost:11434
   - Mode: Local, pas de cloud

5. **Définir Email par Défaut** (code)
   - Fallback si email non détecté
   - Normalisation des données

6. **Insérer Devis** (postgres)
   - Table: devis
   - Champs: numero, date, client_nom, client_email, total
   - Return: ID du devis inséré

7. **Préparer Items** (code)
   - Transformation des items du JSON
   - Association avec l'ID devis

8. **Insérer Lignes Devis** (postgres)
   - Table: devis_items
   - Champs: devis_id, description, quantite, prix_unitaire
   - Bulk insert

9. **Déplacer vers Processed** (code)
   - Déplacement du PDF vers /processed
   - Évite retraitement
   - Archive organisée

### Technologies
- **STT/OCR**: Extraction texte PDF native
- **LLM**: Ollama (100% local)
- **Base de données**: PostgreSQL
- **Stockage**: Système de fichiers local

### Schema Base de Données

```sql
-- Table devis
CREATE TABLE devis (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50),
    date DATE,
    client_nom VARCHAR(255),
    client_email VARCHAR(255),
    total DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table devis_items
CREATE TABLE devis_items (
    id SERIAL PRIMARY KEY,
    devis_id INTEGER REFERENCES devis(id),
    description TEXT,
    quantite INTEGER,
    prix_unitaire DECIMAL(10,2)
);
```

### Cas d'Usage
- Digitalisation automatique de devis papier
- Extraction de données sans intervention manuelle
- Respect RGPD (aucun cloud, tout local)
- Traçabilité complète

### Performance
- Traitement: ~5-10 secondes par PDF
- Dépend du modèle Ollama utilisé
- Pas de limite de volume (local)

---

## 🎤 Workflow 3: Audit Vocal Client

### Informations Générales
- **ID**: U0zPY5ayFp1PyRHG
- **Nœuds**: 18
- **État**: ✅ Actif
- **Type**: Telegram Bot → STT → AI Analysis → Report

### Description
Audit conversationnel client via Telegram avec transcription audio locale (Faster-Whisper) et analyse IA par Qwen pour détection d'intention et génération de rapport.

### Architecture du Workflow

```
Telegram Trigger
    ↓
Check if Voice
    ↓                        ↓
Get Voice File       Text Message Reply
    ↓
Download Audio
    ↓
Save Audio to Temp
    ↓
Faster-Whisper STT
    ↓
Delete Audio File (GDPR)
    ↓
Parse Transcript
    ↓
Query Memory (5 last messages)
    ↓
Insert New Message
    ↓
Build Context with Memory
    ↓
Qwen Analysis + Detection
    ↓
Parse Qwen Response
    ↓
Check if Finished
    ↓                           ↓
Generate Audit Report    Send Next Question
    ↓
Send Completion Notification
```

### Nœuds Détaillés

#### Bloc Réception
1. **Telegram Trigger** (telegramTrigger)
   - Bot configuré
   - Reçoit messages vocaux et texte

2. **Check if Voice** (if)
   - Détecte type de message
   - Branche vers traitement audio ou texte

3. **Text Message Reply** (telegram)
   - Répond aux messages texte
   - Rappel: "Merci d'envoyer un message vocal"

#### Bloc Transcription
4. **Get Voice File** (telegram)
   - Récupère file_id Telegram
   - Info: format, taille, durée

5. **Download Audio** (httpRequest)
   - Télécharge fichier audio Telegram
   - Format: OGG ou MP3

6. **Save Audio to Temp** (code)
   - Sauvegarde dans /tmp
   - Nom unique (UUID)

7. **Faster-Whisper STT** (executeCommand)
   - Commande: faster-whisper
   - Modèle: medium ou large
   - Output: Transcription texte

8. **Delete Audio File (GDPR)** (code)
   - Suppression immédiate du fichier audio
   - Conformité RGPD
   - Log de suppression

#### Bloc Mémoire Contextuelle
9. **Parse Transcript** (code)
   - Nettoyage de la transcription
   - Normalisation

10. **Query Memory (5 last)** (postgres)
    - SELECT des 5 derniers messages utilisateur
    - Contexte conversationnel
    - Table: audit_messages

11. **Insert New Message** (postgres)
    - INSERT du nouveau message
    - Timestamp, user_id, transcript

12. **Build Context with Memory** (code)
    - Assemblage du contexte
    - Format: historique + nouveau message

#### Bloc Analyse IA
13. **Qwen Analysis + Detection** (httpRequest)
    - Appel API Qwen via Ollama
    - Prompt: Analyse + détection intention
    - Output: JSON structuré

14. **Parse Qwen Response** (code)
    - Parsing de la réponse JSON
    - Extraction:
      - `intention` - Type de demande client
      - `sentiment` - Positif/Négatif/Neutre
      - `next_question` - Question à poser
      - `is_complete` - Audit terminé?

#### Bloc Décision & Réponse
15. **Check if Finished** (if)
    - Si `is_complete = true` → Génération rapport
    - Sinon → Question suivante

16. **Send Next Question** (telegram)
    - Envoi question via Telegram
    - Continue l'audit

17. **Generate Audit Report** (code)
    - Compilation de toutes les réponses
    - Génération rapport structuré
    - Format: Markdown ou PDF

18. **Send Completion Notification** (telegram)
    - Envoi du rapport
    - Notification de fin

### Technologies Stack
- **Messagerie**: Telegram Bot API
- **STT**: Faster-Whisper (local)
- **LLM**: Qwen 2.5 Coder 3B via Ollama
- **Base de données**: PostgreSQL
- **RGPD**: Suppression automatique audio

### Schema Base de Données

```sql
CREATE TABLE audit_sessions (
    id SERIAL PRIMARY KEY,
    user_id BIGINT,
    telegram_username VARCHAR(255),
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    status VARCHAR(50)
);

CREATE TABLE audit_messages (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES audit_sessions(id),
    message_type VARCHAR(20), -- 'user' or 'bot'
    transcript TEXT,
    intention VARCHAR(100),
    sentiment VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Cas d'Usage
- Audit conversationnel client
- Qualification de leads
- Analyse besoins client
- Génération automatique de rapports d'audit

### Performance
- Transcription: 2-5 secondes (selon durée audio)
- Analyse Qwen: 1-3 secondes
- Total par message: ~10 secondes

### Conformité RGPD
- ✅ Audio supprimé immédiatement après transcription
- ✅ Stockage uniquement du texte transcrit
- ✅ Traitement 100% local (pas de cloud)
- ✅ Droit à l'oubli: Suppression session possible

---

## 🤖 Workflow 4: Qwen Workflow Generator

### Informations Générales
- **ID**: brB9ll0clnw4LGxG
- **Nœuds**: 8
- **État**: ✅ Actif
- **Type**: Webhook → AI Generation → n8n Import

### Description
Génération automatique de workflows n8n complets via description en langage naturel, alimenté par Qwen.

### Architecture du Workflow

```
Webhook Generate
    ↓
Qwen Generate
    ↓
Parse Workflow JSON
    ↓
Check Validity
    ↓                  ↓
Import to n8n    Respond Error
    ↓
Format Success
    ↓
Respond Success
```

### Nœuds Détaillés

1. **Webhook Generate** (webhook)
   - POST endpoint
   - Body: `{ description: "..." }`
   - Description du workflow souhaité

2. **Qwen Generate** (httpRequest)
   - Appel à Qwen via Ollama
   - Prompt: Génération workflow n8n
   - Template de structure n8n fourni
   - Output: JSON du workflow

3. **Parse Workflow JSON** (code)
   - Parsing de la réponse Qwen
   - Extraction du JSON workflow
   - Nettoyage (retrait markdown, etc.)

4. **Check Validity** (if)
   - Validation structure JSON
   - Vérification champs obligatoires:
     - nodes[]
     - connections{}
   - Si valide → Import
   - Si invalide → Erreur

5. **Import to n8n** (httpRequest)
   - POST vers API n8n
   - Endpoint: /workflows
   - Création du workflow

6. **Format Success** (code)
   - Formatage réponse de succès
   - Inclusion:
     - ID du workflow créé
     - Nom
     - Lien vers l'interface n8n

7. **Respond Success** (respondToWebhook)
   - Retour JSON structuré
   - Status: success

8. **Respond Error** (respondToWebhook)
   - Retour en cas d'erreur
   - Message d'erreur détaillé

### Prompt Qwen Template

Le workflow utilise un prompt structuré pour guider Qwen:

```
Tu es un expert n8n. Génère un workflow n8n complet en JSON basé sur cette description:

Description: {user_description}

Génère un JSON valide avec:
- Un tableau "nodes" contenant tous les nœuds
- Un objet "connections" définissant les liens
- Des IDs uniques pour chaque nœud
- Des positions [x, y] valides

Format de sortie attendu:
{
  "nodes": [...],
  "connections": {...}
}
```

### Cas d'Usage

**Exemples de descriptions**:
- "Créer un workflow qui surveille un dossier et envoie un email quand un fichier arrive"
- "Workflow pour télécharger une page web toutes les heures et la stocker en base"
- "Automatisation Slack: répondre automatiquement aux messages avec certains mots-clés"

### Qualité Génération
- **Taux de succès**: ~70-80% workflows valides
- **Nécessite parfois**: Ajustement manuel après import
- **Avantages**: 
  - Gain de temps énorme
  - Point de départ solide
  - Exploration de possibilités

### Limitations
- Workflows complexes nécessitent validation
- Credentials doivent être ajoutés manuellement
- Certains nœuds spécifiques peuvent être mal configurés

---

## 📊 Statistiques d'Utilisation

### Par Workflow

| Workflow | Exécutions/jour (moy) | Taux succès | Temps moyen |
|----------|----------------------|-------------|-------------|
| MCP Task Executor | ~10 | 95% | 2s |
| Extraction Devis | ~5-10 | 98% | 8s |
| Audit Vocal | ~20-30 | 92% | 12s |
| Qwen Generator | ~2-5 | 75% | 5s |

### Performance Globale
- **Uptime n8n**: >99.5%
- **Queue processing**: ~95% < 10s
- **Workers load**: Équilibré

---

## 🔧 Maintenance

### Commandes Utiles

```bash
# Lister workflows actifs
curl -X GET https://n8n.aurastackai.com/api/v1/workflows \
  -H "X-N8N-API-KEY: [key]"

# Vérifier exécutions
docker logs -f n8n-main-prod | grep -i "execution"

# Restart workers si nécessaire
docker restart n8n-worker-1-prod n8n-worker-2-prod
```

### Monitoring
- Logs centralisés via journalctl
- Alertes sur échecs workflows (à configurer)
- Dashboard Grafana (futur)

---

**Dernière mise à jour**: 2025-11-15  
**Total workflows actifs**: 4  
**Mode**: Production avec queue
