----------------------------------------------------------------------------------
--
-- SimpleComm.lua
--
-- Author: Zarkan@Ner'zhul-EU, Fkaï@Ner'zhul-EU, Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------
SimpleComm = {}

SIMPLECOMM_CHARACTERSPERTICK_MAX = 255;	-- char per tick
SIMPLECOMM_OUTBOUND_TICK_DELAY = 1.2;	-- delay in second between tick

SIMPLECOMM_INBOUND_TICK_DELAY = 0.125;	-- TODO : change from 0.125 to 0.5 according to FPS

local PIPE_ENTITIE = "\127p";

SimpleComm_DisconnectedMessage = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "(.*)");
SimpleComm_AmbiguousMessage = string.format(ERR_CHAT_PLAYER_AMBIGUOUS_S, "(.*)");
SimpleComm_AFK_MESSAGE = string.format(MARKED_AFK_MESSAGE, "(.*)");
SimpleComm_DND_MESSAGE = string.format(MARKED_DND, "(.*)");

SimpleComm_oldSendChatMessage = nil;

local frame

local firstJoin = true

-- dataChannelLib --------------------------------------------
local dataChannelLib = DataChannelLib:GetInstance("1");

-- about the channel --------------------------------------------
local currentChannel = {
	-- name
	-- password
	-- id
	-- slashCmd
	-- slashCmdUpper
	-- aliasName
	-- isChatMessageVisible
	-- onMessage
	-- onJoin
	-- onLeave
	-- onStatusChange
	-- onChatFlagChange
	maxMessageLength = 0,
	prefix = "",
	drunkTemplate = { "\t", "", "\029" },
	chatStatus = "Starting",
	chatStatusMessage = "",
	disconnected = {},
	messageStack = {},
	inboundQueue = {},
	outboundQueueHeader = { who=false, length=32768 },
	extraBytes = 0,
	aliasMustBeSet = false,
	stats = {
		totalSentMessages = 0,
		totalSentBytes = 0,
		totalReceivedMessages = 0,
		totalReceivedBytes = 0,
	}
}
currentChannel.outboundQueueLast = currentChannel.outboundQueueHeader
	-- .delay
	-- .to
	-- .text
	-- .length
	-- .next

SimpleComm.currentChannel = currentChannel

-- about the player --------------------------------------------
local player = {
	-- chatFlag
	-- chatFlagText
}
SimpleComm.player = player

--------------------------------------------------
local _G = _G

local string_char = _G.string.char
local math_min = _G.math.min
local table_concat = _G.table.concat
local type = _G.type
local unpack = _G.unpack
local ipairs = _G.ipairs
local pairs = _G.pairs
local next = _G.next
local select = _G.select
local UnitName = _G.UnitName
local setmetatable = _G.setmetatable
local GetTime = _G.GetTime
local tostring = _G.tostring
local tonumber = _G.tonumber
local error = _G.error
local pcall = _G.pcall
local GetCVar = _G.GetCVar
local SetCVar = _G.SetCVar

---------------------------------------------------------------------------------
--
-- new/del/deep
-- 
---------------------------------------------------------------------------------
local new, del, deepDel
do
	local list = setmetatable({},{__mode='k'})
	function new(...)
		local t = next(list)
		if t then
			list[t] = nil
			for i = 1, select('#', ...) do
				t[i] = select(i, ...)
			end
			return t
		else
			return {...}
		end
	end
	function del(t)
		for k in pairs(t) do
			t[k] = nil
		end
		t[''] = true
		t[''] = nil
		list[t] = true
		return nil
	end
	function deepDel(t)
		for k,v in pairs(t) do
			if type(v) == "table" then
				deepDel(v)
			end
			t[k] = nil
		end
		t[''] = true
		t[''] = nil
		list[t] = true
		return nil
	end
end

---------------------------------------------------------------------------------
--
-- Alias
-- 
---------------------------------------------------------------------------------

