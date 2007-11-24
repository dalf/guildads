----------------------------------------------------------------------------------
--
-- SimpleComm.lua
--
-- Author: Zarkan@Ner'zhul-EU, Fkaï@Ner'zhul-EU, Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

SIMPLECOMM_CHARACTERSPERTICK_MAX = 239;		-- char per tick
SIMPLECOMM_OUTBOUND_TICK_DELAY = 1.2;		-- delay in second between tick

SIMPLECOMM_INBOUND_TICK_DELAY = 0.125;	-- TODO : change from 0.125 to 0.5 according to FPS

local PIPE_ENTITIE = "\127p";

SimpleComm_Channel = nil;
SimpleComm_Password = nil;
SimpleComm_ChatFrame = nil;

SimpleComm_JoinHandler = nil;
SimpleComm_LeaveHandler = nil;

local SimpleComm_FirstJoin = true;
SimpleComm_aliasMustBeSet = false;

local SimpleComm_Handler
local SimpleComm_FilterText

local SimpleComm_Status = "Starting";
local SimpleComm_StatusMessage;

local SimpleComm_oldChatFrame_OnEvent;

SimpleComm_oldSendChatMessage = nil;
local SimpleComm_chanSlashCmd;
local SimpleComm_chanSlashCmdUpper;

local SimpleComm_FlagListener;

local SimpleComm_messageQueueHeader = { who=false, length=32768 };
local SimpleComm_messageQueueLast = SimpleComm_messageQueueHeader;
	-- .delay
	-- .to
	-- .text
	-- .length
	-- .next
	
local SimpleComm_inboundMessageQueue = {};
local SimpleComm_extraBytes = 0;
local SimpleComm_channelId;
SimpleComm_YouAreDrunk = false;

SimpleComm_DisconnectedMessage = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "(.*)");
SimpleComm_AmbiguousMessage = string.format(ERR_CHAT_PLAYER_AMBIGUOUS_S, "(.*)");
SimpleComm_AFK_MESSAGE = string.format(MARKED_AFK_MESSAGE, "(.*)");
SimpleComm_DND_MESSAGE = string.format(MARKED_DND, "(.*)");

SimpleComm_Flags = nil;
SimpleComm_FlagsText  =nil;
SimpleComm_Disconnected = {};

local SimpleComm_messageStack = {};

local SimpleCommFrame

local maxMessageLength = 0
local SimpleCommPrefix = ""
local drunkMessageTemplate = { "\t", "", "\029" }

-- for stats
local SimpleComm_totalSentMessages = 0;
local SimpleComm_totalSentBytes = 0;
local SimpleComm_totalReceivedMessages = 0;
local SimpleComm_totalReceivedBytes = 0;

local onEvent, onUpdate

-- dataChannelLib
local dataChannelLib = DataChannelLib:GetInstance("1");

--------------------------------------------------
local _G = _G

local math_floor = _G.math.floor
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
local rawget = _G.rawget

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
-- On load
-- 
---------------------------------------------------------------------------------
function SimpleComm_OnLoad()
	SimpleCommFrame = CreateFrame("Frame", nil, UIParent)
	SimpleCommFrame:SetScript("OnEvent", onEvent)
	SimpleCommFrame:SetScript("OnUpdate", onUpdate)
	SimpleCommFrame:RegisterEvent("CHAT_MSG_ADDON");
	SimpleCommFrame:RegisterEvent("CHAT_MSG_CHANNEL");
end

