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

// Internal mirror of the 9 `Update` fields the `Listener` supports, used only as a
// `cloneWithType()` target. Open so binding tolerates the other `Update` fields this connector
// doesn't handle (see `dispatcher_service.bal`'s `dispatch()`).
type WireUpdate record {
    int update_id?;
    Message message?;
    Message edited_message?;
    Message channel_post?;
    Message edited_channel_post?;
    CallbackQuery callback_query?;
    InlineQuery inline_query?;
    Poll poll?;
    PreCheckoutQuery pre_checkout_query?;
    ShippingQuery shipping_query?;
};