local function dummy()
end

local function setAliasChannel()
	if not currentChannel.name then
		return;
	end
	local id = GetChannelName( currentChannel.name );
	if (id~=0 and currentChannel.aliasMustBeSet) then
		ChatTypeInfo[currentChannel.slashCmdUpper] = ChatTypeInfo["CHANNEL"..id];
		ChatTypeInfo[currentChannel.slashCmdUpper].sticky = 1;
		
		setglobal("CHAT_MSG_"..currentChannel.slashCmdUpper, currentChannel.aliasName);
		setglobal("CHAT_"..currentChannel.slashCmdUpper.."_GET", "["..currentChannel.aliasName.."] %s:\32");
		setglobal("CHAT_"..currentChannel.slashCmdUpper.."_SEND", currentChannel.aliasName..":\32");
		
		SlashCmdList[currentChannel.slashCmdUpper] = dummy;
		setglobal("SLASH_"..currentChannel.slashCmdUpper.."1", "/"..currentChannel.slashCmd);
		
		-- hook only one time
		if (not SimpleComm_oldSendChatMessage) then
			SimpleComm_oldSendChatMessage = SendChatMessage;
			SendChatMessage = SimpleComm_newSendChatMessage;
		end
		currentChannel.aliasMustBeSet = false;
	end
end

local function unsetAliasChannel()
	if (currentChannel.slashCmdUpper) then
		
		if ( DEFAULT_CHAT_FRAME.editBox.stickyType == string.upper(currentChannel.slashCmdUpper) ) then
			DEFAULT_CHAT_FRAME.editBox.chatType = "SAY"
			DEFAULT_CHAT_FRAME.editBox.stickyType = "SAY"
		end
		
		setglobal("CHAT_MSG_"..currentChannel.slashCmdUpper, nil);
		setglobal("CHAT_"..currentChannel.slashCmdUpper.."_GET", nil);
		setglobal("CHAT_"..currentChannel.slashCmdUpper.."_SEND", nil);
		
		SlashCmdList[currentChannel.slashCmdUpper] = nil;
		setglobal("SLASH_"..currentChannel.slashCmdUpper.."1", nil);
		
		currentChannel.aliasMustBeSet = true;
	end
end

function SimpleComm_newSendChatMessage(msg, sys, lang, name)
	if (sys == currentChannel.slashCmdUpper) then
		return SimpleComm_oldSendChatMessage(string.gsub(msg, "|", PIPE_ENTITIE), "CHANNEL", lang, GetChannelName( currentChannel.name ));
	else
		return SimpleComm_oldSendChatMessage(msg, sys, lang, name);
	end
end

---------------------------------------------------------------------------------
--
-- AFK/DND status
-- 
---------------------------------------------------------------------------------
local function setFlag(flag, message)
	player.chatFlag = flag
	player.chatFlagText = message
	currentChannel.onChatFlagChange(flag, message);
end

function SimpleComm_GetFlag()
	return player.chatFlag, player.chatFlagText;
end

