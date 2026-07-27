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

# Configuration for the Telegram Bot API `Client`.
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    # The bot token issued by @BotFather; embedded in every request's resource path
    @display {label: "Bot Token"}
    string token;
    # The HTTP version understood by the client
    http:HttpVersion httpVersion = http:HTTP_2_0;
    # Configurations related to HTTP/1.x protocol
    http:ClientHttp1Settings http1Settings = {};
    # Configurations related to HTTP/2 protocol
    http:ClientHttp2Settings http2Settings = {};
    # The maximum time to wait (in seconds) for a response before closing the connection
    decimal timeout = 30;
    # The choice of setting `forwarded`/`x-forwarded` header
    string forwarded = FORWARDED_DISABLE;
    # Configurations associated with redirection
    http:FollowRedirects followRedirects?;
    # Configurations associated with request pooling
    http:PoolConfiguration poolConfig?;
    # HTTP caching related configurations
    http:CacheConfig cache = {};
    # Specifies the way of handling compression (`accept-encoding`) header
    http:Compression compression = http:COMPRESSION_AUTO;
    # Configurations associated with the behaviour of the Circuit Breaker
    http:CircuitBreakerConfig circuitBreaker?;
    # Configurations associated with retrying
    http:RetryConfig retryConfig?;
    # Configurations associated with cookies
    http:CookieConfig cookieConfig?;
    # Configurations associated with inbound response size limits
    http:ResponseLimitConfigs responseLimits = {};
    # SSL/TLS-related options
    http:ClientSecureSocket secureSocket?;
    # Proxy server related options
    http:ProxyConfig proxy?;
    # Provides settings related to client socket configuration
    http:ClientSocketConfig socketConfig = {};
    # Enables the inbound payload validation functionality provided by the constraint package
    boolean validation = true;
    # Enables relaxed data binding on the client side
    boolean laxDataBinding = true;
|};

// ── Core Objects ─────────────────────────────────────────────────────────────────
// Field names mirror Telegram's own snake_case names verbatim (no camelCase translation).
// Big/evolving objects are open records so `cloneWithType` tolerates wire fields outside this
// v1 subset.

# A Telegram user or bot.
#
# + id - The user's unique identifier
# + is_bot - Whether this user is a bot
# + first_name - The user's first name
# + last_name - The user's last name
# + username - The user's username
# + language_code - The user's IETF language tag
# + is_premium - Whether the user has Telegram Premium
public type User record {
    int id;
    boolean is_bot;
    string first_name;
    string last_name?;
    string username?;
    string language_code?;
    boolean is_premium?;
};

# A chat: a private chat, group, supergroup, or channel.
#
# + id - The chat's unique identifier
# + type - The chat type: `private`, `group`, `supergroup`, or `channel`
# + title - The chat's title, for groups/supergroups/channels
# + username - The chat's username, for private chats/supergroups/channels
# + first_name - The other party's first name, for private chats
# + last_name - The other party's last name, for private chats
# + is_forum - Whether the supergroup has forum topics enabled
public type Chat record {
    int id;
    string 'type;
    string title?;
    string username?;
    string first_name?;
    string last_name?;
    boolean is_forum?;
};

# The set of actions a restricted chat member is or is not allowed to take.
#
# + can_send_messages - Whether the user can send text messages, contacts, invoices, locations, and venues
# + can_send_audios - Whether the user can send audio files
# + can_send_documents - Whether the user can send documents
# + can_send_photos - Whether the user can send photos
# + can_send_videos - Whether the user can send videos
# + can_send_video_notes - Whether the user can send video notes
# + can_send_voice_notes - Whether the user can send voice notes
# + can_send_polls - Whether the user can send polls
# + can_send_other_messages - Whether the user can send animations, games, stickers, and use inline bots
# + can_add_web_page_previews - Whether the user can add web page previews to their messages
# + can_change_info - Whether the user can change the chat title, photo, and other settings
# + can_invite_users - Whether the user can invite new users to the chat
# + can_pin_messages - Whether the user can pin messages
# + can_manage_topics - Whether the user can create forum topics
public type ChatPermissions record {
    boolean can_send_messages?;
    boolean can_send_audios?;
    boolean can_send_documents?;
    boolean can_send_photos?;
    boolean can_send_videos?;
    boolean can_send_video_notes?;
    boolean can_send_voice_notes?;
    boolean can_send_polls?;
    boolean can_send_other_messages?;
    boolean can_add_web_page_previews?;
    boolean can_change_info?;
    boolean can_invite_users?;
    boolean can_pin_messages?;
    boolean can_manage_topics?;
};

# The full chat details returned by `getChat`.
#
# + bio - The other party's bio, for private chats
# + description - The chat's description, for groups/supergroups/channels
# + invite_link - The chat's primary invite link
# + pinned_message - The chat's currently pinned message
# + permissions - The default member permissions, for groups/supergroups
# + slow_mode_delay - The minimum seconds between consecutive messages a non-admin can send
# + message_auto_delete_time - The auto-delete timer setting, in seconds
# + sticker_set_name - The chat's assigned sticker set name, for supergroups
# + can_set_sticker_set - Whether the bot can change the chat's sticker set
# + linked_chat_id - The linked discussion group/channel ID
public type ChatFullInfo record {
    *Chat;
    string bio?;
    string description?;
    string invite_link?;
    Message pinned_message?;
    ChatPermissions permissions?;
    int slow_mode_delay?;
    int message_auto_delete_time?;
    string sticker_set_name?;
    boolean can_set_sticker_set?;
    int linked_chat_id?;
};

