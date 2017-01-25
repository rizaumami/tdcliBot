local M = {}

function dl_cb(arg, data)
end

local function getChatId(chat_id)
  local chat = {}
  local chat_id = tostring(chat_id)

  if chat_id:match('^-100') then
    local channel_id = chat_id:gsub('-100', '')
    chat = {ID = channel_id, type = 'channel'}
  else
    local group_id = chat_id:gsub('-', '')
    chat = {ID = group_id, type = 'group'}
  end

  return chat
end

local function getInputFile(file)
  local input = tostring(file)

  if input:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif input:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  return infile
end

local function getParseMode(parse_mode)
  if parse_mode then
    local mode = parse_mode:lower()

    if mode == 'markdown' or mode == 'md' then
      P = {ID = "TextParseModeMarkdown"}
    elseif mode == 'html' then
      P = {ID = "TextParseModeHTML"}
    end
  end

  return P
end

local function sendRequest(request_id, chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, callback, extra)
  tdcli_function ({
    ID = request_id,
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = input_message_content,
  }, callback or dl_cb, extra)
end

local function getAuthState(dl_cb, cmd)
  tdcli_function ({
    ID = "GetAuthState",
  }, cb or dl_cb, cmd)
end

M.getAuthState = getAuthState

local function resetAuth(force, cb, cmd)
  tdcli_function ({
    ID = "ResetAuth",
    force_ = force or nil
  }, cb or dl_cb, cmd)
end

M.resetAuth = resetAuth

local function getPasswordState(dl_cb, cmd)
  tdcli_function ({
    ID = "GetPasswordState",
  }, cb or dl_cb, cmd)
end

M.getPasswordState = getPasswordState

local function setPassword(old_password, new_password, new_hint, set_recovery_email, new_recovery_email, cb, cmd)
  tdcli_function ({
    ID = "SetPassword",
    old_password_ = old_password,
    new_password_ = new_password,
    new_hint_ = new_hint,
    set_recovery_email_ = set_recovery_email,
    new_recovery_email_ = new_recovery_email
  }, cb or dl_cb, cmd)
end

M.setPassword = setPassword

local function getRecoveryEmail(password, cb, cmd)
  tdcli_function ({
    ID = "GetRecoveryEmail",
    password_ = password
  }, cb or dl_cb, cmd)
end

M.getRecoveryEmail = getRecoveryEmail

local function setRecoveryEmail(password, new_recovery_email, cb, cmd)
  tdcli_function ({
    ID = "SetRecoveryEmail",
    password_ = password,
    new_recovery_email_ = new_recovery_email
  }, cb or dl_cb, cmd)
end

M.setRecoveryEmail = setRecoveryEmail

local function requestPasswordRecovery(dl_cb, cmd)
  tdcli_function ({
    ID = "RequestPasswordRecovery",
  }, cb or dl_cb, cmd)
end

M.requestPasswordRecovery = requestPasswordRecovery

local function recoverPassword(recovery_code, cb, cmd)
  tdcli_function ({
    ID = "RecoverPassword",
    recovery_code_ = tostring(recovery_code)
  }, cb or dl_cb, cmd)
end

M.recoverPassword = recoverPassword

local function getMe(cb, cmd)
  tdcli_function ({
    ID = "GetMe",
  }, cb or dl_cb, cmd)
end

M.getMe = getMe

local function getUser(user_id, cb, cmd)
  tdcli_function ({
    ID = "GetUser",
    user_id_ = user_id
  }, cb or dl_cb, cmd)
end

M.getUser = getUser

local function getUserFull(user_id, cb, cmd)
  tdcli_function ({
    ID = "GetUserFull",
    user_id_ = user_id
  }, cb or dl_cb, cmd)
end

M.getUserFull = getUserFull

local function getGroup(group_id, cb, cmd)
  tdcli_function ({
    ID = "GetGroup",
    group_id_ = getChatId(group_id).ID
  }, cb or dl_cb, cmd)
end

M.getGroup = getGroup

local function getGroupFull(group_id, cb, cmd)
  tdcli_function ({
    ID = "GetGroupFull",
    group_id_ = getChatId(group_id).ID
  }, cb or dl_cb, cmd)
end

M.getGroupFull = getGroupFull

local function getChannel(channel_id, cb, cmd)
  tdcli_function ({
    ID = "GetChannel",
    channel_id_ = getChatId(channel_id).ID
  }, cb or dl_cb, cmd)
end

M.getChannel = getChannel

local function getChannelFull(channel_id, cb, cmd)
  tdcli_function ({
    ID = "GetChannelFull",
    channel_id_ = getChatId(channel_id).ID
  }, cb or dl_cb, cmd)
end

M.getChannelFull = getChannelFull

