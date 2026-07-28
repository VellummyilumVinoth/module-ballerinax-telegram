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

// ── Client / API-Call Error Messages ─────────────────────────────────────────────

const ERR_API_CALL_FAILED = "Telegram Bot API call failed";
const ERR_ENVELOPE_PARSE_FAILED = "Failed to parse the Telegram Bot API response envelope";
const ERR_RESPONSE_PARSE_FAILED = "Failed to parse the Telegram Bot API response";
const ERR_HTTP_CLIENT_INIT_FAILED = "Failed to initialize the underlying HTTP client";
const ERR_HTTP_REQUEST_FAILED = "The request to the Telegram Bot API failed";
const ERR_RESPONSE_READ_FAILED = "Failed to read the Telegram Bot API response body";
const ERR_SECRET_DERIVATION_FAILED = "Failed to derive the webhook secret token";
const ERR_EDIT_TARGET_REQUIRED =
    "editMessageText requires either (chatId and messageId) or inlineMessageId, but not both";
const ERR_DRAFT_ID_REQUIRED = "draftId must be non-zero";
const ERR_FILE_PATH_UNAVAILABLE = "The file has no downloadable path; it may be too large or expired";
const ERR_FILE_DOWNLOAD_FAILED = "File download failed";
