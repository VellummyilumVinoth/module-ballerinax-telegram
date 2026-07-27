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
import ballerina/jballerina.java;
import ballerina/log;

# Invokes the named handler on `telegramService` with `payload`, if (and only if) the service
# declares that handler; since `TelegramService` declares no remote methods (all nine handlers are
# optional), there is no statically bound method to call directly, so this dispatches reflectively
# via the native (Java) runtime.
#
# + telegramService - The attached `TelegramService` implementation
# + methodName - The handler's name, e.g. `onMessage`
# + payload - The record to pass as the handler's sole argument, e.g. the received `Message`
# + return - The handler's result, or `()` if it does not declare that handler
isolated function invokeHandlerIfPresent(TelegramService telegramService, string methodName, anydata payload)
        returns error? = @java:Method {
    name: "invokeIfPresent",
    'class: "io.ballerinax.telegram.HandlerDispatcher"
} external;

# The HTTP service that backs the Telegram `Listener`. A single `POST` resource authenticates each
# update via the caller-chosen secret token and dispatches it to the attached `TelegramService`.
service class HttpService {
    *http:Service;

    private final TelegramService telegramService;
    private final string secretToken;

    function init(TelegramService telegramService, string secretToken) {
        self.telegramService = telegramService;
        self.secretToken = secretToken;
    }

    # Inbound update handler. Authenticates the secret token header, acknowledges immediately, then
    # parses and dispatches the update. Telegram retries on a slow/non-2xx response, so the
    # acknowledgement is sent before the potentially slow handler invocation runs.
    #
    # + caller - The HTTP caller used to send the acknowledgement before dispatching
    # + request - The inbound update request
    # + return - An error if the acknowledgement could not be sent; errors from dispatching the
    #            parsed update to the `TelegramService` are logged instead of returned
    resource function post .(http:Caller caller, http:Request request) returns error? {
        string|error header = request.getHeader(SECRET_TOKEN_HEADER);
        if header is error || !constantTimeEquals(header, self.secretToken) {
            log:printDebug(WARN_SECRET_TOKEN_MISMATCH);
            return caller->respond(<http:Unauthorized>{});
        }

        string|error rawPayload = request.getTextPayload();
        if rawPayload is error {
            log:printDebug(ERR_PAYLOAD_READ_FAILED, rawPayload);
            return caller->respond(<http:BadRequest>{});
        }
        log:printDebug(LOG_WEBHOOK_POST_RECEIVED, payloadLength = rawPayload.length());

        json|error payload = rawPayload.fromJsonString();
        if payload is error {
            log:printDebug(ERR_PAYLOAD_PARSE_FAILED, payload);
            return caller->respond(<http:BadRequest>{});
        }

        // Acknowledge receipt first so Telegram does not retry, then dispatch (handlers may be
        // slow, e.g. an AI agent invocation).
        check caller->respond(<http:Ok>{});
        self.dispatch(payload);
    }

    function dispatch(json payload) {
        WireUpdate|error update = payload.cloneWithType();
        if update is error {
            log:printDebug(ERR_UPDATE_PARSE_FAILED, update);
            return;
        }
        int updateId = update.update_id ?: 0;

        Message? message = update.message;
        Message? editedMessage = update.edited_message;
        Message? channelPost = update.channel_post;
        Message? editedChannelPost = update.edited_channel_post;
        CallbackQuery? callbackQuery = update.callback_query;
        InlineQuery? inlineQuery = update.inline_query;
        Poll? poll = update.poll;
        PreCheckoutQuery? preCheckoutQuery = update.pre_checkout_query;
        ShippingQuery? shippingQuery = update.shipping_query;

        if message is Message {
            error? result = invokeHandlerIfPresent(self.telegramService, "onMessage", message);
            if result is error {
                log:printDebug(ERR_ON_MESSAGE_HANDLER, result, updateId = updateId);
            }
        } else if editedMessage is Message {
            error? result = invokeHandlerIfPresent(self.telegramService, "onEditedMessage", editedMessage);
            if result is error {
                log:printDebug(ERR_ON_EDITED_MESSAGE_HANDLER, result, updateId = updateId);
            }
        } else if channelPost is Message {
            error? result = invokeHandlerIfPresent(self.telegramService, "onChannelPost", channelPost);
            if result is error {
                log:printDebug(ERR_ON_CHANNEL_POST_HANDLER, result, updateId = updateId);
            }
        } else if editedChannelPost is Message {
            error? result = invokeHandlerIfPresent(self.telegramService, "onEditedChannelPost", editedChannelPost);
            if result is error {
                log:printDebug(ERR_ON_EDITED_CHANNEL_POST_HANDLER, result, updateId = updateId);
            }
        } else if callbackQuery is CallbackQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onCallbackQuery", callbackQuery);
            if result is error {
                log:printDebug(ERR_ON_CALLBACK_QUERY_HANDLER, result, updateId = updateId);
            }
        } else if inlineQuery is InlineQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onInlineQuery", inlineQuery);
            if result is error {
                log:printDebug(ERR_ON_INLINE_QUERY_HANDLER, result, updateId = updateId);
            }
        } else if poll is Poll {
            error? result = invokeHandlerIfPresent(self.telegramService, "onPoll", poll);
            if result is error {
                log:printDebug(ERR_ON_POLL_HANDLER, result, updateId = updateId);
            }
        } else if preCheckoutQuery is PreCheckoutQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onPreCheckoutQuery", preCheckoutQuery);
            if result is error {
                log:printDebug(ERR_ON_PRE_CHECKOUT_QUERY_HANDLER, result, updateId = updateId);
            }
        } else if shippingQuery is ShippingQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onShippingQuery", shippingQuery);
            if result is error {
                log:printDebug(ERR_ON_SHIPPING_QUERY_HANDLER, result, updateId = updateId);
            }
        } else {
            // Every other real `Update` field (poll_answer, my_chat_member, chat_member,
            // chat_join_request, business-account events, ...) is outside this connector's
            // supported set; log and drop rather than deliver anywhere.
            log:printDebug(WARN_UNRECOGNIZED_UPDATE_FIELD, updateId = updateId);
        }
    }
}
