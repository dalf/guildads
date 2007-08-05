-- defined config table : playerName, realmName, faction, channelName, wowPath, guildAdsDatabaseFile
dofile("testDBConfig.lua");

--
-- About WOW
--
SlashCmdList = {}
tinsert = table.insert;
getn = table.getn;

getglobal = function(name)
	return _G[name];
end

setglobal = function(name, value)
	_G[name] = value;
end

GetCVar = function(name)
	if name=="realmName" then
		return config.realmName;
	end
end

UnitName = function(name)
	if name=="player" then
		return config.playerName;
	end
end

--
-- About Ace
--
AceEventFrame = {
	RegisterEvent = function(event)
	end;
}

dofile(config.wowPath.."Interface\\AddOns\\Ace\\Ace.lua")
dofile(config.wowPath.."Interface\\AddOns\\Ace\\AceDB.lua")
dofile(config.wowPath.."Interface\\AddOns\\Ace\\AceData.lua")
dofile(config.wowPath.."Interface\\AddOns\\Ace\\AceEvent.lua")
dofile(config.wowPath.."Interface\\AddOns\\Ace\\AceHook.lua")
dofile(config.wowPath.."Interface\\AddOns\\Ace\\AceModule.lua")

--
-- About GuildAds
--
GUILDADS_VERSION = 200;

GuildAdsTask = {
	AddNamedSchedule = function(self, n, t, r, c, f, ...)
	end
}

GuildAds_ChatDebug = function(t, m)
end

dofile(config.guildAdsDatabaseFile);
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsDB.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsDataType.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsFakeDataType.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsTableDataType.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsAdminData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeNeedData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeOfferData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeSkillData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsSkillData.lua");

GuildAds = {
	playerName = config.playerName;
	channelName = config.channelName;
	realmName = config.realmName;
	factionName = config.faction;
	db = AceDatabase:new("GuildAdsDatabase");
}

GuildAds.db:Initialize();
GuildAdsDB:Initialize();
