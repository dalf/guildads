----------------------------------------------------------------------------------
--
-- GuildAdsComm.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GUILDADS_VERSION_PROTOCOL = "2";
GUILDADS_MSG_PREFIX_NOVERSION = "GA\t";

GUILDADS_MSG_PREFIX1= GUILDADS_MSG_PREFIX_NOVERSION..GUILDADS_VERSION_PROTOCOL;
GUILDADS_MSG_PREFIX = GUILDADS_MSG_PREFIX1..":";
	
GUILDADS_MSG_PREFIX_REGEX_UNSPLIT = GUILDADS_MSG_PREFIX.."([0-9]+)([\.|\:])(.*)";

GUILDADS_MSG_TYPE_REQUEST = 1;
GUILDADS_MSG_TYPE_AVAILABLE = 2;

--------------------------------------------------------------------------------
--
-- GuildAdsComm
-- 
---------------------------------------------------------------------------------
GuildAdsComm = AceModule:new({
	IGNOREMYMESSAGE = {
		CF=true,
		OT=true,
		N=true,
		O=true,
		K=true,
		CT=true,
	},
	
	MessageCodecs = {
		M= {	-- Meta
			[1] = "String",		-- version
			[2] = "BigInteger",	-- startTime
			[3] = "Integer"		-- playerCount
		};
		
		CF= {	-- Chat Flag
			[1]	= "String",		-- flag
			[2] = "String"		-- text
		};
		
		S= {	-- Search
			[1] = "String",		-- dataTypeName
			[2] = "String"		-- playerName
		};
		
		R= {	-- Result
			[1] = "String",		-- dataTypeName
			[2] = "String",		-- playerName
			[3] = "String",		-- who
			[4] = "Integer",	-- revision
			[5] = "Integer",	-- weight
			[6] = "Integer",	-- worstRevision
			[7] = "Integer"		-- version
		};
		
		SR= {	-- Search Result
			[1] = "String",		-- dataTypeName
			[2] = "String",		-- playerName
			[3] = "String",		-- who
			[4] = "Integer", 	-- toRevision
			[5] = "Integer"		-- fromRevision
		};
		
		OT= {	-- Open Transaction
			[1] = "String",		-- dataTypeName
			[2] = "String",		-- playerName
			[3] = "Integer",	-- fromRevision
			[4] = "Integer",	-- toRevision
			[5] = "Integer"		-- version
		};
		
		N= {	-- New revision
			[1] = "Integer",	-- revision
			[2] = "Raw",		-- id
			[3] = "Raw"			-- data
		};
		
		O={		-- Old revisions list
			[1] = "String"		-- revisions
		};
		
		K= {	-- Keys
			[1] = "Raw"			-- keys
		};
		
		CT= {	-- Close Transaction
		}
	},
	
	MessageMethod = {
		M	= "ReceiveMeta",
		CF	= "ReceiveChatFlag",
		S	= "ReceiveSearch",
		R	= "ReceiveSearchResultToParent",
		SR	= "ReceiveSearchResult",
		OT	= "ReceiveOpenTransaction",
		N	= "ReceiveNewRevision",
		O	= "ReceiveOldRevision",
		K	= "ReceiveKeys",
		CT	= "ReceiveCloseTransaction"
	},
	
	hasJoined = {},
	playerTree = {},
	playerList = {},
	playerMeta = {},
	channelName = "",
	channelPassword = "",
	
	DTS = {},
	DTSPriority = {},
	
	transactions = {},
	transactionQueue = {},
	searchQueue = {},
	
	delay = {
		Init 					= 15,
		AnswerMeta 				= 10,
		SendSearchAboutMeMin 	= 20,
		Search 					= 2,
		SearchDelay				= 2,		-- updated by self:_UpdateTree
		ExpectedTransaction 	= 25,
		Transaction				= 2,
		TransactionStartRange	= 20
	}
});

local DTSMT = {
	__index = function(t, DTSName)
		if DTSName then
			local mt = getmetatable(t);
			if not mt[DTSName] then
				mt[DTSName] = GuildAdsDTS:new(GuildAdsFakeDataType:new(DTSName));
			end
			return mt[DTSName];
		end
	end
}
setmetatable(GuildAdsComm.DTS, DTSMT);

