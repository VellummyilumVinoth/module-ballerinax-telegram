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
import ballerina/test;

// ── Shared Mock Bot API for Client Remote Method Tests ─────────────────────────────
//
// One mock Bot API service backs most `Client` remote-method tests below: it inspects the
// requested method (the last path segment of `/bot<token>/<method>`) and returns a canned,
// method-appropriate `result`, so `cloneWithType` on the real return type succeeds. Tests run
// serially (Ballerina's default test executor), so the captured `clientTestLastMethod`/
// `clientTestLastPayload` globals are safe to assert on immediately after the call that set them.

final int clientTestApiPort = TEST_PORT + 20;
string clientTestLastMethod = "";
json clientTestLastPayload = {};

final json & readonly CLIENT_TEST_CHAT_JSON = {id: 100, 'type: "private"};
final json & readonly CLIENT_TEST_CHAT_MEMBER_JSON = {
    status: "member",
    user: {id: 1, is_bot: false, first_name: "Bot"}
};
final json & readonly CLIENT_TEST_FILE_JSON = {
    file_id: "file-1",
    file_unique_id: "unique-1",
    file_path: "documents/file_1.png"
};
final json & readonly CLIENT_TEST_WEBHOOK_INFO_JSON = {url: "", has_custom_certificate: false, pending_update_count: 0};
final json & readonly CLIENT_TEST_MESSAGE_JSON = {
    message_id: 1,
    date: 1700000000,
    chat: {id: 100, 'type: "private"},
    text: "hi"
};

final string[] & readonly CLIENT_TEST_MESSAGE_METHODS = [
    "sendLocation", "sendAnimation", "sendAudio", "sendDocument", "sendPhoto", "sendSticker", "sendVideo",
    "sendMessage", "sendMessageDraft", "sendRichMessage", "sendRichMessageDraft"
];

isolated function clientTestResultFor(string method, json payload) returns json {
    if method == "getChat" {
        return {ok: true, result: CLIENT_TEST_CHAT_JSON};
    }
    if method == "getChatAdministrators" {
        return {ok: true, result: [CLIENT_TEST_CHAT_MEMBER_JSON]};
    }
    if method == "getChatMember" {
        return {ok: true, result: CLIENT_TEST_CHAT_MEMBER_JSON};
    }
    if method == "getFile" {
        return {ok: true, result: CLIENT_TEST_FILE_JSON};
    }
    if method == "getWebhookInfo" {
        return {ok: true, result: CLIENT_TEST_WEBHOOK_INFO_JSON};
    }
    if method == "editMessageText" {
        if payload is map<json> && payload.hasKey("inline_message_id") {
            return {ok: true, result: true};
        }
        return {ok: true, result: CLIENT_TEST_MESSAGE_JSON};
    }
    if method == "sendMediaGroup" {
        return {ok: true, result: [CLIENT_TEST_MESSAGE_JSON]};
    }
    if CLIENT_TEST_MESSAGE_METHODS.indexOf(method) is int {
        return {ok: true, result: CLIENT_TEST_MESSAGE_JSON};
    }
    return {ok: true, result: true};
}

listener http:Listener clientTestListener = new (clientTestApiPort);

service / on clientTestListener {

    resource function post [string... path](@http:Payload json payload) returns json {
        string method = path.length() > 1 ? path[1] : "";
        lock {
            clientTestLastMethod = method;
            clientTestLastPayload = payload.clone();
        }
        return clientTestResultFor(method, payload);
    }

    resource function get [string... path]() returns http:Response {
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setBinaryPayload("file-bytes".toBytes());
        return response;
    }
}

isolated function clientTestClient() returns Client|error =>
    new ({token: "test-token"}, string `http://localhost:${clientTestApiPort}`);

function clientTestLastPayloadSnapshot() returns json {
    lock {
        return clientTestLastPayload.clone();
    }
}

// ── Chat ─────────────────────────────────────────────────────────────────────────

@test:Config {}
function testGetChat() returns error? {
    Client telegramClient = check clientTestClient();
    ChatFullInfo chat = check telegramClient->getChat(100);
    test:assertEquals(chat.id, 100);
    test:assertEquals(chat.'type, "private");
}

@test:Config {}
function testGetChatAdministrators() returns error? {
    Client telegramClient = check clientTestClient();
    ChatMember[] admins = check telegramClient->getChatAdministrators(100);
    test:assertEquals(admins.length(), 1);
    test:assertTrue(admins[0] is ChatMemberMember);
}

@test:Config {}
function testGetChatMember() returns error? {
    Client telegramClient = check clientTestClient();
    ChatMember member = check telegramClient->getChatMember(100, 1);
    test:assertTrue(member is ChatMemberMember);
}

@test:Config {}
function testLeaveChat() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->leaveChat(100);
}

@test:Config {}
function testSetChatDescription() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->setChatDescription(100, "A new description");
}

@test:Config {}
function testSetChatTitle() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->setChatTitle(100, "A new title");
}

