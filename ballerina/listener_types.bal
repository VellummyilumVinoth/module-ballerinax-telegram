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

# Configuration for the Telegram webhook `Listener`.
@display {label: "Listener Config"}
public type ListenerConfig record {|
    # The bot access token issued by @BotFather. Used both to derive the webhook secret token
    # and, together with `callbackUrl`, to auto-register the webhook.
    @display {label: "Access Token"}
    string accessToken;
    # This listener's public HTTPS URL, used to auto-register the webhook when set.
    @display {label: "Callback URL"}
    string callbackUrl?;
    # The Telegram Bot API base URL; override only for a self-hosted Bot API server, tests, or a proxy.
    @display {label: "Service URL"}
    string serviceUrl = DEFAULT_BASE_URL;
|};
