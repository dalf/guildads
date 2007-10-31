-- Written by: Galmok@Stormrage-EU

-- with a small contribution of Zarkan.

-- This code works under the assumption that _all_ messages sent using SendChatMessage get echoed by the server OR triggers the THROTTLED event.
-- If messages do not get echoed back OR THROTTLED is triggered, this code will enter an infinite loop, resending the last THROTTLED message over and over.

-- possible message types used in SendChatMessage:
-- "SAY", "WHISPER", "EMOTE", "CHANNEL", "PARTY", "BATTLEGROUND", "GUILD", "OFFICER", "YELL", "RAID", "RAID_WARNING", "AFK", "DND"

--local CT_Version = tonumber(GetAddOnMetadata("ChatThrottler", "Version"))
local CT_Version = 0.11

-- following code is borrowed from ChatThrottleLib
if _G.ChatThrottler and _G.ChatThrottler.Version >= CT_Version then
	-- There's already a newer (or same) version loaded. Buh-bye.
	return
end

if not _G.ChatThrottler then
	_G.ChatThrottler = {}
end

ChatThrottler.Version = CT_Version

ChatThrottler.RateLimitSeconds = 10;
ChatThrottler.RateLimitMessages = 13; -- 15 is the hard limit but due to timing problems, the THROTTLED noticed can occur at 13-14 messages/10 seconds.

ChatThrottler.SendChatMessage_Tick_Delay = 0.75;
ChatThrottler.SendChatMessage_Tick_Interval = 0.75;

ChatThrottler.Initialized = false;
ChatThrottler.Time = ChatThrottler.Time or 0;
ChatThrottler.Timeout = 3;
--ChatThrottler_YouAreDrunk = false; -- this may be wrong initially, but there is no real way to detect that

-- Message types that cannot trigger the THROTTLED event.
-- If any of these can cause the THROTTLED event, this addon will wreck havoc. Sorry.
-- SAY, WHISPER, PARTY, YELL, RAID

-- Message types to monitor (and their associated events).
-- All the mentioned events must have arg1 = message, arg2 = playername, arg3 = language
ChatThrottler.Monitor={ CHANNEL={ "CHAT_MSG_CHANNEL" } };
			
-- Also: 
-- SAY={ "CHAT_MSG_SAY" }
-- WHISPER={ "CHAT_MSG_WHISPER" }
-- EMOTE={ "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE" } -- this may be bad to add, unsure of how it triggers
-- PARTY={ "CHAT_MSG_PARTY" }
-- BATTLEGROUND={ "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER" }
-- GUILD={ "CHAT_MSG_GUILD" }
-- OFFICER={ "CHAT_MSG_OFFICER" }
-- YELL={ "CHAT_MSG_YELL" }
-- RAID={ "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER" }
-- RAID_WARNING={ "CHAT_MSG_RAID_WARNING" }
-- AFK={ "CHAT_MSG_AFK" }
-- DND={ "CHAT_MSG_DND" }


--ChatThrottler_AFK_MESSAGE = string.format(MARKED_AFK_MESSAGE, "(.*)");
--ChatThrottler_DND_MESSAGE = string.format(MARKED_DND, "(.*)");

function ChatThrottler:Initialize()
	self.Frame = CreateFrame("Frame");
	self.Frame:SetScript("OnEvent", ChatThrottler.ParseEvent);
	self.Frame:SetScript("OnUpdate", ChatThrottler.OnUpdate);
	self.Frame:Show();

	self.Frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");

	SlashCmdList["CHATTHROTTLER"] = ChatThrottler.Command;
	SLASH_CHATTHROTTLER1 = "/chatthrottler";
	self.Command("hook");
	
	-- register events
	self.Events={};
	for chatType, events in pairs(self.Monitor) do
		for _, event in pairs(events) do
			self.Frame:RegisterEvent(event);
			self.Events[event]=true;
		end
	end
	
	-- when queueing, we send 1 message and wait for server echo or THROTTLED in which case we resend.
	self.Throttled = false;
	self.Queueing = false; -- is set to true from the first THROTTLED event and until the send queue is empty.

	self.HideChatEditEvent=false;

	self.Initialized = true;
end


