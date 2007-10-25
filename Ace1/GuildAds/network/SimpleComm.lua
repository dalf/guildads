----------------------------------------------------------------------------------
--
-- SimpleComm.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

SIMPLECOMM_DEBUG = false;				-- output debug information

SIMPLECOMM_CHARACTERSPERTICK_MAX = 100;		-- char per tick			300
SIMPLECOMM_OUTBOUND_TICK_DELAY = 0.5;		-- delay in second between tick		1

SIMPLECOMM_INBOUND_TICK_DELAY = 0.125;	-- TODO : change from 0.125 to 0.5 according to FPS

SIMPLECOMM_SENDCHATMESSAGE_TICK_DELAY = 0.5;
SimpleComm_SendChatMessage_Queue ={};

local PIPE_ENTITIE = "\127p";

SimpleComm_Channel = nil;
SimpleComm_Password = nil;
SimpleComm_ChatFrame = nil;

SimpleComm_JoinHandler = nil;
SimpleComm_LeaveHandler = nil;

local SimpleComm_FirstJoin = true;
SimpleComm_aliasMustBeSet = false;

local SimpleComm_Handler;
local SimpleComm_FilterText;
local SimpleComm_FilterMessage;

local SimpleComm_Status = "Starting";
local SimpleComm_StatusMessage;

local SimpleComm_oldChatFrame_OnEvent;

SimpleComm_oldSendChatMessage = nil;
local SimpleComm_chanSlashCmd;
local SimpleComm_chanSlashCmdUpper;

local SimpleComm_FlagListener;

local SimpleComm_messageQueueHeader = {};
local SimpleComm_messageQueueLast = SimpleComm_messageQueueHeader;
	-- .delay
	-- .to
	-- .text
	-- .next
	
local SimpleComm_inboundMessageQueue = {};
	
local SimpleComm_sentBytes = 0;
local SimpleComm_extraBytes = 0;
local SimpleComm_channelId;
SimpleComm_YouAreDrunk = false;

SimpleComm_DisconnectedMessage = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "(.*)");
SimpleComm_AmbiguousMessage = string.format(ERR_CHAT_PLAYER_AMBIGUOUS_S, "(.*)");
SimpleComm_AFK_MESSAGE = string.format(MARKED_AFK_MESSAGE, "(.*)");
SimpleComm_DND_MESSAGE = string.format(MARKED_DND, "(.*)");

SimpleComm_Flags = {};
SimpleComm_RecentWhispers = {};
SimpleComm_Disconnected = {};

local SimpleComm_messageStack = {};

local dataChannelLib = DataChannelLib:GetInstance("1");

---------------------------------------------------------------------------------
--
-- Debug
-- 
---------------------------------------------------------------------------------
local function DEBUG_MSG(msg, high)
	if high then
		GuildAds_ChatDebug(GA_DEBUG_CHANNEL, msg);
	else
		GuildAds_ChatDebug(GA_DEBUG_CHANNEL_HIGH, msg);
	end
end

---------------------------------------------------------------------------------
--
-- On load
-- 
---------------------------------------------------------------------------------
function SimpleComm_OnLoad()
	this:RegisterEvent("CHAT_MSG_ADDON");
	this:RegisterEvent("CHAT_MSG_CHANNEL");
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
			SimpleCommFrame.message_delay = SIMPLECOMM_SENDCHATMESSAGE_TICK_DELAY; -- enabling this line enables chat throttle
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

function SimpleComm_newSendChatMessage(msg, sys, lang, name, noafkclear)
	if (sys == SimpleComm_chanSlashCmdUpper) then
		return SimpleComm_Queue_SendChatMessage(string.gsub(msg, "|", PIPE_ENTITIE), "CHANNEL", lang, GetChannelName( SimpleComm_Channel ), noafkclear);
	else
		return SimpleComm_Queue_SendChatMessage(msg, sys, lang, name, noafkclear);
	end
end

function SimpleComm_test()
	DEBUG_MSG("ok");
end

function SimpleComm_Queue_SendChatMessage(msg, sys, lang, name, noafkclear)
	if SimpleCommFrame.message_delay then
		--DEBUG_MSG("Queuing message "..msg); -- careful, % signs wreck output: cause errors.
		if SimpleCommFrame.message_delay <= 0 then
			SimpleComm_oldSendChatMessage(msg, sys, lang, name);
			SimpleCommFrame.message_delay = SIMPLECOMM_SENDCHATMESSAGE_TICK_DELAY;
		else
			tinsert(SimpleComm_SendChatMessage_Queue, {msg=msg, sys=sys, lang=lang, name=name, noafkclear=noafkclear});
		end
	else
		--DEBUG_MSG("Sending message "..msg);
		return SimpleComm_oldSendChatMessage(msg, sys, lang, name);
	end
