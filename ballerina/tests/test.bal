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
import ballerina/lang.runtime;
import ballerina/test;

// ── Client Initialization ─────────────────────────────────────────────────────────

@test:Config {}
function testClientInitialization() returns error? {
    Client _ = check new ({token: "test-token"});
}

// ── Listener / Webhook Secret Token ───────────────────────────────────────────────

// A service that counts `onMessage` invocations so tests can observe dispatch. `TelegramService`
// declares no remote methods of its own, so declaring only `onMessage` here also verifies that an
// implementation isn't required to declare the other eight (unimplemented) handlers.
isolated service class MockTelegramService {
    *TelegramService;
    private int messageCount = 0;

    remote isolated function onMessage(Message message) returns error? {
        lock {
            self.messageCount += 1;
        }
    }

    isolated function getMessageCount() returns int {
        lock {
            return self.messageCount;
        }
    }
}

// A service that declares none of the nine (all-optional) handlers, so a `Listener` can be
// attached and started in dispatch tests without caring about any particular handler.
isolated service class EmptyTelegramService {
    *TelegramService;
}

const int TEST_PORT = 18291;

function sampleUpdate(int updateId) returns json => {
    "update_id": updateId,
    "message": {
        "message_id": 1,
        "date": 1700000000,
        "chat": {"id": 100, "type": "private"},
        "text": "hi"
    }
};

// A matching secret token is accepted and the update is dispatched to the matching handler.
@test:Config {}
function testSecretTokenMatchDispatchesUpdate() returns error? {
    Listener telegramListener = check new (TEST_PORT, secretToken = "secret-token");
    MockTelegramService mockService = new;
    check telegramListener.attach(mockService);
    check telegramListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${TEST_PORT}`);
    http:Ok _ = check callerClient->post("/", sampleUpdate(1),
            headers = {"X-Telegram-Bot-Api-Secret-Token": "secret-token"});

    int retries = 0;
    while mockService.getMessageCount() == 0 && retries < 20 {
        runtime:sleep(0.05);
        retries += 1;
    }
    test:assertEquals(mockService.getMessageCount(), 1, "onMessage should have been invoked exactly once");

    check telegramListener.immediateStop();
}

// An update routed to a handler the attached service doesn't declare is dropped silently — no
// error, no crash — since every handler on `TelegramService` is optional.
@test:Config {}
function testDispatchSkipsUndeclaredHandler() returns error? {
    int port = TEST_PORT + 4;
    Listener telegramListener = check new (port, secretToken = "secret-token");
    check telegramListener.attach(new EmptyTelegramService());
    check telegramListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${port}`);
    http:Ok _ = check callerClient->post("/", sampleUpdate(1),
            headers = {"X-Telegram-Bot-Api-Secret-Token": "secret-token"});

    check telegramListener.immediateStop();
}

// Dispatch happens asynchronously after the caller gets its response (see `HttpService`'s doc
// comment), so a negative test must wait out the same window a positive test would need to
// observe a dispatch, rather than asserting immediately — otherwise it could pass merely because
// it checked before an erroneous dispatch had a chance to land.
function waitOutDispatchWindow() {
    runtime:sleep(1);
}

// A mismatched secret token is rejected before dispatch.
@test:Config {}
function testSecretTokenMismatchRejected() returns error? {
    int port = TEST_PORT + 1;
    Listener telegramListener = check new (port, secretToken = "secret-token");
    MockTelegramService mockService = new;
    check telegramListener.attach(mockService);
    check telegramListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${port}`);
    http:Unauthorized _ = check callerClient->post("/", sampleUpdate(1),
            headers = {"X-Telegram-Bot-Api-Secret-Token": "wrong-token"});
    waitOutDispatchWindow();
    test:assertEquals(mockService.getMessageCount(), 0, "onMessage should not have been invoked");

    check telegramListener.immediateStop();
}

// A missing secret token header is rejected before dispatch.
@test:Config {}
function testMissingSecretTokenHeaderRejected() returns error? {
    int port = TEST_PORT + 2;
    Listener telegramListener = check new (port, secretToken = "secret-token");
    MockTelegramService mockService = new;
    check telegramListener.attach(mockService);
    check telegramListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${port}`);
    http:Unauthorized _ = check callerClient->post("/", sampleUpdate(1));
    waitOutDispatchWindow();
    test:assertEquals(mockService.getMessageCount(), 0, "onMessage should not have been invoked");

    check telegramListener.immediateStop();
}

