----------------------------------------------------------------------------------
--
-- GuildAdsTooltip.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- local AceHook = LibStub("AceHook-3.0")

local GuildAdsDB = GuildAdsDB
local GuildAdsItems = {}
local GuildAdsCrafts = {}

local _G = getfenv()

local colors = {
		TradeNeed = {
			[true]   = { 1, 0.75, 0 };
			[false]  = { 1, 1   , 0.5 };
		};
		TradeOffer = {
			[true]   = { 1, 0   , 0.75 };
			[false]  = { 1, 0.5 , 1 };
		};
		TradeSkill = {
			[true]   = { 0.75, 0.75, 1 };
			[false]  = { 0.75, 0.75, 1 };
		}
	};
	

local nameToKey = {}
GuildAdsNameToKey = nameToKey
local keyTable = setmetatable({}, {
	__mode = 'k';
	__index = function(t, itemLink)
		if itemLink then
			-- ChatFrame1:AddMessage("getKeyFromItemRef("..itemLink..")")
			local start, _, color, ref, name = string.find(itemLink, "|c([%w]+)|H([^|]+)|h%[([^|]+)%]|h|r");
			local itemRef = start and ref or itemLink
			-- ChatFrame1:AddMessage(" - itemLink="..itemRef)
			local start, _, linkType, itemId = string.find(itemRef, "([^:]+):([^:]+)")
			if start then
				
				local key = (linkType=="item") and tonumber(itemId) or ((linkType=="enchant") and -tonumber(itemId) or false)
				
				rawset(t, itemLink, key)
				
				name = GetItemInfo(itemLink)
				if name then
					rawset(nameToKey, name, key)
				end
				-- ChatFrame1:AddMessage(" - key("..itemLink..") "..tostring(key))
				return key
			else
				-- ChatFrame1:AddMessage(" - key= nil !")
			end
		end
	end
})
GuildAdsKeyTable = keyTable

--------------------------------------------------------------------------
local RECIPEBOOK_RECIPEWORD = "Recipe" 
local RECIPEBOOK_WORD_TRANSMUTE = "Transmute";
local RECIPEBOOK_REGEX_SKILL = string.gsub(string.gsub(ITEM_MIN_SKILL, "%%s", "%(%[%%w%%s%]+%)" ), "%(%%d%)", "%%%(%(%%d+%)%%%)");
local RECIPEBOOK_REGEX_REPUTATION = string.gsub(string.gsub(ITEM_REQ_REPUTATION, "%-", "%%%-"), "%%s", "%(%[%%w %]+%)" );
local RECIPEBOOK_REGEX_SPECIALTY = string.gsub(ITEM_REQ_SKILL, "%%s", "%(%[%%w%%s%]+%)" );
local CRAFTED_BY = string.gsub(ITEM_CREATED_BY, "cff00ff00", "cffffff00")

local function RB_ParseItemLink(link)
	if not link then return false end;
	local _, id, _, _, _, valid, skill = GetItemInfo(link);
	if not id then return false end;
	id = string.match(id, "item:(%d+):");
	skill = GuildAdsSkillDataType:getIdFromName(skill);
	if valid ~= RECIPEBOOK_RECIPEWORD or skill < 1 then
		return false; -- not a recipe.
	else
	    return true, tonumber(skill), tonumber(id);
	end
end

--[[ GetSkillInfo(tooltip) --> Extracts required ranks and specialization needs from tooltip data
	Returns : rank, specialty, faction required, reputation required, the name of the created item]]--