---------------------------------------------------------------------------------
--
-- Alias
-- 
---------------------------------------------------------------------------------
local function SimpleComm_SetAliasChannel()
	if not SimpleComm_Channel then
		return;
	end
	local id = GetChannelName( SimpleComm_Channel );
	if (id~=0 and SimpleComm_aliasMustBeSet) then
		ChatTypeInfo[SimpleComm_chanSlashCmdUpper] = ChatTypeInfo["CHANNEL"..id];
		ChatTypeInfo[SimpleComm_chanSlashCmdUpper].sticky = 1;
		
		setglobal("CHAT_MSG_"..SimpleComm_chanSlashCmdUpper, SimpleComm_chanAlias);
		setglobal("CHAT_"..SimpleComm_chanSlashCmdUpper.."_GET", "["..SimpleComm_chanAlias.."] %s:\32");
		setglobal("CHAT_"..SimpleComm_chanSlashCmdUpper.."_SEND", SimpleComm_chanAlias..":\32");
		
		SlashCmdList[SimpleComm_chanSlashCmdUpper] = SimpleComm_test;
		setglobal("SLASH_"..SimpleComm_chanSlashCmdUpper.."1", "/"..SimpleComm_chanSlashCmd);
		
		-- hook only one time
		if (not SimpleComm_oldSendChatMessage) then
			SimpleComm_oldSendChatMessage = SendChatMessage;
			SendChatMessage = SimpleComm_newSendChatMessage;
		end
		SimpleComm_aliasMustBeSet = false;
	end
end

local function SimpleComm_UnsetAliasChannel()
	if (SimpleComm_chanSlashCmdUpper) then
		
		if ( DEFAULT_CHAT_FRAME.editBox.stickyType == string.upper(SimpleComm_chanSlashCmdUpper) ) then
			DEFAULT_CHAT_FRAME.editBox.chatType = "SAY"
			DEFAULT_CHAT_FRAME.editBox.stickyType = "SAY"
		end
		
		setglobal("CHAT_MSG_"..SimpleComm_chanSlashCmdUpper, nil);
		setglobal("CHAT_"..SimpleComm_chanSlashCmdUpper.."_GET", nil);
		setglobal("CHAT_"..SimpleComm_chanSlashCmdUpper.."_SEND", nil);
		
		SlashCmdList[SimpleComm_chanSlashCmdUpper] = nil;
		setglobal("SLASH_"..SimpleComm_chanSlashCmdUpper.."1", nil);
		
		SimpleComm_aliasMustBeSet = true;
	end
end

function SimpleComm_newSendChatMessage(msg, sys, lang, name)
	if (sys == SimpleComm_chanSlashCmdUpper) then
		return SimpleComm_oldSendChatMessage(string.gsub(msg, "|", PIPE_ENTITIE), "CHANNEL", lang, GetChannelName( SimpleComm_Channel ));
	else
		return SimpleComm_oldSendChatMessage(msg, sys, lang, name);
	end
end

function SimpleComm_test()
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "ok");
end

---------------------------------------------------------------------------------
--
-- AFK/DND status
-- 
---------------------------------------------------------------------------------
function SimpleComm_SetFlag(flag, message)
	SimpleComm_Flags = flag
	SimpleComm_FlagsText = message
	SimpleComm_FlagListener(flag, message);
end

function SimpleComm_GetFlag()
	return SimpleComm_Flags, SimpleComm_FlagsText;
end

---------------------------------------------------------------------------------
--
-- Encode / Decode
-- 
---------------------------------------------------------------------------------
local Encode, EncodeByte
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
	
	function EncodeByte(num, drunk)
		local t
		if drunk then
			t = drunkHelper_t
		else
			t = soberHelper_t
		end
		
		local value = t[num]
		if value then
			return value
		else
			return string_char(num)
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

local PackMessages = function (messages)
	return table.concat(messages, PACK_SEPARATOR);
end

local unpackIterator = function(text, start)
	local s, e = string.find(text, REGEX_UNPACK_ITERATOR, start or 1);
	if s and e then
		return e+2, text:sub(s, e); -- +1 = \007, +2 : next message
	end
end

local UnpackMessagesIterator = function(text)
	return unpackIterator, text;
end

---------------------------------------------------------------------------------
--
-- Splited message
--
---------------------------------------------------------------------------------
local REGEX_UNSPLIT = "^\007([0-9]+)([\.|\:])(.*)";

local SimpleComm_SplitSerialize = function(packetNumber, last, obj)
	if last then
		return "\007".. packetNumber ..":".. obj;
	else
		return "\007".. packetNumber ..".".. obj;
	end
end