// A `Listener` created with `token` (instead of `secretToken`) derives the same secret token
// `deriveSecretToken` would, so a request authenticated with that derived value is accepted.
@test:Config {}
function testListenerDerivesSecretTokenFromToken() returns error? {
    int port = TEST_PORT + 5;
    Listener telegramListener = check new (port, token = "bot-token");
    MockTelegramService mockService = new;
    check telegramListener.attach(mockService);
    check telegramListener.'start();

    string derivedSecret = check deriveSecretToken("bot-token");
    http:StatusCodeClient callerClient = check new (string `http://localhost:${port}`);
    http:Ok _ = check callerClient->post("/", sampleUpdate(1),
            headers = {"X-Telegram-Bot-Api-Secret-Token": derivedSecret});

    int retries = 0;
    while mockService.getMessageCount() == 0 && retries < 20 {
        runtime:sleep(0.05);
        retries += 1;
    }
    test:assertEquals(mockService.getMessageCount(), 1,
            "onMessage should have been invoked once the derived secret token matched");

    check telegramListener.immediateStop();
}

// A `Listener` created with neither `secretToken` nor `token` fails to initialize.
@test:Config {}
function testListenerRequiresSecretTokenOrToken() {
    Listener|error result = new (TEST_PORT + 6);
    test:assertTrue(result is error, "Listener init should fail without secretToken or token");
}

// A `Listener` created with `publicUrl` but no `token` fails to initialize, since there is no bot
// token to build the internal `Client` that would register the webhook.
@test:Config {}
function testListenerRequiresTokenForPublicUrl() {
    Listener|error result = new (TEST_PORT + 8, secretToken = "secret-token", publicUrl = "https://example.com/");
    test:assertTrue(result is error, "Listener init should fail when publicUrl is set without token");
}

// A `Listener` created with `token` and `publicUrl` registers its own webhook on `start()`,
// without a separate `Client->setWebhook` call.
int autoWebhookApiPort = TEST_PORT + 9;
json autoWebhookLastPayload = {};

isolated service class MockAutoWebhookApiService {
    *http:Service;

    resource function post [string... path](@http:Payload json payload) returns json {
        lock {
            autoWebhookLastPayload = payload.clone();
        }
        return {"ok": true, "result": true};
    }
}

@test:Config {}
function testListenerRegistersWebhookOnStart() returns error? {
    http:Listener mockApiListener = check new (autoWebhookApiPort);
    check mockApiListener.attach(new MockAutoWebhookApiService(), "/");
    check mockApiListener.'start();

    int port = TEST_PORT + 10;
    Listener telegramListener = check new (port, token = "bot-token", publicUrl = "https://example.com/webhook",
            serviceUrl = string `http://localhost:${autoWebhookApiPort}`);
    check telegramListener.'start();

    json payload;
    lock {
        payload = autoWebhookLastPayload.clone();
    }
    string expectedSecret = check deriveSecretToken("bot-token");
    test:assertEquals(payload.url, "https://example.com/webhook",
            "start() should register publicUrl as the webhook");
    test:assertEquals(payload.secret_token, expectedSecret,
            "start() should register the webhook with the token-derived secret");

    check telegramListener.immediateStop();
    check mockApiListener.immediateStop();
}

// `Client->setWebhook` must forward the caller's `secret_token` verbatim so that Telegram
// echoes it back on every update via the `X-Telegram-Bot-Api-Secret-Token` header, which is
// what the listener tests above check on the receiving end.
int mockWebhookPort = TEST_PORT + 3;
json mockWebhookLastPayload = {};