local function RB_GetSkillInfo(tooltip, skill)
	local text;
	local rank, spec, rep, honor, makes;
	local uline = 0;
	if type(tooltip) == "table" then tooltip = tooltip:GetName() end;
	for i = 2, getglobal(tooltip):NumLines() do
		text = getglobal(tooltip.."TextLeft"..i):GetText();
		if text then
			if string.find(text, ITEM_SPELL_TRIGGER_ONUSE) then
			    if not skill then
		        	local _, link = getglobal(tooltip):GetItem();
	               	valid, skill = RB_ParseItemLink(link)
					if not valid then skill = 0 end;
			    end
			    -- Enchants do not have a created item in most cases.
				if skill == GuildAdsSkillDataType:getNameFromId(9) then  -- Enchanting
				    makes = string.match(getglobal(tooltip.."TextLeft1"):GetText(), "%w+%: (.+)")
				-- Alchemy transmutes are somewhat quirky; match on "Transmute X to Y" rather than created item.
				elseif skill == GuildAdsSkillDataType:getNameFromId(4) and string.match(getglobal(tooltip):GetItem(), RECIPEBOOK_WORD_TRANSMUTE) then
				    makes = string.match(getglobal(tooltip.."TextLeft1"):GetText(), "%w+%: (.+)");
				else
					makes = getglobal(tooltip.."TextLeft"..i+1):GetText();
				end
				if makes then
					makes = string.gsub(makes, "^%s*(.-)%s*$", "%1");
				end
				break; -- No data beyond this point;
			elseif string.find(text, RECIPEBOOK_REGEX_SKILL) then -- "Requires Skill (Rank)"
				string.gsub(text, RECIPEBOOK_REGEX_SKILL, function(a,b) rank = b end);
			elseif string.find(text, RECIPEBOOK_REGEX_REPUTATION) then -- "Requires Faction - Reputation"
				_,_, rep, honor = string.find(text, RECIPEBOOK_REGEX_REPUTATION);
			elseif string.find(text, RECIPEBOOK_REGEX_SPECIALTY) then -- "Requires Skill"
				string.gsub(text, RECIPEBOOK_REGEX_SPECIALTY, function(a,b) spec = a end);
			end;
		end
	end
	return tonumber(rank), spec, rep, honor, makes;
end
	
--------------------------------------------------------------------------

local function formatData(dataTypeName, data)
	if data then
		local t = colors[dataTypeName][GuildAdsUITools:IsAccountOnline(data.owner) and true or false];
			
		if data.count>0 then
			if data.inf then
				return data.owner .. " (" .. data.count .. "+)", t[1], t[2], t[3];
			else
				return data.owner .. " (" .. data.count .. ")", t[1], t[2], t[3];
			end
		else
			return data.owner, t[1], t[2], t[3];
		end
	else
		return " ", 1, 1, 1;
	end
end

local function unpackIterator(text, start)
	local s, e, o = string.find(text, "([^x]+)x[0-9]+", start or 1);
	if s and e and o then
		return e+2, o; -- +1 = ";", +2 : next message
	end
end

local function unpackItemIterator(text)
	return unpackIterator, text;
end

local function getExtraTipLines(itemKey)
	local lines = {}
	tinsert(lines, GUILDADS_TOOLTIP_USED);
	if itemKey > 0 then
		local t = GuildAdsItems[itemKey]
		for item, items, set in LibStub("LibPeriodicTable-3.1"):IterateSet("TradeskillResultMats.Reverse") do
			if item==itemKey then
				local level = tostring(UnitLevel("player"))
				local set = set:gsub("TradeskillResultMats.Reverse.","")
				local headerInserted
				if items then
					profItems = {}
					for index, item in unpackItemIterator(items) do
						local itemLink
						if tonumber(item) > 0 then
							itemLink="item:"..item..":0:0:0:0:0:0:0:"..level
						else
							itemLink="enchant:"..tostring(-tonumber(item))
						end
						local link
						local itemInfo = GuildAds_ItemInfo[itemLink] or {};
						if (itemInfo and itemInfo.name) then
		  					local r, g, b, hex = GuildAds_GetItemQualityColor(itemInfo.quality);
		  					link = hex..itemInfo.name.."|r";
		  				else
		  					link = itemLink
		  				end
	  					if not headerInserted then
	  						tinsert(lines, set)
	  						headerInserted = true
	  					end
	  					local t = {}
	  					local gai = GuildAdsItems[keyTable[itemLink]]
	  					if gai then
	  						if gai.TradeSkill and gai.TradeSkill[GuildAds.playerName] then
								t.i = "   + "..link
							else
								t.i = "   "..link
							end
						else
							t.i = "   - "..link
						end
						local skillLevel = LibStub("LibPeriodicTable-3.1"):ItemInSet(tonumber(item), "TradeskillLevels."..set)
						local found, start, orange, yellow, green, gray 
						if skillLevel then
							start, _, orange, yellow, green, gray = skillLevel:find("([^/]+)/([^/]+)/([^/]+)/([^/]+)")
							if start then
								t.l = tonumber(gray)
							else
								t.l = 0
							end
						else
							t.l = 0
						end
						--t.i = t.i.." "..tostring(t.l)
						tinsert(profItems, t)
					end
					sort(profItems, function(a,b) if a.l < b.l then return false else if a.l > b.l then return true else return nil end end end)
					for k,v in pairs(profItems) do
						tinsert(lines, v.i)
					end
				end
			end
		end
	end
	return lines
