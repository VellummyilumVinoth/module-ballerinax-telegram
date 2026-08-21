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
# via the native (Java) runtime. If the handler declares a second parameter, `caller` is passed as
# its second argument too, so it can be typed `Caller` for manual acknowledgement.
#
# + telegramService - The attached `TelegramService` implementation
# + methodName - The handler's name, e.g. `onMessage`
# + payload - The record to pass as the handler's sole (or first, if two) argument
# + caller - Passed as the handler's second argument if (and only if) it declares one
# + return - The handler's result, or `()` if it does not declare that handler
isolated function invokeHandlerIfPresent(TelegramService telegramService, string methodName, anydata payload,
        Caller caller) returns error? = @java:Method {
    name: "invokeIfPresent",
    'class: "io.ballerinax.telegram.HandlerDispatcher"
} external;

# The HTTP service that backs the Telegram `Listener`. A single `POST` resource authenticates each
# update via the caller-chosen secret token and dispatches it to the attached `TelegramService`.
service class HttpService {
    *http:Service;

    private final TelegramService telegramService;
    private final string secretToken;
    private final boolean autoAck;

    function init(TelegramService telegramService, string secretToken, boolean autoAck) {
        self.telegramService = telegramService;
        self.secretToken = secretToken;
        self.autoAck = autoAck;
    }

    # Inbound update handler. Authenticates the secret token header, then parses and dispatches the
    # update. If `autoAck` is set (the default), acknowledges immediately — before dispatching —
    # since Telegram retries on a slow/non-2xx response; otherwise, acknowledgement is left to the
    # dispatched handler via the `Caller` it's given as its optional second parameter.
    #
    # + caller - The HTTP caller used to acknowledge the update (directly, or via a `Caller`)
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

        Caller ackCaller = new (caller);
        if self.autoAck {
            // Acknowledge receipt first so Telegram does not retry, then dispatch (handlers may be
            // slow, e.g. an AI agent invocation). The `Caller` passed to the handler already
            // considers itself acknowledged, so a handler that also declares one and calls
            // `caller->complete()` anyway is a safe no-op.
            check ackCaller->complete();
        }
        // With autoAck false, acknowledgement is the dispatched handler's responsibility, via its
        // `Caller` parameter — if it never acknowledges, this connector never responds, and
        // Telegram's own retry-then-give-up behavior is all that follows.
        self.dispatch(payload, ackCaller);
    }

    function dispatch(json payload, Caller caller) {
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
            error? result = invokeHandlerIfPresent(self.telegramService, "onMessage", message, caller);
            if result is error {
                log:printDebug(ERR_ON_MESSAGE_HANDLER, result, updateId = updateId);
            }
        } else if editedMessage is Message {
            error? result = invokeHandlerIfPresent(self.telegramService, "onEditedMessage", editedMessage, caller);
            if result is error {
                log:printDebug(ERR_ON_EDITED_MESSAGE_HANDLER, result, updateId = updateId);
            }
        } else if channelPost is Message {
            error? result = invokeHandlerIfPresent(self.telegramService, "onChannelPost", channelPost, caller);
            if result is error {
                log:printDebug(ERR_ON_CHANNEL_POST_HANDLER, result, updateId = updateId);
            }
        } else if editedChannelPost is Message {
            error? result = invokeHandlerIfPresent(self.telegramService, "onEditedChannelPost", editedChannelPost,
                    caller);
            if result is error {
                log:printDebug(ERR_ON_EDITED_CHANNEL_POST_HANDLER, result, updateId = updateId);
            }
        } else if callbackQuery is CallbackQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onCallbackQuery", callbackQuery, caller);
            if result is error {
                log:printDebug(ERR_ON_CALLBACK_QUERY_HANDLER, result, updateId = updateId);
            }
        } else if inlineQuery is InlineQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onInlineQuery", inlineQuery, caller);
            if result is error {
                log:printDebug(ERR_ON_INLINE_QUERY_HANDLER, result, updateId = updateId);
            }
        } else if poll is Poll {
            error? result = invokeHandlerIfPresent(self.telegramService, "onPoll", poll, caller);
            if result is error {
                log:printDebug(ERR_ON_POLL_HANDLER, result, updateId = updateId);
            }
        } else if preCheckoutQuery is PreCheckoutQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onPreCheckoutQuery", preCheckoutQuery,
                    caller);
            if result is error {
                log:printDebug(ERR_ON_PRE_CHECKOUT_QUERY_HANDLER, result, updateId = updateId);
            }
        } else if shippingQuery is ShippingQuery {
            error? result = invokeHandlerIfPresent(self.telegramService, "onShippingQuery", shippingQuery, caller);
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