# One special entity (mention, URL, bold text, etc.) within message text.
#
# + type - The entity kind (e.g. `mention`, `bold`, `url`, `text_link`, `code`)
# + offset - The entity's start position, in UTF-16 code units
# + length - The entity's length, in UTF-16 code units
# + url - The linked URL, present only when `type` is `text_link`
# + user - The mentioned user, present only when `type` is `text_mention`
# + language - The code block's programming language, present only when `type` is `pre`
# + custom_emoji_id - The custom emoji's identifier, present only when `type` is `custom_emoji`
public type MessageEntity record {
    string 'type;
    int offset;
    int length;
    string url?;
    User user?;
    string language?;
    string custom_emoji_id?;
};

# One resolution of a photo.
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + width - The photo's width, in pixels
# + height - The photo's height, in pixels
# + file_size - The file's size, in bytes, if known
public type PhotoSize record {
    string file_id;
    string file_unique_id;
    int width;
    int height;
    int file_size?;
};

# A general file sent as a document.
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + thumbnail - The document's thumbnail, as predicted by the sender
# + file_name - The document's original filename, as defined by the sender
# + mime_type - The document's MIME type, as defined by the sender
# + file_size - The file's size, in bytes, if known
public type Document record {
    string file_id;
    string file_unique_id;
    PhotoSize thumbnail?;
    string file_name?;
    string mime_type?;
    int file_size?;
};

# A video file.
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + width - The video's width, in pixels
# + height - The video's height, in pixels
# + duration - The video's duration, in seconds
# + thumbnail - The video's thumbnail
# + file_name - The video's original filename, as defined by the sender
# + mime_type - The video's MIME type, as defined by the sender
# + file_size - The file's size, in bytes, if known
public type Video record {
    string file_id;
    string file_unique_id;
    int width;
    int height;
    int duration;
    PhotoSize thumbnail?;
    string file_name?;
    string mime_type?;
    int file_size?;
};

# An audio file.
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + duration - The audio's duration, in seconds
# + performer - The audio's performer, as defined by the sender or embedded audio tags
# + title - The audio's title, as defined by the sender or embedded audio tags
# + file_name - The audio's original filename, as defined by the sender
# + mime_type - The audio's MIME type, as defined by the sender
# + file_size - The file's size, in bytes, if known
# + thumbnail - The album cover thumbnail, as predicted by the sender
public type Audio record {
    string file_id;
    string file_unique_id;
    int duration;
    string performer?;
    string title?;
    string file_name?;
    string mime_type?;
    int file_size?;
    PhotoSize thumbnail?;
};

# A voice note.
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + duration - The voice note's duration, in seconds
# + mime_type - The voice note's MIME type, as defined by the sender
# + file_size - The file's size, in bytes, if known
public type Voice record {
    string file_id;
    string file_unique_id;
    int duration;
    string mime_type?;
    int file_size?;
};

# An animation (GIF or H.264/MPEG-4 AVC video without sound).
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + width - The animation's width, in pixels
# + height - The animation's height, in pixels
# + duration - The animation's duration, in seconds
# + thumbnail - The animation's thumbnail, as predicted by the sender
# + file_name - The animation's original filename, as defined by the sender
# + mime_type - The animation's MIME type, as defined by the sender
# + file_size - The file's size, in bytes, if known
public type Animation record {
    string file_id;
    string file_unique_id;
    int width;
    int height;
    int duration;
    PhotoSize thumbnail?;
    string file_name?;
    string mime_type?;
    int file_size?;
};

# A sticker.
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + type - The sticker type: `regular`, `mask`, or `custom_emoji`
# + width - The sticker's width, in pixels
# + height - The sticker's height, in pixels
# + is_animated - Whether the sticker is animated
# + is_video - Whether the sticker is a video sticker
# + thumbnail - The sticker's thumbnail, in `.webp` or `.jpg` format
# + emoji - The emoji associated with the sticker
# + set_name - The name of the sticker set the sticker belongs to
# + file_size - The file's size, in bytes, if known
public type Sticker record {
    string file_id;
    string file_unique_id;
    string 'type;
    int width;
    int height;
    boolean is_animated;
    boolean is_video;
    PhotoSize thumbnail?;
    string emoji?;
    string set_name?;
    int file_size?;
};

# A shared contact card.
#
# + phone_number - The contact's phone number
# + first_name - The contact's first name
# + last_name - The contact's last name
# + user_id - The contact's user identifier in Telegram, if the contact has a Telegram account
# + vcard - Additional data about the contact, in vCard format
public type Contact record {
    string phone_number;
    string first_name;
    string last_name?;
    int user_id?;
    string vcard?;
};

# A point on the map.
#
# + longitude - The location's longitude, as defined by the sender
# + latitude - The location's latitude, as defined by the sender
# + horizontal_accuracy - The radius of uncertainty for the location, measured in meters
# + live_period - The time, in seconds, for which the location will keep being updated, for live locations
# + heading - The direction in which the user is moving, in degrees, for live locations
# + proximity_alert_radius - The maximum distance, in meters, for proximity alerts about approaching another
#                            chat member, for live locations
public type Location record {
    decimal longitude;
    decimal latitude;
    decimal horizontal_accuracy?;
    int live_period?;
    int heading?;
    int proximity_alert_radius?;
};

