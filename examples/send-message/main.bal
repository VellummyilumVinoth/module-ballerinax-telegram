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

import ballerina/log;
import ballerinax/telegram;

// Provide these in Config.toml
configurable string token = ?;
configurable string chatId = ?;

final telegram:Client telegramClient = check new ({token});

public function main() returns error? {
    // 1. Send a text message.
    telegram:Message sent = check telegramClient->sendMessage(chatId, "Hello! This is a test message sent via the Ballerina connector.");
    log:printInfo(string `Message sent. Message ID: ${sent.message_id}`);

    // 2. Send a photo by URL (no upload needed — Telegram fetches it).
    telegram:Message photoMessage = check telegramClient->sendPhoto(chatId,
            "https://ballerina.io/img/ballerina-logo.png", caption = "The Ballerina logo");
    log:printInfo(string `Photo sent. Message ID: ${photoMessage.message_id}`);

    // 3. Show a "typing..." indicator, then send a document.
    _ = check telegramClient->sendChatAction(chatId, "upload_document");
    byte[] fileContent = "Hello from the Ballerina Telegram connector!".toBytes();
    telegram:Message documentMessage = check telegramClient->sendDocument(chatId, fileContent,
            fileName = "hello.txt", mimeType = "text/plain", caption = "A file uploaded from raw bytes");
    log:printInfo(string `Document sent. Message ID: ${documentMessage.message_id}`);
}