--------------------------------------------------------------------------------
--
-- Initialize
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:Initialize()
	self.startTime = GuildAdsDB:GetCurrentTime();

	SimpleComm_Initialize(
		self.FilterText,
		self.FilterMessage,
		self.SplitSerialize,
		self.UnsplitSerialize,
		self.OnJoin,
		self.OnLeave,
		self.OnMessage,
		self.ChatFlagListener,
		self.ChannelStatusListener
	);
	
	self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN");
	self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE");
end

function GuildAdsComm:JoinChannel(channel, password, command, alias)
	LoggingChat(true);
	
	self.channelName = channel
	self.channelPassword = password
	
	if SimpleComm_Join(channel, password) then
		SimpleComm_SetAlias(command, alias)
	end
end

function GuildAdsComm:LeaveChannel()
	LoggingChat(false);
	
	if self.channelName then
		SimpleComm_Leave();
	
		self.channelName = nil
		self.channelPassword = nil
	end
end

function GuildAdsComm:GetChannelStatus()
	return SimpleComm_GetChannelStatus();
end

function GuildAdsComm.FilterText(text)
	return string.sub(text, 1, string.len(GUILDADS_MSG_PREFIX_NOVERSION)) == GUILDADS_MSG_PREFIX_NOVERSION;
end

function GuildAdsComm.FilterMessage(text)
	return string.sub(text, 1, string.len(GUILDADS_MSG_PREFIX)) == GUILDADS_MSG_PREFIX;
end

function GuildAdsComm.SplitSerialize(packetNumber, last, obj)
	if last then
		return GUILDADS_MSG_PREFIX .. packetNumber ..":".. obj;
	else
		return GUILDADS_MSG_PREFIX .. packetNumber ..".".. obj;
	end
end

function GuildAdsComm.UnsplitSerialize(str)
	local iStart, _ , packetNumber, last, packet = string.find(str, GUILDADS_MSG_PREFIX_REGEX_UNSPLIT);
	if iStart then
		return packet, tonumber(packetNumber), last==":";
	end
	return str;
end

function GuildAdsComm.OnJoin(self)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnJoin] begin");
	self=self or GuildAdsComm;
	
	-- add my self to the channel
	GuildAdsDB.channel[self.channelName]:addPlayer(GuildAds.playerName);
	
	-- I'm online
	self:SetOnlineStatus(GuildAds.playerName, true);
	
	-- create self.DTS and self.DTSPriority
	ga_table_erase(self.DTSPriority);
	
	for name, profileDT in pairs(GuildAdsDB.profile) do
		self.DTS[name] = GuildAdsDTS:new(profileDT);
		table.insert(self.DTSPriority, self.DTS[name]);
	end
	
	for name, channelDT in pairs(GuildAdsDB.channel[self.channelName]) do
		if type(channelDT)=="table" and channelDT.metaInformations and name~="db" then
			self.DTS[name] = GuildAdsDTS:new(channelDT);
			table.insert(self.DTSPriority, self.DTS[name]);
		end
	end
	
	-- sort self.DTSPriority
	table.sort(self.DTSPriority, GuildAdsDTS.predicate);
	for _, DTS in pairs(self.DTSPriority) do
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, " - "..DTS.dataType.metaInformations.name);
	end
	
	-- listeners
	for name, DTS in pairs(self.DTS) do
		DTS.dataType:registerUpdate(GuildAdsComm, "OnDBUpdate");
	end
	
	-- for plugins
	GuildAdsPlugin_OnChannelJoin();
	
	-- Send Meta
	self:SendMeta();
	
	-- Send search about my data in ten seconds (need a valid search tree)
	GuildAdsTask:AddNamedSchedule("SendSearchAboutMyData", self.delay.Init, nil, nil, self.SendSearchAboutMyData, self);
	
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnJoin] end");
end

function GuildAdsComm.OnLeave(self)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnLeave] begin");
	self=self or GuildAdsComm;
	
	-- for plugins
	GuildAdsPlugin_OnChannelLeave();
	
	-- Delete queues
	self.searchQueueDelay = nil;
	self.transactionQueueDelay = nil;

	for i=1,table.getn(self.searchQueue) do table.remove(self.searchQueue) end
	for i=1,table.getn(self.transactionQueue) do table.remove(self.transactionQueue) end

	for name, DTS in pairs(self.DTS) do
		DTS.dataType:unregisterUpdate(GuildAdsComm);
	end
	
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnLeave] end");
end