---------------------------------------------------------------------------------
--
-- Encode / Decode
-- 
---------------------------------------------------------------------------------
local Encode
do
	local drunkHelper_t = {
		[7]  = "\029\008",
		[29] = "\029\030",
		[31] = "\029\032",
		[20] = "\029\021",
		[15] = "\029\016",
		[("S"):byte()] = "\020", -- change S and s to a different set of character bytes.
		[("s"):byte()] = "\015",
		[127] = "\029\126", -- \127 (this is here because \000 is more common)
		[0] = "\127", -- \000
		[10] = "\029\011", -- \n
		[124] = "\029\125", -- |
		[("%"):byte()] = "\029\038", -- %
	}
	for c = 128, 255 do
		local num = c
		num = num - 127
		if num >= 7 then
			num = num + 1
		end
		if num >= 9 then
			num = num + 2
		end
		if num >= 15 then
			num = num + 1
		end
		if num >= 20 then
			num = num + 1
		end
		if num >= 29 then
			num = num + 2
		end
		if num >= 83 then
			num = num + 1
		end
		if num >= 115 then
			num = num + 1
		end
		if num >= 124 then
			num = num + 1
		end
		if num >= 127 then
			drunkHelper_t[c] = string_char(29, num - 127 + 40) --41, 42, 43, 44, 45
		else
			drunkHelper_t[c] = string_char(31, num)
		end
	end
	local function drunkHelper(char)
		return drunkHelper_t[char:byte()]
	end
	local soberHelper_t = {
		[7] = "\176\008",
		[176] = "\176\177",
		[255] = "\176\254", -- \255 (this is here because \000 is more common)
		[0] = "\255", -- \000
		[10] = "\176\011", -- \n
		[124] = "\176\125", -- |
		[("%"):byte()] = "\176\038", -- %
	}
	local function soberHelper(char)
		return soberHelper_t[char:byte()]
	end
	-- Package a message for transmission
	function Encode(text, drunk)
		if drunk then
			return text:gsub("([\007\010\015\020\029%%\031Ss\124\127-\255])", drunkHelper)
		else
			if not text then
				DEFAULT_CHAT_FRAME:AddMessage(debugstack())
			end
			return text:gsub("([\007\176\255%z\010\124%%])", soberHelper)
		end
	end
	
	local function EncodeBytes_helper(drunk, ...)
		local n = select('#', ...)
		if n == 0 then
			return
		end
		local t
		if drunk then
			t = drunkHelper_t
		else
			t = soberHelper_t
		end
		local num = (...)
		local value = t[num]
		if not value then
			return num, EncodeBytes_helper(drunk, select(2, ...))
		else
			local len = #value
			if len == 1 then
				return value:byte(1), EncodeBytes_helper(drunk, select(2, ...))
			else -- 2
				local a, b = value:byte(1, 2)
				return a, b, EncodeBytes_helper(drunk, select(2, ...))
			end
		end
	end
	function EncodeBytes(drunk, ...)
		return string_char(EncodeBytes_helper(drunk, ...))
	end
end

local Decode
do
	local t = {
		["\008"] = "\007",
		["\177"] = "\176",
		["\254"] = "\255",
		["\011"] = "\010",
		["\125"] = "\124",
		["\038"] = "\037",
	}
	local function soberHelper(text)
		return t[text]
	end
	
	local t = {
		["\127"] = "\000",
		["\015"] = "s",
		["\020"] = "S",
	}
	local function drunkHelper1(text)
		return t[text]
	end
	
	local t = setmetatable({}, {__index=function(self, c)
		local num = c:byte()
		if num >= 124 then
			num = num - 1
		end
		if num >= 115 then
			num = num - 1
		end
		if num >= 83 then
			num = num - 1
		end
		if num >= 29 then
			num = num - 2
		end
		if num >= 20 then
			num = num - 1
		end
		if num >= 15 then
			num = num - 1
		end
		if num >= 9 then
			num = num - 2
		end
		if num >= 7 then
			num = num - 1
		end
		num = num + 127 
		self[c] = string_char(num)
		return self[c]
	end})
	local function drunkHelper2(text)
		return t[text]
	end

	local t = {
		["\008"] = "\007",
		["\038"] = "%",
		["\125"] = "\124",
		["\011"] = "\010",
		["\126"] = "\127",
		["\016"] = "\015",
		["\021"] = "\020",
		["\040"] = "\244",
		["\041"] = "\245",
		["\042"] = "\246",
		["\043"] = "\247",
		["\044"] = "\248",
		["\045"] = "\249",
		["\046"] = "\250",
		["\047"] = "\251",
		["\048"] = "\252",
		["\049"] = "\253",
		["\050"] = "\254",
		["\051"] = "\255",
		["\032"] = "\031",
		["\030"] = "\029",
	}
	local function drunkHelper3(text)
		return t[text]
	end
	
	-- Clean a received message
	function Decode(text, drunk)
		if drunk then
			text = text:gsub("([\127\015\020])", drunkHelper1)
			text = text:gsub("\031(.)", drunkHelper2)
			text = text:gsub("\029([\008\038\125\011\126\016\021\040\041\042\043\044\045\046\047\048\049\050\051\032\030])", drunkHelper3)
		else
			text = text:gsub("\255", "\000")
		
			text = text:gsub("\176([\008\177\254\011\125\038])", soberHelper)
		end
		-- remove the hidden character and refix the prohibited characters.
		return text
	end
