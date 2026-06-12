# Automatisation 2 — Validation Telegram & publication

> Copier ce prompt dans [cursor.com/automations](https://cursor.com/automations) ou l'Agents Window.

## ⚠️ IMPORTANT — MCP env ≠ shell env

Les variables dans la config **MCP** (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_BOT_API_TOKEN`)
ne sont visibles **que par le processus MCP**, pas par les commandes shell (`curl`).

| Où mettre le token | Visible par | Usage |
|--------------------|-------------|-------|
| Config MCP → `TELEGRAM_BOT_API_TOKEN` | MCP uniquement | `send-message` (confirmations) |
| Config MCP → `TELEGRAM_BOT_TOKEN` | MCP uniquement | ❌ **inutile** pour curl |
| **Dans le prompt** (remplacer `__BOT_TOKEN__`) | Shell (`curl`) | `getUpdates` (lecture) |

**Avant de sauvegarder l'automatisation**, remplace `__BOT_TOKEN__` dans le prompt
ci-dessous par ton vrai token BotFather. C'est la seule méthode fiable en cloud.

---

## Configuration

| Paramètre | Valeur |
|-----------|--------|
| **Nom** | BlogIA — Validation & publication |
| **Déclencheur** | Planifié — toutes les 15 minutes (`*/15 * * * *`) |
| **Dépôt** | `davyagonma/BlogIA` — branche `main` |
| **Outils** | Open pull request, Memories, MCP Telegram |

### MCP (envoi uniquement)

```json
{
  "mcpServers": {
    "telegram": {
      "command": "npx",
      "args": ["-y", "telegram-bot-mcp-server"],
      "env": {
        "TELEGRAM_BOT_API_TOKEN": "ton_token"
      }
    }
  }
}
```

Une seule variable MCP suffit : `TELEGRAM_BOT_API_TOKEN`.

---

## Prompt

> 🔧 Remplace `__BOT_TOKEN__` par ton token AVANT de coller ce prompt dans l'automatisation.

```
Tu es l'agent de validation éditoriale de BlogIA.

## Mission
Lire les commandes Telegram (VALIDÉ / REFUSÉ), puis publier ou refuser les articles en brouillon.

## Règles Telegram

- LECTURE : curl + API Bot (PAS de MCP pour lire)
- ENVOI : outil MCP `send-message` (chatId: "5530576033", text: "...")
- Token curl (déjà dans le prompt) : __BOT_TOKEN__

## Étapes obligatoires

1. **Lire les messages Telegram** (curl getUpdates)
   - Lis dans `.cursor/MEMORIES.md` le dernier `update_id` (section « Dernier update_id »).
     Si absent, utilise offset=0.
   - Exécute exactement :
     ```bash
     curl -s "https://api.telegram.org/bot8847908337:AAF8EfCMFMvAj_8OyfcCQXX-OLzed8VOXxY/getUpdates?offset=<dernier_update_id+1>&timeout=0"
     ```
   - Parse le JSON : pour chaque `result[].message.text`, cherche `VALIDÉ {slug}` ou `REFUSÉ {slug}`
     (insensible à la casse).
   - Ignore les messages déjà dans MEMORIES.md section « Validations déjà traitées ».
   - Si aucun nouveau message de commande → termine SILENCIEUSEMENT (pas de message Telegram).

2. **Pour chaque commande VALIDÉ {slug}**
   - Retrouve la PR ouverte (titre `[Brouillon]` contenant le slug)
   - Checkout la branche de la PR (ne crée PAS de nouvelle branche)
   - Modifie `content/articles/{slug}.json` :
     - `"draft": false`
     - `"publishedAt"` = maintenant (ISO 8601 UTC)
     - `"updatedAt"` = maintenant
   - Commit, push (`git push origin HEAD`)
   - Merge la PR sur `main`
   - MCP send-message : `✅ Article « {title} » publié sur BlogIA`
   - Mets à jour MEMORIES.md

3. **Pour chaque commande REFUSÉ {slug}**
   - Retrouve la PR ouverte correspondante
   - Ferme la PR sans merger (commentaire : « Refusé par l'éditeur via Telegram »)
   - MCP send-message : `❌ Article « {slug} » refusé et supprimé`
   - Mets à jour MEMORIES.md

4. **Après traitement**
   - Enregistre le plus grand `update_id` dans MEMORIES.md (section « Dernier update_id »)
   - Commit MEMORIES.md si modifié

## Contraintes
- Ne JAMAIS utiliser MCP pour lire (getUpdates n'existe pas sur ce serveur)
- Ne JAMAIS vérifier $TELEGRAM_BOT_TOKEN en shell (cette variable n'existe pas en cloud)
- Ne publier (`draft: false`) QUE sur `VALIDÉ {slug}` explicite
- Si aucune commande en attente : terminer sans envoyer de message
```