end

function SimpleComm_SendChatMessage_Tick()
	local q=SimpleComm_SendChatMessage_Queue[1];
	local noafkclear=q.noafkclear;
	local clearAFK;
	if noafkclear then
		clearAFK = GetCVar("autoClearAFK");
		SetCVar("autoClearAFK", 0);
	end

	SimpleComm_oldSendChatMessage(q.msg, q.sys, q.lang, q.name); -- call original SendChatMessage
	tremove(SimpleComm_SendChatMessage_Queue,1);

	if noafkclear then
		SetCVar("autoClearAFK", clearAFK);
	end
end

---------------------------------------------------------------------------------
--
-- AFK/DND status
-- 
---------------------------------------------------------------------------------
function SimpleComm_SetFlag(player, flag, message)
	player = player or UnitName("player");
	if flag then
		SimpleComm_Flags[player] = { flag=flag; message=message };
	else
		SimpleComm_Flags[player] = nil;
	end
	if player==UnitName("player") and SimpleComm_FlagListener then
		SimpleComm_FlagListener(flag, message);
	end
end

function SimpleComm_GetFlag(player)
	if SimpleComm_Flags[player] then
		return SimpleComm_Flags[player].flag, SimpleComm_Flags[player].message;
	end
end

function SimpleComm_AddWhisper(player)
	SimpleComm_RecentWhispers[string.lower(player)] = GetTime();
end

function SimpleComm_DelWhisper(player)
	local t = SimpleComm_RecentWhispers[string.lower(player)];
	return t and GetTime() - t <= 15;
end

---------------------------------------------------------------------------------
--
-- Encode / Decode
-- 
---------------------------------------------------------------------------------

-- depuis AceComm-2.0
local string_gsub = string.gsub
function SimpleComm_Encode(text, drunk)
	text = string_gsub(text, "°", "°±")
	if drunk then
		text = string_gsub(text, "\020", "°\021")
		text = string_gsub(text, "\015", "°\016")
		text = string_gsub(text, "S", "\020")
		text = string_gsub(text, "s", "\015")
		text = string_gsub(text, "`", "``");
		-- change S and s to a different set of character bytes.
	end
	text = string_gsub(text, "\255", "°\254") -- \255 (this is here because \000 is more common)
	text = string_gsub(text, "%z", "\255") -- \000
	text = string_gsub(text, "\010", "°\011") -- \n
	text = string_gsub(text, "\124", "°\125") -- |
	text = string_gsub(text, "%%", "°\038") -- %
	-- encode assorted prohibited characters
	return text
end

local func
-- Clean a received message
function SimpleComm_Decode(text, drunk)
	if drunk then
		text = string_gsub(text, "^(.*)°.-$", "%1")
		-- get rid of " ...hic!"
	end
	if not func then
		func = function(text)
			if text == "\016" then
				return "\015"
			elseif text == "\021" then
				return "\020"
			elseif text == "±" then
				return "°"
			elseif text == "\254" then
				return "\255"
			elseif text == "\011" then
				return "\010"
			elseif text == "\125" then
				return "\124"
			elseif text == "\038" then
				return "\037"
			end
		end
	end
	text = string_gsub(text, "\255", "\000")
	if drunk then
		text = string_gsub(text, "\020", "S")
		text = string_gsub(text, "\015", "s")
		text = string_gsub(text, "``", "`");
	end
	text = string_gsub(text, drunk and "°([\016\021±\254\011\125\038])" or "°([±\254\011\125\038])", func)
	-- remove the hidden character and refix the prohibited characters.
	return text
end