function GuildAdsComm.ChatFlagListener(flag, message)
	GuildAdsComm:SendChatFlag();
end

function GuildAdsComm.ChannelStatusListener(status, message)
	GuildAdsPlugin_OnEvent(GAS_EVENT_CHANNELSTATUSCHANGED, status, message);
end

function GuildAdsComm:CHAT_MSG_CHANNEL_JOIN()
	if string.lower(self.channelName)==string.lower(arg9) then
		self.hasJoined[arg2] = GuildAdsDB:GetCurrentTime()
	end
end
	
function GuildAdsComm:CHAT_MSG_CHANNEL_LEAVE()
	-- Un joueur vient de quitter le channel  
	-- Mise à jour du statut online
	if string.lower(self.channelName)==string.lower(arg9) then
		GuildAdsComm:SetOnlineStatus(arg2, false)
		self.hasJoined[arg2] = false
	end
end

--------------------------------------------------------------------------------
--
-- SendSearchAboutMyData
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SendSearchAboutMyData()
	self:SendSearchAboutPlayer(GuildAds.playerName);
end

--------------------------------------------------------------------------------
--
-- SendSearchAboutPlayer
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SendSearchAboutPlayer(playerName)
	for index, DTS in ipairs(self.DTSPriority) do
		self:QueueSearch(DTS, playerName);
	end
end

--------------------------------------------------------------------------------
--
-- SendSearchAboutDTS
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SendSearchAboutDTS(DTS)
	local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
	local count = 0;
	for playerName in pairs(players) do
		if not self.playerTree[playerName] then
			self:QueueSearch(DTS, playerName);
			count = count+1;
		end
	end
	return count;
end

--------------------------------------------------------------------------------
--
-- SendSearchAboutOfflines
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SendSearchAboutOfflines(DTSIndex)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "SendSearchAboutOfflines("..DTSIndex..")");
	if self.DTSPriority[DTSIndex] then
	
		local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
		local DTS = self.DTSPriority[DTSIndex];
		local offlinePlayerCount = 0;
		for playerName in pairs(players) do
			if not self.playerTree[playerName] then
				self:QueueSearch(DTS, playerName);
				offlinePlayerCount = offlinePlayerCount+1;
			end
		end
		
		local delay = offlinePlayerCount*table.getn(self.DTSPriority)*self.delay.SearchDelay+1;
		GuildAdsTask:AddNamedSchedule("SendSearchAboutOfflines", delay, nil, nil, self.SendSearchAboutOfflines, self, DTSIndex+1);
	end
end

--------------------------------------------------------------------------------
--
-- Get online status of a player
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:IsOnLine(playerName)
	return self.playerTree[playerName] and true or false;
end

--------------------------------------------------------------------------------
--
-- Get AFK/DND status
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:GetStatus(playerName)
	return SimpleComm_GetFlag(playerName);
end

--------------------------------------------------------------------------------
--
-- Get tree info about a player (parent player, and child players)
-- index  : .i
-- parent : .p
-- childs : .c1, .c2
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:GetTreeInfo(playerName)
	return self.playerTree[playerName];
end

--------------------------------------------------------------------------------
--
-- Update tree
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:_UpdateTree()
	local p, c;
	table.sort(self.playerList);
	for i, playerName in ipairs(self.playerList) do
		p = i>1 and bit.rshift(i, 1);
		c = bit.lshift(i, 1);
		if type(self.playerTree[playerName]) == "table" then
			self.playerTree[playerName].i = i;
			self.playerTree[playerName].p = self.playerList[p];
			self.playerTree[playerName].c1 = self.playerList[c];
			self.playerTree[playerName].c2 = self.playerList[c+1];
		else
			self.playerTree[playerName] = { 
				i=i, 
				p=self.playerList[p], 
				c1=self.playerList[c], 
				c2=self.playerList[c+1]
			};
		end
	end
	-- Too much math. for a simple thing ?
	self.playerDepth = math.floor(math.log(table.getn(self.playerList))/math.log(2));
	-- Update the search delay
	self.delay.SearchDelay = (self.playerDepth+1)*SIMPLECOMM_OUTBOUND_TICK_DELAY;
