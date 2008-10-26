----------------------------------------------------------------------------------
--
-- GuildAdsDB.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local HourMin = 60;
local DayMin = HourMin * 24;
local MonthMin = DayMin * 30;
local TimeRef = 18467940; 	-- Nombre de minutes entre 1/1/1970 et 11/2/2005

--[[
	doc sur LUA :http://www.lua.org/ftp/refman-5.0.pdf
	doc sur les metatables : cf page 21
	
	TODO : rename .db to .raw
]]

--[[ GuildAdsMagicMT ]]
GuildAdsMagicMT = {

	__index = function(t, n)
		local r = {};
		setmetatable(r, {
			_table = t;
			_key = n;
			__newindex = GuildAdsMagicMT.__newindex;
		});
		return r;
	end;
	
	-- create profile only when a value is set
	__newindex = function(t, n, v)
		rawset(t, n, v);
		local mt = getmetatable(t);
		mt._table[mt._key] = t;
		mt.__newindex = nil;
		mt._table = nil;
		mt._key = nil;
	end;
};

--[[ GuildAdsDBChannel ]]
GuildAdsDBChannel = {
	PLAYER = "PLAYER",
	ALLOWEDPLAYER = "ALLOWEDPLAYER",
	ALLOWEDGUILD = "ALLOWEDGUILD",
	DENIEDPLAYER = "DENIEDPLAYER", 
	DENIEDGUILD = "DENIEDGUILD"
}

function GuildAdsDBChannel:getRaw()
	return self.db;
end

function GuildAdsDBChannel:getPlayers()
	return self.db.Players;
end

function GuildAdsDBChannel:addPlayer(playerName)
	if self:isPlayerAllowed(playerName) then
		if not self.db.Players[playerName] then
			self.db.Players[playerName] = true;
			-- old profile data may exist in the database, make sure the hash tree is updated
			for name, profileDT in pairs(GuildAdsDB.profile) do
				if profileDT:getRevision(playerName) > 0 then -- speed-up
					GuildAdsHash:UpdateHashTree(profileDR, playerName, true);
				end
			end
			-- it should not be possible to have old channel data present so there is no need to check
			
			self:triggerEvent(self.PLAYER, playerName);
		end
		return true;
	end
end

function GuildAdsDBChannel:deletePlayer(playerName)
	if self.db.Players[playerName] then
		GuildAds_ChatDebug(GA_DEBUG_STORAGE,"clearing datatypes for player "..playerName);
		for name, profileDT in pairs(GuildAdsDB.profile) do
			--GuildAds:Print("clearing "..name.." for player "..playerName);
			profileDT:clear(playerName);
		end
	
		for name, channelDT in pairs(GuildAdsDB.channel[GuildAds.channelName]) do
			if type(channelDT)=="table" and channelDT.metaInformations and name~="db" then
				--GuildAds:Print("clearing "..name.." for player "..playerName);
				channelDT:clear(playerName);
			end
		end
		self.db.Players[playerName] = nil;
		self:triggerEvent( self.PLAYER, playerName);
	end
end

function GuildAdsDBChannel:deletePlayers(id)
	local leaveChannel;
	local players;
	if id then
		players = { [id]=true }; -- don't check the whole list if we know only 1 id has changed.
	else
		players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
	end
	local workingTable = {};
	for playerName in pairs(players) do
		--GuildAds:Print("Checking player "..playerName..": allowed="..tostring(self:isPlayerAllowed(playerName)));
		if not self:isPlayerAllowed(playerName) then
			tinsert(workingTable, playerName);
			if playerName==GuildAds.playerName then
				leaveChannel=true;
			end
		end
	end
	for _, playerName in pairs(workingTable) do
		self:deletePlayer(playerName);
	end
	if leaveChannel then
		GuildAds:UnconfigureChannel();
	end
end

--[[
	event : 
	   - add/delete d'un joueur
	   - add/delete sur whitelist/guild, whitelist/player, blacklist/guild, blacklist/player
]]
function GuildAdsDBChannel:registerEvent(obj, method)
	self.eventRegistry[obj] = method or true;
end

function GuildAdsDBChannel:unregisterEvent(obj)
	self.eventRegistry[obj] = nil;
end

function GuildAdsDBChannel:triggerEvent(list, name)
	for obj, method in pairs(self.eventRegistry) do
		if method == true then
			obj(self, list, name)
		else
			if( obj[method] ) then 
				obj[method](self, list, name);
			end
		end
	end
