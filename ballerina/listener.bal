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

import ballerina/http;

# A `TelegramService` and its backing `HttpService`, tracked together so `detach` can look up the
# right `HttpService` for a given `TelegramService`.
#
# + telegramService - The attached service
# + httpService - The `HttpService` backing `telegramService`
type AttachedService record {|
    TelegramService telegramService;
    HttpService httpService;
|};

# Listener for Telegram Bot API webhook updates. It wraps an `http:Listener`, authenticates each
# update against a caller-chosen secret token (`X-Telegram-Bot-Api-Secret-Token`), and dispatches
# the 9 supported update types to an attached `TelegramService`.
#
# ```ballerina
# listener telegram:Listener telegramListener = new (8090, token = "<BOT_TOKEN>",
#         publicUrl = "https://<PUBLIC_HOST>/");
#
# service telegram:TelegramService on telegramListener {
#     remote function onMessage(telegram:Message message) returns error? {
#         // handle an incoming message: message.text
#     }
#     // ... plus any of the other eight (optional) handlers this bot needs
# }
# ```
#
# Passing `publicUrl` (alongside `token`) registers this listener's webhook automatically when it
# starts — no separate `Client->setWebhook` call needed.
@display {label: "Telegram", iconPath: "icon.png"}
public class Listener {
    private final http:Listener httpListener;
    private final string secretToken;
    private final string? publicUrl;
    private final Client? webhookClient;
    private AttachedService[] attachedServices = [];

    # Initializes the webhook listener.
    #
    # + listenTo - A port number to bind a new `http:Listener` to, or an existing `http:Listener`
    # + config - The listener configuration; requires either `secretToken` or `token`
    # + return - An `Error` if the listener could not be initialized, otherwise `()`
    public function init(int|http:Listener listenTo, *ListenerConfig config) returns Error? {
        if listenTo is int {
            http:Listener|error httpListener = new (listenTo);
            if httpListener is error {
                return error ClientError(ERR_HTTP_LISTENER_INIT_FAILED, httpListener);
            }
            self.httpListener = httpListener;
        } else {
            self.httpListener = listenTo;
        }
        string? secretToken = config.secretToken;
        string? token = config.token;
        if secretToken is string {
            self.secretToken = secretToken;
        } else if token is string {
            self.secretToken = check deriveSecretToken(token);
        } else {
            return error ClientError(ERR_SECRET_TOKEN_OR_TOKEN_REQUIRED);
        }

        string? publicUrl = config.publicUrl;
        if publicUrl is string {
            if token is () {
                return error ClientError(ERR_PUBLIC_URL_REQUIRES_TOKEN);
            }
            self.publicUrl = publicUrl;
            self.webhookClient = check new ({token}, config.serviceUrl);
        } else {
            self.publicUrl = ();
            self.webhookClient = ();
        }
    }

    # Attaches a `TelegramService` implementation to the listener.
    #
    # + telegramService - The service that handles webhook updates
    # + name - The path (or path segments) to attach the service on; defaults to the listener root
    # + return - An `Error` if attaching failed, otherwise `()`
    public function attach(TelegramService telegramService, string[]|string? name = ()) returns Error? {
        HttpService httpService = new (telegramService, self.secretToken);
        error? attachResult = self.httpListener.attach(httpService, name);
        if attachResult is error {
            return error ClientError(ERR_HTTP_LISTENER_ATTACH_FAILED, attachResult);
        }
        self.attachedServices.push({telegramService, httpService});
    }

    # Detaches the attached `TelegramService` from the listener.
    #
    # + telegramService - The service to detach
    # + return - An `Error` if detaching failed, otherwise `()`
    public function detach(TelegramService telegramService) returns Error? {
        foreach int i in 0 ..< self.attachedServices.length() {
            if self.attachedServices[i].telegramService === telegramService {
                error? detachResult = self.httpListener.detach(self.attachedServices[i].httpService);
                if detachResult is error {
                    return error ClientError(ERR_HTTP_LISTENER_DETACH_FAILED, detachResult);
                }
                _ = self.attachedServices.remove(i);
                return;
            }
        }
    }

    # Starts the listener. If `publicUrl` was set on `ListenerConfig`, also registers it as the
    # webhook via `Client->setWebhook`.
    #
    # + return - An `Error` if the listener, or the webhook registration, could not be started
    public function 'start() returns Error? {
        error? startResult = self.httpListener.'start();
        if startResult is error {
            return error ClientError(ERR_HTTP_LISTENER_START_FAILED, startResult);
        }
        string? publicUrl = self.publicUrl;
        Client? webhookClient = self.webhookClient;
        if publicUrl is string && webhookClient is Client {
            _ = check webhookClient->setWebhook(publicUrl, secret_token = self.secretToken);
        }
    }

    # Gracefully stops the listener, allowing in-flight requests to complete.
    #
    # + return - An `Error` if the listener could not be stopped, otherwise `()`
    public function gracefulStop() returns Error? {
        error? result = self.httpListener.gracefulStop();
        return result is error ? error ClientError(ERR_HTTP_LISTENER_STOP_FAILED, result) : result;
    }

    # Immediately stops the listener.
    #
    # + return - An `Error` if the listener could not be stopped, otherwise `()`
    public function immediateStop() returns Error? {
        error? result = self.httpListener.immediateStop();
        return result is error ? error ClientError(ERR_HTTP_LISTENER_STOP_FAILED, result) : result;
    }
}