end

--------------------------------------------------------------------------------
--
-- Set online status of a player
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SetOnlineStatus(playerName, status)
	if status then
		if (not self.playerTree[playerName]) then
			table.insert(self.playerList, playerName);
			self:_UpdateTree();
			if self.hasJoined[playerName] then
				self.hasJoined[playerName] = nil;
				GuildAdsPlugin_OnEvent(GAS_EVENT_CONNECTION, playerName, true);
			end
			GuildAdsPlugin_OnEvent(GAS_EVENT_ONLINE, playerName, true);
		end
	else
		if (self.playerTree[playerName]) then
			self.playerTree[playerName] = nil;
			local f = function(i, p) 
				if p==playerName then 
					return i 
				end
			end;
			table.remove(self.playerList, table.foreach(self.playerList, f));
			self:_UpdateTree();
			GuildAdsPlugin_OnEvent(GAS_EVENT_ONLINE, playerName, false);
			GuildAdsPlugin_OnEvent(GAS_EVENT_CONNECTION, playerName, false);
		end
	end
end

--------------------------------------------------------------------------------
--
-- Send outbound messages
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SendMeta(toPlayerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendMeta");
	SimpleComm_SendMessage(toPlayerName, GUILDADS_MSG_PREFIX.."M>"..GUILDADS_VERSION..">"..self.startTime..">"..table.getn(self.playerList)..">");
	self:SendChatFlag(toPlayerName);
end

function GuildAdsComm:SendChatFlag(toPlayerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendChatFlag");
	local flag, message = SimpleComm_GetFlag(GuildAds.playerName);
	SimpleComm_SendMessage(toPlayerName, GUILDADS_MSG_PREFIX.."CF>"..(flag or "")..">"..(message or "")..">");
end

function GuildAdsComm:SendSearch(dataType, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendSearch("..dataType.metaInformations.name..","..playerName..")");
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."S>"..dataType.metaInformations.name..">"..playerName..">");
end

function GuildAdsComm:SendSearchResultToParent(parentPlayerName, dataType, playerName, who, revision, weight, worstRevision, version)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendRevisionWhisper["..parentPlayerName.."]("..dataType.metaInformations.name..","..playerName..")");
	SimpleComm_SendMessage(parentPlayerName, GUILDADS_MSG_PREFIX.."R>"..dataType.metaInformations.name..">"..playerName..">"..who..">"..revision..">"..weight..">"..worstRevision..">"..version..">");
end

function GuildAdsComm:SendSearchResult(dataType, playerName, who, revision, worstRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendSearchResult("..dataType.metaInformations.name..","..playerName..")");
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."SR>"..dataType.metaInformations.name..">"..playerName..">"..who..">"..revision..">"..worstRevision..">");
end

function GuildAdsComm:SendOpenTransaction(dataType, playerName, fromRevision, toRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendOpenTransaction("..dataType.metaInformations.name..","..playerName..")");
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."OT>"..dataType.metaInformations.name..">"..playerName..">"..fromRevision..">"..toRevision..">"..dataType.metaInformations.version..">");
end

function GuildAdsComm:SendRevision(dataType, playerName, revision, id, data)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendNewRevision("..dataType.metaInformations.name..","..playerName..","..tostring(id)..")");
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."N>"..revision..">"..GuildAdsCodecs[dataType.schema.id].encode(id)..">"..GuildAdsCodecs[dataType.metaInformations.name.."Data"].encode(data)..">");
end

function GuildAdsComm:SendKeys(dataType, playerName, keys)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendKeys("..dataType.metaInformations.name..","..playerName..")");
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."K>"..GuildAdsCodecs[dataType.metaInformations.name.."Keys"].encode(keys)..">");
end

function GuildAdsComm:SendOldRevision(dataType, playerName, revisions)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendOldRevision("..dataType.metaInformations.name..","..playerName..")");
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."O>"..table.concat(revisions, "/")..">");
end

function GuildAdsComm:SendCloseTransaction(dataType, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendCloseTransaction("..dataType.metaInformations.name..","..playerName..")");
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."CT");
end

