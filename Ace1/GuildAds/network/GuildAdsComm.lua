----------------------------------------------------------------------------------
--
-- GuildAdsComm.lua
--
-- Author: Zarkan@Ner'zhul-EU, Fkaï@Ner'zhul-EU, Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

--[[
Bug
	* Erreur ligne 148, et 168 dans le code lua de la réput (en faisant tous/aucun)
Todo :
	Add to field to SR/R messages : number of player ignoring this search (even if this is not fully implemented now, it's will avoid to break the protocol after)
	The curse-gaming (etc..) zip : all ChatDebug are deleted to avoid memory/cpu usage.
	Clean up :
		Move GuildAdsDB:FormatTime to the UI
		Replace some "if ... error... end" by "assert"
]]

GUILDADS_VERSION_PROTOCOL = "5";
GUILDADS_MSG_PREFIX_NOVERSION = "GA\t";

GUILDADS_MSG_PREFIX1= GUILDADS_MSG_PREFIX_NOVERSION..GUILDADS_VERSION_PROTOCOL;
GUILDADS_MSG_PREFIX = GUILDADS_MSG_PREFIX1..":";
	
GUILDADS_MSG_PREFIX_REGEX_UNSPLIT = GUILDADS_MSG_PREFIX.."([0-9]+)([\.|\:])(.*)";
GUILDADS_MSG_PREFIX_PACK = GUILDADS_MSG_PREFIX.."&";
GUILDADS_MSG_PACK_SEPARATOR = "\007";
GUILDADS_MSG_REGEX_PACK_ITERATOR = "([^"..GUILDADS_MSG_PACK_SEPARATOR.."]+)";
assert(GUILDADS_MSG_PACK_SEPARATOR:len() == 1, "GUILDADS_MSG_PACK_SEPARATOR:()len > 1")

--------------------------------------------------------------------------------
--
-- GuildAdsComm
-- 
---------------------------------------------------------------------------------
GuildAdsComm = AceModule:new({
	IGNOREMESSAGE = {
		HS=true,
		HR=true,
		HSR=true,
		S=true,
		R=true,
		SR=true,
		OT=true,
		N=true,
		O=true,
		K=true,
		CT=true,
		T=true
	},
	
	MessageCodecs = {
		M= {	-- Meta
		 	[1] = "String", 	-- SVN revision
			[2] = "String", 	-- user friendly version
			[3] = "BigInteger",	-- startTime
			[4] = "Integer",	-- playerCount
			[5] = "String"		-- databaseId
		};
		
		CF= {	-- Chat Flag
			[1]	= "String",		-- flag
			[2] = "String"		-- text
		};
		
		HS= {	-- Hash Search
			[1] = "String",		-- Hash Path
			[2] = "String"		-- Hash sequence (16 parts)
		};
		
		HR= {	-- Hash Result
			[1] = "String",		-- Hash Path
			[2] = "Integer",		-- Hash Changed (16 bits, 1=changed, 0=not changed)
			[3] = "Integer",		-- Who: name=self.playerList[who] or who=self.playerTree[index]
			[4] = "Integer",		-- number of ID's 'who' has for this path
			[5] = "Integer",		-- number of players, 'who' has been selected from (to ensure even probabilities)
		};
		
		HSR= {	-- Hash Search Result
			[1] = "String",		-- Hash Path
			[2] = "Integer",		-- Hash Changed (16 bits, 1=changed, 0=not changed)
			[3] = "Integer",		-- Who
			[4] = "Integer",		-- number of ID's 'who' has for this path
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
		};
		
		T= {	-- Move the token to the next player
			[1] = "Integer"		-- new token position
		};
	},
	
	MessageMethod = {
		M	= "ReceiveMeta",
		CF	= "ReceiveChatFlag",
		HS	= "ReceiveHashSearch",
		HR	= "ReceiveHashSearchResultToParent",
		HSR	= "ReceiveHashSearchResult",
		S	= "ReceiveSearch",
		R	= "ReceiveSearchResultToParent",
		SR	= "ReceiveSearchResult",
		OT	= "ReceiveOpenTransaction",
		N	= "ReceiveNewRevision",
		O	= "ReceiveOldRevision",
		K	= "ReceiveKeys",
		CT	= "ReceiveCloseTransaction",
		T	= "ReceiveMoveToken"
	},
	
	hasJoined = {},
	playerTree = {},
	playerList = {},
	playerMeta = {},
	playerChatFlags = {},
	databaseIdList = {},
	token = 1,
	channelName = "",
	channelPassword = "",
	
	minimumRevision = GUILDADS_REVISION_NUMBER,
	maximumRevision = GUILDADS_REVISION_NUMBER,
	
	DTS = {},
	
	transactions = {},
	searchQueue = GuildAdsList:new(),
	hashSearchQueue={ GuildAdsList:new(), GuildAdsList:new() };
	
	delay = {
		Init 					= 14,
		AnswerMeta 				= 10,
		Search 					= 2,
		SearchDelay				= 2,		-- updated by self:_UpdateTree
		Transaction				= 0.5,
		TransactionDelay		= 40,
		Timeout					= 15,		-- timeout should now trigger for most portal crossings
		HashDelay				= 60,		-- all databases are identical. Wait a while before searching again.
		MoveToken				= 5			-- delay to wait before actually moving the token
	},
	
	-- to check the token
	state = "Init",
	stateTime = 0,
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

	-- Store latest known GuildAds revision
	self.latestRevision = GUILDADS_REVISION;
	self.latestRevisionString = GUILDADS_REVISION_STRING;

	SimpleComm_Initialize(
		self.FilterText,
		self.FilterMessage,
		self.SplitSerialize,
		self.UnsplitSerialize,
		self.PackedMessages,
		self.UnpackMessagesIterator,
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

function GuildAdsComm.PackedMessages(messages)
	return GUILDADS_MSG_PREFIX_PACK..table.concat(messages, GUILDADS_MSG_PACK_SEPARATOR);
end

local unpackIterator = function(text, start)
	if not start then
		if text:sub(1, GUILDADS_MSG_PREFIX_PACK:len()) ~= GUILDADS_MSG_PREFIX_PACK then
			return
		end
		start = GUILDADS_MSG_PREFIX_PACK:len()+1;
	end
	local s, e = string.find(text, GUILDADS_MSG_REGEX_PACK_ITERATOR, start);
	if s and e then
		return e+1, text:sub(s, e);
	end
end

function GuildAdsComm.UnpackMessagesIterator(text)
	return unpackIterator, text;
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
	local self=self or GuildAdsComm;
	
	-- add my self to the channel
	GuildAdsDB.channel[self.channelName]:addPlayer(GuildAds.playerName);
	
	-- I'm online
	self:SetOnlineStatus(GuildAds.playerName, true);
	
	-- create self.DTS
	for name, profileDT in pairs(GuildAdsDB.profile) do
		self.DTS[name] = GuildAdsDTS:new(profileDT);
	end
	
	for name, channelDT in pairs(GuildAdsDB.channel[self.channelName]) do
		if type(channelDT)=="table" and channelDT.metaInformations and name~="db" then
			self.DTS[name] = GuildAdsDTS:new(channelDT);
		end
	end
	
	-- listeners
	for name, DTS in pairs(self.DTS) do
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, " - %s", DTS.dataType.metaInformations.name);
		DTS.dataType:registerUpdate(GuildAdsComm, "OnDBUpdate");
	end
	
	-- for plugins
	GuildAdsPlugin_OnChannelJoin();

	-- create hash tree. This will unfortunately cause a noticable lag spike (probably 0.3 - 1 seconds depending on number of players in database)
	GuildAdsHash:Initialize();
	GuildAdsHash.tree=GuildAdsHash:CreateHashTree();
	
	-- reset the minimum and maximum version on the channel (updated when the M message is received from other players)
	self.minimumRevision = GUILDADS_REVISION_NUMBER;
	self.maximumRevision = GUILDADS_REVISION_NUMBER;
	
	-- Send Meta
	self:SendMeta();
	
	-- after initialization : tick
	GuildAdsTask:AddNamedSchedule("Tick", self.delay.Init, nil, nil, self.EnableFullProtocol, self);
	
	-- set state
	self:SetState("JOIN");
	
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnJoin] end");
end

function GuildAdsComm.OnLeave(self)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnLeave] begin");
	self=self or GuildAdsComm;
	
	-- set state
	self:SetState("LEAVE");
	
	-- for plugins
	GuildAdsPlugin_OnChannelLeave();

	-- clear the search queue
	--for i=1,table.getn(self.searchQueue) do table.remove(self.searchQueue) end
	self.searchQueue:DeleteAll();
	self.hashSearchQueue[1]:DeleteAll();
	self.hashSearchQueue[2]:DeleteAll();
	
	-- unregister the datatype listeners
	for name, DTS in pairs(self.DTS) do
		DTS.dataType:unregisterUpdate(GuildAdsComm);
	end
	
	GuildAdsComm:DisableFullProtocol()
	
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
function GuildAdsComm:GetChatFlag(playerName)
	if not self.playerChatFlags[playerName] then
		return "", ""
	else
		return self.playerChatFlags[playerName].flag, self.playerChatFlags[playerName].text
	end
end

function GuildAdsComm:SetChatFlag(playerName, flag, text)
	self.playerChatFlags[playerName] = {
		flag = flag,
		text = text
	}
end

--------------------------------------------------------------------------------
--
-- Update tree
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:_UpdateTree()
	local p, c;
	self.databaseIdList = {};
	table.sort(self.playerList);
	for i, playerName in ipairs(self.playerList) do
		-- update self.databaseIdList
		if playerName ~= GuildAds.playerName then
			table.insert(self.databaseIdList, self.playerMeta[playerName].databaseId);
		end
		-- update self.playerTree
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
		-- change to online
		if (not self.playerTree[playerName]) then
			table.insert(self.playerList, playerName);
			self:_UpdateTree();
			self.token = 1;
			if self.hasJoined[playerName] then
				self.hasJoined[playerName] = nil;
				GuildAdsPlugin_OnEvent(GAS_EVENT_CONNECTION, playerName, true);
			end
			GuildAdsPlugin_OnEvent(GAS_EVENT_ONLINE, playerName, true);
		end
	else
		-- change to offline
		if (self.playerTree[playerName]) then
			self.playerTree[playerName] = nil;
			local f = function(i, p) 
				if p==playerName then 
					return i 
				end
			end;
			table.remove(self.playerList, table.foreach(self.playerList, f));
			self:_UpdateTree();
			if self.token>#self.playerList then
				self.token = 1;
			end
			GuildAdsPlugin_OnEvent(GAS_EVENT_ONLINE, playerName, false);
			GuildAdsPlugin_OnEvent(GAS_EVENT_CONNECTION, playerName, false);
		end
	end
end

--------------------------------------------------------------------------------
--
-- Set the current state
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SetState(state, timeout)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Set state \"%s\", timeout=%s", state, tostring(timeout));
	local now = time();
	self.state = state;
	self.stateTime = now;
	if timeout then
		GuildAdsTask:AddNamedSchedule("CheckTimeout", timeout, nil, nil, self.CheckTimeout, self, state, now);
	else
		GuildAdsTask:DeleteNamedSchedule("CheckTimeout");
	end
