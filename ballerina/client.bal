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

# Client for the Telegram Bot API, covering chat management, callback/inline query answers, file
# metadata/download, messaging (text, media, locations, drafts, and rich messages), and webhook
# management.
@display {label: "Telegram", iconPath: "icon.png"}
public isolated client class Client {
    private final http:Client clientEp;
    private final string token;

    # Initializes the connector.
    #
    # + config - The connection configuration, including the bot token
    # + serviceUrl - The Telegram Bot API base URL
    # + return - A `ClientError` if initialization failed, otherwise `()`
    public isolated function init(ConnectionConfig config, string serviceUrl = DEFAULT_BASE_URL)
    returns Error? {
        http:ClientConfiguration httpClientConfig = {
            httpVersion: config.httpVersion,
            http1Settings: config.http1Settings,
            http2Settings: config.http2Settings,
            timeout: config.timeout,
            forwarded: config.forwarded,
            followRedirects: config.followRedirects,
            poolConfig: config.poolConfig,
            cache: config.cache,
            compression: config.compression,
            circuitBreaker: config.circuitBreaker,
            retryConfig: config.retryConfig,
            cookieConfig: config.cookieConfig,
            responseLimits: config.responseLimits,
            secureSocket: config.secureSocket,
            proxy: config.proxy,
            socketConfig: config.socketConfig,
            validation: config.validation,
            laxDataBinding: config.laxDataBinding
        };
        http:Client|error clientEp = new (serviceUrl, httpClientConfig);
        if clientEp is error {
            return error ClientError(ERR_HTTP_CLIENT_INIT_FAILED, clientEp);
        }
        self.clientEp = clientEp;
        self.token = config.token;
    }

    private isolated function apiPath(string method) returns string => string `/bot${self.token}/${method}`;

    private isolated function filePath(string telegramFilePath) returns string =>
        string `/file/bot${self.token}/${telegramFilePath}`;

    # Posts a JSON-bodied request and returns the raw response envelope. A non-2xx status still
    # surfaces its body (Telegram Bot API errors carry `ok`/`description`/`error_code` in the body
    # of an otherwise-failing HTTP status) by reading it off `http:ClientRequestError`/
    # `http:RemoteServerError`'s `body` detail field, so `unwrapResult` can build a `TelegramError`
    # from it.
    #
    # + resourcePath - The request's resource path
    # + payload - The request body
    # + return - The raw JSON response envelope, or a `ClientError`
    private isolated function postJson(string resourcePath, anydata payload) returns json|Error {
        json|error response = self.clientEp->post(resourcePath, payload);
        if response is http:ClientRequestError|http:RemoteServerError {
            json|error body = response.detail().body.ensureType();
            return body is error ? error ClientError(ERR_RESPONSE_READ_FAILED, body) : body;
        }
        if response is error {
            return error ClientError(ERR_HTTP_REQUEST_FAILED, response);
        }
        return response;
    }

    # Posts a pre-built `multipart/form-data` request and returns the raw response envelope,
    # regardless of HTTP status code (see `postJson`'s doc comment for why).
    #
    # + resourcePath - The request's resource path
    # + request - The pre-built multipart request
    # + return - The raw JSON response envelope, or a `ClientError`
    private isolated function postRequest(string resourcePath, http:Request request) returns json|Error {
        json|error response = self.clientEp->post(resourcePath, request);
        if response is http:ClientRequestError|http:RemoteServerError {
            json|error body = response.detail().body.ensureType();
            return body is error ? error ClientError(ERR_RESPONSE_READ_FAILED, body) : body;
        }
        if response is error {
            return error ClientError(ERR_HTTP_REQUEST_FAILED, response);
        }
        return response;
    }

    // ── Chat ─────────────────────────────────────────────────────────────────────

    # Gets up-to-date information about a chat.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + return - The chat's full details, or an `Error`
    remote isolated function getChat(int|string chatId) returns ChatFullInfo|Error {
        json response = check self.postJson(self.apiPath(METHOD_GET_CHAT), {chat_id: chatId});
        ChatFullInfo|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Gets the administrators of a chat.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + return - The chat's administrators, or an `Error`
    remote isolated function getChatAdministrators(int|string chatId) returns ChatMember[]|Error {
        json response = check self.postJson(self.apiPath(METHOD_GET_CHAT_ADMINISTRATORS), {chat_id: chatId});
        ChatMember[]|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Gets information about one member of a chat.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + userId - The target user's ID
    # + return - The chat member's details, or an `Error`
    remote isolated function getChatMember(int|string chatId, int userId) returns ChatMember|Error {
        json response = check self.postJson(self.apiPath(METHOD_GET_CHAT_MEMBER),
                {chat_id: chatId, user_id: userId});
        ChatMember|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Makes the bot leave a chat.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function leaveChat(int|string chatId) returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_LEAVE_CHAT), {chat_id: chatId});
        _ = check unwrapResult(response);
    }

    # Sets a group, supergroup, or channel's description.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + description - The new description, 0-255 characters
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function setChatDescription(int|string chatId, string description) returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_SET_CHAT_DESCRIPTION),
                {chat_id: chatId, description});
        _ = check unwrapResult(response);
    }

    # Sets a chat's title.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + title - The new title, 1-255 characters
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function setChatTitle(int|string chatId, string title) returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_SET_CHAT_TITLE), {chat_id: chatId, title});
        _ = check unwrapResult(response);
    }

    // ── Callback ─────────────────────────────────────────────────────────────────

    # Answers a callback query sent from an inline keyboard button press.
    #
    # + callbackQueryId - The callback query's ID, from `CallbackQuery.id`
    # + options - Additional fields, e.g. `text`/`show_alert` to show the user a notification
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function answerCallbackQuery(string callbackQueryId, *AnswerCallbackQueryOptions options)
    returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_ANSWER_CALLBACK_QUERY),
                {callback_query_id: callbackQueryId, ...options});
        _ = check unwrapResult(response);
    }

    # Answers an inline query.
    #
    # + inlineQueryId - The inline query's ID, from `InlineQuery.id`
    # + results - The results to show, up to 50
    # + options - Additional fields
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function answerInlineQuery(string inlineQueryId, InlineQueryResult[] results,
            *AnswerInlineQueryOptions options) returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_ANSWER_INLINE_QUERY),
                {inline_query_id: inlineQueryId, results, ...options});
        _ = check unwrapResult(response);
    }

    // ── File ─────────────────────────────────────────────────────────────────────

    # Gets a file's metadata, including the path used to download its bytes.
    #
    # + fileId - The file's identifier
    # + return - The file's metadata, or an `Error`
    remote isolated function getFile(string fileId) returns File|Error {
        json response = check self.postJson(self.apiPath(METHOD_GET_FILE), {file_id: fileId});
        File|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Downloads a file's raw bytes. Resolves the file's `file_path` (via `getFile`) and then fetches
    # it from the same host the Bot API is served from.
    #
    # + fileId - The file's identifier
    # + return - The file's raw bytes, or an `Error`
    remote isolated function downloadFile(string fileId) returns byte[]|Error {
        File file = check self->getFile(fileId);
        string? path = file.file_path;
        if path is () {
            return error ClientError(ERR_FILE_PATH_UNAVAILABLE);
        }
        http:Response|error response = self.clientEp->get(self.filePath(path));
        if response is error {
            return error ClientError(ERR_HTTP_REQUEST_FAILED, response);
        }
        if response.statusCode != http:STATUS_OK {
            return error ClientError(ERR_FILE_DOWNLOAD_FAILED, statusCode = response.statusCode);
        }
        byte[]|error bytes = response.getBinaryPayload();
        return bytes is error ? error ClientError(ERR_RESPONSE_READ_FAILED, bytes) : bytes;
    }

    // ── Webhook Management ───────────────────────────────────────────────────────

    # Registers a webhook URL for Telegram to push updates to.
    #
    # + url - The HTTPS URL to deliver updates to
    # + options - Additional fields; `allowed_updates` defaults to exactly the 9 update types this
    #             connector's `Listener` supports. `secret_token` defaults to
    #             `deriveSecretToken(token)` (the same bot token this `Client` was created with),
    #             so a `Listener` created with `token` set instead of `secretToken` lands on the
    #             same value automatically — pass `secret_token` explicitly to opt out
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function setWebhook(string url, *SetWebhookOptions options) returns Error? {
        string[]|"*" allowedUpdates = options.allowed_updates;
        map<anydata> payload = {url, ...options};
        payload["allowed_updates"] = allowedUpdates is "*" ? SUPPORTED_UPDATE_TYPES : allowedUpdates;
        if options.secret_token is () {
            payload["secret_token"] = check deriveSecretToken(self.token);
        }
        json response = check self.postJson(self.apiPath(METHOD_SET_WEBHOOK), payload);
        _ = check unwrapResult(response);
    }

    # Removes the currently registered webhook.
    #
    # + dropPendingUpdates - Whether to discard any updates that were queued for delivery
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function deleteWebhook(boolean dropPendingUpdates = false) returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_DELETE_WEBHOOK),
                {drop_pending_updates: dropPendingUpdates});
        _ = check unwrapResult(response);
    }

    # Gets the currently registered webhook's status.
    #
    # + return - The webhook's status, or an `Error`
    remote isolated function getWebhookInfo() returns WebhookInfo|Error {
        json response = check self.postJson(self.apiPath(METHOD_GET_WEBHOOK_INFO), {});
        WebhookInfo|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    // ── Message ──────────────────────────────────────────────────────────────────

    # Deletes a message.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + messageId - The message's ID
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function deleteMessage(int|string chatId, int messageId) returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_DELETE_MESSAGE),
                {chat_id: chatId, message_id: messageId});
        _ = check unwrapResult(response);
    }

    # Edits a text message the bot previously sent, or the text of an inline message.
    #
    # + text - The new message text
    # + chatId - The target chat's ID, or its `@username`; required together with `messageId`
    # + messageId - The message's ID; required together with `chatId`
    # + inlineMessageId - An inline message's ID; mutually exclusive with `chatId`/`messageId`
    # + options - Additional fields
    # + return - The edited message when editing a chat message, `()` when editing an inline
    #            message the bot has no `Message` object for, or an `Error`
    remote isolated function editMessageText(string text, int|string? chatId = (), int? messageId = (),
            string? inlineMessageId = (), *EditMessageTextOptions options) returns Message|Error? {
        boolean hasChatTarget = chatId is int|string && messageId is int;
        boolean hasInlineTarget = inlineMessageId is string;
        if hasChatTarget == hasInlineTarget {
            return error ClientError(ERR_EDIT_TARGET_REQUIRED);
        }
        map<anydata> payload = {text, ...options};
        if hasChatTarget {
            payload["chat_id"] = chatId;
            payload["message_id"] = messageId;
        } else {
            payload["inline_message_id"] = inlineMessageId;
        }
        json response = check self.postJson(self.apiPath(METHOD_EDIT_MESSAGE_TEXT), payload);
        Message|boolean|error result = (check unwrapResult(response)).cloneWithType();
        if result is error {
            return error ClientError(ERR_RESPONSE_PARSE_FAILED, result);
        }
        return result is boolean ? () : result;
    }

    # Pins a message in a chat.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + messageId - The message's ID
    # + disableNotification - Whether to pin silently, without notifying chat members
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function pinChatMessage(int|string chatId, int messageId, boolean disableNotification = false)
    returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_PIN_CHAT_MESSAGE),
                {chat_id: chatId, message_id: messageId, disable_notification: disableNotification});
        _ = check unwrapResult(response);
    }

    # Unpins a message in a chat.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + messageId - The pinned message's ID; unpins the most recent pinned message if omitted
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function unpinChatMessage(int|string chatId, int? messageId = ()) returns Error? {
        map<anydata> payload = {chat_id: chatId};
        if messageId is int {
            payload["message_id"] = messageId;
        }
        json response = check self.postJson(self.apiPath(METHOD_UNPIN_CHAT_MESSAGE), payload);
        _ = check unwrapResult(response);
    }

    # Shows a short-lived chat action indicator (e.g. "typing...") to chat members.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + action - The action to show; expires after ~5 seconds, or on the next sent message
    # + return - An `Error` if the request failed, otherwise `()`
    remote isolated function sendChatAction(int|string chatId, ChatAction action) returns Error? {
        json response = check self.postJson(self.apiPath(METHOD_SEND_CHAT_ACTION), {chat_id: chatId, action});
        _ = check unwrapResult(response);
    }

    # Sends a point on the map.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + latitude - The location's latitude
    # + longitude - The location's longitude
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendLocation(int|string chatId, decimal latitude, decimal longitude,
            *SendLocationOptions options) returns Message|Error {
        json response = check self.postJson(self.apiPath(METHOD_SEND_LOCATION),
                {chat_id: chatId, latitude, longitude, ...options});
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends an animation (GIF or soundless MP4).
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + animation - A `file_id`, an HTTP URL, or the raw file bytes to upload
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendAnimation(int|string chatId, string|byte[] animation,
            *SendAnimationOptions options) returns Message|Error {
        map<anydata> fields = mediaFields(chatId, options);
        json response = check self.sendMedia(METHOD_SEND_ANIMATION, FIELD_ANIMATION, animation, fields,
                options.fileName, options.mimeType);
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends an audio file.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + audio - A `file_id`, an HTTP URL, or the raw file bytes to upload
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendAudio(int|string chatId, string|byte[] audio, *SendAudioOptions options)
    returns Message|Error {
        map<anydata> fields = mediaFields(chatId, options);
        json response = check self.sendMedia(METHOD_SEND_AUDIO, FIELD_AUDIO, audio, fields,
                options.fileName, options.mimeType);
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a general file.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + document - A `file_id`, an HTTP URL, or the raw file bytes to upload
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendDocument(int|string chatId, string|byte[] document,
            *SendDocumentOptions options) returns Message|Error {
        map<anydata> fields = mediaFields(chatId, options);
        json response = check self.sendMedia(METHOD_SEND_DOCUMENT, FIELD_DOCUMENT, document, fields,
                options.fileName, options.mimeType);
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a photo.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + photo - A `file_id`, an HTTP URL, or the raw file bytes to upload
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendPhoto(int|string chatId, string|byte[] photo, *SendPhotoOptions options)
    returns Message|Error {
        map<anydata> fields = mediaFields(chatId, options);
        json response = check self.sendMedia(METHOD_SEND_PHOTO, FIELD_PHOTO, photo, fields,
                options.fileName, options.mimeType);
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a sticker. Telegram stickers have no caption.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + sticker - A `file_id`, an HTTP URL, or the raw file bytes to upload
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendSticker(int|string chatId, string|byte[] sticker, *SendStickerOptions options)
    returns Message|Error {
        map<anydata> fields = mediaFields(chatId, options);
        json response = check self.sendMedia(METHOD_SEND_STICKER, FIELD_STICKER, sticker, fields,
                options.fileName, options.mimeType);
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a video.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + video - A `file_id`, an HTTP URL, or the raw file bytes to upload
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendVideo(int|string chatId, string|byte[] video, *SendVideoOptions options)
    returns Message|Error {
        map<anydata> fields = mediaFields(chatId, options);
        json response = check self.sendMedia(METHOD_SEND_VIDEO, FIELD_VIDEO, video, fields,
                options.fileName, options.mimeType);
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a text message.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + text - The message text
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendMessage(int|string chatId, string text, *SendMessageOptions options)
    returns Message|Error {
        json response = check self.postJson(self.apiPath(METHOD_SEND_MESSAGE),
                {chat_id: chatId, text, ...options});
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a group of photos, videos, documents, or audio files as an album.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + media - The media items to send, 2-10 items; `file_id`/URL strings only (raw-byte uploads
    #           via Telegram's `attach://` convention are not yet supported)
    # + options - Additional fields
    # + return - The sent messages, or an `Error`
    remote isolated function sendMediaGroup(int|string chatId, InputMedia[] media,
            *SendMediaGroupOptions options) returns Message[]|Error {
        json response = check self.postJson(self.apiPath(METHOD_SEND_MEDIA_GROUP),
                {chat_id: chatId, media, ...options});
        Message[]|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Streams a partial message to the same message bubble, identified by `draftId`. Introduced in
    # Bot API 9.3 (Dec 2025); see the connector's flagged risks before relying on this in production.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + draftId - A non-zero ID; successive calls with the same ID update the same message bubble
    # + options - Additional fields
    # + return - The draft message, or an `Error`
    remote isolated function sendMessageDraft(int|string chatId, int draftId, *SendMessageDraftOptions options)
    returns Message|Error {
        if draftId == 0 {
            return error ClientError(ERR_DRAFT_ID_REQUIRED);
        }
        json response = check self.postJson(self.apiPath(METHOD_SEND_MESSAGE_DRAFT),
                {chat_id: chatId, draft_id: draftId, ...options});
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a message with structured rich-text formatting. Introduced in Bot API 10.1 (June 2026);
    # see the connector's flagged risks before relying on this in production.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + richMessage - The rich message content, in Markdown or HTML
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendRichMessage(int|string chatId, RichMessage richMessage,
            *SendRichMessageOptions options) returns Message|Error {
        json response = check self.postJson(self.apiPath(METHOD_SEND_RICH_MESSAGE),
                {chat_id: chatId, rich_message: richMessage, ...options});
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Streams a partial rich message to the same message bubble, identified by `draftId`.
    # Introduced in Bot API 10.1 (June 2026); see the connector's flagged risks before relying on
    # this in production.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + draftId - A non-zero ID; successive calls with the same ID update the same message bubble
    # + richMessage - The rich message content, in Markdown or HTML
    # + messageThreadId - The forum topic to post the draft in, if any
    # + return - The draft message, or an `Error`
    remote isolated function sendRichMessageDraft(int|string chatId, int draftId, RichMessage richMessage,
            int? messageThreadId = ()) returns Message|Error {
        if draftId == 0 {
            return error ClientError(ERR_DRAFT_ID_REQUIRED);
        }
        map<anydata> payload = {chat_id: chatId, draft_id: draftId, rich_message: richMessage};
        if messageThreadId is int {
            payload["message_thread_id"] = messageThreadId;
        }
        json response = check self.postJson(self.apiPath(METHOD_SEND_RICH_MESSAGE_DRAFT), payload);
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    # Sends a prompt with approve/decline inline-keyboard buttons. This is a client-side
    # convenience wrapper around `sendMessage`; the caller observes which button was pressed via the
    # `Listener`'s `onCallbackQuery` handler, matching on `approve.callback_data`/
    # `decline.callback_data`.
    #
    # + chatId - The target chat's ID, or its `@username` for public supergroups/channels
    # + text - The prompt text
    # + approve - The approve button's label and `callback_data`
    # + decline - The decline button's label and `callback_data`, if a decline option is wanted
    # + options - Additional fields
    # + return - The sent message, or an `Error`
    remote isolated function sendApprovalMessage(int|string chatId, string text, ApprovalButton approve,
            ApprovalButton? decline = (), *ApprovalMessageOptions options) returns Message|Error {
        InlineKeyboardButton[] buttons = [{text: approve.text, callback_data: approve.callback_data}];
        if decline is ApprovalButton {
            buttons.push({text: decline.text, callback_data: decline.callback_data});
        }
        json response = check self.postJson(self.apiPath(METHOD_SEND_MESSAGE),
                {chat_id: chatId, text, ...options, reply_markup: {inline_keyboard: [buttons]}});
        Message|error result = (check unwrapResult(response)).cloneWithType();
        return result is error ? error ClientError(ERR_RESPONSE_PARSE_FAILED, result) : result;
    }

    // ── Shared Media Upload Helper ───────────────────────────────────────────────

    # Posts a media-sending request, choosing a plain JSON body when `media` is a `file_id`/URL
    # string, or a `multipart/form-data` body when it's raw bytes to upload.
    #
    # + method - The Bot API method name
    # + fieldName - The multipart field name to attach raw bytes under (e.g. `photo`)
    # + media - A `file_id`, an HTTP URL, or the raw file bytes to upload
    # + fields - The operation's other fields (already stripped of `fileName`/`mimeType`)
    # + fileName - The multipart filename to use, when `media` is raw bytes
    # + mimeType - The multipart content type to use, when `media` is raw bytes
    # + return - The raw JSON response, or an `Error`
    private isolated function sendMedia(string method, string fieldName, string|byte[] media,
            map<anydata> fields, string? fileName, string? mimeType) returns json|Error {
        if media is string {
            fields[fieldName] = media;
            return self.postJson(self.apiPath(method), fields);
        }
        http:Request request = buildMultipartRequest(fields, fieldName, media,
                fileName ?: DEFAULT_UPLOAD_FILENAME, mimeType ?: DEFAULT_UPLOAD_MIME_TYPE);
        return self.postRequest(self.apiPath(method), request);
    }
}

# Builds the common field map for a media-sending operation, excluding the multipart-only
# `fileName`/`mimeType` options fields (those are threaded separately into `sendMedia`).
#
# + chatId - The target chat's ID, or its `@username` for public supergroups/channels
# + options - The operation's `*Options` record
# + return - The field map, ready for `Client.sendMedia`
isolated function mediaFields(int|string chatId, map<anydata> options) returns map<anydata> {
    map<anydata> fields = {chat_id: chatId};
    foreach [string, anydata] [key, value] in options.entries() {
        if key != "fileName" && key != "mimeType" {
            fields[key] = value;
        }
    }
    return fields;
}