end

---------------------------------------------------------------------------------
--
-- Packed message
--
---------------------------------------------------------------------------------
local PACK_SEPARATOR = "\007"
local REGEX_UNPACK_ITERATOR = "(.[^\007]+)"
assert(PACK_SEPARATOR:len() == 1, "GUILDADS_MSG_PACK_SEPARATOR:()len > 1")

local function packMessages(messages)
	return table.concat(messages, PACK_SEPARATOR);
end

local function unpackIterator(text, start)
	local s, e = string.find(text, REGEX_UNPACK_ITERATOR, start or 1);
	if s and e then
		return e+2, text:sub(s, e); -- +1 = \007, +2 : next message
	end
end

local function unpackMessagesIterator(text)
	return unpackIterator, text;
end

---------------------------------------------------------------------------------
--
-- Splited message
--
---------------------------------------------------------------------------------
local REGEX_UNSPLIT = "^\007([0-9]+)([\.|\:])(.*)";

local function splitSerialize(packetNumber, last, obj)
	if last then
		return "\007".. packetNumber ..":".. obj;
	else
		return "\007".. packetNumber ..".".. obj;
	end
end

local function unsplitSerialize(str)
	local iStart, _ , packetNumber, last, packet = string.find(str, REGEX_UNSPLIT);
	if iStart then
		return packet, tonumber(packetNumber), last==":";
	end
	return str;
end

---------------------------------------------------------------------------------
--
-- Send
-- 
---------------------------------------------------------------------------------
local function sendQueue()
	local clearAFK = GetCVar("autoClearAFK");
	SetCVar("autoClearAFK", 0);
	-- GetLanguageByIndex(1), GetDefaultLanguage()
	
	local sentBytes = 0;
	
	currentChannel.id = GetChannelName(currentChannel.name);
	
	local previousMessage = currentChannel.outboundQueueHeader;
	local message = currentChannel.outboundQueueHeader.next;
	if not message then
		currentChannel.extraBytes=0;
	end
	local num_messages = 0;
	while message do
		
		-- check chat traffic
		if (sentBytes+currentChannel.extraBytes) > SIMPLECOMM_CHARACTERSPERTICK_MAX or num_messages>0 then
			previousMessage = currentChannel.outboundQueueLast;
			break;
		end
		
		-- is it a packed message ?
		local text 
		if message.text then
			text = message.text
		else
			text = packMessages(message)
		end
		
		-- send message
		if message.to then
			if not currentChannel.disconnected[message.to] then
				-- GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "Sending to "..message.to..": "..message.text..")");
				assert(text:len() + currentChannel.prefix:len() + 1<=255, "Too long addon message");
				SendAddonMessage(currentChannel.prefix, text, "WHISPER", message.to);
				sentBytes = sentBytes + string.len(text);
				num_messages = num_messages + 1
			end
		else
			currentChannel.drunkTemplate[2] = text
			text = table_concat(currentChannel.drunkTemplate)
			-- GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "Send to the channel: %s", text);
			assert(text:len()<=255, "Too long chat message");
			SendChatMessage(text, "CHANNEL", nil, currentChannel.id);
			sentBytes = sentBytes + string.len(text);
			num_messages = num_messages + 1
		end
		
		-- delete current message in queue
		previousMessage.next = message.next;
		
		-- go to next message (previousMessage keeps the same value)
		message = message.next
	end
	
	currentChannel.extraBytes = currentChannel.extraBytes + sentBytes - SIMPLECOMM_CHARACTERSPERTICK_MAX;
	
	currentChannel.outboundQueueLast = previousMessage;
	
	SetCVar("autoClearAFK", clearAFK);
	if (sentBytes> 0) then
		GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH, "%i bytes sent", sentBytes)
		currentChannel.stats.totalSentBytes = currentChannel.stats.totalSentBytes + sentBytes
		currentChannel.stats.totalSentMessages = currentChannel.stats.totalSentMessages + num_messages
	end