end

function GuildAdsComm:CheckTimeout(state, stateTime)
	if state==self.state and stateTime==self.stateTime then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Timeout for state: %s", state);
		-- move token to the next 
		local newToken = 1;
		if self.token<#self.playerList then
			newToken = self.token + 1;
		end
		if self.playerList[newToken]==GuildAds.playerName then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "I send the new token position", state);
			self:SendMoveToken(newToken);
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "%s will send the new token position", self.playerList[newToken] or "");
		end
		--self:MoveToken(newToken);
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "NO Timeout for state: %s=%s, %s=%s", state, self.state, stateTime, self.stateTime);
	end
end

--------------------------------------------------------------------------------
--
-- Move the token
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:MoveToken(index)
	-- move the token
	if index then
		self.token = index
	else
		if self.token<#self.playerList then
			self.token = self.token + 1;
		else
			self.token = 1
		end
	end
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "MoveToken %s", tostring(self.token));
	self:Tick();
end

function GuildAdsComm:MoveTokenDelayed(index)
	if self.moveToken then
		if index<self.moveToken then
			self.moveToken=index;
		end
	else
		self.moveToken=index;
	end
	GuildAdsTask:DeleteNamedSchedule("SendSearch");
	GuildAdsTask:DeleteNamedSchedule("SendHashSearch");
	GuildAdsTask:DeleteNamedSchedule("MoveToken"); -- necessary? dont think so
	GuildAdsTask:AddNamedSchedule("MoveToken", self.delay.MoveToken, nil, nil, self.MoveAndDeleteToken, self, nil, nil);
