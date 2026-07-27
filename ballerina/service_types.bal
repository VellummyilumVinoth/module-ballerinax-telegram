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

# The service object a consumer implements to handle Telegram webhook updates. Attach an
# implementation to a `Listener` to receive updates.
#
# `TelegramService` declares no remote methods of its own — implement only the handlers you need;
# an unimplemented handler is simply not invoked. Declaring a remote function under any other
# name, with the wrong parameter type, or without the `remote` qualifier is a compile error (see
# this connector's compiler plugin). There are nine supported handlers, one per supported update
# type:
#
# - `remote function onMessage(Message message) returns error?;` — a new incoming message.
# - `remote function onEditedMessage(Message editedMessage) returns error?;` — a message the
#   bot knows about was edited.
# - `remote function onChannelPost(Message channelPost) returns error?;` — a new channel post.
# - `remote function onEditedChannelPost(Message editedChannelPost) returns error?;` — a
#   channel post the bot knows about was edited.
# - `remote function onCallbackQuery(CallbackQuery callbackQuery) returns error?;` — an inline
#   keyboard button press.
# - `remote function onInlineQuery(InlineQuery inlineQuery) returns error?;` — a new inline query.
# - `remote function onPoll(Poll poll) returns error?;` — a poll's state changed.
# - `remote function onPreCheckoutQuery(PreCheckoutQuery preCheckoutQuery) returns error?;` — a new
#   pre-checkout query.
# - `remote function onShippingQuery(ShippingQuery shippingQuery) returns error?;` — a new shipping
#   query.
#
# An update outside this set (e.g. `poll_answer`, `my_chat_member`, `chat_member`,
# `chat_join_request`, business-account events) is logged and dropped rather than delivered to a
# handler.
public type TelegramService distinct service object {
};