end

---------------------------------------------------------------------------------
--
-- Received message
-- 
---------------------------------------------------------------------------------
local function unqueueMessage()
	if currentChannel.inboundQueue[1] then
		local message = currentChannel.inboundQueue[1];
		table.remove(currentChannel.inboundQueue, 1);
		currentChannel.onMessage(message[1], message[2], message[3]);
		del(message)
		if currentChannel.inboundQueue[1] == nil then
			GuildAdsTask:DeleteNamedSchedule("SimpleCommUnqueueMessage")
		end
	end
end

local function parseOneMessage(author, text, channel, drunk)
	-- decode the message
	text = Decode(text, drunk)

	-- is it a fragmented message ?
	local packets = nil;
	local packet, packetNumber, last = unsplitSerialize(text);

	if packetNumber then
		-- fragmented message
		local id = author.."@"..(channel or "Whisper");
		local newText;
		
		-- set newText if this is a valid packet
		if packetNumber == 1 then
			newText = packet;
		elseif currentChannel.messageStack[id] then
			if currentChannel.messageStack[id].number+1 == packetNumber then
				newText = currentChannel.messageStack[id].text .. packet;
			end
		end
		
		-- update packet and currentChannel.messageStack
		if newText then
			if last then
				currentChannel.messageStack[id] = nil;
				packet = newText;
			else
				currentChannel.messageStack[id] = {
					text = newText;
					number = packetNumber;
				};
				packet = nil;
			end
		else
			currentChannel.messageStack[id] = nil;
			packet = nil;
		end
	end
	
	-- unserialize message from the packet.
	if packet then
		tinsert(currentChannel.inboundQueue, new(author, packet, channel))
		if not GuildAdsTask:NamedScheduleCheck("SimpleCommUnqueueMessage") then
			GuildAdsTask:AddNamedSchedule("SimpleCommUnqueueMessage", SIMPLECOMM_INBOUND_TICK_DELAY, true, nil, unqueueMessage)
		end
	end
end

local function parseMessage(author, text, channel, drunk)
	for _, onePacket in unpackMessagesIterator(text) do
		parseOneMessage(author, onePacket, channel, drunk)
	end
end

local function onEvent(this, event)
	if currentChannel.name then
		currentChannel.id = GetChannelName(currentChannel.name);
		
		-- event=CHAT_MSG_CHANNEL; arg1=chat message; arg2=author; arg3=language; arg4=channel name with number; arg8=channel number; arg9=channel name without number
		if (event == "CHAT_MSG_CHANNEL") and (arg8 == currentChannel.id) then
			currentChannel.disconnected[arg2] = nil;
			-- get rid of prefix and " ...hic!"
			local message, match = arg1:gsub("^"..currentChannel.prefix.."\t(.*)\029.-$", "%1")
			if match==1 then
				-- it's match : parse the message
				parseMessage(arg2, message, arg9, true)
				currentChannel.stats.totalReceivedBytes = currentChannel.stats.totalReceivedBytes + arg1:len()
				currentChannel.stats.totalReceivedMessages = currentChannel.stats.totalReceivedMessages + 1
			end
		elseif (event == "CHAT_MSG_ADDON") and (arg1==currentChannel.prefix) and (arg3=="WHISPER") then
			currentChannel.disconnected[arg4] = nil
			parseMessage(arg4, arg2, nil, false)
			currentChannel.stats.totalReceivedBytes = currentChannel.stats.totalReceivedBytes + arg2:len()
			currentChannel.stats.totalReceivedMessages = currentChannel.stats.totalReceivedMessages + 1
		end
		
	end
