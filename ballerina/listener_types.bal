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

# Configuration for the Telegram webhook `Listener`. Provide exactly one of `secretToken` or
# `token`.
@display {label: "Listener Config"}
public type ListenerConfig record {|
    # Use this secret token directly. Every inbound update is authenticated by comparing it
    # against the `X-Telegram-Bot-Api-Secret-Token` header.
    @display {label: "Secret Token"}
    string secretToken?;
    # Derive the secret token from this bot token via `deriveSecretToken` — the same derivation
    # `Client->setWebhook` falls back to when its own `secret_token` option is omitted, so neither
    # side needs a separately invented/threaded secret. Also required (alongside `publicUrl`) for
    # the listener to register its own webhook automatically when it starts.
    @display {label: "Bot Token"}
    string token?;
    # This listener's public HTTPS URL. When set together with `token`, starting the listener
    # automatically registers it as the webhook via `Client->setWebhook`, so no separate
    # `setWebhook` call is needed.
    @display {label: "Public URL"}
    string publicUrl?;
    # The Telegram Bot API base URL used for the automatic `setWebhook` call when `publicUrl` is
    # set. Only useful to override in tests or when routing through a proxy.
    string serviceUrl = DEFAULT_BASE_URL;
|};
