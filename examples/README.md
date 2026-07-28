# Examples

The following examples demonstrate the use of the Ballerina Telegram Bot API connector.

1. [Send a Telegram message](send-message) — send a text message, a photo by URL, and a document
   via the client.
2. [Run a Telegram approval bot](approval-bot) — handle all 9 supported update types over the
   webhook listener, including an approve/decline flow built on `sendApprovalMessage` and
   `onCallbackQuery`.

## Running an example

Each example is a standalone Ballerina package. Provide the required configuration in a `Config.toml`
in the example directory, then run:

```bash
bal run
```
