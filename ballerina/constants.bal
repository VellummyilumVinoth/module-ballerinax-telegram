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

// ── API Base URL ────────────────────────────────────────────────────────────────

# The default base URL for the Telegram Bot API.
const DEFAULT_BASE_URL = "https://api.telegram.org";

// ── Bot API Method Names ────────────────────────────────────────────────────────
// Used to build each request's resource path: `/bot<token>/<method>`.

const METHOD_GET_CHAT = "getChat";
const METHOD_GET_CHAT_ADMINISTRATORS = "getChatAdministrators";
const METHOD_GET_CHAT_MEMBER = "getChatMember";
const METHOD_LEAVE_CHAT = "leaveChat";
const METHOD_SET_CHAT_DESCRIPTION = "setChatDescription";
const METHOD_SET_CHAT_TITLE = "setChatTitle";

const METHOD_ANSWER_CALLBACK_QUERY = "answerCallbackQuery";
const METHOD_ANSWER_INLINE_QUERY = "answerInlineQuery";

const METHOD_GET_FILE = "getFile";

const METHOD_DELETE_MESSAGE = "deleteMessage";
const METHOD_EDIT_MESSAGE_TEXT = "editMessageText";
const METHOD_PIN_CHAT_MESSAGE = "pinChatMessage";
const METHOD_UNPIN_CHAT_MESSAGE = "unpinChatMessage";
const METHOD_SEND_CHAT_ACTION = "sendChatAction";
const METHOD_SEND_LOCATION = "sendLocation";
const METHOD_SEND_ANIMATION = "sendAnimation";
const METHOD_SEND_AUDIO = "sendAudio";
const METHOD_SEND_DOCUMENT = "sendDocument";
const METHOD_SEND_PHOTO = "sendPhoto";
const METHOD_SEND_STICKER = "sendSticker";
const METHOD_SEND_VIDEO = "sendVideo";
const METHOD_SEND_MESSAGE = "sendMessage";
const METHOD_SEND_MEDIA_GROUP = "sendMediaGroup";
const METHOD_SEND_MESSAGE_DRAFT = "sendMessageDraft";
const METHOD_SEND_RICH_MESSAGE = "sendRichMessage";
const METHOD_SEND_RICH_MESSAGE_DRAFT = "sendRichMessageDraft";

const METHOD_SET_WEBHOOK = "setWebhook";
const METHOD_DELETE_WEBHOOK = "deleteWebhook";
const METHOD_GET_WEBHOOK_INFO = "getWebhookInfo";

// ── Multipart Field Names ───────────────────────────────────────────────────────
// The multipart field a raw-byte upload is attached under, matching Telegram's own parameter name
// for that media type (e.g. `sendPhoto` uploads under `photo`, `sendDocument` under `document`).

const FIELD_PHOTO = "photo";
const FIELD_VIDEO = "video";
const FIELD_AUDIO = "audio";
const FIELD_DOCUMENT = "document";
const FIELD_ANIMATION = "animation";
const FIELD_STICKER = "sticker";

// ── Discriminant Constants ──────────────────────────────────────────────────────

# `ChatMember.status` discriminator for a `ChatMemberOwner`.
const CHAT_MEMBER_STATUS_CREATOR = "creator";

# `ChatMember.status` discriminator for a `ChatMemberAdministrator`.
const CHAT_MEMBER_STATUS_ADMINISTRATOR = "administrator";

# `ChatMember.status` discriminator for a `ChatMemberMember`.
const CHAT_MEMBER_STATUS_MEMBER = "member";

# `ChatMember.status` discriminator for a `ChatMemberRestricted`.
const CHAT_MEMBER_STATUS_RESTRICTED = "restricted";

# `ChatMember.status` discriminator for a `ChatMemberLeft`.
const CHAT_MEMBER_STATUS_LEFT = "left";

# `ChatMember.status` discriminator for a `ChatMemberBanned`.
const CHAT_MEMBER_STATUS_KICKED = "kicked";

# `InputMedia.type` discriminator for an `InputMediaPhoto`.
const INPUT_MEDIA_TYPE_PHOTO = "photo";

# `InputMedia.type` discriminator for an `InputMediaVideo`.
const INPUT_MEDIA_TYPE_VIDEO = "video";

# `InputMedia.type` discriminator for an `InputMediaAudio`.
const INPUT_MEDIA_TYPE_AUDIO = "audio";

# `InputMedia.type` discriminator for an `InputMediaDocument`.
const INPUT_MEDIA_TYPE_DOCUMENT = "document";

# `InlineQueryResult.type` discriminator for an `InlineQueryResultArticle`.
const INLINE_QUERY_RESULT_TYPE_ARTICLE = "article";

# `InlineQueryResult.type` discriminator for an `InlineQueryResultPhoto`.
const INLINE_QUERY_RESULT_TYPE_PHOTO = "photo";

// ── Other Constants ─────────────────────────────────────────────────────────────

# Default value for `ConnectionConfig.forwarded` — disables the `forwarded`/`x-forwarded` header.
const FORWARDED_DISABLE = "disable";

# Default multipart filename used when the caller doesn't supply one for a raw-byte upload.
const DEFAULT_UPLOAD_FILENAME = "file";

# Default multipart content type used when the caller doesn't supply one for a raw-byte upload.
const DEFAULT_UPLOAD_MIME_TYPE = "application/octet-stream";
