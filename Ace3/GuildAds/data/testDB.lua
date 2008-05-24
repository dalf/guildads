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

UnitLevel = function(name)
	if name=="player" then
		return config.playerLevel;
	end
end

UnitRace = function(name)
	if name=="player" then
		return config.playerRace;
	end
end

UnitClass = function(name)
	if name=="player" then
		return config.playerClass;
	end
end

GetInventoryItemLink = function(target,slot)
end

CreateFrame = function()
	local f={}
	f.RegisterEvent = function()
	end;
	f.SetScript = function()
	end;
	return f
end

GetGameTime = function()
	local t=os.date("*t",os.time())
	return t.hour,t.min
end

GetText = function(a,b,c)
	local t={ LASTONLINE_MONTHS = "%s months",
		LASTONLINE_HOURS = "%s hours",
		LASTONLINE_DAYS = "%s days",
		GENERIC_MIN = "%s minutes" };
	return t[a]		
end


--
-- About GuildAds
--
--GUILDADS_VERSION = 200;
GUILDADS_REVISION = "300";
GUILDADS_REVISION_NUMBER = tonumber((GUILDADS_REVISION or "1"):match("(%d+)"))

GuildAdsTask = {
	AddNamedSchedule = function(self, n, t, r, c, f, ...)
	end
}

GuildAds_ChatDebug = function(t, m)
end

dofile(config.guildAdsDatabaseFile);
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\Ace1\\GAAceDB.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\LibStub\\LibStub.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceAddon-3.0\\AceAddon-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\CallbackHandler-1.0\\CallbackHandler-1.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceEvent-3.0\\AceEvent-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceConsole-3.0\\AceConsole-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceGUI-3.0\\AceGUI-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceConfig-3.0\\AceConfigRegistry-3.0\\AceConfigRegistry-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceConfig-3.0\\AceConfigCmd-3.0\\AceConfigCmd-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceConfig-3.0\\AceConfigDialog-3.0\\AceConfigDialog-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\lib\\AceConfig-3.0\\AceConfig-3.0.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\Localization.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsDB.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsList.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsHash.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsDataType.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsFakeDataType.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\GuildAdsTableDataType.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsAdminData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsMainData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeSkillData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsFactionData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeNeedData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTradeOfferData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsInventoryData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsSkillData.lua");
dofile(config.wowPath.."Interface\\AddOns\\GuildAds\\data\\datatypes\\GuildAdsTalentData.lua");

GuildAds = {
	playerName = config.playerName;
	channelName = config.channelName;
	realmName = config.realmName;
	factionName = config.faction;
	db = GAAceDatabase:new("GuildAdsDatabase");
}

function GuildAds:Print(t)
	print("GuildAds:Print "..tostring(t));
	if type(t)=="table" then
		for k,v in pairs(t) do
			print(tostring(k).."="..tostring(v));
		end
	end
end

GuildAds.db:Initialize();
GuildAdsDB:Initialize();
