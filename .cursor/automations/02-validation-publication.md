# Automatisation 2 — Validation Telegram & publication

> Copier ce prompt dans [cursor.com/automations](https://cursor.com/automations) ou l'Agents Window.

## Configuration

| Paramètre | Valeur |
|-----------|--------|
| **Nom** | BlogIA — Validation & publication |
| **Déclencheur** | Planifié — toutes les 15 minutes (`*/15 * * * *`) |
| **Dépôt** | `davyagonma/BlogIA` — branche `main` |
| **Outils** | Open pull request, Memories, MCP Telegram |
| **Modèle** | Recommandé : modèle le plus récent disponible |

### Lecture des réponses Telegram

⚠️ Le serveur `telegram-bot-mcp-server` envoie (`send-message`) mais n'expose PAS
`getUpdates`. Pour LIRE les commandes `VALIDÉ`/`REFUSÉ`, deux approches :

**Approche A — Cron + curl `getUpdates` (simple)**
Déclencheur planifié (`*/15 * * * *`). Le prompt lit les messages via un appel shell :

```bash
curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates?offset=<dernier_update_id+1>"
```

Le token doit être disponible au run (variable d'environnement de l'automatisation
ou inclus dans le prompt). Suivre le dernier `update_id` traité dans MEMORIES.md.

**Approche B — Webhook (instantané)**
Pointer le bot vers l'URL webhook de l'automatisation :

```bash
curl "https://api.telegram.org/bot<TOKEN>/setWebhook?url=<URL_WEBHOOK>"
```

⚠️ Telegram n'envoie pas l'API key Cursor ; un petit relais peut être nécessaire
pour authentifier l'appel webhook. Plus complexe mais publication immédiate.

### Envoi des confirmations
Outil MCP `send-message` (serveur `telegram-bot-mcp-server`, env `TELEGRAM_BOT_API_TOKEN`),
`chatId: "5530576033"`.

---

## Prompt

```
Tu es l'agent de validation éditoriale de BlogIA.

## Mission
Vérifier les messages Telegram récents pour des commandes de validation, puis publier ou refuser les articles en brouillon correspondants.

## Étapes obligatoires

1. **Lire les messages Telegram** (via curl `getUpdates`, voir en-tête du fichier)
   - Récupère les updates : `curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates?offset=<dernier_update_id+1>"`
   - Cherche les messages contenant `VALIDÉ {slug}` ou `REFUSÉ {slug}` (insensible à la casse)
   - Ignore les messages déjà traités (consulte MEMORIES.md section « traités »)
   - Note le dernier `update_id` traité dans MEMORIES.md pour éviter les doublons

2. **Pour chaque commande VALIDÉ {slug}**
   - Retrouve la PR ouverte correspondante (titre `[Brouillon] ...` contenant le slug, ou via le fichier `content/articles/{slug}.json`)
   - Récupère/checkout la branche de cette PR (ne crée pas de nouvelle branche)
   - Modifie le JSON :
     - `"draft": false`
     - `"publishedAt"` = maintenant (ISO 8601 UTC)
     - `"updatedAt"` = maintenant si le champ existe
   - Merge la PR associée sur `main` (ou commit direct sur main si pas de PR)
   - Envoie sur Telegram : `✅ Article « {title} » publié sur BlogIA`
   - Retire l'entrée de la section « en attente » dans MEMORIES.md
   - Ajoute le slug à la section « traités » avec timestamp

3. **Pour chaque commande REFUSÉ {slug}**
   - Retrouve la PR ouverte correspondante (titre `[Brouillon] ...` contenant le slug)
   - Ferme la PR sans merger (commentaire : « Refusé par l'éditeur via Telegram »)
   - Le fichier `content/articles/{slug}.json` n'étant que sur la branche de la PR, il disparaît avec elle ; s'il a atterri sur `main`, supprime-le
   - Envoie sur Telegram : `❌ Article « {slug} » refusé et supprimé`
   - Retire l'entrée de MEMORIES.md

4. **Si aucune commande en attente**
   - Termine silencieusement sans action ni message

## Contraintes
- Ne publier (`draft: false`) QUE sur commande explicite `VALIDÉ {slug}`
- Ne jamais publier un article dont le slug ne correspond pas exactement à la commande
- Un seul traitement par message (idempotence via MEMORIES.md)
- En cas d'erreur (fichier introuvable, PR absente), envoie un message Telegram d'erreur explicite
```