end

function SimpleComm_New_ChatFrame_MessageEventHandler(event)
	if (currentChannel.name) then
		currentChannel.id = GetChannelName(currentChannel.name);
		if ((event == "CHAT_MSG_CHANNEL") and (arg8 == currentChannel.id)) then
			-- Hide if this is an internal message
			if currentChannel.isChatMessageVisible(arg1) then
				return;
			end
			
			-- the message is shown in this ChatFrame ?
			local info;
			local found = 0;
			local channelLength = strlen(arg4);
			for index, value in pairs(this.channelList) do
				if ( channelLength > strlen(value) ) then
					-- arg9 is the channel name without the number in front...
					if ( ((arg7 > 0) and (this.zoneChannelList[index] == arg7)) or (strupper(value) == strupper(arg9)) ) then
						found = 1;
						info = ChatTypeInfo["CHANNEL"..arg8];
						break;
					end
				end
			end
			if (found==0) or not info then
				return;
			end
			
			-- unpack PIPE_ENTITIE
			arg1 = string.gsub(arg1, PIPE_ENTITIE, "|")
			
			-- Hack to change the channel name :
			-- ChatFrame_OnEvent shows "["..gsub(arg4, "%s%-%s.*", "").."] "..body
			-- channelLength = strlen(arg4) is used to find if the channel is shown in this ChatFrame (as above)
			-- -> arg4 is set to name we want to show concatenate with " -" and many spaces which will delete by the gsub call
			if (currentChannel.slashCmdUpper) then
				arg4 = currentChannel.aliasName.." -                                ";
			end
		end
		
		if (event == "CHAT_MSG_CHANNEL_JOIN") and (arg8 == currentChannel.id) then
			currentChannel.disconnected[arg2] = nil;
			return;
		end
		
		if (event == "CHAT_MSG_CHANNEL_LEAVE") and (arg8 == currentChannel.id) then
			-- to avoid bug #1315237 : guess that player is offline if he isn't on the channel
			currentChannel.disconnected[arg2] = time();
			return;
		end
		
		if (event == "CHAT_MSG_CHANNEL_NOTICE") and (arg8 == currentChannel.id) then
			GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH,  arg1);
			return;
		end
		
		if (event == "CHAT_MSG_CHANNEL_NOTICE_USER") and (arg8 == currentChannel.id) then
			GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH,  "%s (%s)", arg1, arg5);
			return;
		end
		
	else
		if event=="CHAT_MSG_CHANNEL" then
			if currentChannel.isChatMessageVisible and currentChannel.isChatMessageVisible(arg1) then
				return;
			end
		end
	end
	
	-- update DND/AFK/Drunk status
	if (event == "CHAT_MSG_SYSTEM") then
		local _, _, playerName = string.find(arg1, SimpleComm_DisconnectedMessage);
		if not playerName then
			local _, _, playerName = string.find(arg1, SimpleComm_AmbiguousMessage);
		end
		if playerName then
			local t = GetTime();
			if currentChannel.disconnected[playerName] then
				if t-currentChannel.disconnected[playerName] < 2 then 
					return;
				end
			else
				currentChannel.disconnected[playerName] = t;
			end
		end
		
		-- update my AFK/DND status
		local iStart, iEnd, message = string.find(arg1, SimpleComm_AFK_MESSAGE);
		if iStart or arg1==MARKED_AFK then 
			setFlag("AFK", message);
		end
		
		local iStart, iEnd, message = string.find(arg1, SimpleComm_DND_MESSAGE);
		if iStart then
			setFlag("DND", message);
		end
		
		if arg1==CLEARED_AFK or arg1==CLEARED_DND then
			setFlag(nil, nil);
		end
	end
	
	-- call the default ChatFrame_OnEvent
	SimpleComm_Old_ChatFrame_MessageEventHandler(event);
