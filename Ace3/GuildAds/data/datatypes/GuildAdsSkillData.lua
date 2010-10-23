----------------------------------------------------------------------------------
--
-- GuildAdsSkillData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsSkillDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "Skill",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 300,
		depend = { "Main" }
	};
	schema = {
		id = "Integer",
		data = {
			[1] = { key="v",	codec="Integer" },
			[2] = { key="m",	codec="Integer" }
		}
	}
});

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(GuildAdsSkillDataType)

function GuildAdsSkillDataType:Initialize()
	--[[
		SKILL_LINES_CHANGED event fires when there is change in skills
		CHAT_MSG_SYSTEM event with this text ERR_SPELL_UNLEARNED_S fires when a skill is forget
		CHARACTER_POINTS_CHANGED when player level up or forget/learn a skill
		CHAT_MSG_SKILL event fires when the player progress
	]]
	GuildAdsTask:AddNamedSchedule("GuildAdsSkillDataTypeInit", 8, nil, nil, self.onEvent, self)
	self:RegisterEvent("CHARACTER_POINTS_CHANGED", "onEvent");
	self:RegisterEvent("CHAT_MSG_SKILL", "onEvent");
	self:RegisterEvent("PLAYER_LEVEL_UP", "onEvent");
end

function GuildAdsSkillDataType:doIt(...)
	local playerName = UnitName("player");
	local playerSkillIds = {};
	-- add new skills
	for i=1,select("#", ...) do
		local professionIndex = select(i,...)
		if professionIndex ~= nil then
			local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine = GetProfessionInfo(professionIndex)
			local id = self:getIdFromName(name);
			if (id > 0) then
				self:set(playerName, id, { v=skillLevel; m=maxSkillLevel });
				playerSkillIds[id] = true;
			end
		end
	end
	-- delete skills
	for id in pairs(self:getTableForPlayer(playerName)) do
		if not playerSkillIds[id] and id~="_u" then
			self:set(playerName, id, nil);
			if GuildAdsTradeSkillDataType and GuildAdsTradeSkillDataType.deleteTradeSkillItems then
				GuildAdsTradeSkillDataType:deleteTradeSkillItems(id);
			end
		end
	end
end

function GuildAdsSkillDataType:onEvent()
	-- process
	self:doIt(GetProfessions());
end

function GuildAdsSkillDataType:getIdFromName(SkillName)
	for id, name in pairs(GUILDADS_SKILLS) do
		if (name == SkillName) then
			return id;
		end
	end
	return -1;	
end

function GuildAdsSkillDataType:getNameFromId(SkillId)
	return GUILDADS_SKILLS[SkillId] or "";
end

function GuildAdsSkillDataType:getTableForPlayer(author)
	return self.profile:getRaw(author).skills;
end

function GuildAdsSkillDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).skills[id];
end

function GuildAdsSkillDataType:getRevision(author)
	return self.profile:getRaw(author).skills._u or 0;
end

function GuildAdsSkillDataType:setRevision(author, revision)
	self.profile:getRaw(author).skills._u = revision;
end

function GuildAdsSkillDataType:setRaw(author, id, info, revision)
	local skills = self.profile:getRaw(author).skills;
	skills[id] = info;
	if info then
		skills[id]._u = revision;
	end
end

function GuildAdsSkillDataType:set(author, id, info)
	local skills = self.profile:getRaw(author).skills;
	if info then
		if skills[id]==nil or info.v ~= skills[id].v or info.m ~= skills[id].m then
			skills._u = 1 + (skills._u or 0);
			info._u = skills._u;
			skills[id] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if skills[id] then
			skills[id] = nil;
			skills._u = 1 + (skills._u or 0);
			self:triggerUpdate(author, id);
		end
	end
end

GuildAdsSkillDataType:register();