isolated service class MockTelegramApiService {
    *http:Service;

    resource function post [string... path](@http:Payload json payload) returns json {
        lock {
            mockWebhookLastPayload = payload.clone();
        }
        return {"ok": true, "result": true};
    }
}

@test:Config {}
function testSetWebhookSendsSecretToken() returns error? {
    http:Listener mockHttpListener = check new (mockWebhookPort);
    check mockHttpListener.attach(new MockTelegramApiService(), "/");
    check mockHttpListener.'start();

    Client telegramClient = check new ({token: "test-token"}, string `http://localhost:${mockWebhookPort}`);
    check telegramClient->setWebhook("https://example.com/webhook", secret_token = "secret-token");

    json payload;
    lock {
        payload = mockWebhookLastPayload.clone();
    }
    test:assertEquals(payload.secret_token, "secret-token",
            "setWebhook should forward the configured secret_token to Telegram");
    test:assertEquals(payload.url, "https://example.com/webhook");

    check mockHttpListener.immediateStop();
}

// When `secret_token` is omitted, `setWebhook` must derive it from the client's own bot token
// (`deriveSecretToken`) rather than registering the webhook with no secret at all.
int derivedWebhookPort = TEST_PORT + 7;
json derivedWebhookLastPayload = {};

isolated service class MockDerivedTelegramApiService {
    *http:Service;

    resource function post [string... path](@http:Payload json payload) returns json {
        lock {
            derivedWebhookLastPayload = payload.clone();
        }
        return {"ok": true, "result": true};
    }
}

@test:Config {}
function testSetWebhookDerivesSecretTokenWhenOmitted() returns error? {
    http:Listener mockHttpListener = check new (derivedWebhookPort);
    check mockHttpListener.attach(new MockDerivedTelegramApiService(), "/");
    check mockHttpListener.'start();

    Client telegramClient = check new ({token: "test-token"}, string `http://localhost:${derivedWebhookPort}`);
    check telegramClient->setWebhook("https://example.com/webhook");

    json payload;
    lock {
        payload = derivedWebhookLastPayload.clone();
    }
    string expectedSecret = check deriveSecretToken("test-token");
    test:assertEquals(payload.secret_token, expectedSecret,
            "setWebhook should default secret_token to deriveSecretToken(token) when omitted");

    check mockHttpListener.immediateStop();
}

// ── ChatMember Union Discrimination ───────────────────────────────────────────────

@test:Config {}
function testChatMemberUnionDiscriminatesOwner() returns error? {
    json payload = {
        "status": "creator",
        "user": {"id": 1, "is_bot": false, "first_name": "Bot"},
        "is_anonymous": false
    };
    ChatMember member = check payload.cloneWithType();
    test:assertTrue(member is ChatMemberOwner, "status 'creator' should discriminate to ChatMemberOwner");
}

@test:Config {}
function testChatMemberUnionDiscriminatesAdministrator() returns error? {
    json payload = {
        "status": "administrator",
        "user": {"id": 1, "is_bot": false, "first_name": "Bot"},
        "can_be_edited": true,
        "is_anonymous": false,
        "can_manage_chat": true,
        "can_delete_messages": true,
        "can_manage_video_chats": true,
        "can_restrict_members": true,
        "can_promote_members": false,
        "can_change_info": true,
        "can_invite_users": true
    };
    ChatMember member = check payload.cloneWithType();
    test:assertTrue(member is ChatMemberAdministrator,
            "status 'administrator' should discriminate to ChatMemberAdministrator");
}

@test:Config {}
function testChatMemberUnionDiscriminatesMember() returns error? {
    json payload = {"status": "member", "user": {"id": 1, "is_bot": false, "first_name": "Bot"}};
    ChatMember member = check payload.cloneWithType();
    test:assertTrue(member is ChatMemberMember, "status 'member' should discriminate to ChatMemberMember");
}

