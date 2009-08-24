----------------------------------------------------------------------------------
--
-- GuildAdsComm.lua
--
-- Author: Zarkan@Ner'zhul-EU, Fkaï@Ner'zhul-EU, Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GUILDADS_VERSION_PROTOCOL = "5";
GUILDADS_MSG_PREFIX_NOVERSION = "GA";
GUILDADS_MSG_PREFIX_REGEX = "GA.*\t";

GUILDADS_MSG_PREFIX = GUILDADS_MSG_PREFIX_NOVERSION..GUILDADS_VERSION_PROTOCOL;

local new = GuildAds.new
local new_kv = GuildAds.new_kv
local del = GuildAds.del
local deepDel = GuildAds.deepDel

--------------------------------------------------------------------------------
--
-- GuildAdsComm
-- 
---------------------------------------------------------------------------------
GuildAdsComm = GuildAds:NewModule("GuildAdsComm", {
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
		
		P= {
			-- Active player list
			[1] = "String"
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
		
		D= {
			[1] = "String"		-- marks [1] as being offline, or if nil, marks sender to be offline
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
		T	= "ReceiveMoveToken",
		D	= "ReceivePlayerLeaving",
		P	= "ReceivePlayerList"
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
		MoveToken				= 5,		-- delay to wait before actually moving the token
		GlobalTimeout			= 180		-- the delay before GuildAdsComm checks the player on the channel, send a new token.
											-- WARNING : no transaction should be longer than this delay.
	},
	
	stats = {
		Tick					= 0,
		RevisionSearch 			= 0,
		HashSearch				= {},
		Transaction				= 0,
		AcceptedTransaction = 0,
		TokenProblem			= 0,
		Join					= 0,
		Leave					= 0,
		Timeout					= {},
		TransactionPerDatabase	= {
			count = {},
			db = {}
		}
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
		GUILDADS_MSG_PREFIX,
		self.FilterText,
		self.OnJoin,
		self.OnLeave,
		self.OnSomeoneJoin,
		self.OnSomeoneLeave,
		self.OnMessage,
		self.ChatFlagListener,
		self.ChannelStatusListener
	);
end

function GuildAdsComm:JoinChannel(channel, password, command, alias)
	--LoggingChat(true);
	self.channelName = channel
	self.channelPassword = password
	
	if SimpleComm_Join(channel, password) then
		SimpleComm_SetAlias(command, alias)
	end
end

function GuildAdsComm:LeaveChannel()
	--LoggingChat(false);
	if self.channelName then
		-- Send leave message in case we don't actually leave the channel.
		self:SendPlayerLeaving()
		
		SimpleComm_Leave();
	
		self.channelName = nil
		self.channelPassword = nil
	end
end

function GuildAdsComm:GetChannelStatus()
	-- add information about the sync state
	-- min/max number of searches based on hash queue length
	local t_min = GuildAdsComm.hashSearchQueue[1]:Length()  * 1 + GuildAdsComm.hashSearchQueue[2]:Length()
	local t_max = GuildAdsComm.hashSearchQueue[1]:Length()  * 17 + GuildAdsComm.hashSearchQueue[2]:Length()
	-- number of new (in this session) updates
	local s = GuildAdsComm.searchQueue:Length()
	local status, chatStatus = SimpleComm_GetChannelStatus()
	return status, chatStatus, s, t_min, t_max
end

local mostRecentSeenProtocol = tonumber(GUILDADS_VERSION_PROTOCOL)

function GuildAdsComm.FilterText(text)
	local s, e, version = text:find(GUILDADS_MSG_PREFIX_REGEX, 1)
	if s~= nil then
		version = tonumber(version)
		if version and version > mostRecentSeenProtocol then
			DEFAULT_CHAT_FRAME:AddMessage("\124cffff8080"..GUILDADS_MAJOR_VERSION.."\124r")
			mostRecentSeenProtocol = version
		end
		return true
	else
		return false
	end
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
	
	-- Get ready to store responding players
	self.logging_on=true;
	self.sendPlayerList=false; -- set to true to enable sending of the P message (not fully operational)
	
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

function GuildAdsComm.OnSomeoneJoin(playerName, channelName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnSomeoneJoin(%s)]", playerName);
	local self=GuildAdsComm
	self.hasJoined[playerName] = GuildAdsDB:GetCurrentTime()
end
	
function GuildAdsComm.OnSomeoneLeave(playerName, channelName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAdsComm.OnSomeoneLeave(%s)]", playerName);
	local self=GuildAdsComm;
	-- Un joueur vient de quitter le channel  
	-- Mise à jour du statut online
	GuildAdsComm:SetOnlineStatus(playerName, false)
	self.hasJoined[playerName] = false
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
	del(self.playerChatFlags[playerName])
	self.playerChatFlags[playerName] = new_kv(
		'flag', flag,
		'text', text
	)
end

--------------------------------------------------------------------------------
--
-- Update tree
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:_UpdateTree()
	local p, c;
	del(self.databaseIdList);
	self.databaseIdList = new();
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
			self.playerTree[playerName] = new_kv(
				'i', i, 
				'p', self.playerList[p], 
				'c1', self.playerList[c], 
				'c2', self.playerList[c+1]
			);
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
		self.stats.Join = self.stats.Join + 1
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
		self.stats.Leave = self.stats.Leave + 1
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
		self.stats.Timeout[state] = (self.stats.Timeout[state] or 0) + 1
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

function GuildAdsComm:SetGlobalTimeout()
	GuildAdsTask:AddNamedSchedule("CheckGlobalTimeout", self.delay.GlobalTimeout, nil, nil, self.GlobalTimeout, self);
end

function GuildAdsComm:UnsetGlobalTimeout()
	GuildAdsTask:DeleteNamedSchedule("CheckGlobalTimeout");
end

function GuildAdsComm:GlobalTimeout()
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"== GuildAdsComm:GlobalTimeout() ==");
	-- there is problem : nothing on network since a long time
	
	-- reset all timers
	GuildAdsTask:DeleteNamedSchedule("MoveToken")
	GuildAdsTask:DeleteNamedSchedule("CheckTimeout")
	
	-- GuildAdsComm guesses that player tree is broken : someone has disconnect, and it didn't catch it
	SimpleComm_GetMembers(GuildAdsComm.ChannelListComplete)
end

function GuildAdsComm.ChannelListComplete(playerList)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"Comparing GuildAds online playerlist with players on the channel");
	local self = GuildAdsComm
	
	-- update the player list
	for _,playerName in pairs(self.playerList) do
		if not playerList[playerName] then
			GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"Player "..tostring(playerName).." is flagged online in GuildAds but is not on the GuildAds channel!");
			self:SetOnlineStatus(playerName, false)
		end
	end
	
	-- tick again
	if self.playerList[1]==GuildAds.playerName then
		self:SendMoveToken(1)
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
		-- sanity check
		if index<1 or index>#self.playerList then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "MoveToken %s |cffff1e00invalid|r", tostring(index));
			self.token = 1
		else
			self.token = index
		end
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
	self.stats.Tick = self.stats.Tick + 1
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
		self:UnsetGlobalTimeout();
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
	-- playerCount=-1 when sending to channel or when self.logging_in==true, (#self.playerList) otherwise
	local playerCount=toPlayerName and ((not self.logging_in) and (#self.playerList) or -1) or -1
	SimpleComm_SendMessage(toPlayerName, string.format("M>%s>%s>%i>%i>%s", GUILDADS_REVISION, GUILDADS_REVISION_STRING, self.startTime, playerCount, GuildAdsDB.databaseId));
	self:SendChatFlag(toPlayerName);
end

function GuildAdsComm:SendChatFlag(toPlayerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendChatFlag");
	local flag, message = SimpleComm_GetFlag(GuildAds.playerName);
	SimpleComm_SendMessage(toPlayerName, string.format("CF>%s>%s", (flag or ""), (message or "")));
end

function GuildAdsComm:SendHashSearch(path)
	local hashSequence = GuildAdsHash:GetBase64Hash(GuildAdsHash.tree[path]); -- always use the newest hash key
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendHashSearch(%s, %s)", path, hashSequence);
	SimpleComm_SendMessage(nil, string.format("HS>%s>%s", path, hashSequence));
end

function GuildAdsComm:SendHashSearchResultToParent(parentPlayerName, path, hashChanged, who, amount, numplayers)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendHashSearchResultWhisper[%s](%s, %i)", parentPlayerName, path, hashChanged);
	SimpleComm_SendMessage(parentPlayerName, string.format("HR>%s>%i>%i>%i>%i", path, hashChanged, who, amount, numplayers));
end

function GuildAdsComm:SendHashSearchResult(path, hashChanged, who, amount)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendHashSearchResult(%s, %i)", path, hashChanged);
	SimpleComm_SendMessage(nil, string.format("HSR>%s>%i>%i>%i", path, hashChanged, who, amount));
end

function GuildAdsComm:SendSearch(dataType, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendSearch(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, string.format("S>%s>%s", dataType.metaInformations.name, playerName));
end

function GuildAdsComm:SendSearchResultToParent(parentPlayerName, dataType, playerName, who, revision, weight, worstRevision, version)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendRevisionWhisper[%s](%s, %s)", parentPlayerName, dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(parentPlayerName, string.format("R>%s>%s>%s>%s>%i>%i>%i", dataType.metaInformations.name, playerName, who, revision, weight, worstRevision, version));
end

function GuildAdsComm:SendSearchResult(dataType, playerName, who, revision, worstRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendSearchResult(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, string.format("SR>%s>%s>%s>%i>%i", dataType.metaInformations.name, playerName, who, revision, worstRevision));
end

function GuildAdsComm:SendOpenTransaction(dataType, playerName, fromRevision, toRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendOpenTransaction(%s, %s, %s->%s, v%s)", dataType.metaInformations.name, playerName, fromRevision, toRevision,dataType.metaInformations.version);
	SimpleComm_SendMessage(nil, string.format("OT>%s>%s>%s>%s>%s", dataType.metaInformations.name, playerName, fromRevision, toRevision, dataType.metaInformations.version) );
end

function GuildAdsComm:SendRevision(dataType, playerName, revision, id, data)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendNewRevision(%s, %s, %s)", dataType.metaInformations.name, playerName, tostring(id));
	SimpleComm_SendMessage(nil, "N>"..tostring(revision)..">"..GuildAdsCodecs[dataType.schema.id].encode(id)..">"..GuildAdsCodecs[dataType.metaInformations.name.."Data"].encode(data) );
end

function GuildAdsComm:SendKeys(dataType, playerName, keys)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendKeys(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, "K>"..GuildAdsCodecs[dataType.metaInformations.name.."Keys"].encode(keys) );
end

function GuildAdsComm:SendOldRevision(dataType, playerName, revisions)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendOldRevision(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, "O>"..table.concat(revisions, "/"));
end

function GuildAdsComm:SendCloseTransaction(dataType, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendCloseTransaction(%s, %s)", dataType.metaInformations.name, playerName);
	SimpleComm_SendMessage(nil, "CT");
end

function GuildAdsComm:SendMoveToken(index)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendMoveToken");
	SimpleComm_SendMessage(nil, string.format("T>%s", index or ""));
end

function GuildAdsComm:SendPlayerList(toPlayerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendPlayerList(%s)", toPlayerName or "");
	SimpleComm_SendMessage(toPlayerName, "P>"..table.concat(self.playerList, "/"));
	self.sendPlayerList=false;
end

function GuildAdsComm:SendPlayerLeaving(toPlayerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendPlayerLeaving(%s)", toPlayerName or "");
	SimpleComm_SendMessage(nil, "D>"..(toPlayerName or ""));
end
--------------------------------------------------------------------------------
--
-- Parse inbound messages
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:CallReceive(channelName, personName, command)
	-- ignore message
	local cmd = command[1]
 	if GuildAdsComm.IGNOREMESSAGE[cmd] then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "Ignore message, command=%s", tostring(cmd));
		return;
	end
	
	-- call Receive* method
	local d = GuildAdsComm.MessageCodecs[cmd];
	local m = GuildAdsComm.MessageMethod[cmd];
	if m then
		GuildAdsComm[m](
			self,
			channelName,
			personName,
			d[1] and GuildAdsCodecs[d[1]].decode(command[2]),
			d[2] and GuildAdsCodecs[d[2]].decode(command[3]),
			d[3] and GuildAdsCodecs[d[3]].decode(command[4]),
			d[4] and GuildAdsCodecs[d[4]].decode(command[5]),
			d[5] and GuildAdsCodecs[d[5]].decode(command[6]),
			d[6] and GuildAdsCodecs[d[6]].decode(command[7]),
			d[7] and GuildAdsCodecs[d[7]].decode(command[8])
		);
	end
end

local string_find = string.find
local string_sub = string.sub
local table_insert = table.insert
local function ssplit( inSplitPattern, str)
	outResults = { }
	local theStart = 1
	local theSplitStart, theSplitEnd = string_find( str, inSplitPattern, theStart )
	while theSplitStart do
		table_insert( outResults, string_sub( str, theStart, theSplitStart-1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string_find( str, inSplitPattern, theStart )
	end
	table_insert( outResults, string_sub( str, theStart ) )
	return outResults
end

function GuildAdsComm.OnMessage(personName, text, channelName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "%s", text);
	GuildAdsComm:CallReceive(channelName, personName, ssplit(">", text));
end

function GuildAdsComm:EnableFullProtocol()
	del(GuildAdsComm.IGNOREMESSAGE)
	GuildAdsComm.IGNOREMESSAGE = new()
	self.logging_on=nil; -- fully logged on now
	if self.sendPlayerList then
		self:SendPlayerList();
	end
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
		GuildAdsMinimapButtonCore.addAlertText(string.format("%s%s",GUILDADS_UPGRADE_TIP,tostring(revisionString)));
	end
	if personName ~= GuildAds.playerName then
		if not GuildAdsDB.channel[GuildAds.channelName]:isPlayerAllowed(personName) then
			DEFAULT_CHAT_FRAME:AddMessage(string.format("\124cffff8080%s\124r", GUILDADS_BLACKLISTED_PLAYER, personName))
		end
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
			if self.logging_in and playerCount==-1 then
				self.sendPlayerList=false;
			end
		end
		-- after initialization : tick again
		self:SetState("BUILDING_PLAYER_TREE");
		GuildAdsTask:AddNamedSchedule("Initialise", self.delay.Init, nil, nil, self.EnableFullProtocol, self);
		-- set the global time out
		GuildAdsComm:SetGlobalTimeout()
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
	local lasttoken = self.playerTree[personName] and self.playerTree[personName].i or 1;
	if self.token~=lasttoken then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "GuildAdsComm:ReceiveHashSearch TOKEN MISMATCH: Should be %i, but %i is sending.",self.token, lasttoken );
		self.stats.TokenProblem = self.stats.TokenProblem + 1
	end
	self.token = lasttoken; -- the last to send a hash search. Used to get clients back on track
end

function GuildAdsComm:ReceiveHashSearchResultToParent(channelName, personName, path, hashChanged, who, amount, numplayers)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveHashSearchFromChild(%s, %i)= %s, %i, %i", path, hashChanged, who, amount, numplayers or 1);
	GuildAdsHash:ReceiveHashSearchToParent(personName, path, hashChanged, who, amount, numplayers);
end

function GuildAdsComm:ReceiveHashSearchResult(channelName, personName, path, hashChanged, who, amount)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveHashSearchResult(%s, %i) = %s", path, hashChanged, who, amount);
	
	local depth = (path=="" and 0) or select("#", strsplit(",",path))
	-- local pathTable=GuildAdsHash:stringToPath(path); local depth=#pathTable;
	self.stats.HashSearch[depth] = (self.stats.HashSearch[depth] or 0) + 1
	
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
	
	-- set the global time out
	self:SetGlobalTimeout()
end


function GuildAdsComm:ReceiveSearch(channelName, personName, dataTypeName, playerName)
	local DTS = self.DTS[dataTypeName];
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "ReceiveSearch(%s, %s)", tostring(DTS), playerName);
	DTS:ReceiveSearch(playerName)
	-- Add playerName to the current channel
	GuildAdsDB.channel[GuildAds.channelName]:addPlayer(playerName);
	-- reset timeout
	self:SetState("SEARCHING", self.delay.SearchDelay+self.delay.Timeout);
	local lasttoken = self.playerTree[personName] and self.playerTree[personName].i or 1;
	if self.token~=lasttoken then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "GuildAdsComm:ReceiveSearch TOKEN MISMATCH: Should be %i, but %i is sending.",self.token, lasttoken );
		self.stats.TokenProblem = self.stats.TokenProblem + 1
	end
	self.token = lasttoken
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
	
	self.stats.RevisionSearch = self.stats.RevisionSearch + 1
	
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
	-- set the global time out
	self:SetGlobalTimeout()
end

function GuildAdsComm:ReceiveOpenTransaction(channelName, personName, dataTypeName, playerName, fromRevision, toRevision, version)
	self.stats.Transaction = self.stats.Transaction + 1
	if self.playerMeta[personName] then
		local databaseId = self.playerMeta[personName].databaseId
		local statsPerDB = self.stats.TransactionPerDatabase
		statsPerDB.changed = true
		if statsPerDB.count[databaseId] then
			statsPerDB.count[databaseId] = statsPerDB.count[databaseId] + 1
		else
			statsPerDB.count[databaseId] = 1
			table.insert(statsPerDB.db, new( databaseId, personName ))
		end
		
		local DTS = self.DTS[dataTypeName];
		if personName~=GuildAds.playerName then
			if self.transactions[personName] then
				GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Duplicate|r OPEN TRANSACTION from %s (already open)", personName);
			end
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveOpenTransaction(%s, %s, %s)", tostring(DTS), playerName, fromRevision);
			-- add transaction
			self.transactions[personName] = new_kv(
				'playerName', playerName,
				'ignore', not GuildAdsDB.channel[GuildAds.channelName]:isPlayerAllowed(playerName),
				'dataTypeName', dataTypeName,
				'fromRevision', fromRevision,
				'toRevision', toRevision,
				'lmt', time()
			)
			self.transactions[personName].__index = self.transactions[personName];
			-- parse message
			DTS:ReceiveOpenTransaction(self.transactions[personName], playerName, fromRevision, toRevision, version or 1);
			if self.transactions[personName].ignore then
				GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"|cffff1e00Ignore|r ReceiveOpenTransaction(%s, %s, %s) (blacklisted)", tostring(DTS), playerName, fromRevision);
			elseif self.transactions[personName]._valid then
				self.stats.AcceptedTransaction = self.stats.AcceptedTransaction + 1
			end
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"|cffff1e00Ignore|r ReceiveOpenTransaction(%s, %s, %s) (my update)", tostring(DTS), playerName, fromRevision);
		end
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"|cffff1e00Ignore|r ReceiveOpenTransaction(%s, %s) (unknown playerMeta for %s)", playerName, fromRevision, personName);
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
			local revisions = new();
			local revision;
			for revision in string.gmatch(revisionsSerialized, "([^\/]*)/?$?") do
				revision = tonumber(revision);
				if revision then
					revisions[tonumber(revision)] = true;
				end
			end
			DTS:ReceiveOldRevisions(t, revisions)
			del(revisions)
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
			--GuildAdsHash:UpdateHashTree(self.DTS[t.dataTypeName].dataType, t.playerName, not t._IntegrityProblem); -- can't delete player/datatype combos using transactions (except on integrity problems)
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "|cffff1e00Ignore|r CLOSE TRANSACTION about %s (blacklisted)", self.transactions[personName].playerName);
		end
		-- delete the transaction
		del(self.transactions[personName])
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
		--assert(index<=#self.playerList, "Invalid token (> #self.playerList)"); -- this occurs when e.g. making /reloadui and another player sends the MoveToken command. 
		if index>#self.playerList then
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveMoveToken(%s) |cffff1e00invalid token|r", tostring(index));
			index=1
		end
	end
	-- move the token
	self:MoveTokenDelayed(index);
	self:SetState("MOVETOKEN", self.delay.MoveToken+self.delay.Timeout);
end

function GuildAdsComm:ReceivePlayerList(channelName, personName, playersSerialized)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceivePlayerList(%s)", playersSerialized);
	-- NOTE: from the time the playerSerialized is sent to we receive it, players may have come online or gone offline!
	-- This means playersSerialized may occasionally be wrong
	
	-- This function assumes that self.playerTree is in perfect sync with self.playerList
	
	-- check self.playerList against playersSerialized
	-- players mentioned in playerList but not in playersSerialized must be logged off: self:SetOnlineStatus(playerName, false)
	-- 
	-- create table holding players mentioned in playersSerialized but not in self.playerList
	local playerWorkTable = new()
--	self.playerWorkTable = playerWorkTable; -- for debug purpose
	
	local sendMeta=false;
	local amOnline=false;
	for player in string.gmatch(playersSerialized, "([^\/]+)/?$?") do
		player = tostring(player);
		playerWorkTable[player]=true;
		--table.insert(playerWorkTable,player);
		if not self.playerTree[player] then 
			-- player is active on the channel, but I don't know about him/her. 
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceivePlayerList() Unknown player %s", player);
			sendMeta=true;
		end
		if player == GuildAds.playerName then
			amOnline=true
		end
	end
	if sendMeta or not amOnline then
		-- I don't know about all active clients. Send Meta and wait for everyone to respond.
		-- NOTE: This is a somewhat bandwidth wasteful solution but is backwards compatible.
		--self:SendMeta();
		GuildAdsTask:AddNamedSchedule("SendMeta", random(self.delay.SearchDelay), nil, nil, self.SendMeta, self, nil);
	else
		GuildAdsTask:DeleteNamedSchedule("SendMeta");		
	end
	for _,player in pairs(self.playerList) do
		if not playerWorkTable[player] then
			-- player is marked online with me, but didn't respond to last M sent (client crash/lagged).
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceivePlayerList() Correctly marking player as offline: %s", player);
			self:SetOnlineStatus(playerName, false)
		end
	end
	del(playerWorkTable)
end

function GuildAdsComm:ReceivePlayerLeaving(channelName, personName, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceivePlayerLeaving(%s)", playerName);
	if playerName then
		-- have to handle the situation when playerName == GuildAds.playerName (!!)
		self:SetOnlineStatus(playerName, false)
		if playerName == GuildAds.playerName then
			GuildAdsComm:LeaveChannel()
		end
	else
		self:SetOnlineStatus(personName, false)
	end
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
	local p = GuildAdsHash:pathLength(path)
	if p>0 then
		self.hashSearchQueue[p]:Append(path);
	end
end

function GuildAdsComm:DequeueHashSearch(path)
	local p = GuildAdsHash:pathLength(path)
	if p>0 then
		self.hashSearchQueue[p]:Delete(path);
	end
end

function GuildAdsComm:QueueSearch(DTS, playerName)
	self.searchQueue:Append(DTS.dataType.metaInformations.name.."/"..playerName, new_kv('DTS', DTS, 'playerName', playerName));
end

function GuildAdsComm:DequeueSearch(DTS, playerName)
	self.searchQueue:Delete(DTS.dataType.metaInformations.name.."/"..playerName);
end

function GuildAdsComm:QueueTransaction(DTS, playerName, fromRevision, toRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "GuildAdsComm:QueueTransaction");
	GuildAdsTask:AddNamedSchedule("SendTransaction", self.delay.Transaction, nil, nil, DTS.SendTransaction, DTS, playerName, fromRevision);
end
