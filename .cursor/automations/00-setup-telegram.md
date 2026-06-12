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

Test direct du serveur (envoi réel) :

```bash
set -a && . ./.env && set +a
{ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}'; sleep 8; \
  printf '%s\n' '{"jsonrpc":"2.0","method":"notifications/initialized"}'; \
  printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"send-message","arguments":{"chatId":"'$TELEGRAM_CHAT_ID'","text":"Test MCP OK"}}}'; sleep 5; } \
  | TELEGRAM_BOT_API_TOKEN="$TELEGRAM_BOT_TOKEN" npx -y telegram-bot-mcp-server
```

## 5. Configurer les automatisations cloud

Dans [cursor.com/automations](https://cursor.com/automations), pour CHAQUE automatisation,
ajoutez le serveur MCP Telegram :

- **Command** : `npx -y telegram-bot-mcp-server`
- **Env** :

| Variable | Valeur |
|----------|--------|
| `TELEGRAM_BOT_API_TOKEN` | votre token de bot |

> ⚠️ Le paquet est bien `telegram-bot-mcp-server` (testé, fonctionne).
> `telegram-api-mcp` n'existe pas sur npm et `@node2flow/telegram-bot-mcp` crashe.
>
> Le `chatId` (`5530576033`) est passé directement dans l'appel `send-message`,
> pas via une variable d'environnement.
>
> Les automatisations cloud n'ont PAS accès à votre `.env` local : les variables
> doivent être saisies dans l'UI de l'automatisation.

## 6. Automatisation de validation — token dans le PROMPT

⚠️ Les variables MCP ne sont PAS visibles par `curl` dans le shell cloud.

Pour l'automatisation **Validation & publication** :
1. Config MCP : seulement `TELEGRAM_BOT_API_TOKEN` (pour `send-message`)
2. Dans le **prompt** : remplace `__BOT_TOKEN__` par ton token avant de sauvegarder

Ne mets PAS `TELEGRAM_BOT_TOKEN` dans la config MCP — ça ne sert à rien pour curl.