@test:Config {}
function testChatMemberUnionDiscriminatesRestricted() returns error? {
    json payload = {
        "status": "restricted",
        "user": {"id": 1, "is_bot": false, "first_name": "Bot"},
        "is_member": true,
        "until_date": 1700000000
    };
    ChatMember member = check payload.cloneWithType();
    test:assertTrue(member is ChatMemberRestricted, "status 'restricted' should discriminate to ChatMemberRestricted");
}

@test:Config {}
function testChatMemberUnionDiscriminatesLeft() returns error? {
    json payload = {"status": "left", "user": {"id": 1, "is_bot": false, "first_name": "Bot"}};
    ChatMember member = check payload.cloneWithType();
    test:assertTrue(member is ChatMemberLeft, "status 'left' should discriminate to ChatMemberLeft");
}

@test:Config {}
function testChatMemberUnionDiscriminatesBanned() returns error? {
    json payload = {
        "status": "kicked",
        "user": {"id": 1, "is_bot": false, "first_name": "Bot"},
        "until_date": 1700000000
    };
    ChatMember member = check payload.cloneWithType();
    test:assertTrue(member is ChatMemberBanned, "status 'kicked' should discriminate to ChatMemberBanned");
}

// ── ReplyMarkup Union Discrimination ──────────────────────────────────────────────

@test:Config {}
function testReplyMarkupUnionDiscriminatesInlineKeyboard() returns error? {
    json payload = {"inline_keyboard": [[{"text": "A", "callback_data": "a"}]]};
    ReplyMarkup markup = check payload.cloneWithType();
    test:assertTrue(markup is InlineKeyboardMarkup, "an 'inline_keyboard' field should discriminate accordingly");
}

@test:Config {}
function testReplyMarkupUnionDiscriminatesReplyKeyboard() returns error? {
    json payload = {"keyboard": [[{"text": "A"}]]};
    ReplyMarkup markup = check payload.cloneWithType();
    test:assertTrue(markup is ReplyKeyboardMarkup, "a 'keyboard' field should discriminate accordingly");
}

@test:Config {}
function testReplyMarkupUnionDiscriminatesRemove() returns error? {
    json payload = {"remove_keyboard": true};
    ReplyMarkup markup = check payload.cloneWithType();
    test:assertTrue(markup is ReplyKeyboardRemove, "a 'remove_keyboard' field should discriminate accordingly");
}

@test:Config {}
function testReplyMarkupUnionDiscriminatesForceReply() returns error? {
    json payload = {"force_reply": true};
    ReplyMarkup markup = check payload.cloneWithType();
    test:assertTrue(markup is ForceReply, "a 'force_reply' field should discriminate accordingly");
}

// ── InputMedia Union Discrimination ───────────────────────────────────────────────

@test:Config {}
function testInputMediaUnionDiscriminatesPhoto() returns error? {
    json payload = {"type": "photo", "media": "https://example.com/a.jpg"};
    InputMedia media = check payload.cloneWithType();
    test:assertTrue(media is InputMediaPhoto, "type 'photo' should discriminate to InputMediaPhoto");
}

@test:Config {}
function testInputMediaUnionDiscriminatesVideo() returns error? {
    json payload = {"type": "video", "media": "https://example.com/a.mp4"};
    InputMedia media = check payload.cloneWithType();
    test:assertTrue(media is InputMediaVideo, "type 'video' should discriminate to InputMediaVideo");
}

@test:Config {}
function testInputMediaUnionDiscriminatesDocument() returns error? {
    json payload = {"type": "document", "media": "https://example.com/a.pdf"};
    InputMedia media = check payload.cloneWithType();
    test:assertTrue(media is InputMediaDocument, "type 'document' should discriminate to InputMediaDocument");
}

// ── unwrapResult ───────────────────────────────────────────────────────────────────

@test:Config {}
function testUnwrapResultReturnsResultOnOkTrue() returns error? {
    json response = {"ok": true, "result": {"id": 42}};
    json result = check unwrapResult(response);
    test:assertEquals(result, <json>{"id": 42});
}

