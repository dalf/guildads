----------------------------------------------------------------------------------
--
-- GuildAdsSkillData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local AceOO = AceLibrary("AceOO-2.0");
GuildAdsSkillDataTypeClass = AceOO.Class(GuildAdsTableDataType);
GuildAdsSkillDataTypeClass.prototype.metaInformations = {
		name = "Skill",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 300
};

GuildAdsSkillDataTypeClass.prototype.schema = {
		id = "Integer",
		data = {
			[1] = { key="v",	codec="Integer" },
			[2] = { key="m",	codec="Integer" }
		}
};

function GuildAdsSkillDataTypeClass.prototype:Initialize()
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


function GuildAdsSkillDataTypeClass.prototype:onUpdate()

	local playerName = UnitName("player");
	local playerSkillIds = {};
	-- add new skills
	for i = 1, GetNumSkillLines(), 1 do	
		local skillName, header, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType = GetSkillLineInfo(i);
		if (header ~= 1) then
			local id = GuildAdsSkillDataTypeClass.prototype:getIdFromName(skillName);
			if (id > 0) then
				GuildAdsSkillDataTypeClass.prototype:set(playerName, id, { v=skillRank; m=skillMaxRank });
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


function GuildAdsSkillDataTypeClass.prototype:getIdFromName(SkillName)
	for id, name in pairs(GUILDADS_SKILLS) do

		if (name == SkillName) then
			return id;
		end
	end
	return -1;	
end

function GuildAdsSkillDataTypeClass.prototype:getNameFromId(SkillId)
	return GUILDADS_SKILLS[SkillId] or "";
end

function GuildAdsSkillDataTypeClass.prototype:getTableForPlayer(author)
	return self.profile:getRaw(author).skills;
end

function GuildAdsSkillDataTypeClass.prototype:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).skills[id];
end

function GuildAdsSkillDataTypeClass.prototype:getRevision(author)
	return self.profile:getRaw(author).skills._u or 0;
end

function GuildAdsSkillDataTypeClass.prototype:setRevision(author, revision)
	self.profile:getRaw(author).skills._u = revision;
end

function GuildAdsSkillDataTypeClass.prototype:setRaw(author, id, info, revision)
	local skills = GuildAdsDB.profile:getRaw(author).skills;
	skills[id] = info;
	if info then
		skills[id]._u = revision;
	end
end

function GuildAdsSkillDataTypeClass.prototype:set(author, id, info)
	local skills = GuildAdsDB.profile:getRaw(author).skills;
	if info then
		if skills[id]==nil or info.v ~= skills[id].v or info.m ~= skills[id].m then
			skills._u = 1 + (skills._u or 0);
			info._u = skills._u;
			skills[id] = info;

			GuildAdsSkillDataTypeClass.prototype:triggerEvent(author, id);

			return info;
		end
	else
		if skills[id] then
			skills[id] = nil;
			skills._u = 1 + (skills._u or 0);

			GuildAdsSkillDataTypeClass.prototype:triggerEvent(author, id);

		end
	end
end

GuildAdsSkillDataType = GuildAdsSkillDataTypeClass:new();
GuildAdsSkillDataType:register();