end
SimpleComm_Old_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
ChatFrame_MessageEventHandler = SimpleComm_New_ChatFrame_MessageEventHandler;

---------------------------------------------------------------------------------
--
-- DataChannelLib callback
-- 
---------------------------------------------------------------------------------
local function SimpleComm_Callback(event, channelName, a1)
	if event==dataChannelLib.YOU_JOINED then
		if (currentChannel.slashCmd) then
			setAliasChannel();
		end
		if (currentChannel.onJoin) then
			currentChannel.onJoin()
		end
		GuildAdsTask:AddNamedSchedule("SimpleCommSendQueue", SIMPLECOMM_OUTBOUND_TICK_DELAY, true, nil, sendQueue)
		
		currentChannel.id = a1;
		SimpleComm_SetChannelStatus("Connected");
	elseif event==dataChannelLib.YOU_LEFT then
		if (currentChannel.slashCmd) then
			unsetAliasChannel();
		end
		if (currentChannel.onLeave) then
			currentChannel.onLeave()
		end
		SimpleComm_SetChannelStatus("Disconnected");
	elseif event==dataChannelLib.TOO_MANY_CHANNELS then
		SimpleComm_SetChannelStatus("Error", GUILDADS_ERROR_TOOMANYCHANNELS)
	elseif event==dataChannelLib.WRONG_NAME then
		SimpleComm_SetChannelStatus("Error", GUILDADS_ERROR_JOINCHANNELFAILED)
	elseif event==dataChannelLib.WRONG_PASSWORD then
		SimpleComm_SetChannelStatus("Error", GUILDADS_ERROR_WRONGPASSWORD)
	elseif event==dataChannelLib.PASSWORD_CHANGED then
		currentChannel.password = a1;
	end
end

---------------------------------------------------------------------------------
--
-- Public functions
-- 
---------------------------------------------------------------------------------
function SimpleComm_SendMessage(who, text)
	if not(who and currentChannel.disconnected[who]) then
		local queueLast = currentChannel.outboundQueueLast
		text = Encode(text, who==nil)
		local textLength = text:len()
		if (textLength + queueLast.length + 1 <= currentChannel.maxMessageLength and queueLast.to == who) then
			if queueLast.text then
				table.insert(queueLast, queueLast.text);
				queueLast.text=nil;
			end
			-- pack message with the previous one
			table.insert(queueLast, text)
			queueLast.length = queueLast.length + textLength + 1
		elseif textLength<= currentChannel.maxMessageLength then
			-- normal message
			currentChannel.outboundQueueLast.next = {
				to=who, 
				text=text,
				length=textLength
			};
			currentChannel.outboundQueueLast = currentChannel.outboundQueueLast.next;
		else
			-- split the message into smaller one.
			local packetNumber = 1;
			while text~="" do
				-- take the first characters
				local tmp = string.sub(text, 1, currentChannel.maxMessageLength);
				text = string.sub(text, currentChannel.maxMessageLength+1);
				tmp = splitSerialize(packetNumber, text=="", tmp)
				-- add a packet
				currentChannel.outboundQueueLast.next = {
					to = who;
					text = tmp;
					length = tmp:len();
				};
				currentChannel.outboundQueueLast = currentChannel.outboundQueueLast.next;
				-- next packet
				packetNumber = packetNumber + 1;
			end
		end
	end
end

function SimpleComm_SetChannelStatus(status, message)
	currentChannel.chatStatus = status;
	currentChannel.chatStatusMessage = message;
	if currentChannel.onStatusChange then
		currentChannel.onStatusChange(currentChannel.chatStatus, currentChannel.chatStatusMessage)
	end