// A mock Bot API that answers with a real non-2xx HTTP status alongside an `ok:false` JSON body,
// the way Telegram's Bot API actually reports errors (e.g. `400 Bad Request`). Exercises the
// `postJson` path end-to-end, rather than calling `unwrapResult` directly, to confirm the error
// body isn't lost when the underlying `http:Client` call fails with a non-2xx status.
int telegramErrorApiPort = TEST_PORT + 11;

isolated service class MockTelegramErrorApiService {
    *http:Service;

    resource function post [string... path](@http:Payload json payload) returns http:BadRequest {
        return {
            body: {"ok": false, "error_code": 400, "description": "Bad Request: chat not found"}
        };
    }
}

@test:Config {}
function testNonTwoXxStatusStillProducesTelegramError() returns error? {
    http:Listener mockHttpListener = check new (telegramErrorApiPort);
    check mockHttpListener.attach(new MockTelegramErrorApiService(), "/");
    check mockHttpListener.'start();

    Client telegramClient = check new ({token: "test-token"}, string `http://localhost:${telegramErrorApiPort}`);
    ChatFullInfo|Error result = telegramClient->getChat(123);
    if result is TelegramError {
        test:assertEquals(result.detail().errorCode, 400);
        test:assertEquals(result.message(), "Bad Request: chat not found");
    } else {
        test:assertFail("a non-2xx status with an ok:false body should produce a TelegramError, not a generic ClientError");
    }

    check mockHttpListener.immediateStop();
}

@test:Config {}
function testUnwrapResultReturnsErrorOnOkFalse() {
    json response = {
        "ok": false,
        "error_code": 400,
        "description": "Bad Request",
        "parameters": {"retry_after": 5}
    };
    json|error result = unwrapResult(response);
    if result is TelegramError {
        TelegramErrorDetail detail = result.detail();
        test:assertEquals(detail.errorCode, 400);
        ResponseParameters? params = detail.parameters;
        if params is ResponseParameters {
            test:assertEquals(params.retryAfter, 5);
        } else {
            test:assertFail("parameters should be present on the constructed TelegramError");
        }
    } else {
        test:assertFail("ok:false should produce a TelegramError");
    }
}

// ── constantTimeEquals ────────────────────────────────────────────────────────────

@test:Config {}
function testConstantTimeEqualsMatch() {
    test:assertTrue(constantTimeEquals("secret-token", "secret-token"));
}

@test:Config {}
function testConstantTimeEqualsMismatch() {
    test:assertFalse(constantTimeEquals("secret-token", "wrong-token"));
    test:assertFalse(constantTimeEquals("short", "a-much-longer-string"));
    // Same length as the correct value, differing only in the last byte — the only case that
    // actually exercises the byte-by-byte comparison loop rather than short-circuiting at the
    // length check above.
    test:assertFalse(constantTimeEquals("secret-token", "secret-tokeN"));
}

// ── deriveSecretToken ─────────────────────────────────────────────────────────────

@test:Config {}
function testDeriveSecretTokenIsDeterministic() returns error? {
    string first = check deriveSecretToken("bot-token");
    string second = check deriveSecretToken("bot-token");
    test:assertEquals(first, second, "the same token should always derive the same secret token");
}

@test:Config {}
function testDeriveSecretTokenDiffersPerToken() returns error? {
    string a = check deriveSecretToken("bot-token-a");
    string b = check deriveSecretToken("bot-token-b");
    test:assertNotEquals(a, b, "different tokens should derive different secret tokens");
}

@test:Config {}
function testDeriveSecretTokenUsesAllowedCharset() returns error? {
    string secret = check deriveSecretToken("bot-token");
    test:assertEquals(secret.length(), 64, "a hex-encoded SHA-256 HMAC should be 64 characters");
    foreach string:Char c in secret {
        test:assertTrue(re `[A-Za-z0-9_-]`.isFullMatch(c),
                string `'${c}' is outside secret_token's allowed [A-Za-z0-9_-] charset`);
    }
}