# A venue.
#
# + location - The venue's location
# + title - The venue's name
# + address - The venue's address
# + foursquare_id - The venue's Foursquare identifier
# + foursquare_type - The venue's Foursquare type (e.g. `arts_entertainment/default`)
# + google_place_id - The venue's Google Places identifier
# + google_place_type - The venue's Google Places type
public type Venue record {
    Location location;
    string title;
    string address;
    string foursquare_id?;
    string foursquare_type?;
    string google_place_id?;
    string google_place_type?;
};

# One answer option on a poll.
#
# + text - The option's text
# + voter_count - The number of users who voted for this option
public type PollOption record {
    string text;
    int voter_count;
};

# A native poll.
#
# + id - The poll's unique identifier
# + question - The poll question
# + options - The list of poll answer options
# + total_voter_count - The total number of users who voted in the poll
# + is_closed - Whether the poll is closed and no longer accepts new votes
# + is_anonymous - Whether the poll is anonymous
# + type - The poll type: `regular` or `quiz`
# + allows_multiple_answers - Whether the poll allows multiple answers
# + correct_option_ids - The 0-based identifiers of the correct answer option(s), for quiz-type polls
# + explanation - Text shown when a user chooses an incorrect answer or taps the lamp icon, for quiz-type polls
# + open_period - The amount of time the poll is active, in seconds
# + close_date - The point in time (Unix timestamp) when the poll is scheduled to close automatically
public type Poll record {
    string id;
    string question;
    PollOption[] options;
    int total_voter_count;
    boolean is_closed;
    boolean is_anonymous;
    string 'type;
    boolean allows_multiple_answers;
    int[] correct_option_ids?;
    string explanation?;
    int open_period?;
    int close_date?;
};

# The webhook status returned by `getWebhookInfo`.
#
# + url - The webhook URL currently set; empty if no webhook is set
# + has_custom_certificate - Whether a custom certificate was provided for webhook certificate checks
# + pending_update_count - The number of updates awaiting delivery
# + ip_address - The current IP address resolved for the webhook URL
# + last_error_date - The Unix timestamp of the most recent error, if any, delivering an update via webhook
# + last_error_message - The error message for the most recent error, if any, delivering an update via webhook
# + max_connections - The maximum allowed number of simultaneous HTTPS connections to the webhook
# + allowed_updates - The update types the bot is subscribed to
public type WebhookInfo record {
    string url;
    boolean has_custom_certificate;
    int pending_update_count;
    string ip_address?;
    int last_error_date?;
    string last_error_message?;
    int max_connections?;
    string[] allowed_updates?;
};

# A file's metadata, as returned by `getFile`.
#
# + file_id - An identifier for reusing this file in future requests
# + file_unique_id - An identifier that is the same regardless of which bot requested the file
# + file_size - The file's size, in bytes, if known
# + file_path - The path to fetch the file's bytes from, valid for at least 1 hour
public type File record {
    string file_id;
    string file_unique_id;
    int file_size?;
    string file_path?;
};

# A message. Mirrors a v1 subset of Telegram's own [`Message` object](https://core.telegram.org/bots/api#message)
#
# + message_id - The message's unique identifier within the chat
# + message_thread_id - The forum topic the message belongs to, if any
# + date - The message's send date, as a Unix timestamp
# + chat - The chat the message belongs to
# + 'from - The message's sender; absent for messages sent to channels
# + text - The message's text, for text messages
# + entities - Special entities (mentions, URLs, formatting, ...) within `text`
# + caption - The media caption, for media messages
# + caption_entities - Special entities within `caption`
# + reply_to_message - The message being replied to, if any
# + photo - The message's photo, in up to 4 resolutions
# + document - The message's general file, if any
# + video - The message's video, if any
# + audio - The message's audio file, if any
# + voice - The message's voice note, if any
# + animation - The message's animation, if any
# + sticker - The message's sticker, if any
# + contact - The message's shared contact, if any
# + location - The message's shared location, if any
# + venue - The message's shared venue, if any
# + poll - The message's native poll, if any
# + reply_markup - The inline keyboard attached to the message, if any
public type Message record {
    int message_id;
    int message_thread_id?;
    int date;
    Chat chat;
    User 'from?;
    string text?;
    MessageEntity[] entities?;
    string caption?;
    MessageEntity[] caption_entities?;
    Message reply_to_message?;
    PhotoSize[] photo?;
    Document document?;
    Video video?;
    Audio audio?;
    Voice voice?;
    Animation animation?;
    Sticker sticker?;
    Contact contact?;
    Location location?;
    Venue venue?;
    Poll poll?;
    InlineKeyboardMarkup reply_markup?;
};

// ── Reply Markup (4-way union) ────────────────────────────────────────────────────

# A `web_app` button's launch target.
#
# + url - The HTTPS URL of the Web App to open when the button is pressed
public type WebAppInfo record {
    string url;
};

