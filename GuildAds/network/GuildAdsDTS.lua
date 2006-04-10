----------------------------------------------------------------------------------
--
-- GuildAdsDTS.lua (DataType Synchronization)
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsDTS = {};

function GuildAdsDTS:new(dataType)
	if not dataType.metaInformations or  not dataType.metaInformations.name then
		return;
	end
	
	if dataType.schema.data then
		local dataCodec = GuildAdsCodecTable:new({ schema=dataType.schema.data }, dataType.metaInformations.name.."Data", 1);
	end
	
	if dataType.schema.keys then
		local keysCodec = GuildAdsCodecTable:new({ schema=dataType.schema.keys }, dataType.metaInformations.name.."Keys", 1);
	end
	
	local o = {
		dataType = dataType;
		search = {};
		deleteTable = {};
	};
	self.__index = self;
	setmetatable(o, self);
	return o;
end

function GuildAdsDTS:__tostring()
	return self.dataType.metaInformations.name;
end


--------------------------------------------------------------------------------
--
-- Return the weight on this player (higher = better to send update)
-- 
--------------------------------------------------------------------------------
function GuildAdsDTS:GetWeight()
	local fps = GetFramerate()
	local _, _, lag = GetNetStats();
	return math.floor(fps*(1000-lag));
end

function GuildAdsDTS:SendSearch(playerName)
	-- envoyer la demande de recherche sur le canal (playerName)
	GuildAdsComm:SendSearch(self.dataType, playerName);
end

function GuildAdsDTS:ReceiveSearch(playerName)
	if not self.search[playerName] then
		self.search[playerName] = {
			best = {
				playerName = GuildAds.playerName,
				revision = self.dataType:getRevision(playerName),
				weight = self:GetWeight()
			};
			worstRevision = self.dataType:getRevision(playerName),
		};
	else
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"  - Search already in progress");
	end
	
	if not (GuildAdsComm.isOnline[GuildAds.playerName].c1 or GuildAdsComm.isOnline[GuildAds.playerName].c2) then
		-- I'm a leaf : don't wait, send my revision information to my parent
		self:SendRevision(playerName);
	end
end

function GuildAdsDTS:SendRevision(playerName)
	if self.search[playerName] then
		local result = self.search[playerName];
		if GuildAdsComm.isOnline[GuildAds.playerName].p then
			-- send result to parent in whisper
			GuildAdsComm:SendSearchResultToParent(GuildAdsComm.isOnline[GuildAds.playerName].p, self.dataType, playerName, result.best.playerName, result.best.revision, result.best.weight, result.worstRevision);
		else
			-- send search result to channel
			GuildAdsComm:SendSearchResult(self.dataType, playerName, result.best.playerName, result.best.revision, result.worstRevision);
		end
	end
end

function GuildAdsDTS:ReceiveRevision(childPlayerName, playerName, who, revision, weight, worstRevision)
	if not self.search[playerName] then
		return;
	end
	local result = self.search[playerName];
	local best = result.best;
	if  (revision>best.revision) or
		(best.revision==revision and weight>best.weight) then
		best.playerName = who;
		best.revision = revision;
		best.weight = weight;
	end
	
	if (worstRevision<result.worstRevision) then
		result.worstRevision = worstRevision;		
	end
	
	if childPlayerName == GuildAdsComm.isOnline[GuildAds.playerName].c1 then
		result.c1 = true;
	end
	
	if childPlayerName == GuildAdsComm.isOnline[GuildAds.playerName].c2 then
		result.c2 = true;
	end
	
	if (	GuildAdsComm.isOnline[GuildAds.playerName].c1
		and result.c1
		and GuildAdsComm.isOnline[GuildAds.playerName].c2 
		and result.c2)
	   or
	   (	GuildAdsComm.isOnline[GuildAds.playerName].c1
		and result.c1
		and not GuildAdsComm.isOnline[GuildAds.playerName].c2
		and not result.c2
	   )
	then
		self:SendRevision(playerName)
	end
end

function GuildAdsDTS:ReceiveSearchResult(playerName, who, fromRevision, toRevision)
	if self.search[playerName] then
		
		if (GuildAds.playerName==who) and (fromRevision<toRevision) then
			GuildAdsComm:QueueUpdate(self, playerName, fromRevision, self.dataType:getRevision(playerName));
		end
		
		self.search[playerName] = nil;
	end
end

function GuildAdsDTS:SendUpdate(playerName, fromRevision)
	-- send open transaction
	GuildAdsComm:SendOpenTransaction(self.dataType, playerName, fromRevision, self.dataType:getRevision(playerName));
	
	if self.dataType.schema.data then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"data");
		self:SendUpdateData(playerName, fromRevision);
	elseif self.dataType.schema.keys then
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"keys");
		self:SendUpdateKeys(playerName, fromRevision);
	end

	-- send close transaction with the current revision number
	GuildAdsComm:SendCloseTransaction(self.dataType, playerName);
end

function GuildAdsDTS:SendUpdateData(playerName, fromRevision)
	local currentRevision = self.dataType:getRevision(playerName);
	GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"currentRevision="..currentRevision);
	local t = {};
	local newEntries = 0;
	-- send new entries >r1
	for id, _, data, revision in self.dataType:iterator(playerName) do
		if (revision>fromRevision) then
			newEntries = newEntries + 1;
			-- send this revision
			GuildAdsComm:SendRevision(self.dataType, playerName, revision, id, data);
		else
			table.insert(t, revision);
		end
	end

	if currentRevision-fromRevision~=newEntries then
		-- idealement : 1-10, 12-15, 17-30 au lieu de la liste complete
		table.sort(t);
		GuildAdsComm:SendOldRevision(self.dataType, playerName, t)
	end
end

function GuildAdsDTS:SendUpdateKeys(playerName, fromRevision)
	-- TODO : stupide : recopie de la table deja en mémoire
	keys = {};
	for id, _, data in self.dataType:iterator(playerName) do
		keys[id] = data;
	end
	GuildAdsComm:SendKeys(self.dataType, playerName, keys)
end

function GuildAdsDTS:ReceiveOpenTransaction(transaction, playerName, fromRevision, toRevision)
	-- Nothing to do
end

function GuildAdsDTS:ReceiveCloseTransaction(transaction)
	self.dataType:setRevision(transaction.playerName, transaction.toRevision);
end

function GuildAdsDTS:ReceiveNewRevision(transaction, revision, id, data)
	self.dataType:setRaw(transaction.playerName, id, data, revision);
end

function GuildAdsDTS:ReceiveOldRevisions(transaction, revisions)
	table.setn(self.deleteTable, 0);
	
	-- find which id to delete
	for id, _, data, revision in self.dataType:iterator(transaction.playerName) do
		if not revisions[revision] then
			tinsert(self.deleteTable, id);
		end
	end
	
	-- delete them
	for _, id in self.deleteTable do
		self.dataType:setRaw(transaction.playerName, id, nil, nil)
	end
	
	table.setn(self.deleteTable, 0);
end

function GuildAdsDTS:ReceiveKeys(transaction, keys)
	for key, data in pairs(keys) do
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"  - ["..tostring(key).."]="..tostring(data));
		self.dataType:setRaw(transaction.playerName, key, data);
	end
end