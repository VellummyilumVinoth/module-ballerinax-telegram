# Run a Telegram approval bot

This example runs a webhook `Listener` implementing all 9 `TelegramService` handlers. Any text
message it receives gets an approve/decline prompt via `Client->sendApprovalMessage`; pressing a
button is handled by `onCallbackQuery`, which acknowledges the press and edits the original
message to show the decision.

## Prerequisites

Create a `Config.toml` in this directory:

```toml
token = "<BOT_TOKEN>"
secretToken = "<WEBHOOK_SECRET_TOKEN>"
```

See the root [setup guide](../../README.md#setup-guide) for how to obtain a bot token and
register a webhook.

## Run the example

```bash
bal run
```

The listener starts on port `8090`. Point a public tunnel (e.g. `ngrok http 8090`) at it and
register the webhook:

```ballerina
telegram:Client telegramClient = check new ({token});
_ = check telegramClient->setWebhook("https://my-app.example.com/", secret_token = secretToken);
```

Then message the bot to see the approve/decline prompt.