function ChatThrottler.Command(msg)
	local self=ChatThrottler
	
	ChatFrame1:AddMessage("/chatthrottler called with argument "..tostring(msg));
	if msg=="hook" then
		self.SendChatMessage_Queue=ChatThrottlerList:new();
		self.LastMessageReceived = self.SendChatMessage_Queue.first;
		self.SentChatMessage_Queue=ChatThrottlerList:new(); -- messages that were actually sent properly
		-- hook only one time
		if (not self.oldSendChatMessage) then
			self.oldSendChatMessage = SendChatMessage;
		end
		SendChatMessage = self.newSendChatMessage;
		if (not self.oldChatFrame_OnEvent) then 
			self.oldChatFrame_OnEvent =ChatFrame_OnEvent;
		end
		ChatFrame_OnEvent = self.newChatFrame_OnEvent;

		self.Frame.message_delay = self.SendChatMessage_Tick_Interval;
		
		ChatFrame1:AddMessage("SendChatMessage hooked.");
	elseif msg=="unhook" then
		if self.oldSendChatMessage then
			SendChatMessage = self.oldSendChatMessage;
		end
		if self.oldChatFrame_OnEvent then
			ChatFrame_OnEvent = self.oldChatFrame_OnEvent;
		end
		self.oldSendChatMessage = nil;
		self.Frame.message_delay = nil;
		self.SendChatMessage_Queue:DeleteAll();
		
		ChatFrame1:AddMessage("SendChatMessage unhooked.");
	elseif msg=="version" then
		ChatFrame1:AddMessage("ChatThrottler version "..tostring(self.Version));
	end
end

--[[
ChatThrottler_RecurseProtect=false;
function ChatThrottler_SetFlag(flag, message)
	ChatThrottler_Flags = flag
	ChatThrottler_FlagsText = message
	--ChatThrottler_FlagListener(flag, message);
	if not ChatThrottler_RecurseProtect then
		ChatThrottler_RecurseProtect=true;
		local afk=GetCVar("autoClearAFK");
		SetCVar("autoClearAFK",0);
		ChatFrame1:AddMessage("Sending: "..tostring(flag)..", "..tostring(message)..", "..GetCVar("autoClearAFK"));
		SendChatMessage("Sending: "..tostring(flag)..", "..tostring(message)..", "..GetCVar("autoClearAFK"), "CHANNEL", nil, 8);
		SetCVar("autoClearAFK",afk);
		ChatThrottler_RecurseProtect=false;
	else
		ChatFrame1:AddMessage("Recursion");
	end
end
]]

function ChatThrottler:DeleteOldMessages()
	-- store only message sent in the last 10 seconds.
	while self.SentChatMessage_Queue:Length()>0 do
		local obj=self.SentChatMessage_Queue:First().obj;
		if self.Time - obj.time >= ChatThrottler.RateLimitSeconds then
			self.SentChatMessage_Queue:Delete(obj);
		else
			break;
		end
	end
end

function ChatThrottler.ParseEvent(this, event)
	local self=ChatThrottler;
	--[[
	if event == "CHAT_MSG_SYSTEM" then
		-- update Drunk status (borrowed from ChatThrottler, thanks)
		if arg1==DRUNK_MESSAGE_SELF1 then
			ChatThrottler_YouAreDrunk = false;
		else
			local i = 2;
			while getglobal("DRUNK_MESSAGE_SELF"..i) do
				if arg1==getglobal("DRUNK_MESSAGE_SELF"..i) then
					ChatThrottler_YouAreDrunk = true;
					break;
				end
				i = i +1;
			end
		end
		
		-- update my AFK/DND status
		local iStart, iEnd, message = string.find(arg1, ChatThrottler_AFK_MESSAGE);
		if iStart or arg1==MARKED_AFK then 
			ChatFrame1:AddMessage("CHAT_MSG_SYSTEM, MARKED_AFK");
			ChatThrottler_SetFlag("AFK", message);
		end
		
		local iStart, iEnd, message = string.find(arg1, ChatThrottler_DND_MESSAGE);
		if iStart then
			ChatFrame1:AddMessage("CHAT_MSG_SYSTEM, MARKED_DND");
			ChatThrottler_SetFlag("DND", message);
		end
		
		if arg1==CLEARED_AFK or arg1==CLEARED_DND then
			ChatFrame1:AddMessage("CHAT_MSG_SYSTEM, CLEARED_AFK or CLEARED_DND");
			ChatThrottler_SetFlag(nil, nil);
		end
		
		
	end
	]]
	if not self.Initialized then
		return;
	end
	-- event=CHAT_MSG_CHANNEL; arg1=chat message; arg2=author; arg3=language; arg4=channel name with number; arg8=channel number; arg9=channel name without number
	if event == "CHAT_MSG_CHANNEL_NOTICE" then
		if arg1 == "THROTTLED" then
			--ChatFrame1:AddMessage("CHAT_MSG_CHANNEL_NOTICE, THROTTLED");
			self.Throttled=false;
			self.Queueing=true;
			self.HideChatEditEvent=true;
			self.Frame.message_delay = self.SendChatMessage_Tick_Delay;
			self.SentMessageTime=nil; -- message was handled by server
			-- last successful message sent
			-- CHAT_MSG_CHANNEL: arg4=channel name with number; arg7=?; arg8=channel number; arg9=channel name without number;
			-- CHAT_MSG_GUILD: arg4="&"..GuildName, arg7=0, arg8=0
			-- CHAT_MSG_OFFICER: same as CHAT_MSG_GUILD
			
			--ChatFrame1:AddMessage("We have a problem! "..tostring(arg2)..","..tostring(arg3)..","..tostring(arg4)..","..tostring(arg5)..","..tostring(arg6)..","..tostring(arg7)..","..tostring(arg8)..","..tostring(arg9));

		end
	else
		if arg2 == UnitName("player") then
			--ChatFrame1:AddMessage(event.." "..tostring(arg1));
			if self.Events[event] then
				self.SentMessageTime=nil; -- message was handled by server
				self.SentChatMessage_Queue:Append({msg=arg1, time=self.Time});
				
				if self.SendChatMessage_Queue:First() then
					--ChatFrame1:AddMessage("Latency = "..tostring(self.Time-self.SendChatMessage_Queue:First().obj.time));
					self.SendChatMessage_Queue:Delete(self.SendChatMessage_Queue:First().obj);
				end
								
				self.Throttled=false; -- we received a message and the server obviously isn't throttling us
				
			end
		end
	end
	