// ── Callback ─────────────────────────────────────────────────────────────────────

@test:Config {}
function testAnswerCallbackQuery() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->answerCallbackQuery("callback-1", text = "Got it");
}

@test:Config {}
function testAnswerInlineQuery() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->answerInlineQuery("inline-1", []);
}

// ── File ─────────────────────────────────────────────────────────────────────────

@test:Config {}
function testGetFile() returns error? {
    Client telegramClient = check clientTestClient();
    File file = check telegramClient->getFile("file-1");
    test:assertEquals(file.file_id, "file-1");
    test:assertEquals(file.file_path, "documents/file_1.png");
}

@test:Config {}
function testDownloadFile() returns error? {
    Client telegramClient = check clientTestClient();
    byte[] bytes = check telegramClient->downloadFile("file-1");
    test:assertEquals(string:fromBytes(bytes), "file-bytes");
}

int downloadFileMissingPathPort = TEST_PORT + 21;

isolated service class MockFilePathUnavailableApiService {
    *http:Service;

    resource function post [string... path](@http:Payload json payload) returns json =>
        {ok: true, result: {file_id: "file-1", file_unique_id: "unique-1"}};
}

@test:Config {}
function testDownloadFileFailsWhenFilePathUnavailable() returns error? {
    http:Listener mockHttpListener = check new (downloadFileMissingPathPort);
    check mockHttpListener.attach(new MockFilePathUnavailableApiService(), "/");
    check mockHttpListener.'start();

    Client telegramClient = check new ({token: "test-token"},
            string `http://localhost:${downloadFileMissingPathPort}`);
    byte[]|Error result = telegramClient->downloadFile("file-1");
    test:assertTrue(result is ClientError, "downloadFile should fail when the file has no file_path");

    check mockHttpListener.immediateStop();
}

int downloadFileNonOkStatusPort = TEST_PORT + 22;

isolated service class MockFileNonOkStatusApiService {
    *http:Service;

    resource function post [string... path](@http:Payload json payload) returns json =>
        {ok: true, result: {file_id: "file-1", file_unique_id: "unique-1", file_path: "missing.png"}};

    resource function get [string... path]() returns http:NotFound => {};
}

@test:Config {}
function testDownloadFileFailsOnNonOkStatus() returns error? {
    http:Listener mockHttpListener = check new (downloadFileNonOkStatusPort);
    check mockHttpListener.attach(new MockFileNonOkStatusApiService(), "/");
    check mockHttpListener.'start();

    Client telegramClient = check new ({token: "test-token"},
            string `http://localhost:${downloadFileNonOkStatusPort}`);
    byte[]|Error result = telegramClient->downloadFile("file-1");
    test:assertTrue(result is ClientError, "downloadFile should fail on a non-200 file download response");

    check mockHttpListener.immediateStop();
}

// ── Webhook Management ───────────────────────────────────────────────────────────

@test:Config {}
function testDeleteWebhook() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->deleteWebhook();
}

@test:Config {}
function testGetWebhookInfo() returns error? {
    Client telegramClient = check clientTestClient();
    WebhookInfo info = check telegramClient->getWebhookInfo();
    test:assertEquals(info.pending_update_count, 0);
}

// ── Message ──────────────────────────────────────────────────────────────────────

@test:Config {}
function testDeleteMessage() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->deleteMessage(100, 1);
}

@test:Config {}
function testEditMessageTextWithChatTarget() returns error? {
    Client telegramClient = check clientTestClient();
    Message? result = check telegramClient->editMessageText("updated text", chatId = 100, messageId = 1);
    test:assertTrue(result is Message, "editing a chat message should return the edited Message");
}

@test:Config {}
function testEditMessageTextWithInlineTarget() returns error? {
    Client telegramClient = check clientTestClient();
    Message? result = check telegramClient->editMessageText("updated text", inlineMessageId = "inline-msg-1");
    test:assertEquals(result, (), "editing an inline message should return () when Telegram replies with true");
}

@test:Config {}
function testEditMessageTextRequiresExactlyOneTarget() returns error? {
    Client telegramClient = check clientTestClient();
    Message?|Error neitherTarget = telegramClient->editMessageText("text");
    test:assertTrue(neitherTarget is ClientError, "editMessageText should fail when no target is given");

    Message?|Error bothTargets = telegramClient->editMessageText("text", chatId = 100, messageId = 1,
            inlineMessageId = "inline-msg-1");
    test:assertTrue(bothTargets is ClientError, "editMessageText should fail when both targets are given");
}

@test:Config {}
function testPinChatMessage() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->pinChatMessage(100, 1);
}

