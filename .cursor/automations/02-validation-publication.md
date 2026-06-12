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

### MCP Telegram (envoi uniquement)

- Command : `npx -y telegram-bot-mcp-server`
- Env : `TELEGRAM_BOT_API_TOKEN` = ton token

⚠️ Ce serveur expose **`send-message`** mais PAS `getUpdates`.
La **lecture** des commandes se fait via **curl** dans le shell (voir prompt).

### Token accessible au shell (OBLIGATOIRE)

Le token MCP n'est PAS disponible dans le shell du run cloud.
Tu dois **dupliquer** le token dans les variables d'environnement de l'automatisation :

| Variable | Valeur | Usage |
|----------|--------|-------|
| `TELEGRAM_BOT_API_TOKEN` | ton token | MCP `send-message` |
| `TELEGRAM_BOT_TOKEN` | **même token** | curl `getUpdates` dans le shell |

Dans l'UI Cursor Automations → section **Environment variables** (ou Secrets),
ajoute `TELEGRAM_BOT_TOKEN` en plus de la config MCP.

Si l'UI ne propose pas de variables shell, remplace `__TELEGRAM_BOT_TOKEN__`
dans le prompt ci-dessous par ton token avant de sauvegarder l'automatisation.

---

## Prompt

```
Tu es l'agent de validation éditoriale de BlogIA.

## Mission
Lire les commandes Telegram (VALIDÉ / REFUSÉ), puis publier ou refuser les articles en brouillon.

## Règles Telegram

- LECTURE : uniquement via curl + API Bot (PAS de MCP, PAS de getUpdates MCP)
- ENVOI : uniquement via outil MCP `send-message` (chatId: "5530576033", text: "...")
- Token pour curl : utilise $TELEGRAM_BOT_TOKEN si défini, sinon __TELEGRAM_BOT_TOKEN__

## Étapes obligatoires

0. **Vérifier le token**
   - Exécute : `test -n "$TELEGRAM_BOT_TOKEN" && echo "TOKEN_OK" || echo "TOKEN_MISSING"`
   - Si TOKEN_MISSING et que __TELEGRAM_BOT_TOKEN__ n'est pas remplacé, envoie via MCP
     send-message : "⚠️ Config manquante : TELEGRAM_BOT_TOKEN non défini dans l'automatisation."
     puis STOP.

1. **Lire les messages Telegram** (curl getUpdates)
   - Lis dans `.cursor/MEMORIES.md` le dernier `update_id` traité (section « Dernier update_id »).
     Si absent, utilise offset=0.
   - Exécute :
     ```bash
     TOKEN="${TELEGRAM_BOT_TOKEN:-__TELEGRAM_BOT_TOKEN__}"
     OFFSET="<dernier_update_id + 1>"
     curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=${OFFSET}&timeout=0"
     ```
   - Parse le JSON : pour chaque `result[].message.text`, cherche `VALIDÉ {slug}` ou `REFUSÉ {slug}`
     (insensible à la casse, slug en kebab-case).
   - Ignore les messages déjà dans MEMORIES.md section « Validations déjà traitées ».
   - Si aucun nouveau message de commande → termine SILENCIEUSEMENT (pas de message Telegram).

2. **Pour chaque commande VALIDÉ {slug}**
   - Retrouve la PR ouverte (titre `[Brouillon]` contenant le slug ou fichier `content/articles/{slug}.json`)
   - Checkout la branche de la PR (ne crée PAS de nouvelle branche)
   - Modifie `content/articles/{slug}.json` :
     - `"draft": false`
     - `"publishedAt"` = maintenant (ISO 8601 UTC)
     - `"updatedAt"` = maintenant
   - Commit, push sur la branche courante (`git push origin HEAD`)
   - Merge la PR sur `main`
   - MCP send-message : `✅ Article « {title} » publié sur BlogIA`
   - Mets à jour MEMORIES.md (retire « en attente », ajoute « traités », note update_id)

3. **Pour chaque commande REFUSÉ {slug}**
   - Retrouve la PR ouverte correspondante
   - Ferme la PR sans merger (commentaire : « Refusé par l'éditeur via Telegram »)
   - MCP send-message : `❌ Article « {slug} » refusé et supprimé`
   - Mets à jour MEMORIES.md

4. **Après traitement**
   - Enregistre le plus grand `update_id` vu dans MEMORIES.md (section « Dernier update_id »)
   - Commit MEMORIES.md sur la branche courante si modifié

## Contraintes
- Ne JAMAIS utiliser MCP pour lire les messages (getUpdates n'existe pas sur ce serveur)
- Ne publier (`draft: false`) QUE sur `VALIDÉ {slug}` explicite
- Un seul traitement par update_id (idempotence via MEMORIES.md)
- Si aucune commande en attente : terminer sans envoyer de message
- En cas d'erreur sur UNE commande : send-message avec le détail, continuer les autres
```
