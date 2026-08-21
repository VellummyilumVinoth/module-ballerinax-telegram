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
import ballerina/log;

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
# update against a secret token (`X-Telegram-Bot-Api-Secret-Token`) derived internally from
# `accessToken`, and dispatches the 9 supported update types to an attached `TelegramService`.
#
# ```ballerina
# listener telegram:Listener telegramListener = new (8090, accessToken = "my-bot-access-token",
#         callbackUrl = "https://my-app.example.com/");
#
# service telegram:TelegramService on telegramListener {
#     remote function onMessage(telegram:Message message) returns error? {
#         // handle an incoming message: message.text
#     }
#     // ... plus any of the other eight (optional) handlers this bot needs
# }
# ```
#
# The webhook secret token is always derived internally from `accessToken` via
# `deriveSecretToken`, and passing `callbackUrl` registers this listener's webhook automatically
# when it starts — no separate `Client->setWebhook` call needed.
#
# By default, each update is acknowledged (`200 OK`) automatically as soon as it's received, before
# any handler runs. Annotate an attached service with `ServiceConfig` and set `autoAck: false` to
# take control of this yourself — declare a handler's optional second parameter as a `Caller` and
# call `caller->complete()` when ready; see `Caller` and `ServiceConfig`.
@display {label: "Telegram", iconPath: "icon.png"}
public class Listener {
    private final http:Listener httpListener;
    private final string secretToken;
    private final string? callbackUrl;
    private final Client? webhookClient;
    private AttachedService[] attachedServices = [];

    # Initializes the webhook listener.
    #
    # + listenTo - A port number to bind a new `http:Listener` to, or an existing `http:Listener`
    # + config - The listener configuration
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
        self.secretToken = check deriveSecretToken(config.accessToken);

        string? callbackUrl = config.callbackUrl;
        if callbackUrl is string {
            self.callbackUrl = callbackUrl;
            self.webhookClient = check new ({accessToken: config.accessToken}, config.serviceUrl);
        } else {
            self.callbackUrl = ();
            self.webhookClient = ();
        }
    }

    # Attaches a `TelegramService` implementation to the listener.
    #
    # + telegramService - The service that handles webhook updates
    # + name - The path (or path segments) to attach the service on; defaults to the listener root
    # + return - An `Error` if attaching failed, otherwise `()`
    public function attach(TelegramService telegramService, string[]|string? name = ()) returns Error? {
        TelegramServiceConfig serviceConfig = (typeof telegramService).@ServiceConfig ?: {};
        HttpService httpService = new (telegramService, self.secretToken, serviceConfig.autoAck);
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

    # Starts the listener. If `callbackUrl` was set on `ListenerConfig`, also registers it as the
    # webhook via `Client->setWebhook`. If that registration fails, the underlying `http:Listener`
    # is stopped again before the error is returned, so a failed `start()` never leaves a listener
    # running with no webhook registered.
    #
    # + return - An `Error` if the listener, or the webhook registration, could not be started
    public function 'start() returns Error? {
        error? startResult = self.httpListener.'start();
        if startResult is error {
            return error ClientError(ERR_HTTP_LISTENER_START_FAILED, startResult);
        }
        string? callbackUrl = self.callbackUrl;
        Client? webhookClient = self.webhookClient;
        if callbackUrl is string && webhookClient is Client {
            Error? webhookResult = webhookClient->setWebhook(callbackUrl, secret_token = self.secretToken);
            if webhookResult is error {
                // The HTTP listener already started and is accepting requests; if webhook
                // registration fails, leaving it running would keep the port bound with no way to
                // register the webhook without a fresh `Listener`, so tear it back down.
                error? stopResult = self.httpListener.immediateStop();
                if stopResult is error {
                    log:printError(ERR_HTTP_LISTENER_STOP_FAILED, stopResult);
                }
                return webhookResult;
            }
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