local SimpleComm_UnsplitSerialize = function (str)
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
local function SimpleComm_SendQueue()
	local clearAFK = GetCVar("autoClearAFK");
	SetCVar("autoClearAFK", 0);
	-- GetLanguageByIndex(1), GetDefaultLanguage()
	
	local sentBytes = 0;
	
	SimpleComm_channelId = GetChannelName(SimpleComm_Channel);
	
	local previousMessage = SimpleComm_messageQueueHeader;
	local message = SimpleComm_messageQueueHeader.next;
	if not message then
		SimpleComm_extraBytes=0;
	end
	local num_messages = 0;
	while message do
		
		-- check chat traffic
		if (sentBytes+SimpleComm_extraBytes) > SIMPLECOMM_CHARACTERSPERTICK_MAX or num_messages>0 then
			previousMessage = SimpleComm_messageQueueLast;
			break;
		end
		
		-- is it a packed message ?
		local text 
		if message.text then
			text = message.text
		else
			text = PackMessages(message)
		end
		
		-- send message
		if message.to then
			if not SimpleComm_Disconnected[message.to] then
				-- GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "Sending to "..message.to..": "..message.text..")");
				assert(text:len() + SimpleCommPrefix:len() + 1<=255, "Too long addon message");
				SendAddonMessage(SimpleCommPrefix, text, "WHISPER", message.to);
				sentBytes = sentBytes + string.len(text);
				num_messages = num_messages + 1
			end
		else
			drunkMessageTemplate[2] = text
			text = table_concat(drunkMessageTemplate)
			-- GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "Send to the channel: %s", text);
			assert(text:len()<=255, "Too long chat message");
			SendChatMessage(text, "CHANNEL", nil, SimpleComm_channelId);
			sentBytes = sentBytes + string.len(text);
			num_messages = num_messages + 1
		end
		
		-- delete current message in queue
		previousMessage.next = message.next;
		
		-- go to next message (previousMessage keeps the same value)
		message = message.next
	end
	
	SimpleComm_extraBytes = SimpleComm_extraBytes + sentBytes - SIMPLECOMM_CHARACTERSPERTICK_MAX;
	
	SimpleComm_messageQueueLast = previousMessage;
	
	SetCVar("autoClearAFK", clearAFK);
	if (sentBytes> 0) then
		GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH, "%i bytes sent", sentBytes)
		SimpleComm_totalSentBytes = SimpleComm_totalSentBytes + sentBytes
		SimpleComm_totalSentMessages = SimpleComm_totalSentMessages + num_messages
	end
end

---------------------------------------------------------------------------------
--
-- Received message
-- 
---------------------------------------------------------------------------------
local function parseOneMessage(author, text, channel, drunk)
	-- decode the message
	text = Decode(text, drunk)

	-- is it a fragmented message ?
	local packets = nil;
	local packet, packetNumber, last = SimpleComm_UnsplitSerialize(text);

	if packetNumber then
		-- fragmented message
		local id = author.."@"..(channel or "Whisper");
		local newText;
		
		-- set newText if this is a valid packet
		if packetNumber == 1 then
			newText = packet;
		elseif SimpleComm_messageStack[id] then
			if SimpleComm_messageStack[id].number+1 == packetNumber then
				newText = SimpleComm_messageStack[id].text .. packet;
			end
		end
		
		-- update packet and SimpleComm_messageStack
		if newText then
			if last then
				SimpleComm_messageStack[id] = nil;
				packet = newText;
			else
				SimpleComm_messageStack[id] = {
					text = newText;
					number = packetNumber;
				};
				packet = nil;
			end
		else
			SimpleComm_messageStack[id] = nil;
			packet = nil;
		end
	end
	
	-- unserialize message from the packet.
	if packet then
		tinsert(SimpleComm_inboundMessageQueue, new(author, packet, channel))
		if not SimpleCommFrame.inbound then
			SimpleCommFrame.inbound = SIMPLECOMM_INBOUND_TICK_DELAY
		end
	end
end

