----------------------------------------------------------------------------------
--
-- GuildAdsTradeSkillData.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
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
local wowIdToGuildAdsId = {}

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
		id = "ItemRef", -- item:XX, enchant:XX or trade:XX
		data = {
			[1] = { key="cd",	codec="BigInteger" },	-- nil
			[2] = { key="e",	codec="ItemRef" }, 	-- enchant:XX (with id being item:XX or enchant:XX) or nil
			[3] = { key="q",	codec="String" }, 	-- enchant: or trade: number of items made from resources or 
									--  trade: nil
		}
	}
});

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(GuildAdsTradeSkillDataType)

function GuildAdsTradeSkillDataType:Initialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "enterWorld");
	-- create wowSkillId to GuildAds skill ID mapping
	local LTLFunc = LibStub("LibTradeLinks-1.0")
	wowIdToGuildAdsId[LTLFunc.SKILL_ALCHEMY] = 4
	wowIdToGuildAdsId[LTLFunc.SKILL_BLACKSMITHING] = 5
	wowIdToGuildAdsId[LTLFunc.SKILL_COOKING] = 12
	wowIdToGuildAdsId[LTLFunc.SKILL_ENCHANTING] = 9
	wowIdToGuildAdsId[LTLFunc.SKILL_ENGINEERING] = 6
	wowIdToGuildAdsId[LTLFunc.SKILL_FIRSTAID] = 11
	wowIdToGuildAdsId[LTLFunc.SKILL_JEWELCRAFTING] = 14
	wowIdToGuildAdsId[LTLFunc.SKILL_LEATHERWORKING] = 7
	wowIdToGuildAdsId[LTLFunc.SKILL_MINING] = 2
	wowIdToGuildAdsId[LTLFunc.SKILL_TAILORING] = 8
	wowIdToGuildAdsId[LTLFunc.SKILL_INSCRIPTION] = 15
end

function GuildAdsTradeSkillDataType:enterWorld()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("TRADE_SKILL_SHOW", "onEvent");
	self:RegisterEvent("TRADE_SKILL_UPDATE", "onEvent");
	self:RegisterEvent("TRADE_SKILL_CLOSE", "onEvent");
end

-- Nearly impossible to get reliable tradeskill information. 
local Orig_CloseTradeSkill = CloseTradeSkill
function CloseTradeSkill()
	GuildAdsTradeSkillDataType.tradeSkillWindowOpen=false;
	-- call the original CloseTradeSkill
	Orig_CloseTradeSkill();
end

function GuildAdsTradeSkillDataType:onEvent(event, arg1)
	GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: event="..tostring(event));
	if event=="TRADE_SKILL_SHOW" then
		GuildAdsTradeSkillDataType.tradeSkillWindowOpen=true;
		GuildAdsTradeSkillDataType:UpdateTradeSkills();
	elseif event=="TRADE_SKILL_CLOSE" then
		GuildAdsTradeSkillDataType.tradeSkillWindowOpen=false;
	elseif GuildAdsTradeSkillDataType.tradeSkillWindowOpen then
		GuildAdsTradeSkillDataType:UpdateTradeSkills();
	end
end

