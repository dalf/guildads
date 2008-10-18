----------------------------------------------------------------------------------
--
-- GuildAdsTradeSkillData.lua
--
-- Author: Zarkan, Fka� of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

--[[
	Implementation problem : 
		an item can't craft be two two different recipes.
		if this is the case (as for small primatic shard, item:22448), each time the player opens the craft/trade frame,
		the datatype is updated
	For now, the revision updates are avoided : an item is set only one time for the craft frame; but only recipe is stored.
]]

local clearedWoW2

GuildAdsTradeSkillDataType = GuildAdsTableDataType:new({
	metaInformations = {
		name = "TradeSkill",
		version = 2,
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
			[3] = { key="q",	codec="String" },
		}
	}
});

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(GuildAdsTradeSkillDataType)

function GuildAdsTradeSkillDataType:Initialize()
	self:RegisterEvent("CRAFT_SHOW", "onEventSpecial");
	self:RegisterEvent("CRAFT_UPDATE", "onEventSpecial");
	self:RegisterEvent("TRADE_SKILL_SHOW", "onEvent");
	self:RegisterEvent("TRADE_SKILL_UPDATE", "onEvent");
	


end

function GuildAdsTradeSkillDataType:onEventSpecial()
	local item, kind, itemRecipe, minMade, maxMade, q;
	local skillId = GuildAdsSkillDataType:getIdFromName(GetCraftName());
	local t = self:getTableForPlayer(GuildAds.playerName);
	
	for i=1,GetNumCrafts() do
		_, kind = GetCraftInfo(i);
		if (kind ~= "header") then
			item = GetCraftItemLink(i);
			minMade, maxMade = GetCraftNumMade(i);
			-- cooldown = GetCraftCooldown(i);
			itemRecipe = GetCraftRecipeLink(i);
			if item then
				_, item = GuildAds_ExplodeItemRef(item);
				_, itemRecipe = GuildAds_ExplodeItemRef(itemRecipe);
				q=nil;
				if minMade~=1 or maxMade~=1 then
					q=tostring(minMade);
					if maxMade~=minMade then
						q=q.."-"..tostring(maxMade);
					end
				end
				-- if not(t[item] and skillId==t[item].s and itemRecipe==t[item].e and q==t[item].q) then
				if not(t[item]) then
					self:set(GuildAds.playerName, item, { s=skillId, e=itemRecipe, q=q });
				end
			end
		end
	end
		
end

function GuildAdsTradeSkillDataType:onEvent()
	local item, colddown, kind, itemRecipe, minMade, maxMade, q;
	local skillId = GuildAdsSkillDataType:getIdFromName(GetTradeSkillLine());
	local t = self:getTableForPlayer(GuildAds.playerName);
	
	self:deleteOrphanTradeSkillItems(); -- just in case there are any items without profession label
	
	self:clearAllWoW2TradeSkillItems(); -- old WoW2 items are no more
	
	for i=1,GetNumTradeSkills() do
		_, kind = GetTradeSkillInfo(i);
		if (kind ~= "header") then
			item = GetTradeSkillItemLink(i);
			minMade, maxMade = GetTradeSkillNumMade(i);
			itemRecipe = GetTradeSkillRecipeLink(i);
			if item then
				_, item = GuildAds_ExplodeItemRef(item);
				-- don't share cooldown, causes too much update
				--[[
				cooldown = GetTradeSkillCooldown(i) 
				if cooldown then
					cooldown = cooldown / 60 + GuildAdsDB:GetCurrentTime();
				end;
				]]
				_, itemRecipe = GuildAds_ExplodeItemRef(itemRecipe);
				q=nil;
				if minMade~=1 or maxMade~=1 then
					q=tostring(minMade);
					if maxMade~=minMade then
						q=q.."-"..tostring(maxMade);
					end
				end
				
				-- if not (t[item] and t[item].e and t[item].q) then
				if not (t[item]) then
					self:set(GuildAds.playerName, item, { s=skillId, e=itemRecipe, q=q });
				elseif not t[item].s then
					t[item].s = skillId
				end
			end
		end
	end
end

function GuildAdsTradeSkillDataType:deleteWoW2TradeSkillItems()
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


-- This function will delete all item codes with only 8 numbers in. WoW3 has 9 numbers.
-- It will NOT cause a DB update or increase revision numbers. (all clients call this and 
-- there is no need to propagate the deletion).
function GuildAdsTradeSkillDataType:clearAllWoW2TradeSkillItems()
	if (GuildAds.channelName and not clearedWoW2) then
		-- delete the items from WOW2 for every player (dont update revision)
		local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
		--DEFAULT_CHAT_FRAME:AddMessage("Clearing old items");
		local playerName;
		for playerName in pairs(players) do
			--DEFAULT_CHAT_FRAME:AddMessage("Clearing "..playerName);
			local craft = GuildAdsTradeSkillDataType:getTableForPlayer(playerName);
			if (craft) then
				local tmp = {}
				for item, data in pairs(craft) do
					if string.find(item, "^item:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%d+)$") then
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
		clearedWoW2 = true
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

function GuildAdsTradeSkillDataType:deleteOrphanTradeSkillItems()
	local item, data;
	local t = {};
	for item, data in pairs(self:getTableForPlayer(GuildAds.playerName)) do
		if item~="_u" and not data.s then
			table.insert(t, item);
		end
	end
	for _, item in pairs(t) do
		self:set(GuildAds.playerName, item, nil);
	end
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
		if craft[id]==nil or info.s ~= craft[id].s or info.e ~= craft[id].e or info.q ~= craft[id].q then
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
