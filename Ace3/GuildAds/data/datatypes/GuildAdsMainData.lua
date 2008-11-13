----------------------------------------------------------------------------------
--
-- GuildAdsMainData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local GAClasses = {
	["WARRIOR"] = 1,
	["SHAMAN"] = 2,
	["PALADIN"] = 3,
	["DRUID"] = 4,
	["ROGUE"] = 5,
	["HUNTER"] = 6,
	["WARLOCK"] = 7,
	["MAGE"] = 8,
	["PRIEST"] = 9,
	["DEATHKNIGHT"] = 10
}

local GARaces = {
	["Human"] = 1,
	["Dwarf"] = 2,
	["NightElf"] = 3,
	["Gnome"] = 4,
	["Orc"] = 5,
	["Scourge"] = 6,
	["Tauren"] = 7,
	["Troll"] = 8,
	["Draenei"] = 9,
	["BloodElf"] = 10
}


GuildAdsMainDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "Main",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 100,
		depend = { "Admin" }
	};
	schema = {
		keys = {
			[1] = { key="g",  	codec="String" },
			[2] = { key="gr", 	codec="String" },
			[3] = { key="gri",	codec="Integer" },
			[4] = { key="l",	codec="Integer" },
			[5] = { key="c",	codec="Integer" },
			[6] = { key="r",	codec="Integer" },
			[7] = { key="a",	codec="String" }
		}
	};
	Guild = "g";
	GuildRank = "gr";
	GuildRankIndex = "gri";
	Level = "l";
	Class = "c";
	Race = "r";
	Account = "a";
});

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(GuildAdsMainDataType)

function GuildAdsMainDataType:Initialize()	
	GuildAdsTask:AddNamedSchedule("GuildAdsMainDataTypeInit", 7.5, nil, nil, self.onInitialize, self)
end

function GuildAdsMainDataType:onInitialize()
	local _, WoWRaceId = UnitRace("player")
	local _, WoWClassId = UnitClass("player")
	self:set(GuildAds.playerName, self.Level, UnitLevel("player"))
	self:set(GuildAds.playerName, self.Race, GARaces[WoWRaceId])
	self:set(GuildAds.playerName, self.Class, GAClasses[WoWClassId])
	self:set(GuildAds.playerName, self.Account, GuildAdsDB.account)
	
	self:RegisterEvent("PLAYER_LEVEL_UP", "onLevelUp")
	self:RegisterEvent("PLAYER_GUILD_UPDATE", "onGuildUpdate")
end

function GuildAdsMainDataType:onLevelUp()
	self:set(GuildAds.playerName, self.Level, arg1);
end

function GuildAdsMainDataType:onGuildUpdate()
	local guildName, guildRank, guildRankIndex = GetGuildInfo("player");
	
	self:set(GuildAds.playerName, self.Guild, guildName);
	self:set(GuildAds.playerName, self.GuildRank, guildRank);
	self:set(GuildAds.playerName, self.GuildRankIndex, guildRankIndex);
end

function GuildAdsMainDataType:getClassIdFromWoWClassId(WoWClassId)
	return GAClasses[WoWClassId]
end

function GuildAdsMainDataType:getClassIdFromName(ClassName)
	for id, name in pairs(GUILDADS_CLASSES) do
		if (name == ClassName) then
			return id;
		end
	end
	return -1;
end

function GuildAdsMainDataType:getClassNameFromId(ClassId)
	return GUILDADS_CLASSES[ClassId or ""] or "";
end

function GuildAdsMainDataType:getRaceIdFromName(RaceName)
	for id, name in pairs(GUILDADS_RACES) do
		if (name == RaceName) then
			return id;
		end
	end
	return -1;
end

function GuildAdsMainDataType:getRaceNameFromId(RaceId)
	return GUILDADS_RACES[RaceId or ""] or "";
end

function GuildAdsMainDataType:getTableForPlayer(author)
	return self.profile:getRaw(author).main;
end

function GuildAdsMainDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).main[id];
end

function GuildAdsMainDataType:getRevision(author)
	return self.profile:getRaw(author).main._u or 0;
end

function GuildAdsMainDataType:setRevision(author, revision)
	self.profile:getRaw(author).main._u = revision;
end

function GuildAdsMainDataType:setRaw(author, id, info, revision)
	local main =self.profile:getRaw(author).main;
	main[id] = info;
end

--[[
function GuildAdsMainDataType:compareTable(a, b)
	return not table.foreach(a, function(k, v) if b[k]~=v then return true end);
end
]]

function GuildAdsMainDataType:set(author, id, info)
	local main = self.profile:getRaw(author).main;
	if info then
		if main[id]==nil or main[id]~=info then
			main._u = 1 + (main._u or 0);
			main[id] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if main[id] then
			main[id] = nil;
			main._u = 1 + (main._u or 0);
			self:triggerUpdate(author, id);
		end
	end
end

GuildAdsMainDataType:register();
