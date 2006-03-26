----------------------------------------------------------------------------------
--
-- GuildAdsDRS.lua (DataType Synchronization)
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsDTS = {};

function GuildAdsDTS:new(channelName, dataType)
	if not dataType.metaInformations or  not dataType.metaInformations.name then
		return;
	end
	local dataCodecName = dataType.metaInformations.name.."Data";
	local dataCodec = GuildAdsCodecTable:new({ schema=dataType.schema.data }, dataCodecName, 1);
	local o = {
		channelName = channelName;	-- TODO : not use
		dataType = dataType;
		playerName = "";
		best = {
			playerName = "",
			revision = 0,
			weight = 0
		};
		worst = {
			playerName = "",
			revision = 0,
			weight = 0
		};
		count = 0;
		state = "READY";
		schema = {
			[1] = { key="id",		codec=dataType.schema.id },
			[2] = { key="data",		codec=dataCodecName }
		}
	};
	self.__index = self;
	setmetatable(o, self);
	return o;
end


--------------------------------------------------------------------------------
--
-- Return the weight on this player (higher = better to send update)
-- 
--------------------------------------------------------------------------------
function GuildAdsDTS:GetWeight()
	local fps = GetFramerate()
	local _, _, lag = GetNetStats();
	return fps*(1000-lag);
end

function GuildAdsDTS:SendSearch(playerName)
	if self.state=="READY" then
		self.state="STARTINGSEARCH";
		self.playerName = playerName;

		self.best.playerName = GuildAds.playerName;
		self.best.revision = self.dataType:getRevision(playerName);
		self.best.weight = self:GetWeight();
		self.worst.playerName = GuildAds.playerName;
		self.worst.revision = self.dataType:getRevision(playerName);
		self.worst.weight = self:GetWeight();
		self.count = 1;
		
		-- envoyer la demande de recherche sur le canal (playerName)
		GuildAdsComm:SendSearch(self.dataType, playerName);
	end
end

function GuildAdsDTS:ReceiveSearch(playerName)
	if self.state=="STARTINGSEARCH" then 
		self.state = "SEARCH";
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"state="..self.state);
		if not (GuildAdsComm.isOnline[GuildAds.playerName].c1 or GuildAdsComm.isOnline[GuildAds.playerName].c2) then
			-- I'm a leaf : don't wait, send my revision information to my parent
			self:SendRevision();
		end
	end
end

function GuildAdsDTS:SendRevision()
	if self.state=="SEARCH" then
		self.state = "SENT";
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"state="..self.state);
		if GuildAdsComm.isOnline[GuildAds.playerName].p then
			-- send result to parent in whisper
			GuildAdsComm:SendRevisionWhisper(self.isOnline[GuildAds.playerName].p, self.dataType, self.playerName, self.best.playerName, self.best.revision, self.best.weight, self.worst.revision);
		else
			-- send result to channel
			GuildAdsComm:SendRevisionChannel(self.dataType, self.playerName, self.best.playerName, self.best.revision, self.worst.revision);
		end
	end
end

function GuildAdsDTS:ReceiveRevision(playerName, revision, weight, worstRevision)
	if self.state~="SEARCH" then
		return;
	end
	if self.cmd.result.count>=3 then
		error("More than 2 childs");
		return;
	end
	
	local best = self.best;
	if  (revision>best.revision) or
		(best.revision==revision and weight>best.weight) then
		best.playerName = playerName;
		best.revision = revision;
		best.weight = weight;
	end
	
	local worst = self.worst;
	if (worstRevision<worst.revision) then
		worst.playerName = playerName;
		worst.revision = revision;
		worst.weight = weight;		
	end
	
	self.count = self.count+1;
	
	if self.cmd.result.count==3 then
		self:SendRevision()
	end
end

function GuildAdsDTS:ReceiveSearchResult(playerName, who, fromRevision, toRevision)
	if (self.state=="SEARCH") or (self.state=="SENT") then
		self.state="READY"
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"state="..self.state);
		
		if (GuildAds.playerName==who) and (fromRevision<toRevision) then
			GuildAdsComm:QueueUpdate(self, playerName, fromRevision, self.dataType:getRevision(playerName));
		end
	end
end

function GuildAdsDTS:SendUpdate(playerName, fromRevision)
	if self.state=="READY" then
		self.state="UPDATING";
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"state="..self.state);
		
		-- send open transaction
		GuildAdsComm:SendOpenTransaction(self.dataType, playerName, fromRevision);
		
		local currentRevision = self.dataType:getRevision(playerName);
		local t = {};
		local newEntries = 0;
		-- send new entries >r1

		for _, id, data, revision in self.dataType:iterator(playerName) do
			if revision>fromRevision then
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
			for _, revision in ipairs(t) do
				-- send this revision still exist
				GuildAdsComm:SendKeepRevision(self.dataType, revision)
			end
		end

		-- send close transaction with the current revision number
		GuildAdsComm:SendCloseTransaction(self.dataType, playerName, currentRevision);
	end
end

function GuildAdsDTS:ReceiveOpenTransaction(sourceName, playerName)
	if self.state=="READY" then
		self.state="OPEN"
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"state="..self.state);
		
		self.playerName = playerName
		self.sourceName = sourceName;
		self.keepTable = nil;
	end
end

function GuildAdsDTS:ReceiveCloseTransaction(sourceName, revision)
	if ((self.state=="OLD" or self.state=="NEW" or self.state=="OPEN") and (self.sourceName==sourceName)) 
		or (self.state=="STANDBY") then
		self.state="READY"
		GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"state="..self.state);
		
		if self.keepTable then
			-- find which id to delete
			local deleteTable = {};
			for _, id, revision in self.dataType:iterator(self.playerName) do
				if not self.keepTable[revision] then
					tinsert(self.deleteTable, id);
				end
			end
			-- delete them
			for _, id in deleteTable do
				dataType:setRaw(self.playerName, id, nil, nil)
			end
			self.keepTable = nil;
		end
		
		self.dataType:setRevision(self.playerName, revision);
	end
end

function GuildAdsDTS:ReceiveAddNewEntrie(sourceName, id, data, revision)
	if (self.state=="OPEN") and (self.sourceName==sourceName) then
		self.state="NEW"
		self.dataType:setRaw(self.playerName, id, data, revision);
	end
end

function GuildAdsDTS:ReceiveKeepOldEntrie(sourceName, revision)
	if (self.state=="NEW" or self.state=="OPEN") and (self.sourceName==sourceName) then
		self.state="OLD"
		if not self.keepTable then
			self.keepTable = {};
		end
		self.keepTable[revision] = true;
	end
end