function GuildAdsTradeSkillDataType:UpdateTradeSkills()
	local skillId = GuildAdsSkillDataType:getIdFromName(GetTradeSkillLine());
	if skillId > 0 and not IsTradeSkillLinked() and not IsTradeSkillGuild() then
		local item, colddown, kind, open, itemRecipe, minMade, maxMade, q;
		local tmp = {}
		local added, deleted = 0, 0;
		local t = self:getTableForPlayer(GuildAds.playerName);

		self:deleteOrphanTradeSkillItems(); -- just in case there are any items without profession label
	
		--	--self:clearAllWoW2TradeSkillItems(); -- old WoW2 items are no more
		self:deleteWoW2TradeSkillItems(); -- only delete my own items
		local tradeSkillLink = GetTradeSkillListLink()
		local color, link
		if tradeSkillLink then
			GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: TradeSkillLink available")
			color, link = GuildAds_ExplodeItemRef(tradeSkillLink)
			if link then
				tmp[link]=true
				if not t[link] then
					added = added - 1
				end
					GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: Adding TradeSkill Link "..link)
					self:set(GuildAds.playerName, link, { s=skillId, q=select(2, GetBuildInfo()) })
					added = added + 1
				--end
			end
		end

		-- Check the TradeSkill UI to see if any filters are enabled.
		local fullListShown = true
		if TradeSkillFrameAvailableFilterCheckButton then
			fullListShown = fullListShown and not TradeSkillFrameAvailableFilterCheckButton:GetChecked()
			--GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: button = "..tostring(TradeSkillFrameAvailableFilterCheckButton:GetChecked() and "checked" or "not checked"))
		end
		if TradeSkillFrameEditBox then
			fullListShown = fullListShown and (TradeSkillFrameEditBox:GetText() == "" or TradeSkillFrameEditBox:GetText() == SEARCH)
			--GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: text = "..tostring(TradeSkillFrameEditBox:GetText()))
		end
		if TradeSkillInvSlotDropDown then
			local dd = UIDropDownMenu_GetSelectedID(TradeSkillInvSlotDropDown)
			fullListShown = fullListShown and (dd == 1 or not dd)
			--GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: InvDropDown = "..(UIDropDownMenu_GetSelectedID(TradeSkillInvSlotDropDown) or ""))
		end
		if TradeSkillSubClassDropDown then
			local dd = UIDropDownMenu_GetSelectedID(TradeSkillSubClassDropDown)
			fullListShown = fullListShown and (dd == 1 or not dd)
			--GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: ClassDropDown = "..(UIDropDownMenu_GetSelectedID(TradeSkillSubClassDropDown) or ""))
		end
		
		-- Check to see if there are any headers. If not, item info is most likely not available yet.
		local headers=false
		for i=1,GetNumTradeSkills() do
			_, kind, _, open = GetTradeSkillInfo(i);
			if (kind == "header") then
				headers = true
			end
		end
		if not headers then
			GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: no headers found")
			return
		end
		
		-- Check for new tradeskills
		if not tradeSkillLink then
			-- if there is no tradeskill link (Poisons, Mining and Runeforging) then gather items the hard way
		for i=1,GetNumTradeSkills() do
			_, kind, _, open = GetTradeSkillInfo(i);
			if (kind ~= "header") then
				item = GetTradeSkillItemLink(i);
				
				minMade, maxMade = GetTradeSkillNumMade(i);
				itemRecipe = GetTradeSkillRecipeLink(i);
				if item then
					_, item = GuildAds_ExplodeItemRef(item);
					tmp[item]=true;
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
						added = added + 1
					elseif not t[item].s then
						t[item].s = skillId
					end
				end
			else
				fullListShown = fullListShown and open
			end
		end
		else
			-- not necessarily true, but will cause the individual item:XXs to be removed from the database
			fullListShown = true
		end
		
		GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: Full List Shown: "..(fullListShown and "true" or "false"))
		
		-- delete items not found in the above code
		if fullListShown then
			for k,v in pairs(tmp) do
				GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: "..tostring(k))
			end
			local tmp2 = {};
			local craft = self:getTableForPlayer(GuildAds.playerName);
			for item, data in pairs(craft) do
				if (item ~= "_u") and (data.s == skillId) then
					GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: checking "..tostring(item))
				end
				if (not tmp[item]) and (item ~= "_u") and (data.s == skillId) then
					tinsert(tmp2, item);
				end
			end
			for _, item in pairs(tmp2) do
				self:set(GuildAds.playerName, item, nil);
				deleted = deleted + 1
			end
		end
		GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "GuildAdsTradeSkillDataType: Updating tradeskill information (%s added, %s deleted)", added, deleted);
	end
end

function GuildAdsTradeSkillDataType:GetTradeLink(playerName, professionID)
	local skillName = GUILDADS_SKILLS[professionID];
	local LTLFunc = LibStub("LibTradeLinks-1.0")
	if skillName and playerName then
		-- for every trade link the player has
		for itemLink, _, data in GuildAdsDB.profile.TradeSkill:iterator(playerName, nil) do
			local start, _, tradeLinkID = string.find(itemLink, "trade:([0-9]+):.*");
			if tradeLinkID then
				tradeLinkID = tonumber(tradeLinkID)
				-- find the LTL-skillId with which the professionID matches
				local wowProfessionId = LTLFunc:GetSkillId(tradeLinkID)
				local GuildAdsSkillId = wowIdToGuildAdsId[wowProfessionId]
				if GuildAdsSkillId == professionID then
					return itemLink, skillName
				end
			end
		end
	end
end

-- returns the profession mastery (if there is any)
function GuildAdsTradeSkillDataType:GetProfessionMastery(playerName, professionID)
	local LTLFunc = LibStub("LibTradeLinks-1.0")
	local name, texture, offset, numberSpells = GetSpellTabInfo(1)
	for s = offset + 1, offset + numberSpells do
		local spell, rank = GetSpellName(s, BOOKTYPE_SPELL)
		local link = GetSpellLink(spell)
		local s, e, spellId = link.find("\124Hspell:(.*)\124h.*\124h")
		local wowProfessionId = LTLFunc:GetSkillId(tonumber(spellId))
		if wowProfessionId == professionID then
			return spellId
		end
	end
end

function GuildAdsTradeSkillDataType:deleteWoW2TradeSkillItems()
	-- delete the items from WOW2
	local tmp = {};
	local craft = GuildAdsTradeSkillDataType:getTableForPlayer(GuildAds.playerName);
	for item, data in pairs(craft) do
		if string.find(item, "^item:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%d+)$") then
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
		if item~="_u" and (not data.s or not GuildAdsSkillDataType:get(GuildAds.playerName,data.s) ) then
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
