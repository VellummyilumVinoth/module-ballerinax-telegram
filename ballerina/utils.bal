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

import ballerina/crypto;
import ballerina/data.jsondata;
import ballerina/http;
import ballerina/mime;

// The raw wire envelope every Telegram Bot API response is wrapped in. Kept module-private —
// callers only ever see the unwrapped `result` (via `unwrapResult`) or a `TelegramError`.
type ApiResponse record {
    boolean ok;
    json result?;
    int error_code?;
    string description?;
    ResponseParameters parameters?;
};

# Unwraps a raw Telegram Bot API response, returning `result` on success or a `TelegramError`
# built from `error_code`/`description`/`parameters` on failure.
#
# + response - The raw JSON response body
# + return - The `result` payload, or a `TelegramError`
isolated function unwrapResult(json response) returns json|Error {
    ApiResponse|error envelope = jsondata:parseAsType(response);
    if envelope is error {
        return error ClientError(ERR_ENVELOPE_PARSE_FAILED, envelope);
    }
    if envelope.ok {
        return envelope?.result ?: {};
    }
    return error TelegramError(envelope.description ?: ERR_API_CALL_FAILED,
            errorCode = envelope.error_code, parameters = envelope.parameters);
}

# Builds a `multipart/form-data` request for a raw-byte media upload, alongside the operation's
# other fields. Structured field values (records, arrays) are JSON-stringified, since Telegram's
# multipart parameters must all be plain strings or files; `()`-valued (absent) fields are skipped.
#
# + fields - The operation's non-media fields (e.g. `chat_id`, `caption`, `reply_markup`)
# + mediaFieldName - The multipart field name to attach `mediaBytes` under (e.g. `photo`)
# + mediaBytes - The raw file bytes to upload
# + filename - The multipart filename for the uploaded file
# + mimeType - The multipart content type for the uploaded file
# + return - The constructed request
isolated function buildMultipartRequest(map<anydata> fields, string mediaFieldName, byte[] mediaBytes,
        string filename, string mimeType) returns http:Request {
    http:Request request = new;
    mime:Entity[] parts = [];
    foreach [string, anydata] [key, value] in fields.entries() {
        if value is () {
            continue;
        }
        mime:Entity part = new;
        part.setContentDisposition(mime:getContentDispositionObject(string `form-data; name="${key}"`));
        string stringValue = value is string ? value : value.toJson().toJsonString();
        part.setText(stringValue);
        parts.push(part);
    }
    mime:Entity mediaPart = new;
    mediaPart.setContentDisposition(mime:getContentDispositionObject(
            string `form-data; name="${mediaFieldName}"; filename="${filename}"`));
    mediaPart.setByteArray(mediaBytes, contentType = mimeType);
    parts.push(mediaPart);
    request.setBodyParts(parts, contentType = mime:MULTIPART_FORM_DATA);
    return request;
}

# Deterministically derives a webhook secret token from a bot token, suitable for both
# `ListenerConfig.secretToken` and `Client->setWebhook`'s `secret_token` option — an alternative to
# inventing and threading a random secret through both sides of a webhook setup by hand.
#
# The same `token` always derives the same secret token, so the `Listener` (verifying inbound
# updates) and the `Client` (registering the webhook) can each compute it independently, and it
# stays stable across restarts — unlike a freshly-generated random secret, which would desync from
# whatever Telegram already has registered the moment the process restarts.
#
# ```ballerina
# string secretToken = check telegram:deriveSecretToken(token);
# listener telegram:Listener telegramListener = new (8090, secretToken = secretToken);
# _ = check telegramClient->setWebhook(webhookUrl, secret_token = secretToken);
# ```
#
# + token - The bot token to derive the secret from, e.g. `ConnectionConfig.token`
# + return - A 64-character lowercase hex string deterministic for a given `token` (hex is already
#            within the `[A-Za-z0-9_-]` charset `secret_token` requires), or a `ClientError` if the
#            underlying HMAC computation fails
public isolated function deriveSecretToken(string token) returns string|Error {
    byte[]|error mac = crypto:hmacSha256(token.toBytes(), DERIVE_SECRET_TOKEN_KEY.toBytes());
    if mac is error {
        return error ClientError(ERR_SECRET_DERIVATION_FAILED, mac);
    }
    return mac.toBase16();
}

# Compares two strings in a way that does not short-circuit on the first differing byte, to avoid
# leaking timing information when checking a caller-supplied secret against the expected one.
#
# + a - The first string
# + b - The second string
# + return - Whether the strings are equal
isolated function constantTimeEquals(string a, string b) returns boolean {
    byte[] aBytes = a.toBytes();
    byte[] bBytes = b.toBytes();
    if aBytes.length() != bBytes.length() {
        return false;
    }
    int diff = 0;
    foreach int i in 0 ..< aBytes.length() {
        diff |= aBytes[i] ^ bBytes[i];
    }
    return diff == 0;
}