local function parseMessage(author, text, channel, drunk)
	-- is it a packed message ?
	local isPacked = false;
	for _, onePacket in UnpackMessagesIterator(text) do
		parseOneMessage(author, onePacket, channel, drunk)
	end
	SimpleComm_totalReceivedMessages = SimpleComm_totalReceivedMessages + 1
end

onEvent = function(this, event)
	if (SimpleComm_Channel) then
		SimpleComm_channelId = GetChannelName(SimpleComm_Channel);
		
		-- event=CHAT_MSG_CHANNEL; arg1=chat message; arg2=author; arg3=language; arg4=channel name with number; arg8=channel number; arg9=channel name without number
		if (event == "CHAT_MSG_CHANNEL") and (arg8 == SimpleComm_channelId) then
			SimpleComm_Disconnected[arg2] = nil;
			-- get rid of prefix and " ...hic!"
			local message, match = arg1:gsub("^"..SimpleCommPrefix.."\t(.*)\029.-$", "%1")
			if match==1 then
				-- it's match : parse the message
				parseMessage(arg2, message, arg9, true)
				SimpleComm_totalReceivedBytes = SimpleComm_totalReceivedBytes + arg1:len()
			end
		elseif (event == "CHAT_MSG_ADDON") and (arg1==SimpleCommPrefix) and (arg3=="WHISPER") then
			SimpleComm_Disconnected[arg4] = nil
			parseMessage(arg4, arg2, nil, false)
			SimpleComm_totalReceivedBytes = SimpleComm_totalReceivedBytes + arg2:len()
		end
		
	end
end

function SimpleComm_New_ChatFrame_MessageEventHandler(event)
	if (SimpleComm_Channel) then
		SimpleComm_channelId = GetChannelName(SimpleComm_Channel);
		if ((event == "CHAT_MSG_CHANNEL") and (arg8 == SimpleComm_channelId)) then
			-- Hide if this is an internal message
			if SimpleComm_FilterText(arg1) then
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
			if (SimpleComm_chanSlashCmdUpper) then
				arg4 = SimpleComm_chanAlias.." -                                ";
			end
		end
		
		if (event == "CHAT_MSG_CHANNEL_JOIN") and (arg8 == SimpleComm_channelId) then
			SimpleComm_Disconnected[arg2] = nil;
			return;
		end
		
		if (event == "CHAT_MSG_CHANNEL_LEAVE") and (arg8 == SimpleComm_channelId) then
			-- to avoid bug #1315237 : guess that player is offline if he isn't on the channel
			SimpleComm_Disconnected[arg2] = time();
			return;
		end
		
		if (event == "CHAT_MSG_CHANNEL_NOTICE") and (arg8 == SimpleComm_channelId) then
			GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH,  arg1);
			return;
		end
		
		if (event == "CHAT_MSG_CHANNEL_NOTICE_USER") and (arg8 == SimpleComm_channelId) then
			GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH,  "%s (%s)", arg1, arg5);
			return;
		end
		
	else
		if event=="CHAT_MSG_CHANNEL" then
			if SimpleComm_FilterText and SimpleComm_FilterText(arg1) then
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
			if SimpleComm_Disconnected[playerName] then
				if t-SimpleComm_Disconnected[playerName] < 2 then 
					return;
				end
			else
				SimpleComm_Disconnected[playerName] = t;
			end
		end
		
		-- update my AFK/DND status
		local iStart, iEnd, message = string.find(arg1, SimpleComm_AFK_MESSAGE);
		if iStart or arg1==MARKED_AFK then 
			SimpleComm_SetFlag("AFK", message);
		end
		
		local iStart, iEnd, message = string.find(arg1, SimpleComm_DND_MESSAGE);
		if iStart then
			SimpleComm_SetFlag("DND", message);
		end
		
		if arg1==CLEARED_AFK or arg1==CLEARED_DND then
			SimpleComm_SetFlag(nil, nil);
		end
		
		-- update Drunk status
		if arg1==DRUNK_MESSAGE_SELF1 then
			SimpleComm_YouAreDrunk = false;
		else
			local i = 2;
			
			while getglobal("DRUNK_MESSAGE_SELF"..i) do
				if arg1==getglobal("DRUNK_MESSAGE_SELF"..i) then
					SimpleComm_YouAreDrunk = true;
					break;
				end
				i = i +1;
			end
		end
	end
	
	-- call default ChatFrame_OnEvent
	SimpleComm_Old_ChatFrame_MessageEventHandler(event);
