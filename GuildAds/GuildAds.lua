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

GA_DEBUG_GLOBAL = 1;
GA_DEBUG_CHANNEL = 2;
GA_DEBUG_CHANNEL_HIGH = 3;
GA_DEBUG_PROTOCOL = 4;
GA_DEBUG_STORAGE = 5;
GA_DEBUG_GUI = 6;
GA_DEBUG_PLUGIN = 8;

if not AceLibrary then
	ChatFrame1:AddMessage("GuildAds: Ace2 not found", 1, 0, 0);
end
GuildAds = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceHook-2.1", "AceConsole-2.0", "AceDB-2.0","AceDebug-2.0");
GuildAds:RegisterDB("GuildAdsDatabase");
GuildAds:RegisterDefaults('char',
	{   ['**'] = {},
		ChannelConfig = 'automatic',
		ChannelCommand = 'ga',
		ChannelAlias = 'GuildAds'
	});
    
--~ GuildAds:RegisterDefaults('profile', {
--~      ['*'] = {}
--~ })
GuildAds:RegisterChatCommand(GUILDADS_CMD, GUILDADS_CMD_OPTIONS);

GuildAds.channelName = nil;
GuildAds.channelPassword = nil;
GuildAds.channelNameFrom = nil;
GuildAds.playerName = false;
GuildAds.guildName = false;
GuildAds.windows = {};

function GuildAds:OnInitialize()
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:OnInitialize] begin");
--~ 	self.dbZZ = self.db;
--~ 	self.db = self.dbZZ.profile;
	
	-- Check if GuildAds is still GuildAds (not erased by SavedVariables/GuildAds.lua version 1)
	if GuildAds.windows then
		GuildAdsBackup = nil
	else
		GuildAds = GuildAdsBackup;
		self = GuildAds;
	end
    self:SetDebugging(true)
    self:Debug(GuildAds.db.profile.Versions)
--~ 	GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,GuildAds.db.profile.Versions.DataTypes["Main"]);
	-- Init player name, faction name, realm name
	self.playerName = UnitName("player");
	self.factionName = UnitFactionGroup("player");
	self.realmName = GetCVar("realmName");
	if IsInGuild() then
		self.guildName = GetGuildInfo("player");
		if not self.guildName then
			GuildAdsTask:AddNamedSchedule("GetGuildName", 4, nil, nil, self.PLAYER_GUILD_UPDATE, self)
		end
	end
	
	-- RegisterEvent
	self:RegisterEvent("PLAYER_GUILD_UPDATE");
	self:RegisterEvent("GUILD_ROSTER_UPDATE");
	
	-- Initialize database
	GuildAdsDB:Initialize(); 
		
	-- Initialize network
	GuildAdsComm:Initialize()
	
	-- LoadGuildRosterTask
	self:LoadGuildRosterTask();
	GuildAdsTask:AddNamedSchedule("LoadGuildRosterTask", 240, true, nil, self.LoadGuildRosterTask, self);
	
	-- Register plugins
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_RegisterPlugins] begin");
	GuildAdsPlugin_RegisterPlugins();
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_RegisterPlugins] end");
	
	-- Initialize windows (main, options, inspect)
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsWindow:Create] begin");
<<<<<<< .mine
	for _, window in pairs(self.windows) do
        window:Create()
=======
	for _, window in pairs(self.windows) do
		window:Create()
>>>>>>> .r166
	end
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsWindow:Create] end");
	
	-- Initialize Plugins
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_OnInit] begin");
  	GuildAdsPlugin_OnInit();
  	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_OnInit] end");
	
	-- Call GuildAds:JoinChannel() in 8 seconds
	GuildAdsSystem:Show();
	GuildAdsTask:AddNamedSchedule("JoinChannel", 8, nil, nil, self.JoinChannel, self)
	
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:OnInitialize] end");
end

function GuildAds:JoinChannel()
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:JoinChannel] begin");
	GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"-----");
	-- Init du channel
    GuildAds:DisplayDebugInfo();
	GuildAds.channelName, GuildAds.channelPassword, GuildAds.channelNameFrom = GuildAds:GetDefaultChannel();
	
	if GuildAds.channelName then
		local command, alias = GuildAds:GetDefaultChannelAlias();
		GuildAdsComm:JoinChannel(GuildAds.channelName, GuildAds.channelPassword, command, alias);
	end
	
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:JoinChannel] end");
end

function GuildAds:LeaveChannel()
	GuildAdsComm:LeaveChannel();
end

function GuildAds:ToggleMainWindow()

GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"---+++--");
	self:ToggleWindow("main");
end

function GuildAds:ToggleOptionsWindow()
	self:ToggleWindow("options");
end

function GuildAds:ToggleWindow(name)
	if (self.channelName) then
		local frame = getglobal(self.windows[name].frame)
		if frame:IsVisible() then
			frame:Hide();
		else
			frame:Show();
		end
	else
		self:CustomPrint(1, 0, 0, nil, nil, nil, GUILDADS_ERROR_NOTINITIALIZED);
	end
end

