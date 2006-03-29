----------------------------------------------------------------------------------
--
-- GuildAdsComm.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GUILDADS_VERSION_PROTOCOL = "27";

GUILDADS_MSG_PREFIX_NOVERSION = "<GA";
GUILDADS_MSG_REGEX_UNSERIALIZE = "([^\>]*)>";
GUILDADS_MSG_PREFIX1= "<GA"..GUILDADS_VERSION_PROTOCOL;
GUILDADS_MSG_PREFIX = GUILDADS_MSG_PREFIX1..">";
	
GUILDADS_MSG_PREFIX_REGEX_UNSPLIT = GUILDADS_MSG_PREFIX.."([0-9]+)([\.|\:])(.*)";

GUILDADS_MSG_TYPE_ANNONCE = 0;
GUILDADS_MSG_TYPE_REQUEST = 1;
GUILDADS_MSG_TYPE_AVAILABLE = 2;
GUILDADS_MSG_TYPE_SKILL = 3;
GUILDADS_MSG_TYPE_EVENT = 4;
GUILDADS_MSG_TYPE_INVENTORY = 5;
GUILDADS_MSG_TYPE_EVENT_SUBSCRIPTION = 7;

GUILDADS_STATE_UNKNOW       = "unknow";
GUILDADS_STATE_SYNC_ONLINE  = "s_online";
GUILDADS_STATE_SYNC_OFFLINE = "s_offline";
GUILDADS_STATE_OK   	     = "ok";

local function GAC_GetGuildChatFrame()
	for i=1,NUM_CHAT_WINDOWS,1 do
		local DefaultMessages = { GetChatWindowMessages(i) };
		for k, channel in DefaultMessages do
			if channel == "GUILD" then
				return getglobal("ChatFrame"..i);
			end
		end
	end
	return DEFAULT_CHAT_FRAME;
end

GAC_GetFlag = SimpleComm_GetFlag;

function GAC_Reinit(channel, password)
	-- Reinit GuildAdsComm
	SimpleComm_SetChannel(channel, password);
	
	-- Init after the channel is joined (GAC_Synchronize called by SimpleComm)
end

--------------------------------------------------------------------------------
--
-- Serialize/Unserialize 
-- 
---------------------------------------------------------------------------------
local SerializeMeta = {
	[1]  = { key="command", 	codec="String" }
};

local SerializeCommand = {
	M= {
		[1] = { key="version", 		codec="String" },
		[2] = { key="startTime",	codec="Integer" },
		[3] = { key="state",		codec="String" }
	};
	
	CF= {
		[1]	= { key="flag",			codec="String" },
		[2] = { key="text",			codec="String" }
	};
	
	S= {
		[1] = { key="dataTypeName",	codec="String" },
		[2] = { key="playerName",	codec="String" }
	};
	
	R= {
		[1] = { key="dataTypeName",	codec="String" },
		[2] = { key="playerName",	codec="String" },
		[3] = { key="who",			codec="String" },
		[4] = { key="revision",		codec="Integer" },
		[5] = { key="weight",		codec="Integer" },
		[6] = { key="worstRevision",codec="Integer" }
	};
	
	SR= {
		[1] = { key="dataTypeName",	codec="String" },
		[2] = { key="playerName",	codec="String" },
		[3] = { key="who",			codec="String" },
		[4] = { key="toRevision",	codec="Integer" },
		[5] = { key="fromRevision", codec="Integer" }
	};
	
	OT= {
		[1] = { key="dataTypeName",	codec="String" },
		[2] = { key="playerName",	codec="String" },
		[3] = { key="fromRevision",	codec="Integer" },
	};
	
	N= {
		[1] = { key="revision",		codec="Integer" },
		[2] = { key="id",			codec="Raw" },
		[3] = { key="data",			codec="Raw" }
	};
	
	O={
		[1] = { key="revisions",	codec="String" },
	};
	
	K= {
		[1] = { key="keys",			codec="Raw" }
	};
	
	CT= {
		[1] = { key="revision",		codec="Integer" },
	}
};

local serializeResult = { GUILDADS_MSG_PREFIX };
function GuildAds_Serialize(o)
	o.currenttime = GuildAdsDB:GetCurrentTime();
	table.setn(serializeResult, 1);
	table.insert(serializeResult, SerializeTable(SerializeMeta, o));
	if SerializeCommand[o.command] then
		table.insert(serializeResult, SerializeTable(SerializeCommand[o.command], o));
		if o.command == "N" then
			table.insert(serializeResult, SerializeTable(GuildAdsComm.DTS[o.dataTypeName].schema, o));
		end
	end
	return table.concat(serializeResult);
end

