# Change Log

This file contains all the notable changes done to the Ballerina Telegram connector through the
releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- [Simplify webhook Listener config and add manual acknowledgement support](https://github.com/ballerina-platform/ballerina-library/issues/9037)
  - Added a `ServiceConfig` annotation (`TelegramServiceConfig.autoAck`) and a `Caller` client, so
    a service can take control of when an update is acknowledged instead of the listener always
    responding `200 OK` automatically before dispatch. Annotate the service `@ServiceConfig
    {autoAck: false}` and declare a handler's optional second parameter as `Caller` (e.g.
    `onMessage(Message message, Caller caller)`), then call `caller->complete()` once that
    handler's own processing has durably succeeded — `Caller` is otherwise irrelevant to declare,
    since with the default `autoAck: true` the listener always acknowledges automatically before
    dispatch.

### Changed

- [Simplify webhook Listener config and add manual acknowledgement support](https://github.com/ballerina-platform/ballerina-library/issues/9037)
  - Renamed `ConnectionConfig`/`ListenerConfig`'s `token` field to `accessToken`, and
    `ListenerConfig.publicUrl` to `callbackUrl`, to align with common Bot API integration
    terminology.
  - Removed `ListenerConfig.secretToken` as a public field — the webhook secret token is now
    always derived internally from `accessToken` via `deriveSecretToken`.

## [0.9.2] - 2026-08-07

### Changed

- [Reduce doc verbosity in listener config docs](https://github.com/ballerina-platform/module-ballerinax-telegram/pull/8)

## [0.9.1] - 2026-08-03

### Fixed

- [Fix Ballerina Central doc site rendering repo-only README content](https://github.com/ballerina-platform/module-ballerinax-telegram/pull/6)

## [0.9.0] - 2026-07-29

### Added

- [Introduce a Ballerina connector for Telegram](https://github.com/ballerina-platform/ballerina-library/issues/8896),
  providing:
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
