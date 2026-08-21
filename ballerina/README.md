## Overview

The [Telegram Bot API](https://core.telegram.org/bots/api) lets bots send and receive messages, manage chats, answer inline/callback queries, and more, over a simple HTTPS REST API.

The `ballerinax/telegram` package provides both:

- A **client** (`telegram:Client`) covering chat management, callback/inline query answers, file metadata/download, messaging (text, photos, videos, documents, audio, animations, stickers, locations, media groups, message/rich-message drafts), and webhook management.
- A webhook **listener** (`telegram:Listener`) for the 9 update types Telegram delivers most commonly (`message`, `edited_message`, `channel_post`, `edited_channel_post`, `callback_query`, `inline_query`, `poll`, `pre_checkout_query`, `shipping_query`), authenticated via the `X-Telegram-Bot-Api-Secret-Token` header. Each handler is optional — implement only the ones your bot needs.

The client and listener are hand-written directly against the [official Bot API reference](https://core.telegram.org/bots/api) — not generated from an OpenAPI spec (Telegram publishes none). The client covers 27 messaging/chat/callback/file actions plus 3 webhook-management calls (`setWebhook`/`deleteWebhook`/`getWebhookInfo`), and the listener handles 9 update types.

## Setup guide

### Step 1: Create a bot and get an access token

1. Open a chat with [@BotFather](https://t.me/BotFather) on Telegram.
2. Send `/newbot` and follow the prompts to choose a display name and a unique `@username` (must end in `bot`).
3. BotFather replies with a **bot access token** (e.g. `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`) — use this as `accessToken` in `telegram:ConnectionConfig`/`telegram:ListenerConfig`.

Unlike most APIs, Telegram doesn't use a header or query parameter for auth — the access token is embedded directly in every request's URL path (`https://api.telegram.org/bot<accessToken>/<method>`); the client and listener handle this automatically.

Treat the access token like a password: anyone who has it can control the bot. Regenerate it via BotFather's `/revoke` command if it leaks.

### Step 2: Get a chat ID (client)

Most `Client` operations need a `chatId` — the numeric ID of the chat/group/channel to act on:

- **Private chat**: message your bot from your own account, then call `getUpdates` (`https://api.telegram.org/bot<accessToken>/getUpdates`) and read `message.chat.id` from the response. Forwarding a message to [@get_id_bot](https://t.me/get_id_bot) also works, but only forward messages you're comfortable sharing with a third-party bot — prefer `getUpdates` for anything sensitive.
- **Group/supergroup**: add the bot to the group, send any message, then use the same `getUpdates` approach — group chat IDs are negative numbers.
- **Channel**: add the bot as an administrator, then use the channel's `@username` (e.g. `"@my_channel"`) directly as `chatId` instead of a numeric ID.

### Step 3: Configure a webhook (listener)

The `telegram:Listener` needs updates pushed to it — Telegram supports only one webhook URL per bot, and it must be reachable over HTTPS.

Expose the listener's port publicly first (a tunnel such as `ngrok http 8090` is the usual approach during development), then start the listener with the bot access token and that public URL — it registers its own webhook automatically:

```ballerina
listener telegram:Listener telegramListener = new (8090, accessToken = "my-bot-access-token", callbackUrl = "https://my-app.example.com/");
```

No separate `Client->setWebhook` call needed, and there's no separate secret to configure — the listener always derives its webhook secret token internally from `accessToken` via `deriveSecretToken`, and registers `callbackUrl` as the webhook itself as soon as it starts. By default, `allowed_updates` is set to exactly the 9 update types this connector's `Listener` supports (`message`, `edited_message`, `channel_post`, `edited_channel_post`, `callback_query`, `inline_query`, `poll`, `pre_checkout_query`, `shipping_query`), so Telegram itself filters out anything else before it ever reaches your webhook. That's separate from dispatch: even among these 9 types, an update is only delivered to your service if you declared a handler for it (see Step 3 below) — an update whose type you didn't declare a handler for is logged and dropped after reaching the listener, not before.

> **Coming from a platform like n8n's Telegram Trigger?** That node only asks for an **Access Token** (and, optionally, a **Base URL** for a self-hosted Bot API server) because n8n itself is a platform that can supply and auto-register its own reachable webhook URL — you never see that step. This connector is a library, not a platform, so the mapping is:
> - `accessToken` = n8n's **Access Token** — the same bot access token you also pass to `telegram:Client`.
> - `serviceUrl` = n8n's optional **Base URL** — leave it at the default to talk to `api.telegram.org`; only override it if you're running your own Bot API server.
> - `callbackUrl` has no n8n equivalent to set manually — you must supply your own publicly reachable HTTPS URL (e.g. the tunnel URL above), since nothing here auto-provisions one for you.
> - There's no secret-token field at all — n8n doesn't expose one either. It's always derived from `accessToken` and never something you configure.

If you'd rather register the webhook yourself (e.g. from a separate process, or to control exactly when it happens), omit `callbackUrl` and call `Client->setWebhook` explicitly instead — note this still needs an `accessToken`-initialized `Client`:

```ballerina
listener telegram:Listener telegramListener = new (8090, accessToken = "my-bot-access-token");
...
telegram:Client telegramClient = check new ({accessToken: "my-bot-access-token"});
_ = check telegramClient->setWebhook("https://my-app.example.com/");
```

Both independently derive the same secret token from the same `accessToken`, so they agree with no coordination needed — as long as you pass the same `accessToken` to both, `setWebhook`'s default `secret_token` always matches what the `Listener` expects.

Telegram then `POST`s each update to your URL, carrying the derived secret token in the `X-Telegram-Bot-Api-Secret-Token` header — the listener rejects (`401`) any request where this doesn't match exactly.

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
configurable string accessToken = ?;
configurable string chatId = ?;

telegram:Client telegramClient = check new ({accessToken});
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
listener telegram:Listener telegramListener = new (8090, accessToken = "my-bot-access-token");
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

By default, the listener acknowledges (`200 OK`) each update automatically, before any handler runs — Telegram requires a fast `2xx` and retries otherwise, so this is the safe default for slow handlers. If you'd rather decide exactly when an update is acknowledged (e.g. only after some work has durably succeeded), annotate the service `@telegram:ServiceConfig { autoAck: false }` and declare a handler's optional second parameter as a `telegram:Caller`:

```ballerina
listener telegram:Listener telegramListener = new (8090, accessToken = "my-bot-access-token");

@telegram:ServiceConfig {
    autoAck: false
}
service telegram:TelegramService on telegramListener {
    remote function onMessage(telegram:Message message, telegram:Caller caller) returns error? {
        check persistMessage(message);
        check caller->complete();
    }
}
```

If a handler declared with a `Caller` never calls `caller->complete()`, the listener never sends its own `200 OK` for that request — the underlying HTTP service falls back to a default `500`, a non-`2xx` that Telegram's own retry behavior treats the same as any other failed delivery. This connector adds no ack-tracking or retry logic of its own beyond that.

Telegram may redeliver an update if the acknowledgement is slow, dropped, or never sent — under either `autoAck` setting, not just `false`. Make handler processing idempotent, or deduplicate using `update_id`, rather than assuming a webhook update is delivered exactly once.

#### Step 4: Run the Ballerina application

```bash
bal run
```

Register the listener's public URL as the webhook (see the setup guide above) to start receiving updates.

## Examples

The `telegram` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-telegram/tree/main/examples).

1. [Send a Telegram message](https://github.com/ballerina-platform/module-ballerinax-telegram/tree/main/examples/send-message) — send a text message, a photo by URL, and an uploaded document via the client.
2. [Run a Telegram approval bot](https://github.com/ballerina-platform/module-ballerinax-telegram/tree/main/examples/approval-bot) — handle all nine update types over the listener, including an approve/decline flow.