# One button on an inline keyboard.
#
# + text - The label text on the button
# + url - The HTTP or `tg://` URL to open when the button is pressed
# + callback_data - The data sent back to the bot in a `CallbackQuery` when the button is pressed
# + web_app - The Web App to launch when the button is pressed
# + switch_inline_query - The inline query inserted into the input field when the user picks a chat to switch to
# + switch_inline_query_current_chat - The inline query inserted into the input field of the current chat
#                                      when the button is pressed
# + pay - Whether this is a `Pay` button, for invoice messages only
public type InlineKeyboardButton record {
    string text;
    string url?;
    string callback_data?;
    WebAppInfo web_app?;
    string switch_inline_query?;
    string switch_inline_query_current_chat?;
    boolean pay?;
};

# An inline keyboard, shown attached to the message it belongs to.
#
# + inline_keyboard - The array of button rows, each an array of `InlineKeyboardButton` objects
public type InlineKeyboardMarkup record {
    InlineKeyboardButton[][] inline_keyboard;
};

# One button on a custom reply keyboard.
#
# + text - The button's label text, sent as a message when pressed unless another option below is set
# + request_contact - Whether pressing the button requests the user's phone number and sends it as a contact
# + request_location - Whether pressing the button requests the user's current location and sends it
# + web_app - The Web App to launch when the button is pressed
public type KeyboardButton record {|
    string text;
    boolean request_contact?;
    boolean request_location?;
    WebAppInfo web_app?;
|};

# A custom keyboard shown in place of the user's regular keyboard.
#
# + keyboard - The array of button rows that make up the custom keyboard
# + is_persistent - Whether the keyboard is always shown, even when a regular keyboard is available
# + resize_keyboard - Whether the keyboard should be resized vertically to fit only the buttons shown
# + one_time_keyboard - Whether the keyboard should be hidden as soon as it is used
# + input_field_placeholder - The placeholder text shown in the message input field when the keyboard is active
# + selective - Whether the keyboard is shown only to specific users
public type ReplyKeyboardMarkup record {|
    KeyboardButton[][] keyboard;
    boolean is_persistent?;
    boolean resize_keyboard?;
    boolean one_time_keyboard?;
    string input_field_placeholder?;
    boolean selective?;
|};

# An instruction to remove any active custom reply keyboard.
#
# + remove_keyboard - Always `true`; instructs clients to remove the custom keyboard
# + selective - Whether the keyboard is removed only for specific users
public type ReplyKeyboardRemove record {|
    true remove_keyboard = true;
    boolean selective?;
|};

# An instruction to show a "reply" input prompt to selected users.
#
# + force_reply - Always `true`; instructs clients to show a reply interface to the user
# + input_field_placeholder - The placeholder text shown in the message input field when the reply interface
#                             is active
# + selective - Whether the reply interface is shown only to specific users
public type ForceReply record {|
    true force_reply = true;
    string input_field_placeholder?;
    boolean selective?;
|};

# Any keyboard/prompt attachable to an outbound message via `reply_markup`.
public type ReplyMarkup InlineKeyboardMarkup|ReplyKeyboardMarkup|ReplyKeyboardRemove|ForceReply;

// ── Chat Member (6-way union) ─────────────────────────────────────────────────────

# A chat member who owns the chat.
#
# + status - The member's status in the chat; always `creator`
# + user - Information about the user
# + is_anonymous - Whether the user's presence in the chat is hidden
# + custom_title - The owner's custom title
public type ChatMemberOwner record {
    CHAT_MEMBER_STATUS_CREATOR status = CHAT_MEMBER_STATUS_CREATOR;
    User user;
    boolean is_anonymous;
    string custom_title?;
};

# A chat member with administrator privileges.
#
# + status - The member's status in the chat; always `administrator`
# + user - Information about the user
# + can_be_edited - Whether the bot can edit the administrator's privileges
# + is_anonymous - Whether the administrator's presence in the chat is hidden
# + can_manage_chat - Whether the administrator has full access to all chat management features
# + can_delete_messages - Whether the administrator can delete messages from other users
# + can_manage_video_chats - Whether the administrator can manage video chats
# + can_restrict_members - Whether the administrator can restrict, ban, or unban chat members
# + can_promote_members - Whether the administrator can add new administrators or demote existing ones
# + can_change_info - Whether the administrator can change the chat title, photo, and other settings
# + can_invite_users - Whether the administrator can invite new users to the chat
# + can_post_messages - Whether the administrator can post messages in the channel
# + can_edit_messages - Whether the administrator can edit messages of other users, for channels
# + can_pin_messages - Whether the administrator can pin messages, for groups and supergroups
# + can_manage_topics - Whether the administrator can create, rename, close, and reopen forum topics
# + custom_title - The administrator's custom title
public type ChatMemberAdministrator record {
    CHAT_MEMBER_STATUS_ADMINISTRATOR status = CHAT_MEMBER_STATUS_ADMINISTRATOR;
    User user;
    boolean can_be_edited;
    boolean is_anonymous;
    boolean can_manage_chat;
    boolean can_delete_messages;
    boolean can_manage_video_chats;
    boolean can_restrict_members;
    boolean can_promote_members;
    boolean can_change_info;
    boolean can_invite_users;
    boolean can_post_messages?;
    boolean can_edit_messages?;
    boolean can_pin_messages?;
    boolean can_manage_topics?;
    string custom_title?;
};

# A chat member with no special privileges or restrictions.
#
# + status - The member's status in the chat; always `member`
# + user - Information about the user
# + until_date - The Unix timestamp until which the subscription to the chat is active, for subscribers
public type ChatMemberMember record {
    CHAT_MEMBER_STATUS_MEMBER status = CHAT_MEMBER_STATUS_MEMBER;
    User user;
    int until_date?;
};

