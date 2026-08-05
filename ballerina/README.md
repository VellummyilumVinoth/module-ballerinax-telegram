## Overview

The [Telegram Bot API](https://core.telegram.org/bots/api) lets bots send and receive messages, manage chats, answer inline/callback queries, and more, over a simple HTTPS REST API.

The `ballerinax/telegram` package provides both:

- A **client** (`telegram:Client`) covering chat management, callback/inline query answers, file metadata/download, messaging (text, photos, videos, documents, audio, animations, stickers, locations, media groups, message/rich-message drafts), and webhook management.
- A webhook **listener** (`telegram:Listener`) for the 9 update types Telegram delivers most commonly (`message`, `edited_message`, `channel_post`, `edited_channel_post`, `callback_query`, `inline_query`, `poll`, `pre_checkout_query`, `shipping_query`), authenticated via the `X-Telegram-Bot-Api-Secret-Token` header. Each handler is optional — implement only the ones your bot needs.

The client and listener are hand-written directly against the [official Bot API reference](https://core.telegram.org/bots/api) — not generated from an OpenAPI spec (Telegram publishes none). The client covers 27 messaging/chat/callback/file actions plus 3 webhook-management calls (`setWebhook`/`deleteWebhook`/`getWebhookInfo`), and the listener handles 9 update types.

## Setup guide

### Step 1: Create a bot and get a token

1. Open a chat with [@BotFather](https://t.me/BotFather) on Telegram.
2. Send `/newbot` and follow the prompts to choose a display name and a unique `@username` (must end in `bot`).
3. BotFather replies with a **bot token** (e.g. `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`) — use this as `token` in `telegram:ConnectionConfig`.

Unlike most APIs, Telegram doesn't use a header or query parameter for auth — the token is embedded directly in every request's URL path (`https://api.telegram.org/bot<token>/<method>`); the client and listener handle this automatically.

Treat the token like a password: anyone who has it can control the bot. Regenerate it via BotFather's `/revoke` command if it leaks.

### Step 2: Get a chat ID (client)

Most `Client` operations need a `chatId` — the numeric ID of the chat/group/channel to act on:

- **Private chat**: message your bot from your own account, then call `getUpdates` (`https://api.telegram.org/bot<token>/getUpdates`) and read `message.chat.id` from the response. Forwarding a message to [@get_id_bot](https://t.me/get_id_bot) also works, but only forward messages you're comfortable sharing with a third-party bot — prefer `getUpdates` for anything sensitive.
- **Group/supergroup**: add the bot to the group, send any message, then use the same `getUpdates` approach — group chat IDs are negative numbers.
- **Channel**: add the bot as an administrator, then use the channel's `@username` (e.g. `"@my_channel"`) directly as `chatId` instead of a numeric ID.

### Step 3: Configure a webhook (listener)

The `telegram:Listener` needs updates pushed to it — Telegram supports only one webhook URL per bot, and it must be reachable over HTTPS.

Expose the listener's port publicly first (a tunnel such as `ngrok http 8090` is the usual approach during development), then start the listener with the bot token and that public URL — it registers its own webhook automatically:

```ballerina
listener telegram:Listener telegramListener = new (8090, token = "my-bot-token", publicUrl = "https://my-app.example.com/");
```

No separate `Client->setWebhook` call, and no `secretToken`/`secret_token` anywhere — the listener derives the secret token from the bot token via `deriveSecretToken` and registers `publicUrl` as the webhook itself as soon as it starts. By default, `allowed_updates` is set to exactly the 9 update types this connector's `Listener` supports (`message`, `edited_message`, `channel_post`, `edited_channel_post`, `callback_query`, `inline_query`, `poll`, `pre_checkout_query`, `shipping_query`), so Telegram itself filters out anything else before it ever reaches your webhook. That's separate from dispatch: even among these 9 types, an update is only delivered to your service if you declared a handler for it (see Step 3 below) — an update whose type you didn't declare a handler for is logged and dropped after reaching the listener, not before.

If you'd rather register the webhook yourself (e.g. from a separate process, or to control exactly when it happens), omit `publicUrl` and call `Client->setWebhook` explicitly instead — note this still needs a `token`-initialized `Client`, and both the listener and the client must agree on the same secret token:

```ballerina
listener telegram:Listener telegramListener = new (8090, token = "my-bot-token");
...
telegram:Client telegramClient = check new ({token: "my-bot-token"});
_ = check telegramClient->setWebhook("https://my-app.example.com/");
```

Both independently derive the same secret token from the bot token, so they agree with no coordination. And if you'd rather manage the secret token yourself entirely (e.g. to rotate it independently of the bot token), pass `secretToken`/`secret_token` explicitly instead of `token` on **both** the listener and `setWebhook` — any string matching `[A-Za-z0-9_-]{1,256}` — it takes precedence over the derived default. If the two sides end up with different secret tokens (e.g. one passes `token` and the other passes a different `secretToken`), every update is rejected with `401` — see below.

Telegram then `POST`s each update to your URL, carrying the configured secret token in the `X-Telegram-Bot-Api-Secret-Token` header — the listener rejects (`401`) any request where this doesn't match exactly, so `ListenerConfig` always requires one of `secretToken`/`token`, with no bypass.

To stop receiving updates, call `Client->deleteWebhook()`. To check what's currently registered (e.g. to debug a webhook that isn't firing), call `Client->getWebhookInfo()`.

## Quickstart

The connector has two independent entry points — a **client** for calling the Bot API and a **listener** for handling webhook updates. Follow the track that matches your use case.

### Client

Use this if your app only needs to send messages or manage chats/files (no update handling).

#### Step 1: Import the module

```ballerina
import ballerina/io;
import ballerinax/telegram;
```

#### Step 2: Initialize a Telegram client

```ballerina
configurable string token = ?;
configurable string chatId = ?;

telegram:Client telegramClient = check new ({token});
```

#### Step 3: Invoke connector operations

```ballerina
public function main() returns error? {
    telegram:Message sent = check telegramClient->sendMessage(chatId, "Hello from Ballerina!");
    io:println(sent.message_id);
}
```

Send a photo or get chat info the same way:

```ballerina
telegram:Message photo = check telegramClient->sendPhoto(chatId, "https://example.com/photo.jpg");
telegram:ChatFullInfo chat = check telegramClient->getChat(chatId);
```

To answer a callback query, use the `id` of the `telegram:CallbackQuery` your service receives (see the listener's `onCallbackQuery` handler below):

```ballerina
_ = check telegramClient->answerCallbackQuery(callbackQuery.id, text = "Got it!");
```

#### Step 4: Run the Ballerina application

```bash
bal run
```

### Listener

Use this if your app needs to handle incoming messages, callback/inline queries, or other webhook updates.

#### Step 1: Import the module

```ballerina
import ballerinax/telegram;
```

#### Step 2: Initialize a Telegram listener

```ballerina
listener telegram:Listener telegramListener = new (8090, secretToken = "my-secret-token");
```

#### Step 3: Implement the service

`telegram:TelegramService` has nine possible handlers, one per supported update type, and all of them are optional — implement only the ones you need. Telegram's `allowed_updates` already keeps unsupported update types from reaching your webhook at all; among the 9 supported types, one whose handler you didn't declare is logged and dropped after reaching the listener, not delivered anywhere. Declaring a handler under any other name, with the wrong parameter type, or without the `remote` qualifier is a compile error, caught by this connector's compiler plugin.

```ballerina
service telegram:TelegramService on telegramListener {
    remote function onMessage(telegram:Message message) returns error? {
        // handle an incoming message: message.text
    }
}
```

The other eight handlers — `onEditedMessage`, `onChannelPost`, `onEditedChannelPost`, `onCallbackQuery`, `onInlineQuery`, `onPoll`, `onPreCheckoutQuery`, `onShippingQuery` — each take the corresponding Telegram Bot API type directly (`Message`, `CallbackQuery`, `InlineQuery`, `Poll`, `PreCheckoutQuery`, or `ShippingQuery`), matching the field types on Telegram's own `Update` object; add whichever ones your bot needs. See `examples/approval-bot` for a complete implementation of all nine, including an approve/decline flow built on `sendApprovalMessage`.

#### Step 4: Run the Ballerina application

```bash
bal run
```

Register the listener's public URL as the webhook (see the setup guide above) to start receiving updates.

## Examples

The `telegram` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-telegram/tree/main/examples).

1. [Send a Telegram message](https://github.com/ballerina-platform/module-ballerinax-telegram/tree/main/examples/send-message) — send a text message, a photo by URL, and an uploaded document via the client.
2. [Run a Telegram approval bot](https://github.com/ballerina-platform/module-ballerinax-telegram/tree/main/examples/approval-bot) — handle all nine update types over the listener, including an approve/decline flow.