end

local function setPoints(tooltip)
	GuildAdsTooltip:ClearAllPoints();
	local maxWidth = GuildAdsExtraTipWidth or 0
	if (maxWidth + 2) < (UIParent:GetWidth() - (tooltip:GetRight() or 0)) then
		GuildAdsTooltip:SetPoint("TOPLEFT", tooltip, "TOPRIGHT", 0, 0)
	else
		GuildAdsTooltip:SetPoint("TOPRIGHT", tooltip, "TOPLEFT", 0, 0)
	end

end

local hooks = {}

local function hookOnSizeChanged(self, width, height)
	if hooks[self] then
		if GuildAdsExtraTipLastParent == self then 
			setPoints(self)
		end
	end
end

-- Called to apply a pre-hook on the given tooltip's event.
local function hookscript(tip,script,hook)
	local orig = tip:GetScript(script)
	hooks[tip] = hooks[tip] or {origs = {}, hooks = {}}
	hooks[tip].origs[script] = orig
	local h = function(...)
		if hooks[tip].hooks[script] then
			hook(...)
		end
		if orig then orig(...) end
	end
	hooks[tip].hooks[script] = h
	tip:SetScript(script,h)
end

local emptyTable = {}
local function addGuildAdsInfo(tooltip, itemLink)
	local itemKey = keyTable[itemLink]
	if itemKey then
		local t = GuildAdsItems[itemKey]
		if t then
			local infosR = t.TradeNeed or emptyTable
			local infosA = t.TradeOffer or emptyTable
			local infosC = t.TradeSkill
			if infosR or infosA then
				local i=1
				while (infosR[i] or infosA[i]) and i<5 do
					local msgR, msgRr, msgRg, msgRb = formatData(nil, nil)
					if GuildAdsTradeTooltip.getProfileValue(nil, "ShowAsk") then
						msgR, msgRr, msgRg, msgRb = formatData("TradeNeed", infosR[i])
					end
					local msgA, msgAr, msgAg, msgAb = formatData(nil, nil)
					if GuildAdsTradeTooltip.getProfileValue(nil, "ShowHave") then
						msgA, msgAr, msgAg, msgAb = formatData("TradeOffer", infosA[i])
					end
					tooltip:AddDoubleLine(msgR, msgA, msgRr, msgRg, msgRb, msgAr, msgAg, msgAb)
					i= i+1
				end
				if infosC and GuildAdsTradeTooltip.getProfileValue(nil, "ShowCraftedBy") then
					-- = table.concat(infosC, ", ", 1, 10)
					local o = ""
					local glue = ""
					local c = 1
					for k,v in pairs(infosC) do
					 	if c>4 then
					 		o = o..", ..."
					 		break
					 	end
					 	o = o..glue..tostring(k)
						glue = ", "
						c = c + 1
					end
					if c>1 then
						tooltip:AddLine(string.format(CRAFTED_BY, o))
					end
				end
				tooltip:Show()
			end
		end
		if GuildAdsTradeTooltip.getProfileValue(nil, "ShowCraftedBy") then
			local valid, skill, itemid = RB_ParseItemLink(itemLink)
			if valid then
				local aknow, alearn, ahave, banked, rank, spec, rep, honor, makes
				rank, spec, rep, honor, makes = RB_GetSkillInfo(tooltip, skill)
				local craftKey = nameToKey[makes]
				--[[
				tooltip:AddDoubleLine("make:", "'"..tostring(makes).."'")
				tooltip:AddDoubleLine("skill:", skill)
				tooltip:AddDoubleLine("rank:", rank)
				tooltip:AddDoubleLine("rep:", rep)
				tooltip:AddDoubleLine("honor:", honor)
				tooltip:AddDoubleLine("key:", craftKey)
				]]
				local t = GuildAdsItems[craftKey]
				if t then
					local infosC = t.TradeSkill
					-- tooltip:AddDoubleLine("t:", tostring(t))
					-- tooltip:AddDoubleLine("infosC:", tostring(infosC))
					if infosC then
						local o = ""
						local glue = ""
						local c = 1
						for k,v in pairs(infosC) do
						 	if c>4 then
						 		o = o..", ..."
						 		break
						 	end
							o = o..glue..tostring(k)
							glue = ", "
							c = c + 1
						end
						if c>1 then
							tooltip:AddLine(string.format(CRAFTED_BY, o))
						end
					end
				end
				tooltip:Show()
			end
		end
		if GuildAdsTradeTooltip.getProfileValue(nil, "ShowCraftableTooltip") and tooltip:IsVisible() then
			local gatooltip = GuildAdsTooltip
			
			-- hook if not hooked
			if not hooks[tooltip] or not hooks[tooltip].hooks["OnSizeChanged"] then
				hookscript(tooltip, "OnSizeChanged", hookOnSizeChanged)
			end
			
			lines = getExtraTipLines(itemKey)
			GuildAdsExtraTipLastParent = tooltip
			
			if #lines > 1 then
				tooltip:Show()
				local maxWidth = 0
				for _, line in pairs(lines) do
					GuildAdsTooltipDummyText:SetText(line)
					local width = GuildAdsTooltipDummyText:GetWidth()
					if width > maxWidth then
						maxWidth = width
					end
				end
				maxWidth = maxWidth * GuildAdsTradeTooltip.clipTooltipScale(GuildAdsTradeTooltip.getProfileValue(nil, "TooltipScale") or 1.0)
				GuildAdsExtraTipWidth = maxWidth
				gatooltip:ClearLines();
				gatooltip:ClearAllPoints();
				gatooltip:SetOwner(tooltip, "ANCHOR_PRESERVE");
				gatooltip:SetParent(tooltip);
				setPoints(tooltip);
				for _, line in pairs(lines) do
					gatooltip:AddLine(line)
				end
				gatooltip:Show()
			else
				gatooltip:ClearLines();
				gatooltip:Hide()
			end
		end
	end
