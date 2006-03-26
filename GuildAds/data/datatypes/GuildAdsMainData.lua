----------------------------------------------------------------------------------
--
-- GuildAdsMainData.lua
--
-- Author: Zarkan, Fka� of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsMainDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "Main",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE
	};
	schema = {
		id = "String",
		data = {
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
	CreationTime = "_t";
});

function GuildAdsMainDataType:Initialize()
	self:set(GuildAds.playerName, self.Level, UnitLevel("player"));
	self:set(GuildAds.playerName, self.Race, self:getRaceIdFromName(UnitRace("player")));
	self:set(GuildAds.playerName, self.Class, self:getClassIdFromName(UnitClass("player")));
	self:set(GuildAds.playerName, self.Account, GuildAdsDB.account);
	self:onGuildUpdate();
	
	self:RegisterEvent("PLAYER_LEVEL_UP", "onLevelUp");
	self:RegisterEvent("PLAYER_GUILD_UPDATE", "onGuildUpdate");
end

function GuildAdsMainDataType:onLevelUp()
	if self:set(GuildAds.playerName, self.Level, arg1) then
		self:set(GuildAds.playerName, self.CreationTime, GuildAdsDB:GetCurrentTime());
	end
end

function GuildAdsMainDataType:onGuildUpdate()
	local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
	
	local change = self:set(GuildAds.playerName, self.Guild, guildName);
	change = self:set(GuildAds.playerName, self.GuildRank, guildRank) or change;
	change = self:set(GuildAds.playerName, self.GuildRankIndex, guildRankIndex) or change;
	if change then
		self:set(GuildAds.playerName, self.CreationTime, GuildAdsDB:GetCurrentTime());
	end
end

function GuildAdsMainDataType:getClassIdFromName(ClassName)
	for id, name in GUILDADS_CLASSES do
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
	for id, name in GUILDADS_RACES do
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
	return self.profile:getRaw(author).main._u;
end

function GuildAdsMainDataType:setRevision(author, updateTag)
	self.profile:getRaw(author).main._u = updateTag;
end

function GuildAdsMainDataType:setRaw(author, id, info, updateTag)
	local main =self.profile:getRaw(author).main;
	main[id] = info;
	if info then
		main[id]._u = updateTag;
		return true;
	end;
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
			self:triggerEvent(author, id);
			return info;
		end
	else
		if main[id] then
			main[id] = nil;
			main._u = 1 + (main._u or 0);
			self:triggerEvent(author, id);
		end
	end
end

GuildAdsMainDataType:register();