# A chat member restricted by some chat-permission limits.
#
# + status - The member's status in the chat; always `restricted`
# + user - Information about the user
# + is_member - Whether the user is a member of the chat at the moment of the request
# + can_send_messages - Whether the user can send text messages, contacts, invoices, locations, and venues
# + can_send_audios - Whether the user can send audio files
# + can_send_documents - Whether the user can send documents
# + can_send_photos - Whether the user can send photos
# + can_send_videos - Whether the user can send videos
# + can_send_video_notes - Whether the user can send video notes
# + can_send_voice_notes - Whether the user can send voice notes
# + can_send_polls - Whether the user can send polls
# + can_send_other_messages - Whether the user can send animations, games, stickers, and use inline bots
# + can_add_web_page_previews - Whether the user can add web page previews to their messages
# + can_change_info - Whether the user can change the chat title, photo, and other settings
# + can_invite_users - Whether the user can invite new users to the chat
# + can_pin_messages - Whether the user can pin messages
# + can_manage_topics - Whether the user can create forum topics
# + until_date - The Unix timestamp until which the restrictions are in place
public type ChatMemberRestricted record {
    CHAT_MEMBER_STATUS_RESTRICTED status = CHAT_MEMBER_STATUS_RESTRICTED;
    User user;
    boolean is_member;
    boolean can_send_messages?;
    boolean can_send_audios?;
    boolean can_send_documents?;
    boolean can_send_photos?;
    boolean can_send_videos?;
    boolean can_send_video_notes?;
    boolean can_send_voice_notes?;
    boolean can_send_polls?;
    boolean can_send_other_messages?;
    boolean can_add_web_page_previews?;
    boolean can_change_info?;
    boolean can_invite_users?;
    boolean can_pin_messages?;
    boolean can_manage_topics?;
    int until_date;
};

# A former chat member who left on their own.
#
# + status - The member's status in the chat; always `left`
# + user - Information about the user
public type ChatMemberLeft record {
    CHAT_MEMBER_STATUS_LEFT status = CHAT_MEMBER_STATUS_LEFT;
    User user;
};

# A former chat member who was banned.
#
# + status - The member's status in the chat; always `kicked`
# + user - Information about the user
# + until_date - The Unix timestamp until which the ban is in place; `0` means the ban is permanent
public type ChatMemberBanned record {
    CHAT_MEMBER_STATUS_KICKED status = CHAT_MEMBER_STATUS_KICKED;
    User user;
    int until_date;
};

# Any chat member, narrowed by its `status` field.
public type ChatMember ChatMemberOwner|ChatMemberAdministrator|ChatMemberMember|ChatMemberRestricted|
        ChatMemberLeft|ChatMemberBanned;

// ── Input Media (4-way union) ─────────────────────────────────────────────────────
// v1 scope: `media` is a `file_id`/URL string only; Telegram's `attach://` raw-byte multi-upload
// convention for mixed media groups is deferred to a later version. Animations are excluded
// entirely — `sendMediaGroup` only accepts photo/video/audio/document items.

# A photo, as one item of a `sendMediaGroup` batch.
#
# + type - The media type; always `photo`
# + media - A `file_id` or an HTTP(S) URL identifying the photo to send
# + caption - The caption to show with the photo
# + parse_mode - The formatting mode used to parse `caption`
# + has_spoiler - Whether the photo needs to be covered with a spoiler animation
public type InputMediaPhoto record {|
    INPUT_MEDIA_TYPE_PHOTO 'type = INPUT_MEDIA_TYPE_PHOTO;
    string media;
    string caption?;
    string parse_mode?;
    boolean has_spoiler?;
|};

# A video, as one item of a `sendMediaGroup` batch.
#
# + type - The media type; always `video`
# + media - A `file_id` or an HTTP(S) URL identifying the video to send
# + caption - The caption to show with the video
# + parse_mode - The formatting mode used to parse `caption`
# + width - The video's width, in pixels
# + height - The video's height, in pixels
# + duration - The video's duration, in seconds
# + supports_streaming - Whether the uploaded video is suitable for streaming
# + has_spoiler - Whether the video needs to be covered with a spoiler animation
public type InputMediaVideo record {|
    INPUT_MEDIA_TYPE_VIDEO 'type = INPUT_MEDIA_TYPE_VIDEO;
    string media;
    string caption?;
    string parse_mode?;
    int width?;
    int height?;
    int duration?;
    boolean supports_streaming?;
    boolean has_spoiler?;
|};

# An audio file, as one item of a `sendMediaGroup` batch.
#
# + type - The media type; always `audio`
# + media - A `file_id` or an HTTP(S) URL identifying the audio file to send
# + caption - The caption to show with the audio
# + parse_mode - The formatting mode used to parse `caption`
# + duration - The audio's duration, in seconds
# + performer - The audio's performer
# + title - The audio's title
public type InputMediaAudio record {|
    INPUT_MEDIA_TYPE_AUDIO 'type = INPUT_MEDIA_TYPE_AUDIO;
    string media;
    string caption?;
    string parse_mode?;
    int duration?;
    string performer?;
    string title?;
|};