--------------------------------------------------------------------------------
--
-- Parse inbound messages
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:CallReceive(channelName, personName, command, ...)
	-- ignore transaction from myself
 	if personName == GuildAds.playerName and GuildAdsComm.IGNOREMYMESSAGE[command] then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Ignore message from my self, command="..tostring(command));
		return;
	end
	
	-- call Receive* method
	local d = GuildAdsComm.MessageCodecs[command];
	
	if GuildAdsComm.MessageMethod[command] then
		GuildAdsComm[GuildAdsComm.MessageMethod[command]](
			self,
			channelName,
			personName,
			d[1] and GuildAdsCodecs[d[1]].decode(select(1, ...)),
			d[2] and GuildAdsCodecs[d[2]].decode(select(2, ...)),
			d[3] and GuildAdsCodecs[d[3]].decode(select(3, ...)),
			d[4] and GuildAdsCodecs[d[4]].decode(select(4, ...)),
			d[5] and GuildAdsCodecs[d[5]].decode(select(5, ...)),
			d[6] and GuildAdsCodecs[d[6]].decode(select(6, ...)),
			d[7] and GuildAdsCodecs[d[7]].decode(select(7, ...))
		);
	end
end

function GuildAdsComm.OnMessage(personName, text, channelName)
	local prefix, text = strsplit(":", text, 2);
	if prefix ~= GUILDADS_MSG_PREFIX1 then
		return;
	end
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, text);
	GuildAdsComm:CallReceive(channelName, personName, strsplit(">", text));
end

--------------------------------------------------------------------------------
--
-- Receive inbound messages
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:ReceiveMeta(channelName, personName, version, startTime, playerCount)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveMeta("..personName..")");
	-- store information about this player (useful ?)
	self.playerMeta[personName] = {
		onlineSince = startTime;
		version = version
	}
	if personName ~= GuildAds.playerName then
		-- Add this player to the current channel
		GuildAdsDB.channel[GuildAds.channelName]:addPlayer(personName);
		-- This player is online
		self:SetOnlineStatus(personName, true);
		if channelName then
			-- someone has joined, and he is building the player tree : stop search/transaction during this period
			self:Standby(self.delay.Init);
			-- send my information
			GuildAdsTask:AddNamedSchedule("SendMeta", random(self.delay.AnswerMeta), nil, nil, self.SendMeta, self, personName);
			-- delete and queue again all searchs
			for _, DTS in pairs(self.DTS) do
				DTS:RestartAllSearches()
			end
			-- send my search about my data
			local delay = self.playerTree[GuildAds.playerName].i*(self.delay.Search*table.getn(self.DTSPriority))+self.delay.SendSearchAboutMeMin;
			GuildAdsTask:AddNamedSchedule("SendSearchAboutMyData", delay, nil, nil, self.SendSearchAboutMyData, self);
		end
	end
	-- Offline synchronization
	local delay = table.getn(self.playerList)*table.getn(self.DTSPriority)*self.delay.Search+self.delay.SendSearchAboutMeMin;
	GuildAdsTask:AddNamedSchedule("SendSearchAboutOfflines", delay, nil, nil, self.SendSearchAboutOfflines, self, 1);
end

function GuildAdsComm:ReceiveChatFlag(channelName, personName, flag, text)
	SimpleComm_SetFlag(personName, flag, text);
end

function GuildAdsComm:ReceiveSearch(channelName, personName, dataTypeName, playerName)
	local DTS = self.DTS[dataTypeName];
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveSearch("..tostring(DTS)..","..playerName..")");
		self:DeleteDuplicateSearch(DTS, playerName);
		DTS:ReceiveSearch(playerName)
		if personName~=GuildAds.playerName then
			self:Standby(self.delay.SearchDelay)
		end
		-- Add playerName to the current channel
		GuildAdsDB.channel[GuildAds.channelName]:addPlayer(playerName);
end

function GuildAdsComm:ReceiveSearchResultToParent(channelName, personName, dataTypeName, playerName, who, revision, weight, worstRevision, version)
	local DTS = self.DTS[dataTypeName];
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveRevision("..tostring(DTS)..","..playerName..")="..who.."("..worstRevision.."->"..revision..") v"..tostring(version));
	DTS:ReceiveRevision(personName, playerName, who, revision, weight, worstRevision, version)
