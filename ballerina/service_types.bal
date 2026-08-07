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
# Implement only the handlers you need; an unimplemented handler is simply not invoked, and an
# update outside the nine supported types is logged and dropped. A compiler plugin enforces that
# every declared remote function matches one of the nine below, with the right parameter type.
#
# - `remote function onMessage(Message message) returns error?;` — a new incoming message.
# - `remote function onEditedMessage(Message editedMessage) returns error?;` — an edited message.
# - `remote function onChannelPost(Message channelPost) returns error?;` — a new channel post.
# - `remote function onEditedChannelPost(Message editedChannelPost) returns error?;` — an edited
#   channel post.
# - `remote function onCallbackQuery(CallbackQuery callbackQuery) returns error?;` — an inline
#   keyboard button press.
# - `remote function onInlineQuery(InlineQuery inlineQuery) returns error?;` — a new inline query.
# - `remote function onPoll(Poll poll) returns error?;` — a poll's state changed.
# - `remote function onPreCheckoutQuery(PreCheckoutQuery preCheckoutQuery) returns error?;` — a
#   pre-checkout query.
# - `remote function onShippingQuery(ShippingQuery shippingQuery) returns error?;` — a shipping
#   query.
public type TelegramService distinct service object {
};
