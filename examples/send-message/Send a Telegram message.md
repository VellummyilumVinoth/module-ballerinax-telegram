# Send a Telegram message

This example sends a text message, a photo (by URL), and a document (uploaded from raw bytes)
using the connector's `Client`.

## Prerequisites

Create a `Config.toml` in this directory:

```toml
accessToken = "<BOT_ACCESS_TOKEN>"
chatId = "<CHAT_ID>"
```

See the root [setup guide](../../README.md#setup-guide) for how to obtain a bot access token from
@BotFather and find a chat ID.

## Run the example

```bash
bal run
```