end

--------------------------------------------------------------------------

local Hooks = {}
do
  function Hooks:SetAction(id)
    local _, item = self:GetItem()
    if not item then return end
    addGuildAdsInfo(self, item)
  end

  function Hooks:SetAuctionItem(type, index)
    local item = _G.GetAuctionItemLink(type, index)
    addGuildAdsInfo(self, item)
  end

  function Hooks:SetAuctionSellItem()
	local _, item = self:GetItem()
	if not item then return end
    addGuildAdsInfo(self, item)
  end

  function Hooks:SetBagItem(bag, slot)
    local item  = _G.GetContainerItemLink(bag, slot)
    addGuildAdsInfo(self, item)
  end

  function Hooks:SetCraftItem(skill, slot)
    local item = _G.GetCraftReagentItemLink(skill, slot)
    addGuildAdsInfo(self, item)
  end

  function Hooks:SetHyperlink(link, count)
    addGuildAdsInfo(self, link)
  end

  function Hooks:SetInboxItem(index, attachmentIndex)
    local item = _G.GetInboxItemLink(index, attachmentIndex)
    addGuildAdsInfo(self, item)
  end

  function Hooks:SetInventoryItem(unit, slot)
    if type(slot) ~= "number" or slot < 0 then return end
	local item = _G.GetInventoryItemLink(unit, slot)
    addGuildAdsInfo(self, item)
  end

  function Hooks:SetLootItem(slot)
    local item = _G.GetLootSlotLink(slot)
    addGuildAdsInfo(self, item)
  end
--[[
  function Hooks:SetLootRollItem(rollID)
    local _, _, count = _G.GetLootRollItemInfo(rollID)
    ItemPriceTooltip:AddPrice(self, count)
  end
  function Hooks:SetMerchantCostItem(index, item)
    local _, count = _G.GetMerchantItemCostItem(index, item)
    addGuildAdsInfo(self, item)
  end
]]

  function Hooks:SetMerchantItem(slot)
    local item = _G.GetMerchantItemLink(slot)
    addGuildAdsInfo(self, item)
  end
