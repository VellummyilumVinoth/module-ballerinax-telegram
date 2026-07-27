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

import ballerina/data.jsondata;

# Extra data Telegram attaches to some error responses to help automatic handling.
#
# + migrateToChatId - The group's new chat ID, if it was migrated to a supergroup
# + retryAfter - The number of seconds to wait before retrying, present on `429` responses
public type ResponseParameters record {
    @jsondata:Name {value: "migrate_to_chat_id"}
    int migrateToChatId?;
    @jsondata:Name {value: "retry_after"}
    int retryAfter?;
};

# Structured detail attached to a `TelegramError`.
#
# + errorCode - Telegram's `error_code` for the failed call; not guaranteed stable across calls
# + parameters - Extra data to help automatic handling (e.g. `retryAfter` on flood-control errors)
public type TelegramErrorDetail record {|
    int? errorCode;
    ResponseParameters? parameters;
|};

# The common error type for this connector: every error the `Client`/`Listener` raises is a
# `TelegramError` or a `ClientError`. Use this in signatures/documentation when the distinction
# doesn't matter to the caller; narrow with `is TelegramError`/`is ClientError` when it does.
public type Error distinct error;

# An error returned by the Telegram Bot API itself (`ok: false` in the response envelope).
public type TelegramError distinct (Error & error<TelegramErrorDetail>);

# An error raised by the `Client`/`Listener` before (or instead of) a call reaching the Telegram
# Bot API — e.g. invalid arguments, a failed HTTP/data-binding operation, or a file download that
# failed after the HTTP call succeeded. Distinguishes these from a `TelegramError` (which the Bot
# API itself returned).
public type ClientError distinct Error;