end

function SimpleComm_GetChannelStatus()
	return currentChannel.chatStatus, currentChannel.chatStatusMessage;
end

function SimpleComm_Initialize(
					Prefix,
					FilterText,
					OnJoin, OnLeave, OnMessage, 
					FlagListener, StatusListener)
	SetCVar("spamFilter", 0)
	
	currentChannel.prefix = Prefix
	currentChannel.drunkTemplate[1] = Prefix.."\t"
	--[[
		1 "\t" 
		1 "\029"
		3 for split message
	]]
	currentChannel.maxMessageLength = 254-currentChannel.prefix:len()-5
	
	currentChannel.isChatMessageVisible = FilterText
	currentChannel.onMessage = OnMessage
	currentChannel.onJoin = OnJoin
	currentChannel.onLeave = OnLeave
	currentChannel.onStatusChange = StatusListener
	currentChannel.onChatFlagChange = FlagListener
	
	-- AFK/DND test for myself (usefull when the UI was reloaded)
	if SimpleComm_GetFlag(UnitName("player"))==nil then
		if UnitIsAFK("player") then
			setFlag("AFK", "")
		end
		if UnitIsDND("player") then
			setFlag("DND", "")
		end
	end
	
	dataChannelLib:RegisterAddon("GuildAds", SimpleComm_Callback)
	SimpleComm_SetChannelStatus("Initializing")
end

function SimpleComm_Join(Channel, Password)
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_Join] begin");
	
	-- some sanity check
	local typePassword = type(Password);
	if not ( type(Channel) == "string" and (typePassword == "string" or typePassword == "nil") ) then
		GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH,  "Can't join channel (%s,%s)", tostring(Channel), tostring(Password));
		error("SimpleComm_Join([channelName], [channelPassword])", 2);
	end
	
	-- Init Channel
	currentChannel.name = Channel;
	currentChannel.password = Password;
	
	local result = dataChannelLib:OpenChannel("GuildAds", currentChannel.name, currentChannel.password, DEFAULT_CHAT_FRAME);
	
	if firstJoin then
		firstJoin = nil;
		-- Set timer
		frame:Show();
	end
	
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_Join] end");
	
	return result;
end

function SimpleComm_Leave()
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_Leave] begin");
	-- leave channel
	GuildAdsTask:DeleteNamedSchedule("SimpleCommSendQueue")
	GuildAdsTask:DeleteNamedSchedule("SimpleCommUnqueueMessage")
	
	dataChannelLib:CloseChannel("GuildAds", currentChannel.name);
	
	-- set channel
	currentChannel.name = nil;
	currentChannel.password = nil;
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_Leave] end");
end

function SimpleComm_SetAlias(chanSlashCmd, chanAlias)
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_SetAlias] begin");
	-- unset previous alias
	if (currentChannel.slashCmd) then
		unsetAliasChannel();
	end
	
	-- set alias
	currentChannel.slashCmd = chanSlashCmd;
	currentChannel.slashCmdUpper = string.upper(chanSlashCmd);
	currentChannel.aliasName = chanAlias;

	currentChannel.aliasMustBeSet = true;
	setAliasChannel();
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_SetAlias] end");
end

function SimpleComm_GetStats()
	return currentChannel.stats.totalSentMessages, currentChannel.stats.totalSentBytes, currentChannel.stats.totalReceivedMessages, currentChannel.stats.totalReceivedBytes
end

---------------------------------------------------------------------------------
--
-- On load
-- 
---------------------------------------------------------------------------------
local function onLoad()
	frame = CreateFrame("Frame", nil, UIParent)
	frame:SetScript("OnEvent", onEvent)
	frame:RegisterEvent("CHAT_MSG_ADDON")
	frame:RegisterEvent("CHAT_MSG_CHANNEL")
end

onLoad()
