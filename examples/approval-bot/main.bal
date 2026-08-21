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

import ballerina/log;
import ballerinax/telegram;

// Provide these in Config.toml
configurable string accessToken = ?;
configurable string callbackUrl = ?;

final telegram:Client telegramClient = check new ({accessToken});

const string APPROVE_CALLBACK_DATA = "approve_request";
const string DECLINE_CALLBACK_DATA = "decline_request";

// callbackUrl is this listener's public HTTPS URL (e.g. via a tunnel during development). Setting
// it auto-registers the webhook on start() — no separate Client->setWebhook call needed.
listener telegram:Listener telegramListener = new (8090, accessToken = accessToken, callbackUrl = callbackUrl);

service telegram:TelegramService on telegramListener {

    // Reply to any incoming text message with an approval prompt.
    remote function onMessage(telegram:Message message) returns error? {
        string? text = message.text;
        log:printInfo(string `Message from ${message.chat.id}: ${text ?: "(non-text message)"}`);
        if text is string {
            _ = check telegramClient->sendApprovalMessage(message.chat.id,
                    string `Approve this request? "${text}"`,
                    approve = {text: "✅ Approve", callback_data: APPROVE_CALLBACK_DATA},
                    decline = {text: "❌ Decline", callback_data: DECLINE_CALLBACK_DATA});
        }
    }

    // Close the approve/decline loop: acknowledge the button press, then edit the message.
    remote function onCallbackQuery(telegram:CallbackQuery callbackQuery) returns error? {
        telegram:Message? message = callbackQuery.message;
        if message is () {
            return;
        }
        string decision = callbackQuery.data == APPROVE_CALLBACK_DATA ? "Approved ✅" : "Declined ❌";
        _ = check telegramClient->answerCallbackQuery(callbackQuery.id, text = decision);
        _ = check telegramClient->editMessageText(decision, chatId = message.chat.id, messageId = message.message_id);
    }

    remote function onEditedMessage(telegram:Message editedMessage) returns error? {
        log:printInfo(string `Message ${editedMessage.message_id} was edited`);
    }

    remote function onChannelPost(telegram:Message channelPost) returns error? {
        log:printInfo(string `Channel post: ${channelPost.text ?: "(non-text post)"}`);
    }

    remote function onEditedChannelPost(telegram:Message editedChannelPost) returns error? {
        log:printInfo(string `Channel post ${editedChannelPost.message_id} was edited`);
    }

    remote function onInlineQuery(telegram:InlineQuery inlineQuery) returns error? {
        log:printInfo(string `Inline query: ${inlineQuery.query}`);
    }

    remote function onPoll(telegram:Poll poll) returns error? {
        log:printInfo(string `Poll ${poll.id} updated`);
    }

    remote function onPreCheckoutQuery(telegram:PreCheckoutQuery preCheckoutQuery) returns error? {
        log:printInfo(string `Pre-checkout query for ${preCheckoutQuery.total_amount} ${preCheckoutQuery.currency}`);
    }

    remote function onShippingQuery(telegram:ShippingQuery shippingQuery) returns error? {
        log:printInfo(string `Shipping query ${shippingQuery.id}`);
    }
}