function GuildAds_Unserialize(text)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "[GuildAds_Unserialize]"..text);
	local o;
	
	local j=0;
	local s;
	local i=1;
	local m=1;
	
	for str in string.gfind(text, GUILDADS_MSG_REGEX_UNSERIALIZE) do
		if j>0 then
			o = o or {}; -- TODO : idée : cache des messages avec les key déjà créer en fonction de .command
			local d = s[i];
--~ 			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "  -'"..str.."'");
			o[d.key] = GuildAdsCodecs[d.codec].decode(str);
		else
			if str~=GUILDADS_MSG_PREFIX1 then
				return;
			end
		end
		
		i = i + 1;
		if i>m then
			j=j+1;
			if j==1 then
--~ 				GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "1");
				s=SerializeMeta;
			elseif j==2 and o.command and SerializeCommand[o.command] then
--~ 				GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "2");
				s=SerializeCommand[o.command];
			else
				break;
			end
			i=1;
			m=table.getn(s);
		end
	end
	
	return o;
end

function GuildAds_SplitSerialize(packetNumber, last, obj)
	if last then
		return GUILDADS_MSG_PREFIX .. packetNumber ..":".. obj;
	else
		return GUILDADS_MSG_PREFIX .. packetNumber ..".".. obj;
	end
end

function GuildAds_UnsplitSerialize(str)
	local iStart, _ , packetNumber, last, packet = string.find(str, GUILDADS_MSG_PREFIX_REGEX_UNSPLIT);
	if iStart then
		return packet, tonumber(packetNumber), last==":";
	end
	return str;
end

function GuildAds_FilterText(text)
	return string.sub(text, 1, string.len(GUILDADS_MSG_PREFIX_NOVERSION)) == GUILDADS_MSG_PREFIX_NOVERSION;
end

------------------------------------
GuildAdsComm = AceModule:new({
	hasJoined = {},
	isOnline = {},
	playerList = {},
	playerInfo = {},
	channelName = "",
	channelPassword = "",
	
	IGNOREMYMESSAGE = {
		CF=true,
		OT=true,
		N=true,
		O=true,
		K=true,
		CT=true,
	},
	
	transactions = {},
	DTS = {},
	updateQueue = {},
	searchQueue = {},
});

function GuildAdsComm:Initialize()
	self.startTime = GuildAdsDB:GetCurrentTime();

	SimpleComm_PreInit(
		GuildAds_FilterText,
		GuildAds_Serialize,
		GuildAds_Unserialize,
		GuildAds_SplitSerialize,
		GuildAds_UnsplitSerialize,
		GuildAdsComm.OnJoin,
		GuildAdsComm.OnLeave,
		GuildAdsComm.OnMessage
	);
	
	self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN");
	self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE");
	self.state = "UNKNOW";
	
	SimpleComm_SetFlagListener(self.SendChatFlag);
end

function GuildAdsComm:JoinChannel(channel, password)
	self.channelName = string.lower(channel)
	self.channelPassword = password
	
	SimpleComm_Init(channel, password, GAC_GetGuildChatFrame());

	local command, alias = GuildAds:GetDefaultChannelAlias();
	SimpleComm_InitAlias(command, alias);
end

function GuildAdsComm.OnJoin(self)
	self=self or GuildAdsComm;
	
	-- create DTS
	for name, profile in GuildAdsDB.profile do
		self.DTS[name] = GuildAdsDTS:new(self.channelName, profile);
	end
	
	for name, channel in GuildAdsDB.channel[GuildAds.channelName] do
		if type(channel)=="table" then
			self.DTS[name] = GuildAdsDTS:new(self.channelName, channel);
		end
	end
	
	-- Send Meta
	self:SendMeta();
	
	-- TODO : le reste....
--~ 	for name, DTS in pairs(self.DTS) do
--~ 		self:QueueSearch(DTS, GuildAds.playerName);
--~ 	end

--~ 	self:QueueSearch(self.DTS.Main, GuildAds.playerName);

	self:QueueSearch(self.DTS.TradeOffer, GuildAds.playerName);
	self.DTS.TradeOffer.dataType:registerEvent(GuildAdsComm, "OnDBUpdate");
	
--~ 	self:QueueSearch(self.DTS.TradeNeed, GuildAds.playerName);
end

function GuildAdsComm.OnLeave(self)
	self=self or GuildAdsComm;
	self.state = "LEAVING";
	self:SendMeta();
end

function GuildAdsComm:CHAT_MSG_CHANNEL_JOIN()
	-- TODO : Un joueur vient d'arrive sur le channel
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
	if self.isOnline[playerName] then
		return true;
	else
		return false;
	end
end