function GuildAds:ShowWindow(name)
	if (self.channelName) then
		getglobal(self.windows[name].frame):Show();
	else
		self:CustomPrint(1, 0, 0, nil, nil, nil, GUILDADS_ERROR_NOTINITIALIZED);
	end
end

function GuildAds:HideWindow(name)
	if (self.channelName) then
		getglobal(self.windows[name].frame):Hide();
	else
		self:CustomPrint(1, 0, 0, nil, nil, nil, GUILDADS_ERROR_NOTINITIALIZED);
	end
end

function GuildAds:IsDebugging()
	if GuildAds_DebugPlugin then
		return GuildAds_DebugPlugin.showDebug() and "on" or "off";
	else
		return "off";
	end
end

function GuildAds:SetDebug(value)
GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"de");
	if GuildAds_DebugPlugin then
    GuildAds:CustomPrint(1, 0, 0, nil, nil, nil," opn");
		GuildAds_DebugPlugin.logMessages(value == "on");
	end
end

function GuildAds:DisplayDebugInfo()
	local status, message = GuildAdsComm:GetChannelStatus();
	message = message and status.."("..message..")" or status;
	self:Print("version: ", tostring(GUILDADS_VERSION));
	self:Print("Player name: ", tostring(self.playerName));
	self:Print("Guild name: ", tostring(self.guildName));
	self:Print("Account: ", tostring(GuildAdsDB.account));
	self:Print("Faction: ", tostring(self.factionName));
	self:Print("Realm: ", tostring(self.realmName));
	self:Print("Channel: ", tostring(self.channelName));
	self:Print("Channel status: ", tostring(message));
end

function GuildAds:ResetAll()
	GuildAdsDB:ResetAll();
end

function GuildAds:ResetChannel()
	GuildAdsDB:ResetChannel(self.channelName);
end

function GuildAds:ResetOthers()
	GuildAdsDB:ResetOthers();
end

function GuildAds:LoadGuildRosterTask()
	if IsInGuild() then
		GuildRoster();
	end
end

function GuildAds:PLAYER_GUILD_UPDATE()
	local guildName = GetGuildInfo("player");
	if guildName ~= self.guildName then
		self:LoadGuildRosterTask();
	end
	self:CheckChannelConfig();
end

function GuildAds:GUILD_ROSTER_UPDATE()
	self.guildName = GetGuildInfo("player");
	self:CheckChannelConfig();
end

function GuildAds:CheckChannelConfig()
	local channelName, channelPassword = self:GetDefaultChannel();
	if 		self.channelName 
		and (channelName ~= self.channelName or	channelPassword ~= self.channelPassword) then
		GuildAdsComm:LeaveChannel()
		if channelName then
			GuildAdsTask:AddNamedSchedule("JoinChannel", 2, nil, nil, self.JoinChannel, self)
		end
	end
end

function GuildAds:GetDefaultChannel()
	local configType = GuildAds.db.char.ChannelConfig;
	local source, channel, password;
	if configType=="manual" then
		source="user"
		channel = GuildAds.db.char.ChannelName;
		password = GuildAds.db.char.ChannelPassword;
	elseif configType=="automatic" then
		-- If in a guild
		if self.guildName then
			-- channel name bases on the guild info text
			local startIndex;
			startIndex, _, channel, password = string.find(GetGuildInfoText() or "", "%[GA:([^,%]]+),?([^%]]*)%]");
			if startIndex then
				if password=="" then
					password=nil;
				end
				source = "guildInfo"
			else
				-- channel name bases on the guild name
				channel = "GuildAds"..string.gsub(self.guildName, "\ ", "");
				if (strlen(channel) > 31) then
					channel = string.sub(channel, 0, 31);
				end
				source = "guildName";
			end
		end
	end
	
	-- For now, GuildAds doesn't work if there is no channel at all, so define a default one
	if not channel then
		channel = "GuildAds"..self.playerName;
	end
	
	return channel, password, source;
end

function GuildAds:GetDefaultChannelAlias()
	return GuildAds.db.char.ChannelCommand, GuildAds.db.char.ChannelAlias;
end

function GuildAds:SetDefaultChannelAlias(command, alias)
	if 	GuildAds.db.char.ChannelCommand ~= command or
		GuildAds.db.char.ChannelAlias ~= alias then
		GuildAds.db.char.ChannelCommand = command;
		GuildAds.db.char.ChannelAlias = alias;
		SimpleComm_SetAlias(command, alias);
	end
end

---------------------------------------------------------------------------------
--
-- Debug function
-- 
---------------------------------------------------------------------------------
function GuildAds_ChatDebug()
end

---------------------------------------------------------------------------------
--
-- Create a copy of GuildAds table (may be erased by SavedVariables/GuildAds.lua version 1)
-- 
---------------------------------------------------------------------------------
GuildAdsBackup = {};
for k, v in pairs(GuildAds) do
	GuildAdsBackup[k] = v;
end
setmetatable(GuildAdsBackup, getmetatable(GuildAds));

function ga_table_erase(t)
	for i in pairs(t) do
		t[i] = nil
	end	
end