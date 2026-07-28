# Change Log

This file contains all the notable changes done to the Ballerina Telegram connector through the
releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- Initial release of the Telegram Bot API connector
  ([#8896](https://github.com/ballerina-platform/ballerina-library/issues/8896)), providing:
  - A `Client` for chat management, callback/inline query answers, file metadata/download,
    messaging (text, photos, videos, documents, audio, animations, stickers, locations, media
    groups, message/rich-message drafts, and approval messages), and webhook management.
  - A `Listener` and `TelegramService` for receiving webhook updates: messages, edited messages,
    channel posts, edited channel posts, callback queries, inline queries, polls, pre-checkout
    queries, and shipping queries. Each handler is optional — implement only the ones you need.
- Added `sendApprovalMessage`, a convenience method for sending an approve/decline
  inline-keyboard prompt.
- Added `deriveSecretToken`, a convenience function for deterministically deriving a webhook
  secret token from a bot token.
- Added `ListenerConfig.token` as an alternative to `secretToken`.
- Added `ListenerConfig.publicUrl` to automatically register the webhook when the listener starts.
