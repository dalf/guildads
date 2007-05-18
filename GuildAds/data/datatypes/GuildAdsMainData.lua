----------------------------------------------------------------------------------
--
-- GuildAdsMainData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local AceOO = AceLibrary("AceOO-2.0");
GuildAdsMainDataTypeClass = AceOO.Class(GuildAdsTableDataType);

GuildAdsMainDataTypeClass.prototype.metaInformations = {
		name = "Main",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 100
};

GuildAdsMainDataTypeClass.prototype.schema = {
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

GuildAdsMainDataTypeClass.prototype.Guild = "g";
GuildAdsMainDataTypeClass.prototype.GuildRank = "gr";
GuildAdsMainDataTypeClass.prototype.GuildRankIndex = "gri";
GuildAdsMainDataTypeClass.prototype.Level = "l";
GuildAdsMainDataTypeClass.prototype.Class = "c";
GuildAdsMainDataTypeClass.prototype.Race = "r";
GuildAdsMainDataTypeClass.prototype.Account = "a";


function GuildAdsMainDataTypeClass.prototype:Initialize()
	self:set(GuildAds.playerName, self.Level, UnitLevel("player"));
	self:set(GuildAds.playerName, self.Race, self:getRaceIdFromName(UnitRace("player")));
	self:set(GuildAds.playerName, self.Class, self:getClassIdFromName(UnitClass("player")));
	self:set(GuildAds.playerName, self.Account, GuildAdsDB.account);
	
	self:RegisterEvent("PLAYER_LEVEL_UP", "onLevelUp");
	self:RegisterEvent("PLAYER_GUILD_UPDATE", "onGuildUpdate");
end

function GuildAdsMainDataTypeClass.prototype:onLevelUp()
	self:set(GuildAds.playerName, self.Level, arg1);
end

function GuildAdsMainDataTypeClass.prototype:onGuildUpdate()
	local guildName, guildRank, guildRankIndex = GetGuildInfo("player");
	
	self:set(GuildAds.playerName, self.Guild, guildName);
	self:set(GuildAds.playerName, self.GuildRank, guildRank);
	self:set(GuildAds.playerName, self.GuildRankIndex, guildRankIndex);
end


function GuildAdsMainDataTypeClass.prototype:getClassIdFromName(ClassName)
	for id, name in pairs(GUILDADS_CLASSES) do

		if (name == ClassName) then
			return id;
		end
	end
	return -1;
end

function GuildAdsMainDataTypeClass.prototype:getClassNameFromId(ClassId)
	return GUILDADS_CLASSES[ClassId or ""] or "";
end


function GuildAdsMainDataTypeClass.prototype:getRaceIdFromName(RaceName)
	for id, name in pairs(GUILDADS_RACES) do

		if (name == RaceName) then
			return id;
		end
	end
	return -1;
end

function GuildAdsMainDataTypeClass.prototype:getRaceNameFromId(RaceId)
	return GUILDADS_RACES[RaceId or ""] or "";
end

function GuildAdsMainDataTypeClass.prototype:getTableForPlayer(author)
	return self.profile:getRaw(author).main;
end

function GuildAdsMainDataTypeClass.prototype:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).main[id];
end

function GuildAdsMainDataTypeClass.prototype:getRevision(author)
	return self.profile:getRaw(author).main._u or 0;
end

function GuildAdsMainDataTypeClass.prototype:setRevision(author, revision)
	self.profile:getRaw(author).main._u = revision;
end

function GuildAdsMainDataTypeClass.prototype:setRaw(author, id, info, revision)
	local main =self.profile:getRaw(author).main;
	main[id] = info;
end

--[[
function GuildAdsMainDataTypeClass.prototype:compareTable(a, b)
	return not table.foreach(a, function(k, v) if b[k]~=v then return true end);
end
]]

function GuildAdsMainDataTypeClass.prototype:set(author, id, info)
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

GuildAdsMainDataType = GuildAdsMainDataTypeClass:new();
GuildAdsMainDataType:register();
