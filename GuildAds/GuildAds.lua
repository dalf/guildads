----------------------------------------------------------------------------------
--
-- GuildAds.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GUILDADS_VERSION          = 200.1;

GUILDADS_MAX_CHANNEL_JOIN_ATTEMPTS = 5;				-- Wait 8 seconds more if no channel are joined

GA_DEBUG_GLOBAL = 1;
GA_DEBUG_CHANNEL = 2;
GA_DEBUG_CHANNEL_HIGH = 3;
GA_DEBUG_PROTOCOL = 4;
GA_DEBUG_STORAGE = 5;
GA_DEBUG_GUI = 6;
GA_DEBUG_PLUGIN = 8;

GUILDADS_MAPBOOLEAN = {
	[true] = "Yes",
	[false] = "No"
}

GuildAds = AceAddon:new({
	name          = GUILDADS_TITLE,
    description   = GUILDADS_TITLE,
    version       = "2.0 alpha",
    releaseDate   = "03-08-2006",
    aceCompatible = 103,
    author        = "Zarkan, Fkai",
    email         = "guildads@gmail.com",
    website       = "http://guildads.sourceforge.net",
    category      = "guild",
    optionsFrame  = "GuildAdsOptionsWindowFrame",
    db            = AceDatabase:new("GuildAdsDatabase"),
    defaults      = DEFAULT_OPTIONS,
    cmd           = AceChatCmd:new(GUILDADS_CMD, GUILDADS_CMD_OPTIONS),
	
	channelJoined   	= false,			--- Is GuildAds channelJoined?
	joinChannelAttempts = 0,
	channelName			= "",
	channelPassword		= "",
	playerName 			= false,
	windows				= {}
})

function GuildAds:Initialize()
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:Initialize] begin");
	
	-- Start uninitialized
	GuildAds.channelJoined = false;
	
	-- RegisterEvent
	self:RegisterEvent("PLAYER_GUILD_UPDATE", "CheckChannelName");
	self:RegisterEvent("RAID_ROSTER_UPDATE", "CheckChannelName");
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "CheckChannelName");
	
	-- Init player name, faction name, realm name
	self.playerName = UnitName("player");
	self.factionName = UnitFactionGroup("player");
	self.realmName = GetCVar("realmName");
	
	-- Initialize database
	GuildAdsDB:Initialize(); 
		
	-- Initialize network
	GuildAdsComm:Initialize()
	
	-- Register plugins
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_RegisterPlugins] begin");
	GuildAdsPlugin_RegisterPlugins();
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_RegisterPlugins] end");
	
	-- Initialize windows (main, options, inspect)
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsWindow:Create] begin");
	for _, window in self.windows do
		window:Create()
	end
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsWindow:Create] end");
	
	-- Initialize Plugins
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_OnInit] begin");
  	GuildAdsPlugin_OnInit();
  	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_OnInit] end");
	
	-- Call GuildAds:JoinChannel() in 8 seconds
	GuildAdsSystem:Show();
	GuildAdsSystem.InitTimer = 8;
	
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:Initialize] end");
end

function GuildAds:JoinChannel()
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:JoinChannel] begin");

	-- already init ?
	if GuildAds.channelJoined then
		return;
	end
	
	-- does general channels exists ? if not delayed init
	local firstChannelNumber = GetChannelList();
	if (firstChannelNumber == nil) then
		GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds_Init] delay - channels");
		self.joinChannelAttempts = self.joinChannelAttempts +1;
		if (self.joinChannelAttempts <= GUILDADS_MAX_CHANNEL_JOIN_ATTEMPTS) then
			GuildAdsSystem.InitTimer = 2;
			return;
		end
	end
	
	-- Init du channel
	self.channelName, self.channelPassword = self:GetDefaultChannel();
	
	-- GuildAdsComm : init
	GuildAdsComm:JoinChannel(self.channelName, self.channelPassword)
	
	-- Init first step done
	GuildAds.channelJoined = true;
	
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:JoinChannel] end");
end

function GuildAds:ChangeChannel()
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:ChangeChannel]");
	-- TODO : retirer sa présence du channel
	
	GuildAds.channelJoined = false;
	
	GuildAdsSystem.InitTimer = 2;
end

function GuildAds:ToggleMainWindow()
	self:ToggleWindow("main");
end

function GuildAds:ToggleOptionsWindow()
	self:ToggleWindow("options");
end