end
SimpleComm_Old_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
ChatFrame_MessageEventHandler = SimpleComm_New_ChatFrame_MessageEventHandler;

---------------------------------------------------------------------------------
--
-- DataChannelLib callback
-- 
---------------------------------------------------------------------------------
function SimpleComm_Callback(event, channelName, a1)
	if event==dataChannelLib.YOU_JOINED then
		if (SimpleComm_chanSlashCmd) then
			SimpleComm_SetAliasChannel();
		end
		if (SimpleComm_JoinHandler) then
			SimpleComm_JoinHandler();
		end
		SimpleCommFrame.outbound = SIMPLECOMM_OUTBOUND_TICK_DELAY;
		SimpleComm_channelId = a1;
		SimpleComm_SetChannelStatus("Connected");
	elseif event==dataChannelLib.YOU_LEFT then
		if (SimpleComm_chanSlashCmd) then
			SimpleComm_UnsetAliasChannel();
		end
		if (SimpleComm_LeaveHandler) then
			SimpleComm_LeaveHandler();
		end
		SimpleComm_SetChannelStatus("Disconnected");
	elseif event==dataChannelLib.TOO_MANY_CHANNELS then
		SimpleComm_SetChannelStatus("Error", GUILDADS_ERROR_TOOMANYCHANNELS)
	elseif event==dataChannelLib.WRONG_NAME then
		SimpleComm_SetChannelStatus("Error", GUILDADS_ERROR_JOINCHANNELFAILED)
	elseif event==dataChannelLib.WRONG_PASSWORD then
		SimpleComm_SetChannelStatus("Error", GUILDADS_ERROR_WRONGPASSWORD)
	elseif event==dataChannelLib.PASSWORD_CHANGED then
		SimpleComm_Password = a1;
	end
end

---------------------------------------------------------------------------------
--
-- Timer
-- 
---------------------------------------------------------------------------------
onUpdate = function(this, elapsed)
	if this.outbound then
		this.outbound = this.outbound - elapsed;
		if this.outbound <=0 then
			SimpleComm_SendQueue();
			this.outbound = SIMPLECOMM_OUTBOUND_TICK_DELAY;
		end
	end
	
	if this.inbound then
		this.inbound = this.inbound - elapsed;
		if this.inbound <= 0 then
			this.inbound = nil;
			if SimpleComm_inboundMessageQueue[1] then
				local message = SimpleComm_inboundMessageQueue[1];
				table.remove(SimpleComm_inboundMessageQueue, 1);
				if SimpleComm_inboundMessageQueue[1] then
					this.inbound = SIMPLECOMM_INBOUND_TICK_DELAY
				end
				SimpleComm_Handler(message[1], message[2], message[3]);
				del(message)
			end
		end
	end
end
SimpleComm_OnUpdate = onUpdate

---------------------------------------------------------------------------------
--
-- Public functions
-- 
---------------------------------------------------------------------------------
function SimpleComm_SendMessage(who, text)
	if not(who and SimpleComm_Disconnected[who]) then
		local queueLast = SimpleComm_messageQueueLast
		text = Encode(text, who==nil)
		local textLength = text:len()
		if (textLength + queueLast.length <= maxMessageLength and queueLast.to == who) then
			if queueLast.text then
				table.insert(queueLast, queueLast.text);
				queueLast.text=nil;
			end
			-- pack message with the previous one
			table.insert(queueLast, text)
			queueLast.length = queueLast.length + textLength + 1
		elseif textLength<= maxMessageLength then
			-- normal message
			SimpleComm_messageQueueLast.next = {
				to=who, 
				text=text,
				length=textLength
			};
			SimpleComm_messageQueueLast = SimpleComm_messageQueueLast.next;
		else
			-- split the message into smaller one.
			local packetNumber = 1;
			while text~="" do
				-- take the first characters
				local tmp = string.sub(text, 1, maxMessageLength);
				text = string.sub(text, maxMessageLength+1);
				-- add a packet
				SimpleComm_messageQueueLast.next = {
					to = who;
					text = SimpleComm_SplitSerialize(packetNumber, text=="", tmp);
					length = text:len();
				};
				SimpleComm_messageQueueLast = SimpleComm_messageQueueLast.next;
				-- next packet
				packetNumber = packetNumber + 1;
			end
		end
	end
