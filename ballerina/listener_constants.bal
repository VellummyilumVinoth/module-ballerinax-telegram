// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

// ── Webhook Verification ────────────────────────────────────────────────────────

# The header Telegram sends with every webhook request, carrying the caller-chosen secret token.
const SECRET_TOKEN_HEADER = "X-Telegram-Bot-Api-Secret-Token";

# The HMAC key used to derive a webhook secret token from a bot token in `deriveSecretToken`.
# Fixed and public (not itself a secret) — domain separation only, so the derived secret token
# isn't just a bare hash of the bot token.
const DERIVE_SECRET_TOKEN_KEY = "ballerinax/telegram:webhook-secret";

# The 9 `Update` fields this connector's `Listener`/`TelegramService` supports. Used as
# `setWebhook`'s `allowed_updates` default when the caller passes `"*"` — anything Telegram would
# otherwise deliver outside this set is logged and dropped by the dispatcher anyway.
final readonly & string[] SUPPORTED_UPDATE_TYPES = ["message", "edited_message", "channel_post",
        "edited_channel_post", "callback_query", "inline_query", "poll", "pre_checkout_query", "shipping_query"];

// ── Log Messages ────────────────────────────────────────────────────────────────

const LOG_WEBHOOK_POST_RECEIVED = "Telegram webhook POST received";

// ── Warning Messages ────────────────────────────────────────────────────────────
// Expected, non-failure conditions: an adversarial/misconfigured caller, or a real Telegram
// update this connector deliberately doesn't support.

const WARN_SECRET_TOKEN_MISMATCH = "Telegram webhook secret token missing or mismatched; rejecting update";
const WARN_UNRECOGNIZED_UPDATE_FIELD =
    "Update did not match any of the 9 supported fields; dropping notification";

// ── Listener / Dispatch Error Messages ───────────────────────────────────────────
// Failures processing what is otherwise a legitimate, authenticated Telegram request; the update
// is silently dropped as a result.

const ERR_PAYLOAD_READ_FAILED = "Failed to read Telegram webhook payload as text";
const ERR_PAYLOAD_PARSE_FAILED = "Failed to parse Telegram webhook payload as JSON";
const ERR_UPDATE_PARSE_FAILED = "Failed to parse Telegram update envelope";
const ERR_ACK_FAILED = "Failed to acknowledge the Telegram webhook update";

const ERR_HTTP_LISTENER_INIT_FAILED = "Failed to initialize the underlying http:Listener";
const ERR_HTTP_LISTENER_ATTACH_FAILED = "Failed to attach the service to the underlying http:Listener";
const ERR_HTTP_LISTENER_DETACH_FAILED = "Failed to detach the service from the underlying http:Listener";
const ERR_HTTP_LISTENER_START_FAILED = "Failed to start the underlying http:Listener";
const ERR_HTTP_LISTENER_STOP_FAILED = "Failed to stop the underlying http:Listener";

const ERR_ON_MESSAGE_HANDLER = "Error in onMessage handler";
const ERR_ON_EDITED_MESSAGE_HANDLER = "Error in onEditedMessage handler";
const ERR_ON_CHANNEL_POST_HANDLER = "Error in onChannelPost handler";
const ERR_ON_EDITED_CHANNEL_POST_HANDLER = "Error in onEditedChannelPost handler";
const ERR_ON_CALLBACK_QUERY_HANDLER = "Error in onCallbackQuery handler";
const ERR_ON_INLINE_QUERY_HANDLER = "Error in onInlineQuery handler";
const ERR_ON_POLL_HANDLER = "Error in onPoll handler";
const ERR_ON_PRE_CHECKOUT_QUERY_HANDLER = "Error in onPreCheckoutQuery handler";
const ERR_ON_SHIPPING_QUERY_HANDLER = "Error in onShippingQuery handler";
