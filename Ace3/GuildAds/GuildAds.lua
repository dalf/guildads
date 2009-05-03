----------------------------------------------------------------------------------
--
-- GuildAds.lua
--
-- Author: Zarkan@Ner'zhul-EU, Fkaï@Ner'zhul-EU, Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GUILDADS_REVISION_NUMBER = tonumber((GUILDADS_REVISION or "1"):match("(%d+)"))

---------------------------------------------------------------------------------
--
-- Debug function
-- 
---------------------------------------------------------------------------------
GA_DEBUG_GLOBAL = 1;
GA_DEBUG_CHANNEL = 2;
GA_DEBUG_CHANNEL_HIGH = 3;
GA_DEBUG_PROTOCOL = 4;
GA_DEBUG_STORAGE = 5;
GA_DEBUG_GUI = 6;
GA_DEBUG_PLUGIN = 8;
GA_DEBUG_HASH = 9;

function GuildAds_ChatDebug()
end

function ga_table_erase(t)
	for i in pairs(t) do
		t[i] = nil
	end	
end

---------------------------------------------------------------------------------
--
-- new/del/deepDel
-- 
---------------------------------------------------------------------------------
GA_new_table = 0
GA_reuse_table = 0
local new, new_kv, del, deepDel
do
	local debugmt = {
		__index = function(t,k)
			geterrorhandler()("Trying to access freed table: key "..tostring(k).."\n"..debugstack())
		end;
		__newindex = function(t,k,v)
			geterrorhandler()("Trying to insert new key in freed table: "..tostring(k).." with value "..tostring(v).."\n"..debugstack())
		end;
	}
	local list = setmetatable({},{__mode='k'})
	function new(...)
		local t = next(list)
		if t then
			setmetatable(t, nil)
			list[t] = nil
			for i = 1, select('#', ...) do
				t[i] = select(i, ...)
			end
			GA_reuse_table = GA_reuse_table + 1
			return t
		else
			GA_new_table = GA_new_table + 1
			return {...}
		end
	end
	function new_kv(...)
		local t = next(list)
		if t then
			setmetatable(t, nil)
			list[t] = nil
			GA_reuse_table = GA_reuse_table + 1
		else
			GA_new_table = GA_new_table + 1
			t = {}
		end
		for i = 1, select('#', ...),2 do
			t[select(i, ...)] = select(i+1, ...)
		end
		return t
	end
	function del(t)
		if type(t)=="table" then
			for k in pairs(t) do
				t[k] = nil
			end
			t[''] = true
			t[''] = nil
			list[t] = true
			setmetatable(t, debugmt)
		end
		return nil
	end
	function deepDel(t)
		if type(t)=="table" then
			for k,v in pairs(t) do
				if type(v) == "table" then
					deepDel(v)
				end
				t[k] = nil
			end
			t[''] = true
			t[''] = nil
			list[t] = true
			setmetatable(t, debugmt)
		end
		return nil
	end
end

---------------------------------------------------------------------------------
--
-- GuildAds addon
-- 
---------------------------------------------------------------------------------
local ccmd = assert(LibStub("AceConfigCmd-3.0"))
local creg = assert(LibStub("AceConfigRegistry-3.0"))

GuildAds = LibStub("AceAddon-3.0"):NewAddon("GuildAds", "AceEvent-3.0", "AceConsole-3.0")
GuildAds.channelName = nil
GuildAds.channelPassword = nil
GuildAds.channelNameFrom = nil
GuildAds.playerName = UnitName("player")
GuildAds.guildName = false
GuildAds.windows = {}
GuildAds.db = GAAceDatabase:new("GuildAdsDatabase")

GuildAds.new = new
GuildAds.new_kv = new_kv
GuildAds.del = del
GuildAds.deepDel = deepDel

function GuildAds:OnInitialize()
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:Initialize] begin");
	
	-- Initialize options
	creg:RegisterOptionsTable("GuildAds", GuildAds.options)
	ccmd:CreateChatCommand("guildads", "GuildAds")
	
	-- Initialize GuildAdsTask
	GuildAdsTask:Initialize();
	
	-- Initialize GAAceDatabase
	self.db:Initialize()
		
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
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_LEAVING_WORLD");
	
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
	for _, window in pairs(self.windows) do
		window:Create()
	end
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsWindow:Create] end");
	
	-- Initialize Plugins
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_OnInit] begin");
  	GuildAdsPlugin_OnInit();
  	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAdsPlugin_OnInit] end");
		
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:Initialize] end");
end