---------------------------------------------------------------------------------
--
-- Envois
-- 
---------------------------------------------------------------------------------
local function SimpleComm_SendQueue(elapsed)
	local clearAFK = GetCVar("autoClearAFK");
	SetCVar("autoClearAFK", 0);
	-- GetLanguageByIndex(1), GetDefaultLanguage()
	
	SimpleComm_sentBytes = 0;
	SimpleComm_channelId = GetChannelName(SimpleComm_Channel);
	
	local previousMessage = SimpleComm_messageQueueHeader;
	local message = SimpleComm_messageQueueHeader.next;
	if not message then
		SimpleComm_extraBytes=0;
	end
	local num_messages = 0;
	while message do
		
		-- check chat traffic
		if (SimpleComm_sentBytes+SimpleComm_extraBytes) > SIMPLECOMM_CHARACTERSPERTICK_MAX or num_messages>0 then
			previousMessage = SimpleComm_messageQueueLast;
			break;
		end
		
		-- send message
		if message.to then
			if not SimpleComm_Disconnected[message.to] then
				-- DEBUG_MSG("Envois a("..message.to..") de("..message.text..")");
				SendAddonMessage("GuildAds",message.text,"WHISPER",message.to);
				--SimpleComm_AddWhisper(message.to);
				SimpleComm_sentBytes = SimpleComm_sentBytes + string.len(message.text);
				num_messages = num_messages + 1;
			else
				-- Ignore the message since the player is offline.
				--SimpleComm_sentBytes = SimpleComm_sentBytes - string.len(message.text);
			end
		else
			-- DEBUG_MSG("Envois a tous de("..message.text..")");
			SendChatMessage(message.text, "CHANNEL", nil, SimpleComm_channelId, true);
			SimpleComm_sentBytes = SimpleComm_sentBytes + string.len(message.text);
			num_messages = num_messages + 1;
		end
		
		-- delete current message in queue
		previousMessage.next = message.next;
		
		-- go to next message (previousMessage keeps the same value)
		message = message.next
	end
	
	SimpleComm_extraBytes = SimpleComm_extraBytes + SimpleComm_sentBytes - SIMPLECOMM_CHARACTERSPERTICK_MAX;
	
	SimpleComm_messageQueueLast = previousMessage;
	
	SetCVar("autoClearAFK", clearAFK);
	if (SimpleComm_sentBytes> 0) then
		DEBUG_MSG(SimpleComm_sentBytes.." bytes sent", true);
	end
end

---------------------------------------------------------------------------------
--
-- Reception
-- 
---------------------------------------------------------------------------------
local function SimpleComm_ParseMessage(author, text, channel)
	local packet, packetNumber, last = SimpleComm_UnsplitSerialize(text);
	-- fragmented packet ?
	if packetNumber then
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
	if packet and SimpleComm_FilterMessage(packet) then
		tinsert(SimpleComm_inboundMessageQueue, { author, packet, channel });
		if not SimpleCommFrame.inbound then
			SimpleCommFrame.inbound = SIMPLECOMM_INBOUND_TICK_DELAY;
		end
	end
end