--[[
  function Hooks:SetQuestItem(type, slot)
    local _, _, count = _G.GetQuestItemInfo(type, slot)
    ItemPriceTooltip:AddPrice(self, count)
  end

  function Hooks:SetQuestLogItem(type, index)
    local _, _, count = _G.GetQuestLogRewardInfo(index)
    ItemPriceTooltip:AddPrice(self, count)
  end

  function Hooks:SetSendMailItem(index)
    local _, _, count = _G.GetSendMailItem(index)
    ItemPriceTooltip:AddPrice(self, count)
  end

  function Hooks:SetSocketedItem()
    ItemPriceTooltip:AddPrice(self, 1)
  end

  function Hooks:SetExistingSocketGem()
    ItemPriceTooltip:AddPrice(self, 1)
  end

  function Hooks:SetSocketGem()
    ItemPriceTooltip:AddPrice(self, 1)
  end
]]
  function Hooks:SetTradePlayerItem(index)
    local item = _G.GetTradePlayerItemLink(index)
    addGuildAdsInfo(self, item)
  end
  
  function Hooks:SetTradeSkillItem(skill, slot)
    if slot then
      local item = _G.GetTradeSkillReagentItemLink(skill, slot)
	  addGuildAdsInfo(self, item)
    end
  end
  
  function Hooks:SetTradeTargetItem(index)
    local item = _G.GetTradeTargetItemLink(index)
    addGuildAdsInfo(self, item)
  end
  
  function Hooks:SetGuildBankItem(tab, slot)
    local item = _G.GetGuildBankItemLink(tab, slot)
    addGuildAdsInfo(self, item)
  end

end

local function installHooks(tooltip, hooks)
	for name, func in pairs(hooks) do
		if type(tooltip[name]) == "function" then
			-- AceHook:SecureHook(tooltip, name, func)
			hooksecurefunc(tooltip, name, func)
		end
	end
end;

---------------------------------------------------------------------------

local function updateItem(item, playerName, dataTypeName, count, inf)
	local delete = (count == 0) and (inf == false)
	item = keyTable[item]
	if (item ~= nil) then
		if not GuildAdsItems[item] then
			GuildAdsItems[item] = {}
		end
		if not GuildAdsItems[item][dataTypeName] then
			GuildAdsItems[item][dataTypeName] = {}
		end
		
		local f = function(k, v)
			if v.owner==playerName then
				return k;
			end
		end;
		local index = table.foreach(GuildAdsItems[item][dataTypeName], f);
		
		if index then
			if not delete then
				local t = GuildAdsItems[item][dataTypeName][index];
				t.count = count;
				t.inf = inf;
			else
				tremove(GuildAdsItems[item][dataTypeName], index);
			end
		else
			if not delete then
				tinsert(GuildAdsItems[item][dataTypeName], {
					count = count;
					inf = inf;
					owner = playerName;
				});
			end
		end
		table.sort(GuildAdsItems[item][dataTypeName], GuildAdsTradeTooltip.predicate);
	end
end
---------------------------------------------------------------------------