local function getChat(chat_id, cb, cmd)
  tdcli_function ({
    ID = "GetChat",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.getChat = getChat

local function getMessage(chat_id, message_id, cb, cmd)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb or dl_cb, cmd)
end

M.getMessage = getMessage

local function getMessages(chat_id, message_ids, cb, cmd)
  tdcli_function ({
    ID = "GetMessages",
    chat_id_ = chat_id,
    message_ids_ = message_ids -- vector
  }, cb or dl_cb, cmd)
end

M.getMessages = getMessages

local function getFile(file_id, cb, cmd)
  tdcli_function ({
    ID = "GetFile",
    file_id_ = file_id
  }, cb or dl_cb, cmd)
end

M.getFile = getFile

local function getFilePersistent(persistent_file_id, cb, cmd)
  tdcli_function ({
    ID = "GetFilePersistent",
    persistent_file_id_ = persistent_file_id
  }, cb or dl_cb, cmd)
end

M.getFilePersistent = getFilePersistent

local function getChats(offset_order, offset_chat_id, limit, cb, cmd)
  if not limit or limit > 20 then
    limit = 20
  end

  tdcli_function ({
    ID = "GetChats",
    offset_order_ = offset_order or 9223372036854775807,
    offset_chat_id_ = offset_chat_id or 0,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.getChats = getChats

local function searchPublicChat(username, cb, cmd)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb or dl_cb, cmd)
end

M.searchPublicChat = searchPublicChat

local function searchPublicChats(username_prefix, cb, cmd)
  tdcli_function ({
    ID = "SearchPublicChats",
    username_prefix_ = username_prefix
  }, cb or dl_cb, cmd)
end

M.searchPublicChats = searchPublicChats

local function searchChats(query, limit, cb, cmd)
  if not limit or limit > 20 then
    limit = 20
  end

  tdcli_function ({
    ID = "SearchChats",
    query_ = query,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.searchChats = searchChats

local function addRecentlyFoundChat(chat_id, cb, cmd)
  tdcli_function ({
    ID = "AddRecentlyFoundChat",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.addRecentlyFoundChat = addRecentlyFoundChat

local function deleteRecentlyFoundChat(chat_id, cb, cmd)
  tdcli_function ({
    ID = "DeleteRecentlyFoundChat",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.deleteRecentlyFoundChat = deleteRecentlyFoundChat

local function deleteRecentlyFoundChats(dl_cb, cmd)
  tdcli_function ({
    ID = "DeleteRecentlyFoundChats",
  }, cb or dl_cb, cmd)
end

M.deleteRecentlyFoundChats = deleteRecentlyFoundChats

local function getCommonChats(user_id, offset_chat_id, limit, cb, cmd)
  if not limit or limit > 100 then
    limit = 100
  end

  tdcli_function ({
    ID = "GetCommonChats",
    user_id_ = user_id,
    offset_chat_id_ = offset_chat_id,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.getCommonChats = getCommonChats

local function getChatHistory(chat_id, from_message_id, offset, limit, cb, cmd)
  if not limit or limit > 100 then
    limit = 100
  end

  tdcli_function ({
    ID = "GetChatHistory",
    chat_id_ = chat_id,
    from_message_id_ = from_message_id,
    offset_ = offset or 0,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.getChatHistory = getChatHistory

local function deleteChatHistory(chat_id, remove_from_chat_list, cb, cmd)
  tdcli_function ({
    ID = "DeleteChatHistory",
    chat_id_ = chat_id,
    remove_from_chat_list_ = remove_from_chat_list
  }, cb or dl_cb, cmd)
end

M.deleteChatHistory = deleteChatHistory

local function searchChatMessages(chat_id, query, from_message_id, limit, filter, cb, cmd)
  if not limit or limit > 100 then
    limit = 100
  end

  tdcli_function ({
    ID = "SearchChatMessages",
    chat_id_ = chat_id,
    query_ = query,
    from_message_id_ = from_message_id,
    limit_ = limit,
    filter_ = {
      ID = 'SearchMessagesFilter' .. filter
    },
  }, cb or dl_cb, cmd)
end

M.searchChatMessages = searchChatMessages

local function searchMessages(query, offset_date, offset_chat_id, offset_message_id, limit, cb, cmd)
  if not limit or limit > 100 then
    limit = 100
  end

  tdcli_function ({
    ID = "SearchMessages",
    query_ = query,
    offset_date_ = offset_date,
    offset_chat_id_ = offset_chat_id,
    offset_message_id_ = offset_message_id,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.searchMessages = searchMessages

local function sendBotStartMessage(bot_user_id, chat_id, parameter, cb, cmd)
  tdcli_function ({
    ID = "SendBotStartMessage",
    bot_user_id_ = bot_user_id,
    chat_id_ = chat_id,
    parameter_ = parameter
  }, cb or dl_cb, cmd)
end

M.sendBotStartMessage = sendBotStartMessage

local function forwardMessages(chat_id, from_chat_id, message_ids, disable_notification, cb, cmd)
  tdcli_function ({
    ID = "ForwardMessages",
    chat_id_ = chat_id,
    from_chat_id_ = from_chat_id,
    message_ids_ = message_ids, -- vector
    disable_notification_ = disable_notification,
    from_background_ = 1
  }, cb or dl_cb, cmd)
end

M.forwardMessages = forwardMessages

local function deleteMessages(chat_id, message_ids, cb, cmd)
  tdcli_function ({
    ID = "DeleteMessages",
    chat_id_ = chat_id,
    message_ids_ = message_ids -- vector
  }, cb or dl_cb, cmd)
end

M.deleteMessages = deleteMessages

local function deleteMessagesFromUser(chat_id, user_id, cb, cmd)
  tdcli_function ({
    ID = "DeleteMessagesFromUser",
    chat_id_ = chat_id,
    user_id_ = user_id
  }, cb or dl_cb, cmd)
end

M.deleteMessagesFromUser = deleteMessagesFromUser

local function editMessageText(chat_id, message_id, reply_markup, text, disable_web_page_preview, parse_mode, cb, cmd)
  local TextParseMode = getParseMode(parse_mode)

  tdcli_function ({
    ID = "EditMessageText",
    chat_id_ = chat_id,
    message_id_ = message_id,
    reply_markup_ = reply_markup, -- reply_markup:ReplyMarkup
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, cb or dl_cb, cmd)
end

M.editMessageText = editMessageText

local function editMessageCaption(chat_id, message_id, reply_markup, caption, cb, cmd)
  tdcli_function ({
    ID = "EditMessageCaption",
    chat_id_ = chat_id,
    message_id_ = message_id,
    reply_markup_ = reply_markup, -- reply_markup:ReplyMarkup
    caption_ = caption
  }, cb or dl_cb, cmd)
end

M.editMessageCaption = editMessageCaption

local function sendChatAction(chat_id, action, progress, cb, cmd)
  tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessage" .. action .. "Action",
      progress_ = progress or 100
    }
  }, cb or dl_cb, cmd)
end

M.sendChatAction = sendChatAction

local function openChat(chat_id, cb, cmd)
  tdcli_function ({
    ID = "OpenChat",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.openChat = openChat

local function closeChat(chat_id, cb, cmd)
  tdcli_function ({
    ID = "CloseChat",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.closeChat = closeChat

local function viewMessages(chat_id, message_ids, cb, cmd)
  tdcli_function ({
    ID = "ViewMessages",
    chat_id_ = chat_id,
    message_ids_ = message_ids -- vector
  }, cb or dl_cb, cmd)
end

M.viewMessages = viewMessages

local function openMessageContent(chat_id, message_id, cb, cmd)
  tdcli_function ({
    ID = "OpenMessageContent",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb or dl_cb, cmd)
end

M.openMessageContent = openMessageContent

local function createPrivateChat(user_id, cb, cmd)
  tdcli_function ({
    ID = "CreatePrivateChat",
    user_id_ = user_id
  }, cb or dl_cb, cmd)
end

M.createPrivateChat = createPrivateChat

local function createGroupChat(group_id, cb, cmd)
  tdcli_function ({
    ID = "CreateGroupChat",
    group_id_ = getChatId(group_id).ID
  }, cb or dl_cb, cmd)
end

M.createGroupChat = createGroupChat

local function createChannelChat(channel_id, cb, cmd)
  tdcli_function ({
    ID = "CreateChannelChat",
    channel_id_ = getChatId(channel_id).ID
  }, cb or dl_cb, cmd)
end

M.createChannelChat = createChannelChat

local function createNewGroupChat(user_ids, title, cb, cmd)
  tdcli_function ({
    ID = "CreateNewGroupChat",
    user_ids_ = user_ids, -- vector
    title_ = title
  }, cb or dl_cb, cmd)
end

M.createNewGroupChat = createNewGroupChat

local function createNewChannelChat(title, is_supergroup, about, cb, cmd)
  tdcli_function ({
    ID = "CreateNewChannelChat",
    title_ = title,
    is_supergroup_ = is_supergroup,
    about_ = about
  }, cb or dl_cb, cmd)
end

M.createNewChannelChat = createNewChannelChat

local function migrateGroupChatToChannelChat(chat_id, cb, cmd)
  tdcli_function ({
    ID = "MigrateGroupChatToChannelChat",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.migrateGroupChatToChannelChat = migrateGroupChatToChannelChat

local function changeChatTitle(chat_id, title, cb, cmd)
  tdcli_function ({
    ID = "ChangeChatTitle",
    chat_id_ = chat_id,
    title_ = title
  }, cb or dl_cb, cmd)
end

M.changeChatTitle = changeChatTitle

local function changeChatPhoto(chat_id, photo, cb, cmd)
  tdcli_function ({
    ID = "ChangeChatPhoto",
    chat_id_ = chat_id,
    photo_ = getInputFile(photo)
  }, cb or dl_cb, cmd)
end

M.changeChatPhoto = changeChatPhoto

local function changeChatDraftMessage(chat_id, reply_to_message_id, text, disable_web_page_preview, clear_draft, parse_mode, cb, cmd)
  local TextParseMode = getParseMode(parse_mode)

  tdcli_function ({
    ID = "ChangeChatDraftMessage",
    chat_id_ = chat_id,
    draft_message_ = {
      ID = "DraftMessage",
      reply_to_message_id_ = reply_to_message_id,
      input_message_text_ = {
        ID = "InputMessageText",
        text_ = text,
        disable_web_page_preview_ = disable_web_page_preview,
        clear_draft_ = clear_draft,
        entities_ = {},
        parse_mode_ = TextParseMode,
      },
    },
  }, cb or dl_cb, cmd)
end

M.changeChatDraftMessage = changeChatDraftMessage

local function addChatMember(chat_id, user_id, forward_limit, cb, cmd)
  tdcli_function ({
    ID = "AddChatMember",
    chat_id_ = chat_id,
    user_id_ = user_id,
    forward_limit_ = forward_limit or 50
  }, cb or dl_cb, cmd)
end

M.addChatMember = addChatMember

local function addChatMembers(chat_id, user_ids, cb, cmd)
  tdcli_function ({
    ID = "AddChatMembers",
    chat_id_ = chat_id,
    user_ids_ = user_ids -- vector
  }, cb or dl_cb, cmd)
end

M.addChatMembers = addChatMembers

local function changeChatMemberStatus(chat_id, user_id, status, cb, cmd)
  tdcli_function ({
    ID = "ChangeChatMemberStatus",
    chat_id_ = chat_id,
    user_id_ = user_id,
    status_ = {
      ID = "ChatMemberStatus" .. status
    },
  }, cb or dl_cb, cmd)
end

M.changeChatMemberStatus = changeChatMemberStatus

local function getChatMember(chat_id, user_id, cb, cmd)
  tdcli_function ({
    ID = "GetChatMember",
    chat_id_ = chat_id,
    user_id_ = user_id
  }, cb or dl_cb, cmd)
end

M.getChatMember = getChatMember

local function downloadFile(file_id, cb, cmd)
  tdcli_function ({
    ID = "DownloadFile",
    file_id_ = file_id
  }, cb or dl_cb, cmd)
end

M.downloadFile = downloadFile

local function cancelDownloadFile(file_id, cb, cmd)
  tdcli_function ({
    ID = "CancelDownloadFile",
    file_id_ = file_id
  }, cb or dl_cb, cmd)
end

M.cancelDownloadFile = cancelDownloadFile

local function exportChatInviteLink(chat_id, cb, cmd)
  tdcli_function ({
    ID = "ExportChatInviteLink",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.exportChatInviteLink = exportChatInviteLink

local function checkChatInviteLink(link, cb, cmd)
  tdcli_function ({
    ID = "CheckChatInviteLink",
    invite_link_ = link
  }, cb or dl_cb, cmd)
end

M.checkChatInviteLink = checkChatInviteLink

local function importChatInviteLink(invite_link, cb, cmd)
  tdcli_function ({
    ID = "ImportChatInviteLink",
    invite_link_ = invite_link
  }, cb or dl_cb, cmd)
end

M.importChatInviteLink = importChatInviteLink

local function blockUser(user_id, cb, cmd)
  tdcli_function ({
    ID = "BlockUser",
    user_id_ = user_id
  }, cb or dl_cb, cmd)
end

M.blockUser = blockUser

local function unblockUser(user_id, cb, cmd)
  tdcli_function ({
    ID = "UnblockUser",
    user_id_ = user_id
  }, cb or dl_cb, cmd)
end

M.unblockUser = unblockUser

local function getBlockedUsers(offset, limit, cb, cmd)
  tdcli_function ({
    ID = "GetBlockedUsers",
    offset_ = offset,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.getBlockedUsers = getBlockedUsers

local function importContacts(phone_number, first_name, last_name, user_id, cb, cmd)
  tdcli_function ({
    ID = "ImportContacts",
    contacts_ = {[0] = {
      phone_number_ = tostring(phone_number),
      first_name_ = tostring(first_name),
      last_name_ = tostring(last_name),
      user_id_ = user_id
      },
    },
  }, cb or dl_cb, cmd)
end

M.importContacts = importContacts

local function searchContacts(query, limit, cb, cmd)
  tdcli_function ({
    ID = "SearchContacts",
    query_ = query,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.searchContacts = searchContacts

local function deleteContacts(user_ids, cb, cmd)
  tdcli_function ({
    ID = "DeleteContacts",
    user_ids_ = user_ids -- vector
  }, cb or dl_cb, cmd)
end

M.deleteContacts = deleteContacts

local function getUserProfilePhotos(user_id, offset, limit, cb, cmd)
  tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = user_id,
    offset_ = offset,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.getUserProfilePhotos = getUserProfilePhotos

local function getStickers(emoji, cb, cmd)
  tdcli_function ({
    ID = "GetStickers",
    emoji_ = emoji
  }, cb or dl_cb, cmd)
end

M.getStickers = getStickers

local function getStickerSets(is_masks, cb, cmd)
  tdcli_function ({
    ID = "GetStickerSets",
    is_masks_ = is_masks
  }, cb or dl_cb, cmd)
end

M.getStickerSets = getStickerSets

local function getArchivedStickerSets(is_masks, offset_sticker_set_id, limit, cb, cmd)
  tdcli_function ({
    ID = "GetArchivedStickerSets",
    is_masks_ = is_masks,
    offset_sticker_set_id_ = offset_sticker_set_id,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.getArchivedStickerSets = getArchivedStickerSets

local function getTrendingStickerSets(dl_cb, cmd)
  tdcli_function ({
    ID = "GetTrendingStickerSets"
  }, cb or dl_cb, cmd)
end

M.getTrendingStickerSets = getTrendingStickerSets

local function getStickerSet(set_id, cb, cmd)
  tdcli_function ({
    ID = "GetStickerSet",
    set_id_ = set_id
  }, cb or dl_cb, cmd)
end

M.getStickerSet = getStickerSet

local function searchStickerSet(name, cb, cmd)
  tdcli_function ({
    ID = "SearchStickerSet",
    name_ = name
  }, cb or dl_cb, cmd)
end

M.searchStickerSet = searchStickerSet

local function updateStickerSet(set_id, is_installed, is_archived, cb, cmd)
  tdcli_function ({
    ID = "UpdateStickerSet",
    set_id_ = set_id,
    is_installed_ = is_installed,
    is_archived_ = is_archived
  }, cb or dl_cb, cmd)
end

M.updateStickerSet = updateStickerSet

local function viewTrendingStickerSets(sticker_set_ids, cb, cmd)
  tdcli_function ({
    ID = "ViewTrendingStickerSets",
    sticker_set_ids_ = sticker_set_ids -- vector
  }, cb or dl_cb, cmd)
end

M.viewTrendingStickerSets = viewTrendingStickerSets

local function getRecentStickers(is_attached, cb, cmd)
  tdcli_function ({
    ID = "GetRecentStickers",
    is_attached_ = is_attached
  }, cb or dl_cb, cmd)
end

M.getRecentStickers = getRecentStickers

local function addRecentSticker(is_attached, sticker, cb, cmd)
  tdcli_function ({
    ID = "AddRecentSticker",
    is_attached_ = is_attached,
    sticker_ = getInputFile(sticker)
  }, cb or dl_cb, cmd)
end

M.addRecentSticker = addRecentSticker

local function deleteRecentSticker(is_attached, sticker, cb, cmd)
  tdcli_function ({
    ID = "DeleteRecentSticker",
    is_attached_ = is_attached,
    sticker_ = getInputFile(sticker)
  }, cb or dl_cb, cmd)
end

M.deleteRecentSticker = deleteRecentSticker

local function clearRecentStickers(is_attached, cb, cmd)
  tdcli_function ({
    ID = "ClearRecentStickers",
    is_attached_ = is_attached
  }, cb or dl_cb, cmd)
end

M.clearRecentStickers = clearRecentStickers

local function getStickerEmojis(sticker, cb, cmd)
  tdcli_function ({
    ID = "GetStickerEmojis",
    sticker_ = getInputFile(sticker)
  }, cb or dl_cb, cmd)
end

M.getStickerEmojis = getStickerEmojis

local function getSavedAnimations(dl_cb, cmd)
  tdcli_function ({
    ID = "GetSavedAnimations",
  }, cb or dl_cb, cmd)
end

M.getSavedAnimations = getSavedAnimations

local function addSavedAnimation(animation, cb, cmd)
  tdcli_function ({
    ID = "AddSavedAnimation",
    animation_ = getInputFile(animation)
  }, cb or dl_cb, cmd)
end

M.addSavedAnimation = addSavedAnimation

local function deleteSavedAnimation(animation, cb, cmd)
  tdcli_function ({
    ID = "DeleteSavedAnimation",
    animation_ = getInputFile(animation)
  }, cb or dl_cb, cmd)
end

M.deleteSavedAnimation = deleteSavedAnimation

local function getRecentInlineBots(dl_cb, cmd)
  tdcli_function ({
    ID = "GetRecentInlineBots",
  }, cb or dl_cb, cmd)
end

M.getRecentInlineBots = getRecentInlineBots

local function getWebPagePreview(message_text, cb, cmd)
  tdcli_function ({
    ID = "GetWebPagePreview",
    message_text_ = message_text
  }, cb or dl_cb, cmd)
end

M.getWebPagePreview = getWebPagePreview

local function getNotificationSettings(scope, chat_id, cb, cmd)
  tdcli_function ({
    ID = "GetNotificationSettings",
    scope_ = {
      ID = 'NotificationSettingsFor' .. scope,
      chat_id_ = chat_id or nil
    },
  }, cb or dl_cb, cmd)
end

M.getNotificationSettings = getNotificationSettings

local function setNotificationSettings(scope, chat_id, mute_for, show_preview, cb, cmd)
  tdcli_function ({
    ID = "SetNotificationSettings",
    scope_ = {
      ID = 'NotificationSettingsFor' .. scope,
      chat_id_ = chat_id or nil
    },
    notification_settings_ = {
      ID = "NotificationSettings",
      mute_for_ = mute_for,
      sound_ = "default",
      show_preview_ = show_preview
    }
  }, cb or dl_cb, cmd)
end

M.setNotificationSettings = setNotificationSettings

local function resetAllNotificationSettings(dl_cb, cmd)
  tdcli_function ({
    ID = "ResetAllNotificationSettings"
  }, cb or dl_cb, cmd)
end

M.resetAllNotificationSettings = resetAllNotificationSettings

local function setProfilePhoto(photo_path, cb, cmd)
  tdcli_function ({
    ID = "SetProfilePhoto",
    photo_path_ = photo_path
  }, cb or dl_cb, cmd)
end

M.setProfilePhoto = setProfilePhoto

local function deleteProfilePhoto(profile_photo_id, cb, cmd)
  tdcli_function ({
    ID = "DeleteProfilePhoto",
    profile_photo_id_ = profile_photo_id
  }, cb or dl_cb, cmd)
end

M.deleteProfilePhoto = deleteProfilePhoto

local function changeName(first_name, last_name, cb, cmd)
  tdcli_function ({
    ID = "ChangeName",
    first_name_ = first_name,
    last_name_ = last_name
  }, cb or dl_cb, cmd)
end

M.changeName = changeName

local function changeAbout(about, cb, cmd)
  tdcli_function ({
    ID = "ChangeAbout",
    about_ = about
  }, cb or dl_cb, cmd)
end

M.changeAbout = changeAbout

local function changeUsername(username, cb, cmd)
  tdcli_function ({
    ID = "ChangeUsername",
    username_ = username
  }, cb or dl_cb, cmd)
end

M.changeUsername = changeUsername

local function changePhoneNumber(phone_number, allow_flash_call, is_current_phone_number, cb, cmd)
  tdcli_function ({
    ID = "ChangePhoneNumber",
    phone_number_ = phone_number,
    allow_flash_call_ = allow_flash_call,
    is_current_phone_number_ = is_current_phone_number
  }, cb or dl_cb, cmd)
end

M.changePhoneNumber = changePhoneNumber

local function resendChangePhoneNumberCode(dl_cb, cmd)
  tdcli_function ({
    ID = "ResendChangePhoneNumberCode",
  }, cb or dl_cb, cmd)
end

M.resendChangePhoneNumberCode = resendChangePhoneNumberCode

local function checkChangePhoneNumberCode(code, cb, cmd)
  tdcli_function ({
    ID = "CheckChangePhoneNumberCode",
    code_ = code
  }, cb or dl_cb, cmd)
end

M.checkChangePhoneNumberCode = checkChangePhoneNumberCode

local function getActiveSessions(dl_cb, cmd)
  tdcli_function ({
    ID = "GetActiveSessions",
  }, cb or dl_cb, cmd)
end

M.getActiveSessions = getActiveSessions

local function terminateSession(session_id, cb, cmd)
  tdcli_function ({
    ID = "TerminateSession",
    session_id_ = session_id
  }, cb or dl_cb, cmd)
end

M.terminateSession = terminateSession

local function terminateAllOtherSessions(dl_cb, cmd)
  tdcli_function ({
    ID = "TerminateAllOtherSessions",
  }, cb or dl_cb, cmd)
end

M.terminateAllOtherSessions = terminateAllOtherSessions

local function toggleGroupEditors(group_id, anyone_can_edit, cb, cmd)
  tdcli_function ({
    ID = "ToggleGroupEditors",
    group_id_ = getChatId(group_id).ID,
    anyone_can_edit_ = anyone_can_edit
  }, cb or dl_cb, cmd)
end

M.toggleGroupEditors = toggleGroupEditors

local function changeChannelUsername(channel_id, username, cb, cmd)
  tdcli_function ({
    ID = "ChangeChannelUsername",
    channel_id_ = getChatId(channel_id).ID,
    username_ = username
  }, cb or dl_cb, cmd)
end

M.changeChannelUsername = changeChannelUsername

local function toggleChannelInvites(channel_id, anyone_can_invite, cb, cmd)
  tdcli_function ({
    ID = "ToggleChannelInvites",
    channel_id_ = getChatId(channel_id).ID,
    anyone_can_invite_ = anyone_can_invite
  }, cb or dl_cb, cmd)
end

M.toggleChannelInvites = toggleChannelInvites

local function toggleChannelSignMessages(channel_id, sign_messages, cb, cmd)
  tdcli_function ({
    ID = "ToggleChannelSignMessages",
    channel_id_ = getChatId(channel_id).ID,
    sign_messages_ = sign_messages
  }, cb or dl_cb, cmd)
end

M.toggleChannelSignMessages = toggleChannelSignMessages

local function changeChannelAbout(channel_id, about, cb, cmd)
  tdcli_function ({
    ID = "ChangeChannelAbout",
    channel_id_ = getChatId(channel_id).ID,
    about_ = about
  }, cb or dl_cb, cmd)
end

M.changeChannelAbout = changeChannelAbout

local function pinChannelMessage(channel_id, message_id, disable_notification, cb, cmd)
  tdcli_function ({
    ID = "PinChannelMessage",
    channel_id_ = getChatId(channel_id).ID,
    message_id_ = message_id,
    disable_notification_ = disable_notification
  }, cb or dl_cb, cmd)
end

M.pinChannelMessage = pinChannelMessage

local function unpinChannelMessage(channel_id, cb, cmd)
  tdcli_function ({
    ID = "UnpinChannelMessage",
    channel_id_ = getChatId(channel_id).ID
  }, cb or dl_cb, cmd)
end

M.unpinChannelMessage = unpinChannelMessage

local function reportChannelSpam(channel_id, user_id, message_ids, cb, cmd)
  tdcli_function ({
    ID = "ReportChannelSpam",
    channel_id_ = getChatId(channel_id).ID,
    user_id_ = user_id,
    message_ids_ = message_ids -- vector
  }, cb or dl_cb, cmd)
end

M.reportChannelSpam = reportChannelSpam

local function getChannelMembers(channel_id, offset, filter, limit, cb, cmd)
  if not limit or limit > 200 then
    limit = 200
  end

  tdcli_function ({
    ID = "GetChannelMembers",
    channel_id_ = getChatId(channel_id).ID,
    filter_ = {
      ID = "ChannelMembers" .. filter
    },
    offset_ = offset,
    limit_ = limit
  }, cb or dl_cb, cmd)
end

M.getChannelMembers = getChannelMembers

local function deleteChannel(channel_id, cb, cmd)
  tdcli_function ({
    ID = "DeleteChannel",
    channel_id_ = getChatId(channel_id).ID
  }, cb or dl_cb, cmd)
end

M.deleteChannel = deleteChannel

local function getCreatedPublicChannels(dl_cb, cmd)
  tdcli_function ({
    ID = "GetCreatedPublicChannels"
  }, cb or dl_cb, cmd)
end

M.getCreatedPublicChannels = getCreatedPublicChannels

local function getSupportUser(dl_cb, cmd)
  tdcli_function ({
    ID = "GetSupportUser",
  }, cb or dl_cb, cmd)
end

M.getSupportUser = getSupportUser

local function getWallpapers(dl_cb, cmd)
  tdcli_function ({
    ID = "GetWallpapers",
  }, cb or dl_cb, cmd)
end

M.getWallpapers = getWallpapers

local function setPrivacy(key, rule, allowed_user_ids, disallowed_user_ids, cb, cmd)
  local rules = {[0] = {ID = 'PrivacyRule' .. rule}}

  if allowed_user_ids then
    rules = {
      {
        ID = 'PrivacyRule' .. rule
      },
      [0] = {
        ID = "PrivacyRuleAllowUsers",
        user_ids_ = allowed_user_ids -- vector
      },
    }
  end
  if disallowed_user_ids then
    rules = {
      {
        ID = 'PrivacyRule' .. rule
      },
      [0] = {
        ID = "PrivacyRuleDisallowUsers",
        user_ids_ = disallowed_user_ids -- vector
      },
    }
  end
  if allowed_user_ids and disallowed_user_ids then
    rules = {
      {
        ID = 'PrivacyRule' .. rule
      },
      {
        ID = "PrivacyRuleAllowUsers",
        user_ids_ = allowed_user_ids
      },
      [0] = {
        ID = "PrivacyRuleDisallowUsers",
        user_ids_ = disallowed_user_ids
      },
    }
  end
  tdcli_function ({
    ID = "SetPrivacy",
    key_ = {
      ID = 'PrivacyKey' .. key
    },
    rules_ = {
      ID = "PrivacyRules",
      rules_ = rules
    },
  }, cb or dl_cb, cmd)
end

M.setPrivacy = setPrivacy

local function getPrivacy(key, cb, cmd)
  tdcli_function ({
    ID = "GetPrivacy",
    key_ = {
      ID = "PrivacyKey" .. key
    },
  }, cb or dl_cb, cmd)
end

M.getPrivacy = getPrivacy

local function getOption(name, cb, cmd)
  tdcli_function ({
    ID = "GetOption",
    name_ = name
  }, cb or dl_cb, cmd)
end

M.getOption = getOption

local function setOption(name, option, value, cb, cmd)
  tdcli_function ({
    ID = "SetOption",
    name_ = name,
    value_ = {
      ID = 'Option' .. option,
      value_ = value
    },
  }, cb or dl_cb, cmd)
end

M.setOption = setOption

local function changeAccountTtl(days, cb, cmd)
  tdcli_function ({
    ID = "ChangeAccountTtl",
    ttl_ = {
      ID = "AccountTtl",
      days_ = days
    },
  }, cb or dl_cb, cmd)
end

M.changeAccountTtl = changeAccountTtl

local function getAccountTtl(dl_cb, cmd)
  tdcli_function ({
    ID = "GetAccountTtl",
  }, cb or dl_cb, cmd)
end

M.getAccountTtl = getAccountTtl

local function deleteAccount(reason, cb, cmd)
  tdcli_function ({
    ID = "DeleteAccount",
    reason_ = reason
  }, cb or dl_cb, cmd)
end

M.deleteAccount = deleteAccount

local function getChatReportSpamState(chat_id, cb, cmd)
  tdcli_function ({
    ID = "GetChatReportSpamState",
    chat_id_ = chat_id
  }, cb or dl_cb, cmd)
end

M.getChatReportSpamState = getChatReportSpamState

local function changeChatReportSpamState(chat_id, is_spam_chat, cb, cmd)
  tdcli_function ({
    ID = "ChangeChatReportSpamState",
    chat_id_ = chat_id,
    is_spam_chat_ = is_spam_chat
  }, cb or dl_cb, cmd)
end

M.changeChatReportSpamState = changeChatReportSpamState

local function setAlarm(seconds, cb, cmd)
  tdcli_function ({
    ID = "SetAlarm",
    seconds_ = seconds
  }, cb or dl_cb, cmd)
end

M.setAlarm = setAlarm

local function sendText(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, text, disable_web_page_preview, parse_mode, cb, cmd)
  local TextParseMode = getParseMode(parse_mode)
  local input_message_content = {
    ID = "InputMessageText",
    text_ = text,
    disable_web_page_preview_ = disable_web_page_preview,
    clear_draft_ = 0,
    entities_ = {},
    parse_mode_ = TextParseMode,
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendText = sendText

local function sendAnimation(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, animation, width, height, caption, cb, cmd)
  local input_message_content = {
    ID = "InputMessageAnimation",
    animation_ = getInputFile(animation),
    width_ = 0,
    height_ = 0,
    caption_ = caption
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendAnimation = sendAnimation

local function sendAudio(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, audio, duration, title, performer, caption, cb, cmd)
  local input_message_content = {
    ID = "InputMessageAudio",
    audio_ = getInputFile(audio),
    duration_ = duration or 0,
    title_ = title or 0,
    performer_ = performer,
    caption_ = caption
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendAudio = sendAudio

local function sendDocument(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, document, caption, cb, cmd)
  local input_message_content = {
    ID = "InputMessageDocument",
    document_ = getInputFile(document),
    caption_ = caption
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendDocument = sendDocument

local function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption, cb, cmd)
  local input_message_content = {
    ID = "InputMessagePhoto",
    photo_ = getInputFile(photo),
    added_sticker_file_ids_ = {},
    width_ = 0,
    height_ = 0,
    caption_ = caption
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendPhoto = sendPhoto

local function sendSticker(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, sticker, cb, cmd)
  local input_message_content = {
    ID = "InputMessageSticker",
    sticker_ = getInputFile(sticker),
    width_ = 0,
    height_ = 0
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendSticker = sendSticker

local function sendVideo(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, video, duration, width, height, caption, cb, cmd)
  local input_message_content = {
    ID = "InputMessageVideo",
    video_ = getInputFile(video),
    added_sticker_file_ids_ = {},
    duration_ = duration or 0,
    width_ = width or 0,
    height_ = height or 0,
    caption_ = caption
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendVideo = sendVideo

local function sendVoice(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, voice, duration, waveform, caption, cb, cmd)
  local input_message_content = {
    ID = "InputMessageVoice",
    voice_ = getInputFile(voice),
    duration_ = duration or 0,
    waveform_ = waveform,
    caption_ = caption
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendVoice = sendVoice

local function sendLocation(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, latitude, longitude, cb, cmd)
  local input_message_content = {
    ID = "InputMessageLocation",
    location_ = {
      ID = "Location",
      latitude_ = latitude,
      longitude_ = longitude
    },
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendLocation = sendLocation

local function sendVenue(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, latitude, longitude, title, address, id, cb, cmd)
  local input_message_content = {
    ID = "InputMessageVenue",
    venue_ = {
      ID = "Venue",
      location_ = {
        ID = "Location",
        latitude_ = latitude,
        longitude_ = longitude
      },
      title_ = title,
      address_ = address,
      provider_ = 'foursquare',
      id_ = id
    },
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendVenue = sendVenue

local function sendContact(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, phone_number, first_name, last_name, user_id, cb, cmd)
  local input_message_content = {
    ID = "InputMessageContact",
    contact_ = {
      ID = "Contact",
      phone_number_ = phone_number,
      first_name_ = first_name,
      last_name_ = last_name,
      user_id_ = user_id
    },
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendContact = sendContact

local function sendGame(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, bot_user_id, game_short_name, cb, cmd)
  local input_message_content = {
    ID = "InputMessageGame",
    bot_user_id_ = bot_user_id,
    game_short_name_ = game_short_name
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendGame = sendGame

local function sendForwarded(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, from_chat_id, message_id, cb, cmd)
  local input_message_content = {
    ID = "InputMessageForwarded",
    from_chat_id_ = from_chat_id,
    message_id_ = message_id,
    in_game_share_ = in_game_share
  }
  sendRequest('SendMessage', chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, input_message_content, cb, cmd)
end

M.sendForwarded = sendForwarded

local function kickUser(chat_id, user_id, block, cb, cmd)
  local gid = tostring(chat_id)
  local block = block or true

  changeChatMemberStatus(chat_id, user_id, 'Kicked', cb, cmd)

  if gid:match('^-100') and not block then
    unblockUser(user_id)
  end
end

M.kickUser = kickUser

return M