end

function GuildAdsComm:ReceiveSearchResult(channelName, personName, dataTypeName, playerName, who, toRevision, fromRevision)
	local DTS = self.DTS[dataTypeName];
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveSearchResult("..tostring(DTS)..","..playerName..")="..who.."("..fromRevision.."->"..toRevision..")");
	-- add an expected transaction
	if (who ~= GuildAds.playerName) and (fromRevision<toRevision) then
		-- TODO : solve the deadlock problem : 
		-- two search result, one say me to send an transaction, another say John will send an transaction
		-- me and John are waiting each others.
		self:Standby(self.delay.ExpectedTransaction);
	end
	-- parse message
	DTS:ReceiveSearchResult(playerName, who, fromRevision, toRevision)
end

function GuildAdsComm:ReceiveOpenTransaction(channelName, personName, dataTypeName, playerName, fromRevision, toRevision, version)
	local DTS = self.DTS[dataTypeName];
	if self.transactions[personName] then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Duplicate|r OPEN TRANSACTION from "..personName.." (already open)");
	end
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveOpenTransaction("..tostring(DTS)..","..playerName..","..fromRevision..")");
	-- update self.transactionQueue
	self:DeleteDuplicateTransaction(DTS, playerName, fromRevision, toRevision)
	-- add transaction
	self.transactions[personName] = {
		playerName = playerName,
		dataTypeName = dataTypeName,
		fromRevision = fromRevision,
		toRevision = toRevision,
		lmt=time()
	}
	self.transactions[personName].__index = self.transactions[personName];
	-- parse message
	DTS:ReceiveOpenTransaction(self.transactions[personName], playerName, fromRevision, toRevision, version or 1)
end

function GuildAdsComm:ReceiveNewRevision(channelName, personName, revision, idSerialized, dataSerialized)
	if self.transactions[personName] then
		local t = self.transactions[personName];
		local DTS = self.DTS[t.dataTypeName];
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveNewRevision("..tostring(DTS)..","..t.playerName..","..tostring(id)..")");
		t.lmt = time();
		local id, data;
		if t._valid then
			id = GuildAdsCodecs[DTS.dataType.schema.id].decode(idSerialized);
			data = GuildAdsCodecs[t.dataTypeName.."Data"].decode(dataSerialized);
		end
		DTS:ReceiveNewRevision(t, revision, id, data)
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r NEW from "..playerName.." (no transaction)");
	end
end

function GuildAdsComm:ReceiveOldRevision(channelName, personName, revisionsSerialized)
	if self.transactions[personName] then
		local t = self.transactions[personName];
		local DTS = self.DTS[t.dataTypeName];
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveOldRevisions("..tostring(DTS)..","..t.playerName..")");
		t.lmt = time();
		local revisions = {};
		local revision;
		for revision in string.gmatch(revisionsSerialized, "([^\/]*)/?$?") do
			revision = tonumber(revision);
			if revision then
				revisions[tonumber(revision)] = true;
			end
		end
		DTS:ReceiveOldRevisions(t, revisions)
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r OLD from "..personName.." (no transaction)");
	end
end

function GuildAdsComm:ReceiveKeys(channelName, personName, keys)
	if self.transactions[personName] then
		local t = self.transactions[personName];
		local DTS = self.DTS[t.dataTypeName];
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveKeys("..tostring(DTS)..","..t.playerName..")");
		t.lmt = time();
		local keys = GuildAdsCodecs[t.dataTypeName.."Keys"].decode(keys);
		DTS:ReceiveKeys(t, keys);
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r KEYS from "..personName.." (no transaction)");
	end
end

function GuildAdsComm:ReceiveCloseTransaction(channelName, personName)
	if self.transactions[personName] then
		local t = self.transactions[personName];
		local DTS = self.DTS[t.dataTypeName];
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveCloseTransaction("..tostring(DTS)..","..personName..")");
		DTS:ReceiveCloseTransaction(t)
		self.transactions[personName] = nil;
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r CLOSE TRANSACTION from "..personName.." (no transaction)");
	end
end

--------------------------------------------------------------------------------
--
-- When database is updated
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:OnDBUpdate(dataType, playerName, id)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"[GuildAdsComm:OnDBUpdate]"..dataType.metaInformations.name..","..playerName);
	self:QueueSearch(self.DTS[dataType.metaInformations.name], playerName);