function SimpleComm_ParseEvent(event)
	if (SimpleComm_Channel) then
		SimpleComm_channelId = GetChannelName(SimpleComm_Channel);
		
		-- event=CHAT_MSG_CHANNEL; arg1=chat message; arg2=author; arg3=language; arg4=channel name with number; arg8=channel number; arg9=channel name without number
		if ((event == "CHAT_MSG_CHANNEL") and (arg8 == SimpleComm_channelId)) then
			SimpleComm_Disconnected[arg2] = nil;
			SimpleComm_ParseMessage(arg2, SimpleComm_Decode(arg1, true), arg9);
		
		elseif (event == "CHAT_MSG_ADDON") and (arg1=="GuildAds") and (arg3=="WHISPER") then
			SimpleComm_Disconnected[arg4] = nil;
			SimpleComm_ParseMessage(arg4, SimpleComm_Decode(arg2, true), nil);
			
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
			DEBUG_MSG(arg1, true);
			return;
		end
		
		if (event == "CHAT_MSG_CHANNEL_NOTICE_USER") and (arg8 == SimpleComm_channelId) then
			DEBUG_MSG(arg1.."("..arg5..")", true);
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
			SimpleComm_SetFlag(nil, "AFK", message);
		end
		
		local iStart, iEnd, message = string.find(arg1, SimpleComm_DND_MESSAGE);
		if iStart then
			SimpleComm_SetFlag(nil, "DND", message);
		end
		
		if arg1==CLEARED_AFK or arg1==CLEARED_DND then
			SimpleComm_SetFlag(nil, nil, nil);
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
function SimpleComm_OnUpdate(elapsed)
	if (this.outbound) then
		this.outbound = this.outbound - elapsed;
		if (this.outbound <=0) then
			SimpleComm_SendQueue(SIMPLECOMM_OUTBOUND_TICK_DELAY - this.outbound);
			this.outbound = SIMPLECOMM_OUTBOUND_TICK_DELAY;
		end
	end
	
	if (this.inbound) then
		this.inbound = this.inbound - elapsed;
		if (this.inbound <= 0) and (SimpleComm_inboundMessageQueue[1]) then
			local message = SimpleComm_inboundMessageQueue[1];
			table.remove(SimpleComm_inboundMessageQueue, 1);
			if SimpleComm_inboundMessageQueue[1] then
				this.inbound = SIMPLECOMM_INBOUND_TICK_DELAY;
			else
				this.inbound = nil;
			end
			SimpleComm_Handler(message[1], message[2], message[3]);
		end
	end

	if (this.message_delay) then
		this.message_delay = this.message_delay - elapsed;
		if (this.message_delay <=0 and #SimpleComm_SendChatMessage_Queue > 0) then
			SimpleComm_SendChatMessage_Tick();
			this.message_delay = SIMPLECOMM_SENDCHATMESSAGE_TICK_DELAY;
		end
	end
end

---------------------------------------------------------------------------------
--
-- Public functions
-- 
---------------------------------------------------------------------------------
function SimpleComm_SendMessage(who, text)
	if not(who and SimpleComm_Disconnected[who]) then
		text = SimpleComm_Encode(text, true);
		if strlen(text)<240 then
			SimpleComm_messageQueueLast.next = {to=who; text=text };
			SimpleComm_messageQueueLast = SimpleComm_messageQueueLast.next;
		else
			local packetNumber = 1;
			while text~="" do
				-- take first 240 char
				local tmp = string.sub(text, 1, 239);
				text = string.sub(text, 240);
				-- add a packet
				SimpleComm_messageQueueLast.next = {
					to = who;
					text = SimpleComm_SplitSerialize(packetNumber, text=="", tmp);
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
		SimpleComm_StatusListener(SimpleComm_Status, SimpleComm_StatusMessage);
	end
end

function SimpleComm_GetChannelStatus()
	return SimpleComm_Status, SimpleComm_StatusMessage;
end

function SimpleComm_Initialize(FilterText, FilterMessage, SplitSerialize, UnsplitSerialize, OnJoin, OnLeave, OnMessage, FlagListener, StatusListener)
	SetCVar("spamFilter", 0)
	
	SimpleComm_FilterText = FilterText;
	SimpleComm_FilterMessage = FilterMessage;
	
	SimpleComm_SplitSerialize = SplitSerialize;
	SimpleComm_UnsplitSerialize = UnsplitSerialize;
	
	SimpleComm_Handler = OnMessage;
	SimpleComm_JoinHandler = OnJoin;
	SimpleComm_LeaveHandler = OnLeave;
	
	SimpleComm_FlagListener = FlagListener;
	SimpleComm_StatusListener = StatusListener;
	
	SimpleComm_ChatFrame = DEFAULT_CHAT_FRAME;
	
	-- AFK/DND test for myself (usefull when the UI was reloaded)
	if SimpleComm_GetFlag(UnitName("player"))==nil then
		if UnitIsAFK("player") then
			SimpleComm_SetFlag(nil, "AFK", "");
		end
		if UnitIsDND("player") then
			SimpleComm_SetFlag(nil, "DND", "");
		end
	end
	
	dataChannelLib:RegisterAddon("GuildAds", SimpleComm_Callback);
	SimpleComm_SetChannelStatus("Initializing");
end

function SimpleComm_Join(Channel, Password)
	DEBUG_MSG("[SimpleComm_Join] begin");
	
	-- some sanity check
	local typePassword = type(Password);
	if not ( type(Channel) == "string" and (typePassword == "string" or typePassword == "nil") ) then
		DEBUG_MSG("Can't join channel ("..tostring(Channel)..","..tostring(Password)..")", true);
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
	
	DEBUG_MSG("[SimpleComm_Join] end");
	
	return result;
end

function SimpleComm_Leave()
	DEBUG_MSG("[SimpleComm_Leave] begin");
	-- leave channel
	SimpleCommFrame.outbound = nil;
	
	dataChannelLib:CloseChannel("GuildAds", SimpleComm_Channel);
	
	-- set channel
	SimpleComm_Channel = nil;
	SimpleComm_Password = nil;
	DEBUG_MSG("[SimpleComm_Leave] end");
end

function SimpleComm_SetAlias(chanSlashCmd, chanAlias)
	DEBUG_MSG("[SimpleComm_SetAlias] begin");
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
	DEBUG_MSG("[SimpleComm_SetAlias] end");
end
