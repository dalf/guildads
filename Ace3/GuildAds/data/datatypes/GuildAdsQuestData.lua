----------------------------------------------------------------------------------
--
-- GuildAdsQuestData.lua
--
-- Author: Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- /run for q,p,d in GuildAdsDB.profile.QuestData:iterator("Galmok", nil) do print(d) end

QuestTypeToDataType={
	[ELITE] = "E",
	[LFG_TYPE_DUNGEON] = "D",
	[PVP] = "P",
	[RAID] = "R",
	[GROUP] = "G"
}
local QuestTypeToDataTypeMetaTable = {
	__index = function(t,i)
		return i
	end
}
setmetatable(QuestTypeToDataType, QuestTypeToDataTypeMetaTable)

DataTypeToQuestType={
	E = ELITE,
	D = LFG_TYPE_DUNGEON,
	P = PVP,
	R = RAID,
	G = GROUP
}
local DataTypeToQuestTypeMetaTable = {
	__index = function(t,i)
		return i
	end
}
setmetatable(DataTypeToQuestType, DataTypeToQuestTypeMetaTable)

GuildAdsQuestDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "QuestData",
		version = 1,
        	guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 400,
		depend = { "Main" }
	};
	schema = {
		id = "String", -- Quest number (xx in quest:xx:yy)
		data = {
			[1] = { key="l",	codec="Integer" }, -- yy
			[2] = { key="c",	codec="Color" }, -- color from quest link
			[3] = { key="n",	codec="String" }, -- quest name from quest link
			[4] = { key="g",	codec="String" }, -- quest group
			[5] = { key="r",	codec="String" }, -- questTag: E=ELITE, D=LFG_TYPE_DUNGEON, P=PVP, R=RAID, G=GROUP or nil/""
			[6] = { key="s",	codec="Integer" }, -- flags: bit 0 and 1: 0 = FAILED, 1 = ongoing, 2 = COMPLETE, bit 2: 1 = Daily, 0 = normal
		}
	}
});

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(GuildAdsQuestDataType)

function GuildAdsQuestDataType:Initialize()
	GuildAdsTask:AddNamedSchedule("GuildAdsQuestDataTypeInit", 8, nil, nil, self.onEvent, self)
	self:RegisterEvent("PLAYER_LEVEL_UP", "onEvent");
	--self:RegisterEvent("UNIT_QUEST_LOG_CHANGED", "onEvent");
	self:RegisterEvent("QUEST_LOG_UPDATE", "onEvent");
end

function GuildAdsQuestDataType:onEvent()
	GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsQuestDataType: onEvent");
	local playerName = UnitName("player");
	local numEntries, numQuests = GetNumQuestLogEntries()
	local groupName;
	local anyCollapsed = false;
	local questIDs = {}
	local flags; -- bit 0 and 1: 0 = FAILED, 1 = ongoing, 2 = COMPLETE, bit 2: 1 = Daily, 0 = normal
	for i = 1, numEntries do
		local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(i);
		if isHeader then
			groupName = questTitle
			if isCollapsed then
				anyCollapsed = true
			end
		else
			local questLink = GetQuestLink(i)
			if questLink then
				-- split questLink into colour, questID, questLevel and questName
				local questColor, ref, questName = GuildAds_ExplodeItemRef(questLink)
				local start, _, questID, questLevel = string.find(ref, "quest:([^:]+):([^:]+)")
				if questID then
					flags = isComplete and isComplete+1 or 1
					flags = isDaily and flags+4 or flags
					GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsQuestDataType: setting "..tostring(questID).." ("..questName..")");
					self:set(playerName, questID, {l=questLevel, c=questColor, n=questName, g=groupName, r=QuestTypeToDataType[questTag], s=flags})
					questIDs[questID] = true;
				end
			end
		end
	end
	if not anyCollapsed then
		GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsQuestDataType: all showing")
		local tmp = {}
		for questID in pairs(self:getTableForPlayer(playerName)) do
			if not questIDs[questID] and questID~="_u" then
				GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsQuestDataType: deleting "..tostring(questID));
				tinsert(tmp, questID)
			end
		end
		for _, questID in pairs(tmp) do
			self:set(playerName, questID, nil);
		end
	end
end

function GuildAdsQuestDataType:getTableForPlayer(author)
	return self.profile:getRaw(author).quests;
end

function GuildAdsQuestDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).quests[id];
end

function GuildAdsQuestDataType:setRevision(author, revision)
	self.profile:getRaw(author).quests._u = revision;
end

function GuildAdsQuestDataType:getRevision(author)
	return self.profile:getRaw(author).quests._u or 0;
end

function GuildAdsQuestDataType:setRaw(author, id, info, revision)
	local quests = self.profile:getRaw(author).quests;
	quests[id] = info;
	if info then
		quests[id]._u = revision;
	end
end

function GuildAdsQuestDataType:set(author, id, info)
	local quests = self.profile:getRaw(author).quests;
	if info then
		if not quests[id]
		  or info.l~=quests[id].l 
		  or info.c~=quests[id].c 
		  or info.n~=quests[id].n
		  or info.g~=quests[id].g 
		  or info.r~=quests[id].r 
		  or info.s~=quests[id].s then
		  	quests._u = 1 + (quests._u or 0);
			info._u = quests._u;
			quests[id] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if quests[id] then
			quests[id] = nil;
			quests._u = 1 + (quests._u or 0);
			self:triggerUpdate(author, id);
		end
	end
end

GuildAdsQuestDataType:register();
