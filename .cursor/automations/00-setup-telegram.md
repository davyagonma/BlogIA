# Setup Telegram Bot — à faire une seule fois

Bot créé via @BotFather : **t.me/blogia01_bot**

## 1. Sécuriser le token

Le token a été partagé en clair. Régénérez-le :

1. Ouvrez [@BotFather](https://t.me/BotFather)
2. `/revoke` → sélectionnez `@blogia01_bot`
3. Copiez le **nouveau** token

## 2. Renseigner les variables locales

Copiez `.env.example` vers `.env` et remplissez :

```bash
cp .env.example .env
```

```
TELEGRAM_BOT_TOKEN=le_nouveau_token
TELEGRAM_CHAT_ID=...   # voir étape 3
```

`.env` est gitignoré — le token n'est jamais committé.

## 3. Récupérer votre `chat_id`

1. Ouvrez Telegram et **envoyez un message** au bot `t.me/blogia01_bot` (ex: « bonjour »).
2. Récupérez le chat ID via l'API :

```bash
curl "https://api.telegram.org/bot<VOTRE_TOKEN>/getUpdates"
```

3. Dans la réponse JSON, repérez `result[].message.chat.id` — c'est votre `TELEGRAM_CHAT_ID`.
4. Collez-le dans `.env`.

## 4. Charger les variables pour les tests MCP locaux

`.cursor/mcp.json` lit `${TELEGRAM_BOT_TOKEN}` et `${TELEGRAM_CHAT_ID}`.
Exportez-les dans votre shell avant de lancer Cursor, ou définissez-les dans l'UI MCP de Cursor :

```bash
export TELEGRAM_BOT_TOKEN=le_nouveau_token
export TELEGRAM_CHAT_ID=votre_chat_id
```

Vérifiez la connexion :

```bash
cursor agent mcp list-tools telegram
```

## 5. Configurer les automatisations cloud

Dans [cursor.com/automations](https://cursor.com/automations), pour CHAQUE automatisation,
ajoutez le serveur MCP Telegram avec les variables d'environnement :

| Variable | Valeur |
|----------|--------|
| `TELEGRAM_BOT_TOKEN` | le nouveau token |
| `TELEGRAM_DEFAULT_CHAT_ID` | votre chat ID |
| `TELEGRAM_META_MODE` | `true` |

Commande : `npx -y telegram-api-mcp`

> Les automatisations cloud n'ont PAS accès à votre `.env` local : les variables
> doivent être saisies dans l'UI de l'automatisation.
