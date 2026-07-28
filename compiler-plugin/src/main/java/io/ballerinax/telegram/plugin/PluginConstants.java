/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.telegram.plugin;

import java.util.Map;

/**
 * Compiler plugin constants for the Telegram connector.
 */
final class PluginConstants {

    static final String PACKAGE_ORG = "ballerinax";
    static final String PACKAGE_PREFIX = "telegram";
    static final String EXPECTED_RETURN_SIGNATURE = "error?";

    // Handler name -> the simple name of its expected (sole) parameter type.
    static final Map<String, String> HANDLER_PARAM_TYPES = Map.ofEntries(
            Map.entry("onMessage", "Message"),
            Map.entry("onEditedMessage", "Message"),
            Map.entry("onChannelPost", "Message"),
            Map.entry("onEditedChannelPost", "Message"),
            Map.entry("onCallbackQuery", "CallbackQuery"),
            Map.entry("onInlineQuery", "InlineQuery"),
            Map.entry("onPoll", "Poll"),
            Map.entry("onPreCheckoutQuery", "PreCheckoutQuery"),
            Map.entry("onShippingQuery", "ShippingQuery")
    );

    /**
     * Compilation errors reported by the Telegram compiler plugin.
     */
    enum CompilationErrors {
        INVALID_RESOURCE_FUNCTION("Resource functions are not allowed on a TelegramService; " +
                "declare the handlers you need as remote functions instead.", "TELEGRAM_101"),
        FUNCTION_SHOULD_BE_REMOTE("The '%s' handler must have the remote qualifier.", "TELEGRAM_102"),
        UNKNOWN_HANDLER("Unknown TelegramService handler '%s'. Must be one of: onMessage, " +
                "onEditedMessage, onChannelPost, onEditedChannelPost, onCallbackQuery, onInlineQuery, " +
                "onPoll, onPreCheckoutQuery, onShippingQuery.", "TELEGRAM_103"),
        INVALID_PARAMETER_COUNT("Invalid parameter count. The '%s' handler must accept exactly one parameter.",
                "TELEGRAM_104"),
        INVALID_PARAMETER_TYPE("Invalid parameter type for the '%s' handler. Expected '%s'.", "TELEGRAM_105"),
        INVALID_RETURN_TYPE("Invalid return type for the '%s' handler. Must return error?.", "TELEGRAM_106");

        private final String error;
        private final String errorCode;

        CompilationErrors(String error, String errorCode) {
            this.error = error;
            this.errorCode = errorCode;
        }

        String getError() {
            return error;
        }

        String getErrorCode() {
            return errorCode;
        }
    }

    private PluginConstants() {
    }
}