end

function SimpleComm_SetChannelStatus(status, message)
	SimpleComm_Status = status;
	SimpleComm_StatusMessage = message;
	if SimpleComm_StatusListener then
		SimpleComm_StatusListener(SimpleComm_Status, SimpleComm_StatusMessage)
	end
end

function SimpleComm_GetChannelStatus()
	return SimpleComm_Status, SimpleComm_StatusMessage;
end

function SimpleComm_Initialize(
					Prefix,
					FilterText,
					OnJoin, OnLeave, OnMessage, 
					FlagListener, StatusListener)
	SetCVar("spamFilter", 0)
	
	SimpleCommPrefix = Prefix
	drunkMessageTemplate[1] = Prefix.."\t"
	--[[
		1 "\t" 
		1 "\029"
		3 for split message
	]]
	maxMessageLength = 254-SimpleCommPrefix:len()-5
	
	SimpleComm_FilterText = FilterText
	
	SimpleComm_Handler = OnMessage
	SimpleComm_JoinHandler = OnJoin
	SimpleComm_LeaveHandler = OnLeave
	
	SimpleComm_FlagListener = FlagListener
	SimpleComm_StatusListener = StatusListener
	
	SimpleComm_ChatFrame = DEFAULT_CHAT_FRAME
	
	-- AFK/DND test for myself (usefull when the UI was reloaded)
	if SimpleComm_GetFlag(UnitName("player"))==nil then
		if UnitIsAFK("player") then
			SimpleComm_SetFlag("AFK", "")
		end
		if UnitIsDND("player") then
			SimpleComm_SetFlag("DND", "")
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
	SimpleComm_Channel = Channel;
	SimpleComm_Password = Password;
	
	local result = dataChannelLib:OpenChannel("GuildAds", SimpleComm_Channel, SimpleComm_Password, SimpleComm_ChatFrame);
	
	if SimpleComm_FirstJoin then
		SimpleComm_FirstJoin = nil;
		
		-- Set timer
		SimpleCommFrame:Show();
	end
	
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_Join] end");
	
	return result;
end

function SimpleComm_Leave()
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_Leave] begin");
	-- leave channel
	SimpleCommFrame.outbound = nil;
	
	dataChannelLib:CloseChannel("GuildAds", SimpleComm_Channel);
	
	-- set channel
	SimpleComm_Channel = nil;
	SimpleComm_Password = nil;
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_Leave] end");
end

function SimpleComm_SetAlias(chanSlashCmd, chanAlias)
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_SetAlias] begin");
	-- unset previous alias
	if (SimpleComm_chanSlashCmd) then
		SimpleComm_UnsetAliasChannel();
	end
	
	-- set alias
	SimpleComm_chanSlashCmd = chanSlashCmd;
	SimpleComm_chanSlashCmdUpper = string.upper(chanSlashCmd);
	SimpleComm_chanAlias = chanAlias;

	SimpleComm_aliasMustBeSet = true;
	SimpleComm_SetAliasChannel();
	GuildAds_ChatDebug(GA_DEBUG_CHANNEL, "[SimpleComm_SetAlias] end");
end

function SimpleComm_GetStats()
	return SimpleComm_totalSentMessages, SimpleComm_totalSentBytes, SimpleComm_totalReceivedMessages, SimpleComm_totalReceivedBytes;
end

SimpleComm_OnLoad()
