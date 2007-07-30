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
		priority = 600,
		depend = { "Main" }
	};
	schema = {
		id = "ItemRef",
		data = {
			[1] = { key="cd",	codec="BigInteger" },
			[2] = { key="e",	codec="ItemRef" },
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
	local item, kind, itemRecipe;
	local skillId = GuildAdsSkillDataType:getIdFromName(GetCraftName());
	local t = self:getTableForPlayer(GuildAds.playerName);
	
	for i=1,GetNumCrafts() do
		_, kind = GetCraftInfo(i);
		if (kind ~= "header") then
			item = GetCraftItemLink(i);
			itemRecipe = GetCraftRecipeLink(i);
			if item then
				_, item = GuildAds_ExplodeItemRef(item);
				_, itemRecipe = GuildAds_ExplodeItemRef(itemRecipe);
				if not (t[item] and t[item].e) then
					self:set(GuildAds.playerName, item, { s=skillId, e=itemRecipe });
				end
			end
		end
	end
		
end

function GuildAdsTradeSkillDataType:onEvent()
	local item, colddown, kind, itemRecipe;
	local skillId = GuildAdsSkillDataType:getIdFromName(GetTradeSkillLine());
	local t = self:getTableForPlayer(GuildAds.playerName);
	
	for i=1,GetNumTradeSkills() do
		_, kind = GetTradeSkillInfo(i);
		if (kind ~= "header") then
			item = GetTradeSkillItemLink(i);
			itemRecipe = GetTradeSkillRecipeLink(i);
			if item then
				_, item = GuildAds_ExplodeItemRef(item);
				colddown = GetTradeSkillCooldown(i);
				if colddown then
					colddown = colddown / 60 + GuildAdsDB:GetCurrentTime();
				end;
				_, itemRecipe = GuildAds_ExplodeItemRef(itemRecipe);
				--if not (t[item] and t[item].cd==colddown) then
				if not (t[item] and t[item].e) then
					--DEFAULT_CHAT_FRAME:AddMessage("Adding item "..item.." to GuildAds");
					GuildAdsTradeSkillDataType.debug("Adding item: "..item.." : "..tostring(itemRecipe));
					self:set(GuildAds.playerName, item, { cd = colddown, s=skillId, e=itemRecipe });
				end
			end
		end
	end
	
	if (GuildAds.channelName) then
		-- delete the items from WOW1 for every player (dont update revision)
		local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
		--DEFAULT_CHAT_FRAME:AddMessage("Clearing old items");
		local playerName;
		for playerName in pairs(players) do
			--DEFAULT_CHAT_FRAME:AddMessage("Clearing "..playerName);
			local craft = GuildAdsTradeSkillDataType:getTableForPlayer(playerName);
			if (craft) then
				local tmp = {}
				for item, data in pairs(craft) do
					if string.find(item, "^item:(%d+):(%d+):(%d+):(%d+)$") then
						tinsert(tmp, item);
					end
				end
				for _, item in pairs(tmp) do
					--DEFAULT_CHAT_FRAME:AddMessage("Clearing item "..item.." from GuildAds");
					local rev=self:getRevision(playerName);
					self:setRaw(playerName, item, nil, rev);
				end
			end
		end
		
	end
		
end

-- delete items without recipelink for every player
-- if a player has no items with recipelinks, then delete all items from that player and set revision to 0.
-- initially, this will cause a lot of traffic, but when everyone upgrades, this function will do nothing.
-- if at least one item has a recipelink, then we assume everything is alright.
function GuildAdsTradeSkillDataType:deleteOtherTradeSkillItems()
	local playerName,item,data,craft,tmp,recipelinks,count, players, playerAccount;
	if (GuildAds.channelName) then
		players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
		playerAccount = GuildAdsDB.profile.Main:get(GuildAds.playerName, GuildAdsDB.profile.Main.Account)or GuildAds.playerName;
		for playerName in pairs(players) do
			if playerAccount ~= (GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account) or playerName) then
				craft = GuildAdsTradeSkillDataType:getTableForPlayer(playerName);
				if (craft) then
					tmp = {}
					recipelinks=false;
					count=0;
					for item, data in pairs(craft) do
						if item~="_u" then
							count=count+1;
							if data.e then
								recipelinks=true;
							end
						end
					end
					if not recipelinks and count>0 then
						DEFAULT_CHAT_FRAME:AddMessage("deleting tradeskill (craft) data for player "..playerName);
						for item, data in pairs(craft) do
							if item~="_u" then
								tinsert(tmp, item);
							end
						end
						for _, item in pairs(tmp) do
							self:setRaw(playerName, item, nil, 0);
							--self:triggerUpdate(playerName, item);
						end
						self:setRevision(playerName,0);
					end
				end
			end
		end
	end
end

function GuildAdsTradeSkillDataType:getIncompleteTradeSkillItems()
	local playerName,item,data,craft,tmp, players;
	if (GuildAds.channelName) then
		players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
		tmp={}
		for playerName in pairs(players) do
			craft = GuildAdsTradeSkillDataType:getTableForPlayer(playerName);
			if (craft) then
				for item, data in pairs(craft) do
					if item~="_u" then
						if not data.e then
							if not tmp[item] then
								tmp[item]={p={playerName}};
							else
								tinsert(tmp[item].p,playerName);
							end
						end
					end
				end
			end
		end
	end	
	return tmp;
end

function GuildAdsTradeSkillDataType:deleteTradeSkillItemsTable(itemTable)
	for item, players in pairs(itemTable) do
		for _, playerName in pairs(players) do
			self:set(playerName, item, nil);
		end
	end
end

function GuildAdsTradeSkillDataType:deleteIncompleteTradeSkillItems()
	self:deleteTradeSkillItemsTable(self:getIncompleteTradeSkillItems());
end

function GuildAdsTradeSkillDataType:deleteTradeSkillItems(skillId)
	local item, data;
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
		if craft[id]==nil or info.s ~= craft[id].s or info.cd ~= craft[id].cd or info.e ~= craft[id].e then
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