end

function GuildAdsDBChannel:GetACLId(playerName, guildName)
	return playerName or "@"..guildName;
end

function GuildAdsDBChannel:IsGuildID(id)
	if id and string.sub(id,1,1)=="@" then
		return true;
	else
		return false;
	end
end

function GuildAdsDBChannel:isPlayerAllowed(playerName)
	local guildName;
	if GuildAdsDB.profile.Main then
		guildName = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Guild);
	end
	guildName=guildName or "";
	local dataType = GuildAdsDB.channel[GuildAds.channelName].Admin;
	local adminPlayer=dataType:getNewestData(playerName);
	local adminGuild=dataType:getNewestData("@"..guildName);
	-- player can either be allowed, not allowed or undefined (=allowed)
	if not adminPlayer and not adminGuild then	-- neither player nor guild mentioned in black- or whitelist
		return true;
	end
	if adminPlayer and not adminGuild then		-- only player is mentioned
		return adminPlayer.a;
	end
	if not adminPlayer and adminGuild then		-- only guild is mentioned
		return adminGuild.a;
	end
	-- both guild and player mentioned (both have to be allowed)
	return adminPlayer.a and adminGuild.a;
	
	--[[	
	if channelRoot.blackList.guilds[guildName] or channelRoot.blackList.players[playerName] then
		return false;
	end;
	if channelRoot.whiteList.guilds[guildName] or channelRoot.whiteList.players[playerName] then
		return true;
	end;
 	return nil;
	]]
end

function GuildAdsDBChannel:ShowACL()
	if GuildAds.channelName then
		local data;
		local dataType=GuildAdsDB.channel[GuildAds.channelName].Admin;
		for id in dataType:iteratorIds() do
			data=dataType:getNewestData(id);
			if GuildAdsDBChannel:IsGuildID(id) then
				GuildAds:Print("Guild "..string.sub(id,2).." is "..(data.a and "whitelisted" or "blacklisted").." for "..GuildAdsDB:FormatTime(data.t or 0).." with reason: "..tostring(data.c));
			else
				GuildAds:Print("Player "..id.." is "..(data.a and "whitelisted" or "blacklisted").." for "..GuildAdsDB:FormatTime(data.t or 0).." with reason: "..tostring(data.c));
			end
		end
	else
		self:Print(GUILDADS_ERROR_NOTINITIALIZED);
	end
end

function GuildAdsDBChannel:DenyPlayerGuild(id)
	if GuildAds.channelName then
		if CanGuildRemove() then
			GuildAdsDB.channel[GuildAds.channelName].Admin:set(GuildAds.playerName, id, { a=false, t=GuildAdsDB:GetCurrentTime() });
		end
	else
		self:Print(GUILDADS_ERROR_NOTINITIALIZED);
	end		
end

function GuildAdsDBChannel:AllowPlayerGuild(id)
	if GuildAds.channelName then
		if CanGuildRemove() then
			GuildAdsDB.channel[GuildAds.channelName].Admin:set(GuildAds.playerName, id, { a=true, t=GuildAdsDB:GetCurrentTime() });
		end
	else
		self:Print(GUILDADS_ERROR_NOTINITIALIZED);
	end		
end

function GuildAdsDBChannel:RemoveFromACL(id)
	if CanGuildRemove() then
		GuildAdsDB.channel[GuildAds.channelName].Admin:set(GuildAds.playerName, id, nil);
	end
end

function GuildAdsDBChannel:CheckACL(playerName)
	if playerName then
		local guildName;
		if GuildAdsDB.profile.Main then
			guildName = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Guild);
		end
		guildName=guildName or "";
		local dataType = GuildAdsDB.channel[GuildAds.channelName].Admin;
		local adminPlayer=dataType:getNewestData(playerName);
		local adminGuild=dataType:getNewestData("@"..guildName);
		-- player can either be allowed, not allowed or undefined (=allowed)
		if not adminPlayer and not adminGuild then	-- neither player nor guild mentioned in black- or whitelist
			GuildAds:Print(string.format("ID %s is allowed (default)",playerName));
			return true;
		end
		if adminPlayer and not adminGuild then		-- only player is mentioned
			GuildAds:Print(string.format("Player %s is%s allowed",playerName,adminPlayer.a and "" or " not"));
			return adminPlayer.a;
		end
		if not adminPlayer and adminGuild then		-- only guild is mentioned
			GuildAds:Print(string.format("Guild %s is%s allowed",playerName,adminGuild.a and "" or " not"));
			return adminGuild.a;
		end
		-- both guild and player mentioned (both have to be allowed)
		GuildAds:Print(string.format("Player %s is%s allowed %s guild %s is%s allowed",playerName,adminPlayer.a and "" or " not",
												(adminPlayer.a and adminGuild.a) and "and" or "but",
												adminGuild.a and "" or " not"));
		return adminPlayer.a and adminGuild.a;

		--GuildAds:Print("Player "..id.." is "..(GuildAdsDB.channel[GuildAds.channelName]:isPlayerAllowed(id) and "allowed" or "not allowed").." access.");
	end