function GuildAds:JoinChannel()
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:JoinChannel] begin");
	
	-- Init du channel
	self.channelName, self.channelPassword, self.channelNameFrom = self:GetDefaultChannel();
	
	if self.channelName then
		local command, alias = GuildAds:GetDefaultChannelAlias();
		GuildAdsComm:JoinChannel(self.channelName, self.channelPassword, command, alias);
	end
	
	GuildAds_ChatDebug(GA_DEBUG_GLOBAL,"[GuildAds:JoinChannel] end");
end

function GuildAds:LeaveChannel()
	GuildAdsComm:LeaveChannel();
end

function GuildAds:ToggleMainWindow()
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
		self:Print(GUILDADS_ERROR_NOTINITIALIZED);
	end
end

function GuildAds:ShowWindow(name)
	if (self.channelName) then
		getglobal(self.windows[name].frame):Show();
	else
		self:Print(GUILDADS_ERROR_NOTINITIALIZED);
	end
end

function GuildAds:HideWindow(name)
	if (self.channelName) then
		getglobal(self.windows[name].frame):Hide();
	else
		self:Print(GUILDADS_ERROR_NOTINITIALIZED);
	end
end

function GuildAds:SelectWindowFrame(name, frameName)
	if (self.channelName) then
		getglobal(self.windows[name].frame):Show();
		self.windows[name]:SelectFrame(frameName);
	else
		self:Print(GUILDADS_ERROR_NOTINITIALIZED);
	end	
end

function GuildAds:DebugToggleSet(info, val)
	if GuildAds_DebugPlugin then
		GuildAds_DebugPlugin.logMessages(val)
	end
end

function GuildAds:DebugToggleGet()
	if GuildAds_DebugPlugin then
		return GuildAds_DebugPlugin.showDebug
	else
		return false
	end
end

function GuildAds:DebugDisplayInfo()
	local status, message = GuildAdsComm:GetChannelStatus();
	message = message and status.."("..message..")" or status;
	self:Print("Version: ",  GUILDADS_REVISION_STRING)
	self:Print("Player name: ", self.playerName)
	self:Print("Guild name: ", self.guildName)
	self:Print("Account: ", GuildAdsDB.account)
	self:Print("Faction: ", self.factionName)
	self:Print("Realm: ", self.realmName)
	self:Print("Channel: ", self.channelName)
	self:Print("Channel Status: ", message)
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

function GuildAds:ResetPlayer(_,playerName)
	GuildAdsDB.channel[GuildAds.channelName]:deletePlayer(playerName);
end

function GuildAds:CleanOther()
	if GuildAdsTradeSkillDataType then
		GuildAdsTradeSkillDataType:deleteOtherTradeSkillItems();
	end
end

function GuildAds:ShowACL()
	GuildAdsDBChannel:ShowACL();
end

function GuildAds:DenyPlayerGuild(_,id)
	GuildAdsDBChannel:DenyPlayerGuild(id);
end

function GuildAds:AllowPlayerGuild(_,id)
	GuildAdsDBChannel:AllowPlayerGuild(id);
end

function GuildAds:RemoveFromACL(_,id)
	GuildAdsDBChannel:RemoveFromACL(id);
end

function GuildAds:CheckACL(_,id)
	GuildAdsDBChannel:CheckACL(id);
end

function GuildAds:LoadGuildRosterTask()
	if IsInGuild() and not self.roster_updated then
		GuildRoster();
	end
end

function GuildAds:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("GUILD_ROSTER_UPDATE"); -- Only happens when in a guild and GuildRoster has been called. (may never happen)
	self:RegisterEvent("PLAYER_GUILD_UPDATE"); -- Happens on change in guild or friendlist. (may never happen)
	self:LoadGuildRosterTask();
	GuildAdsTask:AddNamedSchedule("LoadGuildRosterTask", 240, true, nil, self.LoadGuildRosterTask, self); -- check guild roster every 4 minutes
	if not IsInGuild() then
		GuildAdsTask:AddNamedSchedule("CheckChannelConfigTask", 12, nil, nil, self.CheckChannelConfig, self); -- check channel config after 12 seconds
	end
end

function GuildAds:PLAYER_LEAVING_WORLD()
	self:UnregisterEvent("GUILD_ROSTER_UPDATE");
	self:UnregisterEvent("PLAYER_GUILD_UPDATE");
	GuildAdsTask:DeleteNamedSchedule("LoadGuildRosterTask")
end

function GuildAds:PLAYER_GUILD_UPDATE()
	local guildName = GetGuildInfo("player");
	if guildName ~= self.guildName then
		self:LoadGuildRosterTask();
	end
end

function GuildAds:GUILD_ROSTER_UPDATE()
	if not self.roster_updated then
		self.guildName = GetGuildInfo("player");
		self.roster_updated=true;
		GuildAdsTask:AddNamedSchedule("GuildInfoIsReadable", 10, nil, nil, self.GuildInfoIsReadable, self);
		self:CheckChannelConfig();
		GuildAdsTask:DeleteNamedSchedule("CheckChannelConfigTask");
	end