end

--------------------------------------------------------------------------------
--
-- About search/transaction queues
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:DeleteDuplicateTransaction(DTS, playerName, fromRevision, toRevision)
	local i = 1;
	while self.transactionQueue[i] do
		local transaction = self.transactionQueue[i];
		if 		(transaction.DTS==DTS)
			and (transaction.playerName==playerName)
			and (		(transaction.toRevision<=toRevision)	-- better revision
					or  (transaction.fromRevision>fromRevision)	-- start from an older revision
				) then
			table.remove(self.transactionQueue, i);
		else
			i=i+1;
		end
	end
end

function GuildAdsComm:DeleteDuplicateSearch(DTS, playerName)
	local i=1;
	while self.searchQueue[i] do
		local search = self.searchQueue[i];
		if 		(search.DTS==DTS)
			and	(search.playerName==playerName)
		then
			table.remove(self.searchQueue, i);
		else
			i = i + 1;
		end
	end	
end

function GuildAdsComm:FindSearch(DTS, playerName)
	local i=1;
	while self.searchQueue[i] do
		local search = self.searchQueue[i];
		if 		(search.DTS==DTS)
			and	(search.playerName==playerName)
		then
			return true;
		end
		i = i + 1;
	end
end

function GuildAdsComm:QueueTransaction(DTS, playerName, fromRevision, toRevision)
	self:DeleteDuplicateTransaction(DTS, playerName, fromRevision, toRevision);
	table.insert(self.transactionQueue, { DTS=DTS, playerName=playerName, fromRevision=fromRevision, toRevision=toRevision });
	if not self.transactionQueueDelay then
		self.transactionQueueDelay = self.delay.Transaction+random(self.delay.TransactionStartRange);
	end
end

function GuildAdsComm:QueueSearch(DTS, playerName)
	if not self:FindSearch(DTS, playerName) then
		table.insert(self.searchQueue, { DTS=DTS, playerName=playerName} );
		if not self.searchQueueDelay then
			self.searchQueueDelay = self.delay.Search;
		end
	end
end

function GuildAdsComm:Standby(delay)
	if delay>(self.standbyDelay or 0) then
		self.standbyDelay = delay - (self.standbyDelay or 0) 
	end
end

function GuildAdsComm:ProcessQueues(elapsed)
	if elapsed>0.75 then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"|cffff1e00Lag !!!|r");
	end
	
	-- Standby (expected transaction, someone has joined the channel etc)
	if self.standbyDelay then
		self.standbyDelay = self.standbyDelay - elapsed;
		if self.standbyDelay<0 then
			self.standbyDelay = nil
		else
			return;
		end
	end
	
	-- Is there some opened transactions ?
	if next(self.transactions) then
		local t = time();
		
		-- timeout about one opened transaction
		local k, v = next(self.transactions);
		if k then
			if v.lmt+20<t then
				self.transactions[k] = nil;
				GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"|cffff1e00Timeout|r opened transaction from "..k);
			end
		end
		
		-- don't flood the channel with my transaction/search
		return;
	end
	
	-- First : send transaction
	if self.transactionQueueDelay then
		self.transactionQueueDelay = self.transactionQueueDelay - elapsed;
		if self.transactionQueueDelay<=0 and self.transactionQueue[1] then
			local update = self.transactionQueue[1];
			table.remove(self.transactionQueue, 1);
			update.DTS:SendTransaction(update.playerName, update.fromRevision);
			
			if self.transactionQueue[1] then
				self.transactionQueueDelay = self.delay.Transaction;
			else
				self.transactionQueueDelay = nil;
			end
		end
	else
		-- No transaction ? then send search
		if self.searchQueueDelay then
			self.searchQueueDelay = self.searchQueueDelay - elapsed;
			if self.searchQueueDelay<=0 and self.searchQueue[1] then
				local search = self.searchQueue[1];
				table.remove(self.searchQueue, 1);
				search.DTS:SendSearch(search.playerName);
				
				if self.searchQueue[1] then
					self.searchQueueDelay = self.delay.Search;
				else
					self.searchQueueDelay = nil;
				end
			end
		end
	end
end