end

function GuildAdsComm:MoveAndDeleteToken()
	self:MoveToken(self.moveToken);
	self.moveToken=nil;
end
--------------------------------------------------------------------------------
--
-- Tick
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:Tick()
	if  #self.playerList>1 then
		if self.playerList[self.token]==GuildAds.playerName then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Tick: I have the token");
			-- If I have token, then I will send a search

			local nextSearch, nextSearchDT, nextSearchP;
			if self.searchQueue:Length() > 0 then
				-- uses searches from the revision search queue first
				nextSearch = self.searchQueue:First();
				self.searchQueue:Delete(nextSearch);
				nextSearchP = nextSearch.data.playerName;
				nextSearchDT = nextSearch.data.DTS.dataType;
				GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Next search : revision queue (%s,%s)",nextSearchDT.metaInformations.name, nextSearchP);
				GuildAdsTask:AddNamedSchedule("SendSearch", self.delay.Search, nil, nil, self.SendSearch, self, nextSearchDT, nextSearchP);
			else
				-- revision search queue empty.
				-- make hash search to find paths (hashIDs) that have IDs (to construct new revision searches with)
				-- ALWAYS use the longest path in the queue.
				-- if queue is empty, use an empty path = {}
				local path, hashSequence, element;
				if self.hashSearchQueue[2]:Length() > 0 then -- check longest path queue first
					path = GuildAdsComm.hashSearchQueue[2]:GetRandom(); -- pick a random element (to avoid deadlocks)
					GuildAdsComm.hashSearchQueue[2]:Delete(path); -- result will be a full path (which will probably give rise to revision searches)
					--GuildAdsComm:DequeueHashSearch(path); -- can be used instead of the above line but is slower.
				elseif self.hashSearchQueue[1]:Length() > 0 then
					path = GuildAdsComm.hashSearchQueue[1]:GetRandom();
					GuildAdsComm.hashSearchQueue[1]:Delete(path);
				else
					path=""; -- search queue empty: Start hash search from the root
				end
				GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Next search : hash search: %s", tostring(path));
				GuildAdsTask:AddNamedSchedule("SendHashSearch", self.delay.Search, nil, nil, self.SendHashSearch, self, path, nil);
			end
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Tick: I DON'T have the token");
			self:SetState("WAITING_SEARCH_OR_MOVE", self.delay.Search+self.delay.Timeout);
		end
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Tick: I'm alone");
		self:SetState("ALONE");
	end