--------------------------------------------------------------------------------
--
-- Get tree info about a player (parent player, and child players)
-- parent : .p
-- childs : .c1, .c2
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:GetTreeInfo(playerName)
	return self.isOnline[playerName];
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
		if type(self.isOnline[playerName]) == "table" then
			self.isOnline[playerName].p = self.playerList[p];
			self.isOnline[playerName].c1 = self.playerList[c];
			self.isOnline[playerName].c2 = self.playerList[c+1];
		else
			self.isOnline[playerName] = { p=self.playerList[p], c1=self.playerList[c], c2=self.playerList[c+1] };
		end
	end
end

--------------------------------------------------------------------------------
--
-- Set online status of a player
-- 
--------------------------------------------------------------------------------
function GuildAdsComm:SetOnlineStatus(playerName, status)
	if status then
		if (not self.isOnline[playerName]) then
			table.insert(self.playerList, playerName);
			self:_UpdateTree();
			if self.hasJoined[playerName] then
				self.hasJoined[playerName] = nil;
				GuildAdsPlugin_OnEvent(GAS_EVENT_CONNECTION, playerName, true);
			end
			GuildAdsPlugin_OnEvent(GAS_EVENT_ONLINE, playerName, true);
			self:SendMeta();	-- TODO : send whisper
		end
	else
		if (self.isOnline[playerName]) then
			self.isOnline[playerName] = nil;
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

function GuildAdsComm:SendMeta()
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendMeta");
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."M>"..GUILDADS_VERSION..">"..self.startTime..">"..self.state..">");
end

function GuildAdsComm:SendChatFlag()
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendChatFlag");
	local flag, message = SimpleComm_GetFlag(GuildAds.playerName);
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."CF>"..(flag or "")..">"..(message or "")..">");
end

function GuildAdsComm:SendSearch(dataType, playerName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendSearch");
	SimpleComm_SendRawMessage(playerName, GUILDADS_MSG_PREFIX.."S>"..dataType.metaInformations.name..">"..playerName..">");
end

function GuildAdsComm:SendRevisionWhisper(toPlayerName, dataType, playerName, who, revision, weight, worstRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendRevisionWhisper");
	SimpleComm_SendRawMessage(toPlayerName, GUILDADS_MSG_PREFIX.."R>"..dataType.metaInformations.name..">"..playerName..">"..who..">"..revision..">"..weight..">"..worstRevision..">");
end

function GuildAdsComm:SendRevisionChannel(dataType, playerName, who, revision, worstRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendRevisionChannel");
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."SR>"..dataType.metaInformations.name..">"..playerName..">"..who..">"..revision..">"..worstRevision..">");
end

function GuildAdsComm:SendOpenTransaction(dataType, playerName, fromRevision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendOpenTransaction");
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."OT>"..dataType.metaInformations.name..">"..playerName..">"..fromRevision..">");
end

function GuildAdsComm:SendRevision(dataType, playerName, revision, id, data)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendRevision");
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."N>"..revision..">"..GuildAdsCodecs[dataType.schema.id].encode(id)..">"..GuildAdsCodecs[dataType.metaInformations.name.."Data"].encode(data)..">");
end

function GuildAdsComm:SendKeys(dataType, playerName, keys)
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."K>"..GuildAdsCodecs[dataType.metaInformations.name.."Keys"].encode(keys)..">");
end

function GuildAdsComm:SendOldRevision(dataType, playerName, revisions)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendKeepRevision");
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."O>"..table.concat(revisions, "/")..">");
end

function GuildAdsComm:SendCloseTransaction(dataType, playerName, revision)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"SendCloseTransaction");
	SimpleComm_SendRawMessage(nil, GUILDADS_MSG_PREFIX.."CT>"..revision..">");
end

function GuildAdsComm.OnMessage(playerName, message, channel)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"[GuildAdsComm.OnMessage]"..playerName..","..tostring(message.command));
	-- ignore update from myself
 	if playerName ~= GuildAds.playerName or not GuildAdsComm.IGNOREMYMESSAGE[message.command] then
		GuildAdsComm:ParseMessage(playerName, message, channel)
	end
end