function GuildAds:ToggleWindow(name)
	if (self.channelJoined) then
		local frame = getglobal(self.windows[name].frame)
		if frame:IsVisible() then
			frame:Hide();
		else
			frame:Show();
		end
	else
		self.cmd:error("GuildAds is not initialized.");
	end
end

function GuildAds:ShowWindow(name)
	if (self.channelJoined) then
		getglobal(self.windows[name].frame):Show();
	else
		self.cmd:error("GuildAds is not initialized.");
	end
end

function GuildAds:HideWindow(name)
	if (self.channelJoined) then
		getglobal(self.windows[name].frame):Hide();
	else
		self.cmd:error("GuildAds is not initialized.");
	end
end

function GuildAds:ToggleDebugOn()
	GuildAds_DebugPlugin.logMessages(true);
	self.cmd:status("Debug tab", TRUE, ACEG_MAP_ONOFF)
end

function GuildAds:ToggleDebugOff()
	GuildAds_DebugPlugin.logMessages(false);
	self.cmd:status("Debug tab", FALSE, ACEG_MAP_ONOFF)
end

function GuildAds:DisplayDebugInfo()
	self.cmd:report({
		{text="version ", val=GUILDADS_VERSION },
		{text="playerName", val=tostring(self.playerName) },
		{text="account", val=tostring(GuildAdsDB.account) },
		{text="faction", val=tostring(self.factionName) },
		{text="realm", val=tostring(self.realmName) },
		{text="channelJoined", val=self.channelJoined, map=GUILDADS_MAPBOOLEAN},
		{text="channel", val=tostring(self.channelName) },
		{text="joinChannelAttempts", val=tostring(self.joinChannelAttempts) }
	});
end

function GuildAds:ResetAll()
	self.channelJoined = false;
	GuildAdsDatabase.Version = "reset";
	ReloadUI();
end

function GuildAds:ResetChannel()
end

function GuildAds:ResetOthers()
end

function GuildAds:CheckChannelName()
	if self.channelJoined and self:GetDefaultChannel() ~= self.channelName then
		GuildAds:ChangeChannel()
	end
end

function GuildAds:GetDefaultChannel()
	local channel = GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelName");
	if not channel then
		-- If in a guild
		local go_guildName, go_GuildRankName, go_guildRankIndex = GetGuildInfo("player");
		if go_guildName then			
			-- channel name bases on the guild name
			name = "GuildAds";
			for word in string.gfind(go_guildName,"[^ ]+") do
				name = name..word;
			end
			if (strlen(name) > 31) then
				name = string.sub(name, 0, 31);
			end
			channel = name;
		end
		
		-- channel name bases on the raid leader name
		if GetNumRaidMembers()>0 then
			for i=1, GetNumRaidMembers(), 1 do
				local name, rank = GetRaidRosterInfo(Raid_Member_ID_Number);
				if rank==2 then
					channel = "GuildAds"..name;
				end
			end
		end
		
		-- channel name bases on the group leader name 
		if ( GetNumPartyMembers() > 0 ) then
			for groupindex = 1,4 do
				local unit = "party"..groupindex;
				if UnitIsPartyLeader(unit) then
					channel = "GuildAds"..UnitName(unit);
				end
			end
		end
		
		-- channel name bases on the player name
		if not channel then
			channel = "GuildAds"..GuildAds.playerName;
		end
	end
	return channel, GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelPassword");
end

function GuildAds:SetDefaultChannel(name, password)
	if 		GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelName", name) 
		or  GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelPassword", password) then
		GuildAds:ChangeChannel()
	end
end

function GuildAds:GetDefaultChannelAlias()
	return GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelCommand", "ga"), GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelAlias", "GuildAds");
end

function GuildAds:SetDefaultChannelAlias(command, alias)
	if 		GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelCommand", command) 
		 or GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelAlias", alias) then
		SimpleComm_InitAlias(command, alias);
	end
end

GuildAds:RegisterForLoad()

---------------------------------------------------------------------------------
--
-- Called by WOW for each frame
-- 
---------------------------------------------------------------------------------
function GuildAds_OnUpdate(elapsed)
	GuildAdsComm:ProcessQueues(elapsed);
	if (this.InitTimer) then
		this.InitTimer = this.InitTimer - elapsed;
		if (this.InitTimer <= 0) then
			this.InitTimer = nil;
			GuildAds:JoinChannel()
		end
	end
end

---------------------------------------------------------------------------------
--
-- Debug function
-- 
---------------------------------------------------------------------------------
function GuildAds_ChatDebug()
end