end

--------------------------------------------------------------------------------
--
-- Check if the player who has the token have a problem
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:CheckToken()
	local now = time();
	if self.lastReceivedTime-self.tokenTime<1 then
		
	end
end

--------------------------------------------------------------------------------
--
-- Send outbound messages
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SendMeta(toPlayerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendMeta");
	SimpleComm_SendMessage(toPlayerName, GUILDADS_MSG_PREFIX.."M>"..GUILDADS_REVISION..">"..GUILDADS_REVISION_STRING..">"..self.startTime..">"..(#self.playerList)..">"..GuildAdsDB.databaseId..">");
	self:SendChatFlag(toPlayerName);
end

function GuildAdsComm:SendChatFlag(toPlayerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendChatFlag");
	local flag, message = SimpleComm_GetFlag(GuildAds.playerName);
	SimpleComm_SendMessage(toPlayerName, string.format("%sCF>%s>%s>", GUILDADS_MSG_PREFIX, (flag or ""), (message or "")));
end

function GuildAdsComm:SendHashSearch(path)
	local hashSequence = GuildAdsHash:GetBase64Hash(GuildAdsHash.tree[path]); -- always use the newest hash key
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendHashSearch(%s, %s)", path, hashSequence);
	SimpleComm_SendMessage(nil, string.format("%sHS>%s>%s>", GUILDADS_MSG_PREFIX, path, hashSequence));
end

function GuildAdsComm:SendHashSearchResultToParent(parentPlayerName, path, hashChanged, who, amount, numplayers)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendHashSearchResultWhisper[%s](%s, %i)", parentPlayerName, path, hashChanged);
	SimpleComm_SendMessage(parentPlayerName, string.format("%sHR>%s>%i>%i>%i>%i>", GUILDADS_MSG_PREFIX, path, hashChanged, who, amount, numplayers));
end

function GuildAdsComm:SendHashSearchResult(path, hashChanged, who, amount)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendHashSearchResult(%s, %i)", path, hashChanged);
	SimpleComm_SendMessage(nil, string.format("%sHSR>%s>%i>%i>%i>", GUILDADS_MSG_PREFIX, path, hashChanged, who, amount));
end

function GuildAdsComm:SendSearch(dataType, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendSearch(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, string.format("%sS>%s>%s>", GUILDADS_MSG_PREFIX, dataType.metaInformations.name, playerName));
end

function GuildAdsComm:SendSearchResultToParent(parentPlayerName, dataType, playerName, who, revision, weight, worstRevision, version)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendRevisionWhisper[%s](%s, %s)", parentPlayerName, dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(parentPlayerName, string.format("%sR>%s>%s>%s>%s>%i>%i>%i>", GUILDADS_MSG_PREFIX, dataType.metaInformations.name, playerName, who, revision, weight, worstRevision, version));
end

function GuildAdsComm:SendSearchResult(dataType, playerName, who, revision, worstRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendSearchResult(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, string.format("%sSR>%s>%s>%s>%i>%i>", GUILDADS_MSG_PREFIX, dataType.metaInformations.name, playerName, who, revision, worstRevision));
end

function GuildAdsComm:SendOpenTransaction(dataType, playerName, fromRevision, toRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendOpenTransaction(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."OT>"..dataType.metaInformations.name..">"..playerName..">"..fromRevision..">"..toRevision..">"..dataType.metaInformations.version..">");
end

function GuildAdsComm:SendRevision(dataType, playerName, revision, id, data)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendNewRevision(%s, %s, %s)", dataType.metaInformations.name, playerName, tostring(id));
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."N>"..revision..">"..GuildAdsCodecs[dataType.schema.id].encode(id)..">"..GuildAdsCodecs[dataType.metaInformations.name.."Data"].encode(data)..">");
end

function GuildAdsComm:SendKeys(dataType, playerName, keys)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendKeys(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."K>"..GuildAdsCodecs[dataType.metaInformations.name.."Keys"].encode(keys)..">");
end

function GuildAdsComm:SendOldRevision(dataType, playerName, revisions)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendOldRevision(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."O>"..table.concat(revisions, "/")..">");
end

function GuildAdsComm:SendCloseTransaction(dataType, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendCloseTransaction(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, GUILDADS_MSG_PREFIX.."CT>");
end

function GuildAdsComm:SendMoveToken(index)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendMoveToken");
	SimpleComm_SendMessage(nil, string.format("%sT>%s>", GUILDADS_MSG_PREFIX, index or ""));
end

--------------------------------------------------------------------------------
--
-- Parse inbound messages
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:CallReceive(channelName, personName, command, ...)
	-- ignore message
 	if GuildAdsComm.IGNOREMESSAGE[command] then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Ignore message, command=%s", tostring(command));
		return;
	end
	
	-- call Receive* method
	local d = GuildAdsComm.MessageCodecs[command];
	local m = GuildAdsComm.MessageMethod[command];
	if m then
		GuildAdsComm[m](
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

function GuildAdsComm:EnableFullProtocol()
	GuildAdsComm.IGNOREMESSAGE={}; -- maybe empty the existing table? shouldn't be necessary
	self:Tick();
end

function GuildAdsComm:DisableFullProtocol()
	GuildAdsComm.IGNOREMESSAGE = {
		HS=true,
		HR=true,
		HSR=true,
		S=true,
		R=true,
		SR=true,
		OT=true,
		N=true,
		O=true,
		K=true,
		CT=true,
		T=true
	};
end
--------------------------------------------------------------------------------
--
-- Receive inbound messages
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:ReceiveMeta(channelName, personName, revision, revisionString, startTime, playerCount, databaseId)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveMeta(%s)", personName);
	-- store information about this player
	self.playerMeta[personName] = {
		onlineSince = startTime;
		version = revision;
		versionString = revisionString;
		databaseId = databaseId
	}
	-- update minimumRevision/maximumRevision.
	local revision_number = tonumber((revision or "1"):match("(%d+)"));
	self.minimumRevision = math.min(revision_number, self.minimumRevision);
	self.maximumRevision = math.max(revision_number, self.maximumRevision);
	-- warn the player if there is new version.
	if revision and self.latestRevision and revision>self.latestRevision then
		self.latestRevision = revision;
		GuildAds.cmd:msg("There is a newer version of GuildAds available: "..tostring(revisionString));
	end
	if personName ~= GuildAds.playerName then
		-- Add this player to the current channel
		GuildAdsDB.channel[GuildAds.channelName]:addPlayer(personName);
		-- This player is online
		self:SetOnlineStatus(personName, true);
		if channelName then
			-- someone has joined, and he is building the player tree : stop search/transaction during this period
			for _, DTS in pairs(self.DTS) do
				DTS:DeleteAllSearches();
			end
			GuildAdsTask:DeleteNamedSchedule("SendSearch");
			GuildAdsHash:DeleteAllSearches();
			GuildAdsTask:DeleteNamedSchedule("SendHashSearch");
			GuildAdsTask:DeleteNamedSchedule("MoveToken");
			-- send my information
			GuildAdsTask:AddNamedSchedule("SendMeta"..personName, random(self.delay.AnswerMeta), nil, nil, self.SendMeta, self, personName);
		end
		-- after initialization : tick again
		self:SetState("BUILDING_PLAYER_TREE");
		GuildAdsTask:AddNamedSchedule("Initialise", self.delay.Init, nil, nil, self.EnableFullProtocol, self);
	end
end

function GuildAdsComm:ReceiveChatFlag(channelName, personName, flag, text)
	self:SetChatFlag(personName, flag, text);
end

function GuildAdsComm:ReceiveHashSearch(channelName, personName, path, hashSequence)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveHashSearch(%s, %s)", path, hashSequence);
	GuildAdsHash:ReceiveSearch(path, hashSequence);
	self:DequeueHashSearch(path); -- enough that 1 player makes a hash search for this path. Everyone else can dequeue it.
	self:SetState("HASHSEARCHING", self.delay.SearchDelay+self.delay.Timeout);
	local lasttoken=(self.playerTree[personName] or { i=1 }).i;
	if self.token~=lasttoken then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "GuildAdsComm:ReceiveHashSearch TOKEN MISMATCH: Should be %i, but %i is sending.",self.token, lasttoken );
	end
	self.token=(self.playerTree[personName] or { i=1 }).i; -- the last to send a hash search. Used to get clients back on track
end

function GuildAdsComm:ReceiveHashSearchResultToParent(channelName, personName, path, hashChanged, who, amount, numplayers)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveHashSearchFromChild(%s, %i)= %s, %i, %i", path, hashChanged, who, amount, numplayers or 1);
	GuildAdsHash:ReceiveHashSearchToParent(personName, path, hashChanged, who, amount, numplayers);
end

function GuildAdsComm:ReceiveHashSearchResult(channelName, personName, path, hashChanged, who, amount)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveHashSearchResult(%s, %i) = %s", path, hashChanged, who, amount);
	
	GuildAdsHash:ReceiveHashSearchResult(path, hashChanged, who, amount, self.DTS);
	
	if hashChanged == 0 then
		if path == "" then
			-- All databases are updated. Wait a while...
			GuildAdsTask:AddNamedSchedule("MoveToken", self.delay.HashDelay, nil, nil, self.MoveToken, self, nil, nil);
			self:SetState("SLEEP", self.delay.HashDelay+self.delay.Timeout);
		else
			self:MoveToken();
		end
	else
		-- not sure about this...
		if amount>0 then
			self:MoveToken(who);
		else
			self:MoveToken();
		end
	end
end


function GuildAdsComm:ReceiveSearch(channelName, personName, dataTypeName, playerName)
	local DTS = self.DTS[dataTypeName];
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveSearch(%s, %s)", tostring(DTS), playerName);
	DTS:ReceiveSearch(playerName)
	-- Add playerName to the current channel
	GuildAdsDB.channel[GuildAds.channelName]:addPlayer(playerName);
	-- reset timeout
	self:SetState("SEARCHING", self.delay.SearchDelay+self.delay.Timeout);
	local lasttoken=(self.playerTree[personName] or { i=1 }).i;
	if self.token~=lasttoken then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "GuildAdsComm:ReceiveSearch TOKEN MISMATCH: Should be %i, but %i is sending.",self.token, lasttoken );
	end
	self.token=(self.playerTree[personName] or { i=1 }).i;
	-- removing my own queued search for the same datatype/player
	self:DequeueSearch(self.DTS[dataTypeName], playerName);
end

function GuildAdsComm:ReceiveSearchResultToParent(channelName, personName, dataTypeName, playerName, who, revision, weight, worstRevision, version)
	local DTS = self.DTS[dataTypeName];
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveRevision(%s, %s)= %s (%i->%i) v%s", tostring(DTS), playerName, who, worstRevision, revision, tostring(version));
	DTS:ReceiveRevision(personName, playerName, who, revision, weight, worstRevision, version)
end

function GuildAdsComm:ReceiveSearchResult(channelName, personName, dataTypeName, playerName, who, toRevision, fromRevision)
	assert(fromRevision<=toRevision, "fromRevsion>toRevision");
	
	local DTS = self.DTS[dataTypeName];
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveSearchResult(%s, %s) = %s (%i->%i)", tostring(DTS), playerName, who, fromRevision, toRevision);
	-- parse message
	DTS:ReceiveSearchResult(playerName, who, fromRevision, toRevision)
	-- no update : move the token
	if fromRevision==toRevision then
		self:MoveToken();
	else
		self:SetState("WAITING_UPDATE", self.delay.Transaction+self.delay.Timeout);
	end
end

function GuildAdsComm:ReceiveOpenTransaction(channelName, personName, dataTypeName, playerName, fromRevision, toRevision, version)
	local DTS = self.DTS[dataTypeName];
	if personName~=GuildAds.playerName then
		if self.transactions[personName] then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Duplicate|r OPEN TRANSACTION from %s (already open)", personName);
		end
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveOpenTransaction(%s, %s, %s)", tostring(DTS), playerName, fromRevision);
		-- add transaction
		self.transactions[personName] = {
			playerName = playerName,
			ignore = not GuildAdsDB.channel[GuildAds.channelName]:isPlayerAllowed(playerName),
			dataTypeName = dataTypeName,
			fromRevision = fromRevision,
			toRevision = toRevision,
			lmt=time()
		}
		self.transactions[personName].__index = self.transactions[personName];
		-- parse message
		DTS:ReceiveOpenTransaction(self.transactions[personName], playerName, fromRevision, toRevision, version or 1);
		if self.transactions[personName].ignore then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"|cffff1e00Ignore|r ReceiveOpenTransaction(%s, %s, %s) (blacklisted)", tostring(DTS), playerName, fromRevision);
		end
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"|cffff1e00Ignore|r ReceiveOpenTransaction(%s, %s, %s) (my update)", tostring(DTS), playerName, fromRevision);
	end
	-- reset timeout
	self:SetState("UPDATING", self.delay.TransactionDelay+self.delay.Timeout);
end

function GuildAdsComm:ReceiveNewRevision(channelName, personName, revision, idSerialized, dataSerialized)
	if self.transactions[personName] then
		if not self.transactions[personName].ignore then
			local t = self.transactions[personName];
			local DTS = self.DTS[t.dataTypeName];
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveNewRevision(%s, %s, %s)", tostring(DTS), t.playerName, tostring(id));
			t.lmt = time();
			local id, data;
			if t._valid then
				id = GuildAdsCodecs[DTS.dataType.schema.id].decode(idSerialized);
				data = GuildAdsCodecs[t.dataTypeName.."Data"].decode(dataSerialized);
			end
			DTS:ReceiveNewRevision(t, revision, id, data)
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r NEW about %s (blacklisted)", self.transactions[personName].playerName);
		end
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r NEW from %s (no transaction)", personName);
	end
	self:SetState("UPDATING", self.delay.TransactionDelay+self.delay.Timeout);
end

function GuildAdsComm:ReceiveOldRevision(channelName, personName, revisionsSerialized)
	if self.transactions[personName] then
		if not self.transactions[personName].ignore then
			local t = self.transactions[personName];
			local DTS = self.DTS[t.dataTypeName];
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveOldRevisions(%s, %s)", tostring(DTS), t.playerName);
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
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r OLD about %s (blacklisted)", self.transactions[personName].playerName);
		end
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r OLD from %s (no transaction)", personName);
	end
	self:SetState("UPDATING", self.delay.TransactionDelay+self.delay.Timeout);
end

function GuildAdsComm:ReceiveKeys(channelName, personName, keys)
	if self.transactions[personName] then
		if not self.transactions[personName].ignore then
			local t = self.transactions[personName];
			local DTS = self.DTS[t.dataTypeName];
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveKeys(%s, %s)", tostring(DTS), t.playerName);
			t.lmt = time();
			local keys = GuildAdsCodecs[t.dataTypeName.."Keys"].decode(keys);
			DTS:ReceiveKeys(t, keys);
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r KEYS about %s (blacklisted)", self.transactions[personName].playerName);
		end
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r KEYS from %s (no transaction)", personName);
	end
	self:SetState("UPDATING", self.delay.TransactionDelay+self.delay.Timeout);
end

function GuildAdsComm:ReceiveCloseTransaction(channelName, personName)
	if personName == GuildAds.playerName then
		self:MoveToken();
	elseif self.transactions[personName] then
		if not self.transactions[personName].ignore then
			local t = self.transactions[personName];
			local DTS = self.DTS[t.dataTypeName];
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveCloseTransaction(%s, %s)", tostring(DTS), personName);
			DTS:ReceiveCloseTransaction(t);
			GuildAdsHash:UpdateHashTree(self.DTS[t.dataTypeName].dataType, t.playerName, true); -- can't delete player/datatype combos using transactions.
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r CLOSE TRANSACTION about %s (blacklisted)", self.transactions[personName].playerName);
		end
		-- delete the transaction
		self.transactions[personName] = nil;
		-- move the token
		self:MoveToken();
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r CLOSE TRANSACTION from %s (no transaction)", personName);
	end
end

function GuildAdsComm:ReceiveMoveToken(channelName, personName, index)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveMoveToken(%s)", tostring(index));
	if index then
		index = tonumber(index);
		assert(index>=0, "Invalid token (<0)");
		assert(index<=#self.playerList, "Invalid token (> #self.playerList)"); -- this occurs when e.g. making /reloadui and another player sends the MoveToken command. 
	end
	-- move the token
	self:MoveTokenDelayed(index);
	self:SetState("MOVETOKEN", self.delay.MoveToken+self.delay.Timeout);
end

--------------------------------------------------------------------------------
--
-- When database is updated
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:OnDBUpdate(dataType, playerName, id)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"[GuildAdsComm:OnDBUpdate] (%s, %s)", dataType.metaInformations.name, playerName);
	self:QueueSearch(self.DTS[dataType.metaInformations.name], playerName);
	GuildAdsHash:UpdateHashTree(dataType, playerName, id);
	if dataType.metaInformations.name=="Admin" then
		local channelRoot=GuildAdsDB.channel[GuildAds.channelName];
		if id and GuildAdsDBChannel:IsGuildID(id) then
			channelRoot:deletePlayers();
		else
			channelRoot:deletePlayers(id);
		end
	end
end

--------------------------------------------------------------------------------
--
-- About search/transaction queues
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:QueueHashSearch(path)
	local pathTable=GuildAdsHash:stringToPath(path);
	local p=#pathTable;
	if p==1 or p==2 then
		local t={ path=path };
		self.hashSearchQueue[p]:Append(path);
	end
end

function GuildAdsComm:DequeueHashSearch(path)
	local pathTable=GuildAdsHash:stringToPath(path);
	local p=#pathTable;
	if p==1 or p==2 then
		self.hashSearchQueue[p]:Delete(path);
	end
end

function GuildAdsComm:QueueSearch(DTS, playerName)
	self.searchQueue:Append(DTS.dataType.metaInformations.name.."/"..playerName, { DTS=DTS, playerName=playerName});
end

function GuildAdsComm:DequeueSearch(DTS, playerName)
	self.searchQueue:Delete(DTS.dataType.metaInformations.name.."/"..playerName);
end

function GuildAdsComm:QueueTransaction(DTS, playerName, fromRevision, toRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "GuildAdsComm:QueueTransaction");
	GuildAdsTask:AddNamedSchedule("SendTransaction", self.delay.Transaction, nil, nil, DTS.SendTransaction, DTS, playerName, fromRevision);
end