end

function GuildAds:GuildInfoIsReadable()
	self.roster_updated=nil;
end

function GuildAds:UnconfigureChannel()
	-- not allow to stay on the channel -> unconfigure the current config
	GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelConfig", nil); -- or "none"?
	GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelName", nil);
	GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelPassword", nil);
	GuildAds:CheckChannelConfig();
	self:Print("You are not allow to use this channel !");	
end

function GuildAds:CheckChannelConfig()
	local channelName, channelPassword = self:GetDefaultChannel();
	if (channelName ~= self.channelName or channelPassword ~= self.channelPassword) then
		if self.channelName then
			GuildAdsComm:LeaveChannel()
		end
		if channelName then
			GuildAdsTask:AddNamedSchedule("JoinChannel", 2, nil, nil, self.JoinChannel, self)
		end
	end
end

function GuildAds:GetDefaultChannel()
	local configType = GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelConfig") or "automatic";
	local source, channel, password;
	if configType=="manual" then
		source="user"
		channel = GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelName");
		password = GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelPassword");		
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
	return GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelCommand", "ga"), GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelAlias", "GuildAds");
end

function GuildAds:SetDefaultChannelAlias(command, alias)
	if 		GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelCommand", command) 
		 or GuildAdsDB:SetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelAlias", alias) then
		SimpleComm_SetAlias(command, alias);
	end
end

---------------------------------------------------------------------------------
--
-- Options
-- 
---------------------------------------------------------------------------------
GuildAds.options = {
	type="group",
	args = {
		toggle = {
			name = "toggle",
			desc = GUILDADS_OPTIONS["toggle"],
			type = "execute",
			handler = GuildAds,
			func = "ToggleMainWindow"
		},
		options = {
			name = "options",
			desc = GUILDADS_OPTIONS["options"],
			type = "execute",
			handler = GuildAds,
			func = "ToggleOptionsWindow"
		},
		debug = {
			name = "debug",
			desc = GUILDADS_OPTIONS["debug"],
			type = "toggle",
			handler = GuildAds,
			get  = "DebugToggleGet",
			set  = "DebugToggleSet"
		},
		info = {
			name = "info",
			desc = GUILDADS_OPTIONS["info"],
			type = "execute",
			handler = GuildAds,
			func = "DebugDisplayInfo"
		},
		reset = {
			name = "reset",
			desc = GUILDADS_OPTIONS["reset"],
			type = "group",
			args = {
				all = {
					name = "all",
					desc = GUILDADS_OPTIONS["reset all"],
					type = "execute",
					handler = GuildAds,
					func = "ResetAll"
				},
				channel = {
					name = "channel",
					desc = GUILDADS_OPTIONS["reset channel"],
					type = "execute",
					handler = GuildAds,
					func = "ResetChannel"
				},
				others = {
					name = "others",
					desc = GUILDADS_OPTIONS["reset others"],
					type = "execute",
					handler = GuildAds,
					func = "ResetOthers"
				},
				player = {
					name = "player",
					desc = GUILDADS_OPTIONS["reset player"],
					type = "input",
					handler = GuildAds,
					set = "ResetPlayer"
				}
			}
		},
		clean = {
			name = "clean",
			desc = GUILDADS_OPTIONS["clean"],
			type = "group",
			args = {
				other = {
					name = "other",
					desc = GUILDADS_OPTIONS["clean other"],
					type = "execute",
					handler = GuildAds,
					func = "CleanOther"
				}
			}
		},
		admin = {
			name = "admin",
			desc = GUILDADS_OPTIONS["admin"],
			type = "group",
			args = {
				show = {
					name = "show",
					desc = GUILDADS_OPTIONS["admin show"],
					type = "execute",
					handler = GuildAds,
					func = "ShowACL"
				},
				deny = {
					name = "deny",
					desc = GUILDADS_OPTIONS["admin deny"],
					type = "input",
					handler = GuildAds,
					set = "DenyPlayerGuild"
				},
				allow = {
					name = "allow",
					desc = GUILDADS_OPTIONS["admin allow"],
					type = "input",
					handler = GuildAds,
					set = "AllowPlayerGuild"
				},
				remove = {
					name = "remove",
					desc = GUILDADS_OPTIONS["admin remove"],
					type = "input",
					handler = GuildAds,
					set = "RemoveFromACL"
				},
				allowed = {
					name = "allowed",
					desc = GUILDADS_OPTIONS["admin allowed"],
					type = "input",
					handler = GuildAds,
					set = "CheckACL"
				}	
			}
		},
	}
}
