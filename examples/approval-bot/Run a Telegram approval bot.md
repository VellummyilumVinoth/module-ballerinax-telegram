# Run a Telegram approval bot

This example runs a webhook `Listener` implementing all 9 `TelegramService` handlers. Any text
message it receives gets an approve/decline prompt via `Client->sendApprovalMessage`; pressing a
button is handled by `onCallbackQuery`, which acknowledges the press and edits the original
message to show the decision.

## Prerequisites

Expose port `8090` publicly first (a tunnel such as `ngrok http 8090` is the usual approach during
development), then create a `Config.toml` in this directory with your bot's access token and that
public URL:

```toml
accessToken = "<BOT_ACCESS_TOKEN>"
callbackUrl = "<YOUR_PUBLIC_HTTPS_URL>"
```

See the root [setup guide](../../README.md#setup-guide) for how to obtain a bot access token.

## Run the example

```bash
bal run
```

The listener starts on port `8090` and registers `callbackUrl` as its webhook automatically —
the webhook secret token is derived internally from `accessToken`, so there's nothing else to
configure. Message the bot to see the approve/decline prompt.
