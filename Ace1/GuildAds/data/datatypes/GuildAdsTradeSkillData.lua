----------------------------------------------------------------------------------
--
-- GuildAdsTradeSkillData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsTradeSkillDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "TradeSkill",
		version = 1,
        guildadsCompatible = 200,
		parent = GuildAdsDataType.PROFILE,
		priority = 600
	};
	schema = {
		id = "ItemRef",
		data = {
			[1] = { key="cd",	codec="BigInteger" },
		}
	}
});

function GuildAdsTradeSkillDataType:Initialize()
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

function GuildAdsTradeSkillDataType:onEventSpecial()
	local item, kind;
	local skillId = GuildAdsSkillDataType:getIdFromName(GetCraftName());
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

function GuildAdsTradeSkillDataType:onEvent()
	local item, colddown, kind;
	local skillId = GuildAdsSkillDataType:getIdFromName(GetTradeSkillLine());
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
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).craft;
end

function GuildAdsTradeSkillDataType:get(author, id)
	if not author then
		error("author is nil", 2);
	end
	return self.profile:getRaw(author).craft[id];
end

function GuildAdsTradeSkillDataType:getRevision(author)
	return self.profile:getRaw(author).craft._u or 0;
end

function GuildAdsTradeSkillDataType:setRevision(author, revision)
	self.profile:getRaw(author).craft._u = revision;
end

function GuildAdsTradeSkillDataType:setRaw(author, id, info, revision)
	local craft = self.profile:getRaw(author).craft;
	craft[id] = info;
	if info then
		craft[id]._u = revision;
		return true;
	end;
end

function GuildAdsTradeSkillDataType:set(author, id, info)
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

GuildAdsTradeSkillDataType:register();