end

--[[
function ChatThrottler_CompareSentWithReceived(sent, received)
	if sent==received then
		return true;
	end
	return true;
	-- Have to check ChatThrottler_YouAreDrunk to see if I am drunk.
	-- Even if ChatThrottler_YouAreDrunk is false, we may be drunk due to logging out while drunk or /reloadui while drunk.
	-- This will be difficult and may be errors. 
	
	-- Drunk corruptions are as follows:
	-- " ...hic!" added to end of line.
	-- Randomly, any "s" or "S" last in a word may get an "h" attached. "yes" -> "yesh"
	-- Randomly, any "s" or "S" at the beginning of a word may get an "h" attached. "start" -> "shtart"
	-- "s"/"S" in the middle of a word do not get modified: "test" -> "test" (always)
	-- lone "s" and "S" are not modified.
	
	-- We can chose to simply remove all s, S, h and ...hic! parts of a message and then compare. Should be enough in most cases.
	--text = string_gsub(text, "^(.*)°.-$", "%1")
end
]]

function ChatThrottler.newSendChatMessage(msg, sys, lang, name)
	local self=ChatThrottler
	--ChatFrame1:AddMessage("SendChatMessage called: type "..tostring(sys)..", "..msg..", autoClearAFK="..GetCVar("autoClearAFK"));
	if self.Frame.message_delay and self.Monitor[sys] then
		-- throttling is enabled
		
		-- put _ALL_ sent messages in the list, even if we aren't throttling (too late to queue messages when we get the THROTTLED event)
		self.SendChatMessage_Queue:Append({msg=msg, sys=sys, lang=lang, name=name, autoclearafk=GetCVar("autoClearAFK"), time=self.Time or 0});
		
		-- how many messages have we sent in the last 10 seconds? (successfully, that means the ones the server echoed back to us)
		-- = self.SentChatMessage_Queue:Length()
		ChatThrottler:DeleteOldMessages();
		
		--ChatFrame1:AddMessage("Sent queue length = "..tostring(self.SentChatMessage_Queue:Length()));
		--ChatFrame1:AddMessage("Send queue length = "..tostring(self.SendChatMessage_Queue:Length()));
		
		local f=self.SendChatMessage_Queue:First();
		local timeout=ChatThrottler.SendChatMessage_Tick_Delay; -- default
		if f and f.obj and f.obj.time then
			timeout=self.Time-f.obj.time; -- time since oldest message was sent.
		end
		
		--ChatFrame1:AddMessage("Time values: "..tostring(timeout));
		
		if not self.Queueing and self.SentChatMessage_Queue:Length()+self.SendChatMessage_Queue:Length() > ChatThrottler.RateLimitMessages then
			self.Queueing=true;
			self.Frame.message_delay = ChatThrottler.RateLimitSeconds-timeout;
			--ChatFrame1:AddMessage("over 15 messages in 10 seconds, enabling queueing");
		end
		
		if GetCVar("autoClearAFK") and UnitIsAFK("player") then
			self.Queueing=true;
		end
		
		if not self.Queueing then
			--ChatFrame1:AddMessage("ORIGINAL SendChatMessage "..msg);
			self.oldSendChatMessage(msg, sys, lang, name);
			self.SentMessageTime = self.Time;
			self.Frame.message_delay = self.SendChatMessage_Tick_Interval;
		end
	else
		-- throttling disabled
		return self.oldSendChatMessage(msg, sys, lang, name);
	end
end