# A general file, as one item of a `sendMediaGroup` batch.
#
# + type - The media type; always `document`
# + media - A `file_id` or an HTTP(S) URL identifying the document to send
# + caption - The caption to show with the document
# + parse_mode - The formatting mode used to parse `caption`
# + disable_content_type_detection - Whether to disable automatic server-side content type detection
public type InputMediaDocument record {|
    INPUT_MEDIA_TYPE_DOCUMENT 'type = INPUT_MEDIA_TYPE_DOCUMENT;
    string media;
    string caption?;
    string parse_mode?;
    boolean disable_content_type_detection?;
|};

# Any media item attachable to a `sendMediaGroup` batch.
public type InputMedia InputMediaPhoto|InputMediaVideo|InputMediaAudio|InputMediaDocument;

// ── Inline Query Result (2 of ~20 variants scoped for v1) ─────────────────────────
// Deliberately scoped to the 2 most commonly used variants; additional variants are additive
// and non-breaking to add later.

# Text content sent in place of the inline query result content, when the result itself has none.
#
# + message_text - The text of the message to be sent, 1-4096 characters
# + parse_mode - The formatting mode used to parse `message_text`
# + entities - Special entities within `message_text`, as an alternative to `parse_mode`
public type InputTextMessageContent record {|
    string message_text;
    string parse_mode?;
    MessageEntity[] entities?;
|};

# A link to an article or web page, as an inline query result.
#
# + type - The result type; always `article`
# + id - The result's unique identifier, 1-64 bytes
# + title - The title shown for the result
# + input_message_content - The content of the message to be sent
# + reply_markup - The inline keyboard attached to the message
# + url - The URL of the article, shown as a link beneath the result
# + description - A short description of the result
# + thumbnail_url - The URL of the result's thumbnail
# + thumbnail_width - The thumbnail's width, in pixels
# + thumbnail_height - The thumbnail's height, in pixels
public type InlineQueryResultArticle record {|
    INLINE_QUERY_RESULT_TYPE_ARTICLE 'type = INLINE_QUERY_RESULT_TYPE_ARTICLE;
    string id;
    string title;
    InputTextMessageContent input_message_content;
    InlineKeyboardMarkup reply_markup?;
    string url?;
    string description?;
    string thumbnail_url?;
    int thumbnail_width?;
    int thumbnail_height?;
|};

# A link to a photo, as an inline query result.
#
# + type - The result type; always `photo`
# + id - The result's unique identifier, 1-64 bytes
# + photo_url - The URL of the photo, which must be in JPEG format and not exceed 5MB
# + thumbnail_url - The URL of the photo's thumbnail
# + photo_width - The photo's width, in pixels
# + photo_height - The photo's height, in pixels
# + title - The title shown for the result
# + description - A short description of the result
# + caption - The caption to show with the photo
# + parse_mode - The formatting mode used to parse `caption`
# + reply_markup - The inline keyboard attached to the message
# + input_message_content - The content to send instead of the photo itself
public type InlineQueryResultPhoto record {|
    INLINE_QUERY_RESULT_TYPE_PHOTO 'type = INLINE_QUERY_RESULT_TYPE_PHOTO;
    string id;
    string photo_url;
    string thumbnail_url;
    int photo_width?;
    int photo_height?;
    string title?;
    string description?;
    string caption?;
    string parse_mode?;
    InlineKeyboardMarkup reply_markup?;
    InputTextMessageContent input_message_content?;
|};

# Any result attachable to an `answerInlineQuery` batch.
public type InlineQueryResult InlineQueryResultArticle|InlineQueryResultPhoto;

# A button shown above inline query results.
#
# + text - The label text on the button
# + web_app - The Web App to launch when the button is pressed
# + start_parameter - The deep-linking parameter for the `/start` message sent to the bot when the user
#                     presses the button and switches to a private chat with it
public type InlineQueryResultsButton record {|
    string text;
    WebAppInfo web_app?;
    string start_parameter?;
|};

// ── Callback / Inline / Payment Queries ──────────────────────────────────────────

# An incoming callback query from an inline keyboard button press.
#
# + id - The query's unique identifier
# + 'from - The user who triggered the callback query
# + message - The message with the button that was pressed, if it was sent by the bot
# + inline_message_id - The identifier of the inline message the button belongs to, if the button belongs
#                        to a message sent via the bot in inline mode
# + chat_instance - An identifier, unique to the chat, tying the callback query to the message it originated
#                   from
# + data - The data associated with the button that was pressed
# + game_short_name - The short name of a `Game` to be returned, for games started via `@BotFather`
public type CallbackQuery record {
    string id;
    User 'from;
    Message message?;
    string inline_message_id?;
    string chat_instance;
    string data?;
    string game_short_name?;
};

# An incoming inline query.
#
# + id - The query's unique identifier
# + 'from - The user who sent the query
# + query - The text of the query, up to 256 characters
# + offset - The offset of the results to return, controlled by the bot
# + chat_type - The type of chat from which the inline query was sent
# + location - The sender's location, present if enabled and requested by the bot
public type InlineQuery record {
    string id;
    User 'from;
    string query;
    string offset;
    string chat_type?;
    Location location?;
};

# A shipping address, as supplied by the user on a flexible-price invoice.
#
# + country_code - The two-letter ISO 3166-1 alpha-2 country code
# + state - The state, if applicable
# + city - The city
# + street_line1 - The first line of the address
# + street_line2 - The second line of the address
# + post_code - The post code
public type ShippingAddress record {
    string country_code;
    string state;
    string city;
    string street_line1;
    string street_line2;
    string post_code;
};