GuildAdsTradeTooltip = {

	metaInformations = { 
		name = "TradeTooltip",
	        guildadsCompatible = 200,
	        ui = {
	        	options = {
				frame = "GuildAdsTradeTooltipOptionsFrame",
				tab = "GuildAdsTradeTooltipOptionsTab",
				priority = 3
			}
		}
	};
		
	onInit = function()
		-- Hook SetItemRef
		-- TODO : add support for LootLink, ItemMatrix, KC_Items 
		installHooks(GameTooltip, Hooks)
		installHooks(ItemRefTooltip, Hooks)
		-- set default options
		if type(GuildAdsTradeTooltip.getRawProfileValue(nil, "ShowCraftableTooltip"))=="nil" then
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowCraftableTooltip", true);
		end
		if type(GuildAdsTradeTooltip.getRawProfileValue(nil, "ShowCraftedBy"))=="nil" then
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowCraftedBy", true);
		end
		if type(GuildAdsTradeTooltip.getRawProfileValue(nil, "ShowAsk"))=="nil" then
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowAsk", true);
		end
		if type(GuildAdsTradeTooltip.getRawProfileValue(nil, "ShowHave"))=="nil" then
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowHave", true);
		end
		GuildAdsTooltip:SetScale(GuildAdsTradeTooltip.clipTooltipScale(GuildAdsTradeTooltip.getProfileValue(nil, "TooltipScale") or 1.0))
	end;
	
	onShowOptions = function()	
		if GuildAdsTradeTooltip.getProfileValue(nil, "ShowCraftableTooltip") then
			GuildAdsTradeTooltip_ShowCraftableTooltipCheckButton:SetChecked(1);
		else
			GuildAdsTradeTooltip_ShowCraftableTooltipCheckButton:SetChecked(0);
		end
		
		if GuildAdsTradeTooltip.getProfileValue(nil, "ShowCraftedBy") then
			GuildAdsTradeTooltip_ShowCraftedByCheckButton:SetChecked(1);
		else
			GuildAdsTradeTooltip_ShowCraftedByCheckButton:SetChecked(0);
		end
		
		if (GuildAdsTradeTooltip.getProfileValue(nil, "ShowAsk")) then
			GuildAdsTradeTooltip_ShowAskCheckButton:SetChecked(1);
		else
			GuildAdsTradeTooltip_ShowAskCheckButton:SetChecked(0);
		end
	
		if (GuildAdsTradeTooltip.getProfileValue(nil, "ShowHave")) then
			GuildAdsTradeTooltip_ShowHaveCheckButton:SetChecked(1);
		else
			GuildAdsTradeTooltip_ShowHaveCheckButton:SetChecked(0);
		end
		local scale = GuildAdsTradeTooltip.getProfileValue(nil, "TooltipScale")
		scale = GuildAdsTradeTooltip.clipTooltipScale(scale)
		GuildAdsTradeTooltip.setProfileValue(nil, "TooltipScale", scale)
		GuildAdsTradeTooltip_ExtraTooltipScale:SetValue(scale);
	end;
	
	saveOptions = function()
		if GuildAdsTradeTooltipOptionsFrame:IsVisible() then
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowCraftableTooltip", GuildAdsTradeTooltip_ShowCraftableTooltipCheckButton:GetChecked() and true or false);
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowCraftedBy", GuildAdsTradeTooltip_ShowCraftedByCheckButton:GetChecked() and true or false);
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowAsk", GuildAdsTradeTooltip_ShowAskCheckButton:GetChecked() and true or false);
			GuildAdsTradeTooltip.setProfileValue(nil, "ShowHave", GuildAdsTradeTooltip_ShowHaveCheckButton:GetChecked() and true or false);
			local scale = GuildAdsTradeTooltip_ExtraTooltipScale:GetValue()
			scale = GuildAdsTradeTooltip.clipTooltipScale(scale)
			GuildAdsTradeTooltip.setProfileValue(nil, "TooltipScale", scale)
			GuildAdsTradeTooltip_ExtraTooltipScale:SetValue(scale);
			GuildAdsTooltip:SetScale(scale);
		end
	end;
	
	defaultsOptions = function()
		GuildAdsTradeTooltip_ShowCraftableTooltipCheckButton:SetChecked(1);
		GuildAdsTradeTooltip_ShowCraftedByCheckButton:SetChecked(1);
		GuildAdsTradeTooltip_ShowAskCheckButton:SetChecked(1);
		GuildAdsTradeTooltip_ShowHaveCheckButton:SetChecked(1);
		GuildAdsTradeTooltip_ExtraTooltipScale:SetValue(1.0);
	end;
	
	clipTooltipScale = function(scale)
		return scale and (scale<0.5 and 0.5 or (scale>1.0 and 1.0 or scale)) or 1.0
	end;
	
	onConfigChanged = function(path, key, value)
		--[[
		if key=="HideOfflinePlayer" or key=="HideMyAds" then
			GuildAdsTradeTooltip.data.resetCache();
			GuildAdsTradeTooltip.updateCurrentTab();
		end
		]]
	end;
	
	resetItems = function()
		GuildAdsItems = {};
		for _, item, playerName, data in GuildAdsDB.channel[GuildAds.channelName].TradeNeed:iterator() do
			updateItem(item, playerName, "TradeNeed", info.q or 0, (not info.q) and true or false)
		end
		for _, item, playerName, data in GuildAdsDB.channel[GuildAds.channelName].TradeOffer:iterator() do
			updateItem(item, playerName, "TradeOffer", info.q or 0, (not info.q) and true or false)
		end
		for _, item, playerName, data in GuildAdsDB.profile.TradeSkill:iterator() do
			GuildAdsTradeTooltip.onCraftUpdate(GuildAdsDB.profile.TradeSkill, playerName, data.e)
			GuildAdsTradeTooltip.onCraftUpdate(GuildAdsDB.profile.TradeSkill, playerName, item)
		end		
	end;
	
	onChannelJoin = function()
		-- Register for events
		GuildAdsDB.channel[GuildAds.channelName].TradeNeed:registerUpdate(GuildAdsTradeTooltip.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName].TradeOffer:registerUpdate(GuildAdsTradeTooltip.onDBUpdate);
		GuildAdsDB.profile.TradeSkill:registerUpdate(GuildAdsTradeTooltip.onCraftUpdate);
		GuildAdsDB.profile.TradeSkill:registerTransactionReceived(GuildAdsTradeTooltip.onTransactionCraftUpdate);
		
		-- Scan database
		GuildAdsTradeTooltip.resetItems();
	end;
	
	onChannelLeave = function()
		-- Unregister for events
		GuildAdsDB.channel[GuildAds.channelName].TradeNeed:unregisterUpdate(GuildAdsTradeTooltip.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName].TradeOffer:unregisterUpdate(GuildAdsTradeTooltip.onDBUpdate);
		GuildAdsDB.profile.TradeSkill:unregisterUpdate(GuildAdsTradeTooltip.onCraftUpdate);
		GuildAdsDB.profile.TradeSkill:unregisterTransactionReceived(GuildAdsTradeTooltip.onTransactionCraftUpdate);
		
		-- Clear database
		GuildAdsItems = {};
	end;
	
	onTransactionCraftUpdate = function(dataType, playerName, newKeys, deletedKeys)
		for _, item in pairs(deletedKeys) do
			GuildAdsTradeTooltip.onCraftUpdate(dataType, playerName, item)
		end
		for _, item in pairs(newKeys) do
			GuildAdsTradeTooltip.onCraftUpdate(dataType, playerName, item)
		end
	end;
	
	onCraftUpdate = function(dataType, playerName, item)
		local dataTypeName = dataType.metaInformations.name
		local info = dataType:get(playerName, item) -- is this an add (non-nil) or remove (nil)
		
		-- the following 2 loops are much too expensive and must be broken into smaller ones
		
		-- handle trade: links
		local LTLFunc = LibStub("LibTradeLinks-1.0")
		local LPTFunc = LibStub("LibPeriodicTable-3.1")
		local itemTable
		if item then
			local _, _, linkType = string.find(item, "^([^:]+):.*$")
			if linkType == "trade" then
				-- trade: link... build table of items with enchant links
				itemTable = {}
				local linkTable
				if GuildAdsTrade and GuildAdsTrade.data.tradelinkIsVisible(item, info) then
					linkTable = LTLFunc:Decode(item, true, false, (LTLFunc:GetBuildVersion()));
				end
				local level = tostring(UnitLevel("player"))
				if linkTable then
					for link in pairs(linkTable) do
						item="enchant:"..tostring(link)
						itemTable[item]=true
						local itemLink = LPTFunc:ItemInSet(-link,"Tradeskill.RecipeLinks")
						if itemLink then
							if tonumber(itemLink) > 0 then
								item="item:"..itemLink..":0:0:0:0:0:0:0:"..level
								itemTable[item]=true
							end
						end
					end
				end
				item = next(itemTable)
			end
		end
		
		while item do
			local key = keyTable[item]
			if key then
				if not GuildAdsItems[key] then
					GuildAdsItems[key] = {}
				end
				if not GuildAdsItems[key][dataTypeName] then
					GuildAdsItems[key][dataTypeName] = {}
				end
				local t = GuildAdsItems[key][dataTypeName]
				t[playerName] = info and true or nil
			end
			if type(itemTable) == "table" then
				item = next(itemTable, item)
			else
				item = nil
			end
		end
	end;
	
	onDBUpdate = function(dataType, playerName, item)
		local dataTypeName = dataType.metaInformations.name -- TradeNeed / TradeOffer
		local info = dataType:get(playerName, item);
		local count = 0;
		local inf = false;
		if info then
			if info.q then
				count = info.q;
			else
				inf = true;
			end
		else
			count = 0;
		end
		updateItem(item, playerName, dataTypeName, count, inf)
	end;
	
	predicate = function(a, b)
		-- nil references are always less than
		if (a == nil) then
			if (b == nil) then
				return false;
			else
				return true;
			end
		elseif (b == nil) then
			return false;
		end
	
		-- inf/count
		if (a.inf) then
			if (not b.inf) then
				return true;
			end
		else
			if (b.inf) then
				return false;
			else
				if (a.count < b.count) then
					return false;
				elseif (a.count > b.count) then
					return true;
				end
			end
		end
	
		-- owner
		if (a.owner<b.owner) then
			return true;
		elseif (a.owner>b.owner) then
			return false;
		end
	
		-- same
		return false;
	end;
	
}

GuildAdsPlugin.UIregister(GuildAdsTradeTooltip);