function ChatThrottler.OnUpdate(this, elapsed)
	local self=ChatThrottler;
	self.Time = self.Time + elapsed;
	
	if (this.message_delay) then
		this.message_delay = this.message_delay - elapsed;
		if self.Queueing then
			if this.message_delay <=0 then
				self:SendChatMessage_Tick();
				this.message_delay = self.SendChatMessage_Tick_Interval;
			end
			if self.SentMessageTime and (self.Time - self.SentMessageTime > self.Timeout) then
				ChatFrame1:AddMessage("ChatThrottler: Timeout waiting for message");
				if self.SendChatMessage_Queue:First() then
					self.SendChatMessage_Queue:Delete(self.SendChatMessage_Queue:First().obj);
				end
				self.Throttled=false;
				self.SentMessageTime = nil;
			end
		end
	end
	
end

function ChatThrottler:SendChatMessage_Tick()
		
	--if self.LastMessageReceived and self.LastMessageReceived.next and self.LastMessageReceived.next.obj then
	if self.SendChatMessage_Queue:First() then
		if self.Queueing and not self.Throttled then
			--local q=self.LastMessageReceived.next.obj;
			local q=self.SendChatMessage_Queue:First().obj;
			local clearAFK = GetCVar("autoClearAFK");
			
			SetCVar("autoClearAFK", q.autoclearafk); -- set clear afk option as it was when SendChatMessage was called.
			--ChatFrame1:AddMessage("TICK ORIGINAL SendChatMessage "..q.msg);
			self.oldSendChatMessage(q.msg, q.sys, q.lang, q.name); -- call original SendChatMessage
			self.SentMessageTime = self.Time;
			self.Throttled=true; -- is set to false once the message is echoed back from the server
			
			SetCVar("autoClearAFK", clearAFK);
		end
	else
		-- send queue empty, we can allow direct sending of messages again
		self.Throttled = false;
		self.Queueing = false; 
	end
end




function ChatThrottler.newChatFrame_OnEvent(event)
	local self=ChatThrottler;
	if (event == "CHAT_MSG_CHANNEL_NOTICE") and arg1 == "THROTTLED" and self.HideChatEditEvent then
		self.HideChatEditEvent=false;
		return
	end
	self.oldChatFrame_OnEvent(event);
end;






-- Following code implements a linked list. Taken from GuildAdsList.lua and renamed.

ChatThrottlerList = {};
function ChatThrottlerList:new(t)
	if (t==nil) then
		t = {};
	end
	if t.head==nil then
		t.first = { next={} };
		t.idx = {}; -- used to quickly find an object: idx[obj]=list_info
		t.list = {}; -- used to make random access into the list: list[1]=obj, list[2]=obj, ... ([1] is not necessarily the first object in the list)
		t.last = t.first.next;
		t.last.prev = t.first;
	end
	self.__index = self;
	setmetatable(t, self);
	return t;
end

function ChatThrottlerList:Append(obj,data)
	if not self.idx[obj] then
		local new;
		new={ obj=obj, data=data, next=self.last , prev=self.last.prev };
		self.last.prev.next = new;
		self.last.prev = new;
		self.idx[obj]=new;
		table.insert(self.list,obj);
		new.idx=#self.list;
	end
end

function ChatThrottlerList:Delete(obj)
	local t=self.idx[obj];
	if t then
		if t.next then
			t.next.prev = t.prev;
		end
		if t.prev then
			t.prev.next = t.next;
		end
		if #self.list > 1 and t.idx < #self.list then
			self.idx[self.list[#self.list]].idx=t.idx;
			self.list[t.idx]=self.list[#self.list];
		end
		self.list[#self.list]=nil;
		self.idx[obj]=nil;
	end
end

function ChatThrottlerList:DeletePtr(ptr)
	--if 
end

function ChatThrottlerList:DeleteAll()
	self.first.next = self.last;
	self.last.prev = self.first;
	self.idx = {};
	self.list = {};
end

-- This function takes an index (1,2,3,..) and returns the object at that index.
-- The sequence of objects is NOT the same as iterating from list:first to list:last.
function ChatThrottlerList:Get(idx)
	return self.list[idx];
end

function ChatThrottlerList:GetObject(obj)
	local t=self.idx[obj];
	if t then
		return t.obj, t.data;
	end
	return nil,nil;
end

function ChatThrottlerList:Exists(obj)
	return self.idx[obj] and true or nil;
end

function ChatThrottlerList:Length()
	return #self.list;
end

function ChatThrottlerList:First()
	if self.first.next.obj then
		return self.first.next;
	end
	return nil;
end

function ChatThrottlerList:Last()
	return self.last.prev;
end

function ChatThrottlerList:GetRandom()
	if #self.list > 0 then
		return self:Get(math.random(1,#self.list))
	end
	return nil;
end


ChatThrottler:Initialize();
