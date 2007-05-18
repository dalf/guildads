----------------------------------------------------------------------------------
--
-- GuildAdsTradeSkillData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local AceOO = AceLibrary("AceOO-2.0");
GuildAdsTradeSkillDataTypeClass = AceOO.Class(GuildAdsTableDataType);
GuildAdsTradeSkillDataTypeClass.prototype.metaInformations = {
		name = "TradeSkill",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 600
};

GuildAdsTradeSkillDataTypeClass.prototype.schema = {
		id = "ItemRef",
		data = {
			[1] = { key="cd",	codec="BigInteger" },
		}
};

function GuildAdsTradeSkillDataTypeClass.prototype:Initialize()
	self:RegisterEvent("CRAFT_SHOW", "onEventSpecial");
	self:RegisterEvent("CRAFT_UPDATE", "onEventSpecial");
	self:RegisterEvent("TRADE_SKILL_SHOW", "onEvent");
	self:RegisterEvent("TRADE_SKILL_UPDATE", "onEvent");
	
	-- delete the items from WOW1
	local tmp = {};
	local craft = GuildAdsTradeSkillDataType:getTableForPlayer(GuildAds.playerName);
	for item, data in pairs(craft) do
		if string.find(item, "^item:(%d+):(%d+):(%d+):(%d+)$") then
			tinsert(tmp, item);
		end
	end
	
	for _, item in pairs(tmp) do
		self:set(GuildAds.playerName, item, nil);
	end

end


function GuildAdsTradeSkillDataTypeClass.prototype:onUpdateSpecial()
	local item, type;

	local t = self:getTableForPlayer(GuildAds.playerName);
	
	for i=1,GetNumCrafts() do
		_, kind = GetCraftInfo(i);
		if (kind ~= "header") then
			item = GetCraftItemLink(i);
			if item then
				_, item = GuildAds_ExplodeItemRef(item);
				if not t[item] then
					self:set(GuildAds.playerName, item, { s=skillId });
				end
			end
		end
	end
end

<<<<<<< .mine
function GuildAdsTradeSkillDataTypeClass.prototype:onUpdate()
	local item, colddown, type;
=======
function GuildAdsTradeSkillDataType:onEvent()
	local item, colddown, kind;
	local skillId = GuildAdsSkillDataType:getIdFromName(GetTradeSkillLine());
>>>>>>> .r166
	local t = self:getTableForPlayer(GuildAds.playerName);
	
	for i=1,GetNumTradeSkills() do
		_, kind = GetTradeSkillInfo(i);
		if (kind ~= "header") then
			item = GetTradeSkillItemLink(i);
			if item then
				_, item = GuildAds_ExplodeItemRef(item);
				colddown = GetTradeSkillCooldown(i);
				if colddown then
					colddown = colddown / 60 + GuildAdsDB:GetCurrentTime();
				end;
				if not (t[item] and t[item].cd==colddown) then
					self:set(GuildAds.playerName, item, { cd = colddown, s=skillId });
				end
			end
		end
	end
end

<<<<<<< .mine
function GuildAdsTradeSkillDataTypeClass.prototype:getTableForPlayer(author)
=======
function GuildAdsTradeSkillDataType:deleteTradeSkillItems(skillId)
	local t = {};
	for item, data in pairs(self:getTableForPlayer(GuildAds.playerName)) do
		if item~="_u" and data.s == skillId then
			table.insert(t, item);
		end
	end
	for _, item in pairs(t) do
		self:set(GuildAds.playerName, item, nil);
	end
end

function GuildAdsTradeSkillDataType:getTableForPlayer(author)
>>>>>>> .r166
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).craft;
end

function GuildAdsTradeSkillDataTypeClass.prototype:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).craft[id];
end

function GuildAdsTradeSkillDataTypeClass.prototype:getRevision(author)
	return self.profile:getRaw(author).craft._u or 0;
end

function GuildAdsTradeSkillDataTypeClass.prototype:setRevision(author, revision)
	self.profile:getRaw(author).craft._u = revision;
end

function GuildAdsTradeSkillDataTypeClass.prototype:setRaw(author, id, info, revision)
	local craft = self.profile:getRaw(author).craft;
	craft[id] = info;
	if info then
		craft[id]._u = revision;
		return true;
	end;
end

<<<<<<< .mine
-- patch 
function GuildAdsTradeSkillDataTypeClass.prototype:set(author, id, info)
=======
function GuildAdsTradeSkillDataType:set(author, id, info)
>>>>>>> .r166
	local craft = self.profile:getRaw(author).craft;
	if info then
		if craft[id]==nil or info.s ~= craft[id].s or info.cd ~= craft[id].cd then
			craft._u = 1 + (craft._u or 0);
			info._u = craft._u;
			craft[id] = info;
			self:triggerUpdate(author, id);
			return info;
		end
	else
		if craft[id] then
			craft[id] = nil;
			craft._u = 1 + (craft._u or 0);
			self:triggerUpdate(author, id);
		end
	end
end

GuildAdsTradeSkillDataType = GuildAdsTradeSkillDataTypeClass:new();
GuildAdsTradeSkillDataType:register();
