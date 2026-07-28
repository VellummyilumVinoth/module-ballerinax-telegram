# Tests

This directory contains the package tests for the Telegram Bot API connector.

- `test.bal` — verifies client initialization, the webhook secret-token check
  (`X-Telegram-Bot-Api-Secret-Token` match/mismatch/missing), discrimination of the `ChatMember`,
  `ReplyMarkup`, and `InputMedia` unions, the `unwrapResult` response-envelope helper, and the
  `constantTimeEquals` secret comparison helper.

## Running the tests

None of the tests require live credentials, but the dispatch tests do exercise the native
`HandlerDispatcher` module, so it must be built first:

```bash
./gradlew :telegram-native:build
cd ballerina
bal test
```

Adding live API tests: create a `Config.toml` with a `token` and a `chatId`, and gate the tests
with a test group (e.g. `@test:Config {groups: ["live"]}`) so they are skipped by default in CI
(`bal test --groups=mock` runs everything except a `live`-tagged group).