# Order information, as supplied by the user on an invoice.
#
# + name - The user's full name
# + phone_number - The user's phone number
# + email - The user's email address
# + shipping_address - The user's shipping address, for flexible-price invoices that require one
public type OrderInfo record {
    string name?;
    string phone_number?;
    string email?;
    ShippingAddress shipping_address?;
};

# An incoming shipping query, for a flexible-price invoice.
#
# + id - The query's unique identifier
# + 'from - The user who sent the query
# + invoice_payload - The bot-specified invoice payload
# + shipping_address - The user's specified shipping address
public type ShippingQuery record {
    string id;
    User 'from;
    string invoice_payload;
    ShippingAddress shipping_address;
};

# An incoming pre-checkout query.
#
# + id - The query's unique identifier
# + 'from - The user who sent the query
# + currency - The three-letter ISO 4217 currency code
# + total_amount - The total price, in the smallest units of the currency
# + invoice_payload - The bot-specified invoice payload
# + shipping_option_id - The identifier of the shipping option chosen by the user
# + order_info - The order information provided by the user
public type PreCheckoutQuery record {
    string id;
    User 'from;
    string currency;
    int total_amount;
    string invoice_payload;
    string shipping_option_id?;
    OrderInfo order_info?;
};

// ── Rich Message ──────────────────────────────────────────────────────────────────
// A simple 2-member union rather than the full rich-text block object model.

# Rich message content authored in Markdown.
#
# + markdown - The rich message content, formatted as Markdown
public type MarkdownRichMessage record {|
    string markdown;
|};

# Rich message content authored in HTML.
#
# + html - The rich message content, formatted as HTML
public type HtmlRichMessage record {|
    string html;
|};

# Rich message content, in either supported format.
public type RichMessage MarkdownRichMessage|HtmlRichMessage;

// ── Other Unions ──────────────────────────────────────────────────────────────────

# The chat action shown via `sendChatAction` (e.g. the "typing..." indicator).
public type ChatAction "typing"|"upload_photo"|"record_video"|"upload_video"|"record_voice"|"upload_voice"|
        "upload_document"|"choose_sticker"|"find_location"|"record_video_note"|"upload_video_note";

// ── Per-Operation Option Records ──────────────────────────────────────────────────
// One record per operation with 2+ optional fields, spread as named optional parameters via
// `*XOptions options` on the matching remote function.

# Optional fields for `sendMessage`.
public type SendMessageOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The formatting mode used to parse the message text
    string parse_mode?;
    # Special entities within the message text, as an alternative to `parse_mode`
    MessageEntity[] entities?;
    # Whether to disable a link preview for links in the message
    boolean disable_web_page_preview?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # Whether to send the message even if the replied-to message is not found
    boolean allow_sending_without_reply?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
|};

# Optional fields for `sendPhoto`.
public type SendPhotoOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The caption to show with the photo
    string caption?;
    # The formatting mode used to parse `caption`
    string parse_mode?;
    # Special entities within `caption`, as an alternative to `parse_mode`
    MessageEntity[] caption_entities?;
    # Whether the photo needs to be covered with a spoiler animation
    boolean has_spoiler?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
    # The multipart filename to use, when `photo` is raw bytes
    string fileName?;
    # The multipart content type to use, when `photo` is raw bytes
    string mimeType?;
|};

# Optional fields for `sendVideo`.
public type SendVideoOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The video's duration, in seconds
    int duration?;
    # The video's width, in pixels
    int width?;
    # The video's height, in pixels
    int height?;
    # The caption to show with the video
    string caption?;
    # The formatting mode used to parse `caption`
    string parse_mode?;
    # Special entities within `caption`, as an alternative to `parse_mode`
    MessageEntity[] caption_entities?;
    # Whether the video needs to be covered with a spoiler animation
    boolean has_spoiler?;
    # Whether the uploaded video is suitable for streaming
    boolean supports_streaming?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
    # The multipart filename to use, when `video` is raw bytes
    string fileName?;
    # The multipart content type to use, when `video` is raw bytes
    string mimeType?;
|};

# Optional fields for `sendAudio`.
public type SendAudioOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The caption to show with the audio
    string caption?;
    # The formatting mode used to parse `caption`
    string parse_mode?;
    # Special entities within `caption`, as an alternative to `parse_mode`
    MessageEntity[] caption_entities?;
    # The audio's duration, in seconds
    int duration?;
    # The audio's performer
    string performer?;
    # The audio's title
    string title?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
    # The multipart filename to use, when `audio` is raw bytes
    string fileName?;
    # The multipart content type to use, when `audio` is raw bytes
    string mimeType?;
|};

# Optional fields for `sendDocument`.
public type SendDocumentOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The caption to show with the document
    string caption?;
    # The formatting mode used to parse `caption`
    string parse_mode?;
    # Special entities within `caption`, as an alternative to `parse_mode`
    MessageEntity[] caption_entities?;
    # Whether to disable automatic server-side content type detection
    boolean disable_content_type_detection?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
    # The multipart filename to use, when `document` is raw bytes
    string fileName?;
    # The multipart content type to use, when `document` is raw bytes
    string mimeType?;
|};