end


-- TODO : une guilde peut etre blacklistée et whitelistée
--[[
	Type : datatype utilisé :
		["datatype"] = version
	Type d'ACL : 
		- blocage de l'écriture sur certains type de données.
		- blocage de la lecture sur certains type de données.
		- blocage complet de l'accès au channel.
	--> ["datatype"] = 3 valeurs possibles : "RW", "R", ""
	
	.guild[guild] = { 
		"TradeOffer" = "RW";
		"_" = 
	}
	
	plugin autorisée pour guilde
	["plugin"][who] = "RW"|"R"
]]
function GuildAdsDBChannel:addACLEntry(list, name, note)
	local t = self:getACL(list);
	if t[name] then
		t[name] = note or true;
		self:triggerEvent(list, name);
	end	
end

function GuildAdsDBChannel:deleteACLEntry(list, name)
	local t = self:getACL(list);
	if t[name] then
		t[name] = nil;
		self:triggerEvent(list, name);
	end	
end

function GuildAdsDBChannel:getACL(list)
	if list==self.PLAYER then
		return self.db.Players;
	elseif list==self.ALLOWEDPLAYER then
		return self.db.Admin.whiteList.players;
	elseif list==self.ALLOWEDGUILD then
		return self.db.Admin.whiteList.guilds;
	elseif list==self.DENIEDPLAYER then
		return self.db.Admin.blackList.players;
	elseif list==self.DENIEDGUILD then
		return self.db.Admin.blackList.guilds;
	end
end;

GuildAdsDBChannel.__index = GuildAdsDBChannel;

--[[ GuildAdsDBchannelMT ]]
GuildAdsDBchannelMT = {
	__index = function(t, n)
		local db = GuildAdsDBchannelMT.getChannel(n);
		-- TODO : db, eventRegistry invisibles sur une iteration sur t[n]
		t[n] = { 
			db = db;
			eventRegistry = {};
		};
		setmetatable(t[n], GuildAdsDBChannel);
		for name, datatype in pairs(GuildAdsDB._channelDataTypes) do
			t[n][name] = {
				channelName = n;
				channel = t;
				db = db;
			};
			setmetatable(t[n][name], { __index=datatype } );
			if t[n][name].InitializeChannel then
				t[n][name]:InitializeChannel();
			end
		end
		return t[n];
	end;
	
	-- TODO : gerer le case des noms
	getChannel = function(channelName)
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "Ask channel["..channelName.."]");
		channelName = GuildAdsDBchannelMT.getChannelKey(channelName);
		local t = GuildAdsDB.db.channels[channelName];
		if t == nil then
			t = {
				Players = {
				};
			};
			GuildAdsDB.db.channels[channelName] = t;
		end;
		if getmetatable(t) == nil then
			setmetatable(t, {
				__index = GuildAdsMagicMT.__index;
			});
		end
		return t;
	end;
	
	getChannelKey = function(channelName)
		return (channelName or GuildAds.channelName).."@"..GuildAds.factionName;
	end
}

--[[ GuildAdsDBprofileMT ]]
GuildAdsDBprofileMT = {
	__index = {
		getRaw = function(self, playerName)
			if playerName then
				local realm = GuildAdsDB.db;
				local t, mt;
				if realm.profiles[playerName] then
					t = realm.profiles[playerName];
					if getmetatable(t) == nil then
						setmetatable(t, {
							__index = GuildAdsMagicMT.__index;
						});
					end
				else
					t = {};
					setmetatable(t, {
						_table = realm.profiles;
						_key = playerName;
						__newindex = GuildAdsMagicMT.__newindex;
						__index = GuildAdsMagicMT.__index;
					});
				end
				return t;
			end	
		end;
	}
}