@test:Config {}
function testUnpinChatMessageWithMessageId() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->unpinChatMessage(100, 1);
    json payload = clientTestLastPayloadSnapshot();
    test:assertTrue(payload is map<json> && payload.hasKey("message_id"),
            "unpinChatMessage should send message_id when provided");
}

@test:Config {}
function testUnpinChatMessageWithoutMessageId() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->unpinChatMessage(100);
    json payload = clientTestLastPayloadSnapshot();
    test:assertTrue(payload is map<json> && !payload.hasKey("message_id"),
            "unpinChatMessage should omit message_id when not provided");
}

@test:Config {}
function testSendChatAction() returns error? {
    Client telegramClient = check clientTestClient();
    check telegramClient->sendChatAction(100, "typing");
}

@test:Config {}
function testSendLocation() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendLocation(100, 37.7749d, -122.4194d);
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendAnimation() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendAnimation(100, "file-id-1");
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendAudio() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendAudio(100, "file-id-1");
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendDocument() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendDocument(100, "file-id-1");
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendPhoto() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendPhoto(100, "file-id-1");
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendSticker() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendSticker(100, "file-id-1");
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendVideo() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendVideo(100, "file-id-1");
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendMessage() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendMessage(100, "hi");
    test:assertEquals(message.text, "hi");
}

@test:Config {}
function testSendMediaGroup() returns error? {
    Client telegramClient = check clientTestClient();
    InputMedia[] media = [{'type: "photo", media: "https://example.com/a.jpg"}];
    Message[] messages = check telegramClient->sendMediaGroup(100, media);
    test:assertEquals(messages.length(), 1);
}

@test:Config {}
function testSendMessageDraft() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendMessageDraft(100, 1, text = "partial reply");
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendMessageDraftRequiresNonZeroDraftId() returns error? {
    Client telegramClient = check clientTestClient();
    Message|Error result = telegramClient->sendMessageDraft(100, 0, text = "partial reply");
    test:assertTrue(result is ClientError, "sendMessageDraft should reject draftId 0");
}

@test:Config {}
function testSendRichMessage() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendRichMessage(100, {markdown: "**bold**"});
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendRichMessageDraft() returns error? {
    Client telegramClient = check clientTestClient();
    Message message = check telegramClient->sendRichMessageDraft(100, 1, {markdown: "**bold**"});
    test:assertEquals(message.message_id, 1);
}

@test:Config {}
function testSendRichMessageDraftRequiresNonZeroDraftId() returns error? {
    Client telegramClient = check clientTestClient();
    Message|Error result = telegramClient->sendRichMessageDraft(100, 0, {markdown: "**bold**"});
    test:assertTrue(result is ClientError, "sendRichMessageDraft should reject draftId 0");
}

type ApprovalPayloadShape record {
    record {|json[][] inline_keyboard;|} reply_markup;
};

@test:Config {}
function testSendApprovalMessageWithoutDecline() returns error? {
    Client telegramClient = check clientTestClient();
    Message _ = check telegramClient->sendApprovalMessage(100, "Approve?", {text: "Yes", callback_data: "yes"});
    ApprovalPayloadShape shape = check clientTestLastPayloadSnapshot().cloneWithType();
    json[][] rows = shape.reply_markup.inline_keyboard;
    test:assertEquals(rows.length(), 1, "a single row of buttons should be sent");
    test:assertEquals(rows[0].length(), 1, "only the approve button should be sent when decline is omitted");
}

@test:Config {}
function testSendApprovalMessageWithDecline() returns error? {
    Client telegramClient = check clientTestClient();
    Message _ = check telegramClient->sendApprovalMessage(100, "Approve?", {text: "Yes", callback_data: "yes"},
            {text: "No", callback_data: "no"});
    ApprovalPayloadShape shape = check clientTestLastPayloadSnapshot().cloneWithType();
    json[][] rows = shape.reply_markup.inline_keyboard;
    test:assertEquals(rows[0].length(), 2, "both approve and decline buttons should be sent");
}

// ── Shared Media Upload Helper (multipart path) ──────────────────────────────────

int multipartUploadPort = TEST_PORT + 23;

isolated service class MockMultipartUploadApiService {
    *http:Service;

    resource function post [string... path](http:Request request) returns json =>
        {ok: true, result: CLIENT_TEST_MESSAGE_JSON};
}

@test:Config {}
function testSendPhotoWithRawBytesUsesMultipartUpload() returns error? {
    http:Listener mockHttpListener = check new (multipartUploadPort);
    check mockHttpListener.attach(new MockMultipartUploadApiService(), "/");
    check mockHttpListener.'start();

    Client telegramClient = check new ({token: "test-token"}, string `http://localhost:${multipartUploadPort}`);
    Message message = check telegramClient->sendPhoto(100, "raw-bytes".toBytes(), fileName = "photo.png",
            mimeType = "image/png");
    test:assertEquals(message.message_id, 1);

    check mockHttpListener.immediateStop();
}