# Optional fields for `sendAnimation`.
public type SendAnimationOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The animation's duration, in seconds
    int duration?;
    # The animation's width, in pixels
    int width?;
    # The animation's height, in pixels
    int height?;
    # The caption to show with the animation
    string caption?;
    # The formatting mode used to parse `caption`
    string parse_mode?;
    # Special entities within `caption`, as an alternative to `parse_mode`
    MessageEntity[] caption_entities?;
    # Whether the animation needs to be covered with a spoiler animation
    boolean has_spoiler?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
    # The multipart filename to use, when `animation` is raw bytes
    string fileName?;
    # The multipart content type to use, when `animation` is raw bytes
    string mimeType?;
|};

# Optional fields for `sendSticker` (Telegram stickers have no caption).
public type SendStickerOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The emoji associated with the sticker, only for uploads
    string emoji?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
    # The multipart filename to use, when `sticker` is raw bytes
    string fileName?;
    # The multipart content type to use, when `sticker` is raw bytes
    string mimeType?;
|};

# Optional fields for `sendLocation`.
public type SendLocationOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The radius of uncertainty for the location, measured in meters
    decimal horizontal_accuracy?;
    # The time, in seconds, for which the location will keep being updated, for live locations
    int live_period?;
    # The direction in which the user is moving, in degrees, for live locations
    int heading?;
    # The maximum distance, in meters, for proximity alerts about approaching another chat member,
    # for live locations
    int proximity_alert_radius?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
|};

# Optional fields for `editMessageText`.
public type EditMessageTextOptions record {|
    # The formatting mode used to parse the new message text
    string parse_mode?;
    # Special entities within the new message text, as an alternative to `parse_mode`
    MessageEntity[] entities?;
    # Whether to disable a link preview for links in the message
    boolean disable_web_page_preview?;
    # The new inline keyboard attached to the message
    InlineKeyboardMarkup reply_markup?;
|};

# Optional fields for `answerCallbackQuery`.
public type AnswerCallbackQueryOptions record {|
    # The notification text to show the user, 0-200 characters
    string text?;
    # Whether to show an alert instead of a notification at the top of the chat screen
    boolean show_alert = false;
    # The URL the client should open, for games launched via `@BotFather`
    string url?;
    # The maximum time, in seconds, that the callback query result may be cached client-side
    int cache_time = 0;
|};

# Optional fields for `answerInlineQuery`.
public type AnswerInlineQueryOptions record {|
    # The maximum time, in seconds, that the results may be cached on the server
    int cache_time?;
    # Whether the results may be cached on the server only for the user that sent the query
    boolean is_personal?;
    # The offset the client should send in the next query with the same text, to fetch more results
    string next_offset?;
    # A button to show above the results
    InlineQueryResultsButton button?;
|};

# Optional fields for `sendMediaGroup`.
public type SendMediaGroupOptions record {|
    # The forum topic to post the messages in, if any
    int message_thread_id?;
    # Whether to send the messages silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent messages' contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the original message, if this batch is a reply
    int reply_to_message_id?;
|};

# Optional fields for `setWebhook`.
public type SetWebhookOptions record {|
    # The update types to subscribe to; `"*"` (the default) means all 9 update types this
    # connector's `Listener` supports
    string[]|"*" allowed_updates = "*";
    # Whether to drop all pending updates before setting the new webhook
    boolean drop_pending_updates = false;
    # A secret token sent in the `X-Telegram-Bot-Api-Secret-Token` header of every webhook request,
    # used to verify the request came from Telegram. Defaults to `deriveSecretToken(token)` if
    # omitted; see `Client->setWebhook`'s doc comment
    string secret_token?;
    # The maximum allowed number of simultaneous HTTPS connections to the webhook, 1-100
    int max_connections?;
    # The fixed IP address to use for webhook requests, instead of one resolved via DNS
    string ip_address?;
|};

# Optional fields for `sendMessageDraft`.
public type SendMessageDraftOptions record {|
    # The forum topic to post the draft in, if any
    int message_thread_id?;
    # The draft message's text
    string text?;
    # The formatting mode used to parse `text`
    string parse_mode?;
|};

# Optional fields for `sendRichMessage`.
public type SendRichMessageOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # Whether to protect the sent message's contents from forwarding and saving
    boolean protect_content?;
    # The identifier of the message effect to add to the message; private chats only
    string message_effect_id?;
    # Whether the rich message content should be rendered right-to-left
    boolean is_rtl?;
    # Whether to skip automatic detection of entities (links, mentions, formatting) in the rich
    # message content
    boolean skip_entity_detection?;
    # The inline keyboard/prompt attached to the message
    ReplyMarkup reply_markup?;
|};

# One button on a `sendApprovalMessage` prompt.
public type ApprovalButton record {|
    # The button's label
    string text;
    # The data delivered back on `CallbackQuery.data` when pressed
    string callback_data;
|};

# Optional fields for `sendApprovalMessage`. Deliberately excludes `reply_markup` — the inline
# keyboard is always derived from the `approve`/`decline` buttons.
public type ApprovalMessageOptions record {|
    # The forum topic to post the message in, if any
    int message_thread_id?;
    # The formatting mode used to parse the prompt text
    string parse_mode?;
    # Whether to send the message silently, without a notification sound
    boolean disable_notification?;
    # The identifier of the original message, if this message is a reply
    int reply_to_message_id?;
|};