function GuildAdsComm:ParseMessage(playerName, message, channelName)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"[GuildAdsComm:ParseMessage]"..playerName..","..tostring(message.command)..","..tostring(channelName));
	if self.transactions[playerName] then
		setmetatable(message, self.transactions[playerName]);
	end
	local DTS = self.DTS[message.dataTypeName];
	if message.command == "M" then
		self.playerInfo[playerName] = {
			state = message.state;
			onlineSince = message.onlineSince;
			version = message.version
		}
		self:SetOnlineStatus(playerName, true);
		GuildAdsDB.channel[channelName]:addPlayer(playerName);
	elseif message.command == "CF" then
		SimpleComm_SetFlag(author, message.flag, message.text);
	elseif message.command == "S" then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "S("..message.playerName..")");
		DTS:ReceiveSearch(message.playerName)
	elseif message.command == "R" then
		DTS:ReceiveRevision(message.playerName, message.who, message.revision, message.weight, message.worstRevision)
	elseif message.command == "SR" then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL, "S("..message.playerName..")="..message.who.."("..message.fromRevision.."->"..message.toRevision..")");
		self:DeleteDuplicateUpdate(DTS, message.playerName, message.who, message.fromRevision, message.toRevision);
		DTS:ReceiveSearchResult(message.playerName, message.who, message.fromRevision, message.toRevision)
	elseif message.command == "OT" then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"ReceiveOpenTransaction("..message.playerName..","..message.fromRevision);
		self.transactions[playerName] = {
			playerName = message.playerName,
			dataTypeName = message.dataTypeName
		}
		self.transactions[playerName].__index = self.transactions[playerName];
		DTS:ReceiveOpenTransaction(playerName, message.playerName, message.fromRevision)
	elseif message.command == "CT" then
		DTS:ReceiveCloseTransaction(playerName, message.revision)
		self.transactions[playerName] = nil;
	elseif message.command == "N" then
		local id = GuildAdsCodecs[DTS.dataType.schema.id].decode(message.id);
		local data = GuildAdsCodecs[message.dataTypeName.."Data"].decode(message.data);
		DTS:ReceiveNewRevision(playerName, message.revision, id, data)
	elseif message.command == "O" then
		local revisions = {};
		local revision;
		for revision in string.gfind(message.revisions, "([^\/]*)/?$?") do
			revision = tonumber(revision);
			if revision then
				revisions[tonumber(revision)] = true;
			end
		end
		DTS:ReceiveOldRevisions(playerName, revisions)
	elseif message.command == "K" then
		local keys = GuildAdsCodecs[message.dataTypeName.."Keys"].decode(message.keys);
		DTS:ReceiveKeys(playerName, keys);
	end
end

function GuildAdsComm:OnDBUpdate(dataType, playerName, id)
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"[GuildAdsComm:OnDBUpdate]"..dataType.metaInformations.name..","..playerName);
	self:QueueSearch(self.DTS[dataType.metaInformations.name], playerName);
end

function GuildAdsComm:DeleteDuplicateUpdate(DTS, playerName, who, fromRevision, toRevision)
	local i = 1;
	while self.updateQueue[i] do
		local update = self.updateQueue[i];
		if 		(update.DTS==DTS) 
			and (update.playerName==playerName) 
			and (		(update.toRevision<toRevision) 		-- better revision
					or  (update.fromRevision>fromRevision)	-- start from an older revision
					or  (GuildAds.playerName==who)			-- already queued
				) then
			table.remove(self.updateQueue, i);
		else
			i=i+1;
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

function GuildAdsComm:QueueUpdate(DTS, playerName, fromRevision, toRevsion)
	self:DeleteDuplicateUpdate(DTS, playerName, GuildAds.playerName, fromRevision, toRevision);
	table.insert(self.updateQueue, { DTS=DTS, playerName=playerName, fromRevision=fromRevision, toRevision=toRevision });
	if not self.updateQueueDelay then
		self.updateQueueDelay = 1;
	end
end

function GuildAdsComm:QueueSearch(DTS, playerName)
	if not self:FindSearch(DTS, playerName) then
		table.insert(self.searchQueue, { DTS=DTS, playerName=playerName} );
		if not self.searchQueueDelay then
			self.searchQueueDelay = 1;
		end
	end
end

function GuildAdsComm:ProcessQueues(elapsed)
	if self.updateQueueDelay then
		self.updateQueueDelay = self.updateQueueDelay - elapsed;
		if self.updateQueueDelay<=0 and self.updateQueue[1] then
			local update = self.updateQueue[1];
			if update.DTS.state=="READY" then
				table.remove(self.updateQueue, 1);
				update.DTS:SendUpdate(update.playerName, update.fromRevision);
			end
			
			if self.updateQueue[1] then
				self.updateQueueDelay = 1; -- check every second
			else
				self.updateQueueDelay = nil;
			end
		end
	end
	
	if self.searchQueueDelay then
		self.searchQueueDelay = self.searchQueueDelay - elapsed;
		if self.searchQueueDelay<=0 and self.searchQueue[1] then
			local search = self.searchQueue[1];
			if search.DTS.state=="READY" then
				table.remove(self.searchQueue, 1);
				search.DTS:SendSearch(search.playerName);
			end
			
			if self.searchQueue[1] then
				self.searchQueueDelay = 1;
			else
				self.searchQueueDelay = nil;
			end
		end
	end
end