--[[ GuildAdsDB ]]
GuildAdsDB = { 
	_load = {};
	_channelDataTypes = {};
	VERSION = "20060512";
	CONFIG_PATH = { "Config" };
	PROFILE_PATH = { "Config", "Profile", GetCVar("realmName"), UnitName("player") };
}

function GuildAdsDB:RegisterDataType(dataType)
	if self._load then
		tinsert(self._load, dataType);
	else
		error("data type must registered at load time", 3);
	end
end

function GuildAdsDB:CreateAccount()
	local str = "";
	for i=1,4,1 do
		str = str .. string.char(math.random(65, 90));
	end
	str = str..self:GetCurrentTime();
	return str;
end

function GuildAdsDB:CreateDatabaseId()
	local str = string.sub(GuildAds.playerName, 1, 1);
	local t = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+*";
	for i=1,5,1 do
		local j = math.random(string.len(t));
		str = str .. string.sub(t, j, j);
	end
	return str;
end

function GuildAdsDB:Initialize()
	-- import from the version 20060311
	if GuildAds.db:get({}, "Version") == "20060311" then
		GuildAds.db:set({ "Config" }, "Account", GuildAds.db:get({}, "Account"));
		GuildAds.db:set({}, "Account", nil);
		GuildAds.db:set({}, "Version", nil);
		GuildAds.db:set({ "Versions" }, "DB", self.VERSION);
	end
	
	-- import from the version 20060426
	if GuildAds.db:get({"Metadata" }, "Version") == "20060426" then
		GuildAds.db:set({ }, "Metadata", nil);
		GuildAds.db:set({ "Versions" }, "DB", self.VERSION);
	end
	
	-- check version
	local currentVersion = GuildAds.db:get({ "Versions" }, "DB");
	if currentVersion ~= self.VERSION then
		if type(GuildAds.db)=="table" then
			GuildAds:Print("|cffff1e00All data are deleted (except account ID)|r");
			local account = GuildAds.db:get({ "Config" }, "Account");
			GuildAds.db:set({ }, "Data", nil);
			GuildAds.db:set({ }, "Config", nil);
			GuildAds.db:set({ }, "Versions", nil);
			--GuildAds.db:set({ }, "UpdateHistory", nil);
			GuildAds.db:set({ }, "DatabaseId", nil);
			self.account = GuildAds.db:set({ "Config" }, "Account", account);
		end
		GuildAds.db:set({ "Versions" }, "DB", self.VERSION);
	end;

	-- initialize account
	self.account = GuildAds.db:get({ "Config" }, "Account");
	if not self.account then
		-- TODO : not defined : try to get it on the network
		self.account = GuildAds.db:set({ "Config" }, "Account", self:CreateAccount());
	end
	
	-- initialize database id
	self.databaseId = GuildAds.db:get({ }, "DatabaseId");
	if not self.databaseId then
		self.databaseId = GuildAds.db:set({ }, "DatabaseId", self:CreateDatabaseId());
	end
	
	-- initialize realm
	self.db = GuildAds.db:get({"Data"}, GuildAds.realmName);
	if not self.db then
		self.db = GuildAds.db:set({"Data"}, GuildAds.realmName, 
		{
			profiles = {};
			channels = {}
		});
	end
	
	-- initialize profile & channel
	self.profile = {};
	self.channel = {};
	setmetatable(GuildAdsDB.channel, GuildAdsDBchannelMT);
	setmetatable(GuildAdsDB.profile, GuildAdsDBprofileMT);
	
	-- prioritize data types
	local priority=100
	local list = {}
	while true do
		-- check dependency of every module
		tmp = {}
		for _, dataType in pairs(self._load) do
			if not list[dataType.metaInformations.name] then
				local dependencyFailed=false;
				for _, dependency in pairs(dataType.metaInformations.depend) do
					if not list[dependency] then
						dependencyFailed=true;
					end
				end
				if not dependencyFailed then
					tinsert(tmp,dataType.metaInformations.name)
				end
			end
		end
		if #tmp == 0 then
			break
		end
		-- pick one from tmp at random
		local i=math.random(#tmp)
		list[tmp[i]]=priority;
		priority=priority+100;
	end
	for _, dataType in pairs(self._load) do
		if list[dataType.metaInformations.name] then
			dataType.metaInformations.priority = list[dataType.metaInformations.name];
			GuildAds_ChatDebug(GA_DEBUG_STORAGE,"datatype "..dataType.metaInformations.name.." is given priority "..dataType.metaInformations.priority);
		else
			dataType.metaInformations.priority = priority;
			GuildAds_ChatDebug(GA_DEBUG_STORAGE,"datatype "..dataType.metaInformations.name.." is given default priority "..dataType.metaInformations.priority);
			priority=priority+100;
		end
	end

	
	-- initialize data types
	local metadataPath = { "Versions", "DataTypes" };
	for _, dataType in pairs(self._load) do
		local name = dataType.metaInformations.name;
		dataType.profile = self.profile;
		if dataType.metaInformations.parent == GuildAdsDataType.PROFILE then
			dataType.db = self.db.profiles;
			self.profile[name] = dataType;
		elseif dataType.metaInformations.parent == GuildAdsDataType.CHANNEL then
			self._channelDataTypes[name] = dataType;
		end
		
		local version = GuildAds.db:get(metadataPath, name);
		local current = version and version.Current or 0;
		local mostRecent = version and version.MostRecent or dataType.metaInformations.version;
		if type(dataType.Initialize)=="function" then
			dataType:Initialize(current);
		end
		GuildAds.db:set(metadataPath, name, {Current=dataType.metaInformations.version, MostRecent=mostRecent});
	end
	
	self._load = nil;
end

function GuildAdsDB:ResetAll()
	GuildAds.db:set({ "Versions" }, "DB", "Reset");
	ReloadUI();
end

function GuildAdsDB:ResetChannel(channelName)
	GuildAdsDB.db.channels[GuildAdsDBchannelMT.getChannelKey(channelName)] = nil;
	ReloadUI();
end

function GuildAdsDB:ResetOthers()
	GuildAds:Print("Not implemented");
end

--[[ About config ]]
function GuildAdsDB:GetConfigValue(path, key, defaultValue)
	return GuildAds.db:get(path, key) or defaultValue;
end

-- GALMOK -- needed a way to read the raw db value
function GuildAdsDB:GetRawConfigValue(path, key)
	return GuildAds.db:get(path, key);
end

function GuildAdsDB:SetConfigValue(...)
	local path, key, val = GuildAds.db:_GetArgs({...})
	local node = GuildAds.db:_GetNode(path, TRUE)
	if not key then error("No key supplied to AceDatabase:set.", 2) end
	local changed = node[key] ~= val;
	node[key] = val
	return changed;
end

--[[About time]]

--[[
	Provide a common time between different players.
	Return the number of minutes since 11/2/2005 00h00 (date of the WOW release in Europe)
	Get UTC time, using server time and PC date.
	do not use UTC ( !*t ) to avoid to much difference between server and PC time.
]]
function GuildAdsDB:GetCurrentTime()
	local hours,minutes = GetGameTime();
	local t = date("*t");
	t.wday = nil;
	t.yday = nil;
	t.isdst = nil;
	t.sec = nil;
	
	local local_min = t.hour*60+t.min;
	local server_min = hours*60+minutes; 
	
	local TimeShift = server_min-local_min;
	if math.abs(TimeShift)>=12*60 then
		if local_min<server_min then
			TimeShift = TimeShift-DayMin;
		else
			TimeShift = TimeShift+DayMin;
		end
	end
	
	t.hour, t.min = hours, minutes;
	-- local_min+TimeShift : server time not round between 0 and DayMin
	return math.floor(time(t) / 60)+math.floor((local_min+TimeShift)/DayMin)*DayMin-TimeRef;
end

-- A migrer dans GuildAds/ui/GuildAdsUI.lua
function GuildAdsDB:FormatTime(ref, relative)
	local delta;
	local prefix = "";
	if relative then
		delta = tonumber(ref);
	else
		delta = self:GetCurrentTime()-tonumber(ref);
	end
	
	if delta<0 then
		prefix = "-";
		delta = -delta;
	end
	
	month = math.floor(delta / MonthMin);
	deltamonth = math.fmod(delta, MonthMin);
	
	day = math.floor(deltamonth / DayMin);
	deltaday = math.fmod(delta, DayMin);
	
	hour = math.floor(deltaday / HourMin);
	minute = math.fmod(delta, HourMin);
	
	if (month > 0) then
		return prefix..string.format(GetText("LASTONLINE_MONTHS", nil, month), month);
	elseif (day > 0) then
		return prefix..string.format(GetText("LASTONLINE_DAYS", nil, day), day);
	elseif (hour > 0) then
		return prefix..string.format(GetText("LASTONLINE_HOURS", nil, hour), hour);
	else
		return prefix..string.format(GetText("GENERIC_MIN", nil, minute), minute);
	end
end
