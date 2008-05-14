----------------------------------------------------------------------------------
--
-- GuildAdsItem.lua
--
-- Author: Zarkan@Ner'zhul-EU, Fkaï@Ner'zhul-EU, Galmok@Stormrage-EU
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- cache for GetItemInfo and Tooltip information.
GuildAds_ItemInfo = setmetatable({}, {
	__index = function(t, n)
		local v = GuildAds_GetItemInfo(n);
		if v then
			rawset(t, n, v);
			return v;
		end;
	end;
	
	__newindex = function(t, n, v)
		error("GuildAds_ItemInfo can't be assigned", 2);
	end;
});

local _ItemInfo = CreateFrame("GameTooltip", "GuildAdsITT", nil, "GameTooltipTemplate");
local _ITT = GuildAdsITT
local SetItem, Timeout, AddItem, ItemReady, ParseTooltip
do
	function SetItem(itemRef)
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - SetItem:"..itemRef);
		_ITT.currentItemRef = itemRef;
		_ITT:ClearLines();
		_ITT:SetOwner(WorldFrame, "ANCHOR_NONE"); 
		
		_ITT:SetHyperlink(itemRef);
		GuildAdsTask:AddNamedSchedule("GuildAdsItem_Timeout", 2, nil, nil, Timeout);
	end

	function Timeout()
		if _ITT.currentItemRef then
			GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - Timeout:".._ITT.currentItemRef);
		
			GuildAdsTask:DeleteNamedSchedule("GuildAdsItem_ItemReady")
		
			if _ITT.itemRefs[_ITT.currentItemRef] < 3 then
				_ITT.itemRefs[_ITT.currentItemRef] = (_ITT.itemRefs[_ITT.currentItemRef] or 0) + 1;
			else
				-- hide tooltip
				_ITT.itemRefs[_ITT.currentItemRef] = nil
				_ITT.count = _ITT.count-1
				_ITT.currentItemRef = nil
				_ITT:Hide();
			end
			local itemRef = next(_ITT.itemRefs);
			if itemRef then
				SetItem(itemRef);
			else
				GuildAdsPlugin_OnEvent(GAS_EVENT_ITEMINFOREADY);
			end
		end
	end

	function AddItem(itemRef)
		if itemRef then
			if not _ITT.itemRefs then
				_ITT.itemRefs = {};
				_ITT.count = 0;
			end
			if not _ITT.itemRefs[itemRef] then
				-- GuildAds_ChatDebug(GA_DEBUG_STORAGE, "AddItem:"..itemRef);
				_ITT.itemRefs[itemRef] = 1;
				_ITT.count = 1 + _ITT.count;
				if _ITT.count == 1 then
					SetItem(itemRef);
				end
			end
		end
	end

	-- patch 2.0.2 : to be call be OnTooltipSetItem handler
	function ItemReady()
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - ItemReady: %s", tostring(_ITT.currentItemRef));
		if not _ITT.currentItemRef then
			-- unknown error occured. Drop remaining items from queue and signal iteminfo ready
			-- This is just a crude workaround
			_ITT.itemRefs = {}
			GuildAdsPlugin_OnEvent(GAS_EVENT_ITEMINFOREADY);
			return
		end			
		
		if (_G["GuildAdsITTTextLeft1"]:GetText() == RETRIEVING_ITEM_INFO) then
			GuildAdsTask:AddNamedSchedule("GuildAdsItem_ItemReady", 0.3, nil, nil, ItemReady)
			return
		end
		
		-- GetItemInfo again
		GuildAds_GetItemInfo(_ITT.currentItemRef);
		-- parse tooltips
		ParseTooltip(_ITT.currentItemRef);

		-- for enchant link : create a fake texture, type, subtype
		local found, _, itemLink1 = string.find(_ITT.currentItemRef, "enchant:(%d+)");
		if found then
			local t = _ItemInfo[_ITT.currentItemRef];
			t.texture = "Interface/Icons/Spell_Holy_GreaterHeal";
			t.type = GUILDADS_SKILLS[9];
			t.subtype = "";
		end
		
		-- hide tooltip
		_ITT.itemRefs[_ITT.currentItemRef] = nil
		_ITT.count = _ITT.count-1
		_ITT.currentItemRef = nil
		_ITT:Hide();
		
		-- next item if there is one
		local itemRef = next(_ITT.itemRefs);
		if itemRef then
			SetItem(itemRef);
		else
			GuildAdsPlugin_OnEvent(GAS_EVENT_ITEMINFOREADY);
		end
	end

	function ParseTooltip(itemRef)
		if not rawget(_ItemInfo, itemRef) then
			rawset(_ItemInfo, itemRef, { _tt = true });
		else
			_ItemInfo[itemRef]._tt = true;
		end
		
		-- use first line of the tooltip to get a name
		-- patch 2.0.2 : name, link = Tooltip:GetItem()
		if not _ItemInfo[itemRef].name then
			_ItemInfo[itemRef].name = _G["GuildAdsITTTextLeft1"]:GetText();
		end
		
		-- use color of first line of the tooltip to get quality
		if not _ItemInfo[itemRef].quality then
			local r, g, b = _G["GuildAdsITTTextLeft1"]:GetTextColor()
			local color = string.format("%02x%02x%02x", r*255, g*255, b*255);
			-- there is some round problem : find the minimum distance between GetItemQualityColor() values and GetTextColor() values
			local rr, gg, bb;
			local d = 10;
			local q = 1;
			--for quality=1,6,1 do
			for quality=-1,6,1 do -- quality starts from 0, not 1. Also added quality -1 for enchant links. --GALMOK
				rr, gg, bb = GuildAds_GetItemQualityColor(quality);
				local dd = math.abs(rr-r)+math.abs(gg-g)+math.abs(bb-b);
				if dd<d then
					d = dd;
					q = quality;
				end
			end
			_ItemInfo[itemRef].quality = q;
		end
		_ItemInfo[itemRef].soulbound = false;
		_ItemInfo[itemRef].questitem = false;
		-- TODO : add ITEM_CREATED_BY
		-- ITEM_CLASSES_ALLOWED, ITEM_RACES_ALLOWED, ITEM_REQ_REPUTATION, ITEM_REQ_SKILL, LOCKED_WITH_SPELL_KNOWN, ITEM_MIN_SKILL, 
		for idx = 2, 5 do
			local ttext = _G["GuildAdsITTTextLeft"..idx];
			if(ttext and ttext:GetText() ~= nil) then
				local textLeft = ttext:GetText();
				if textLeft==ITEM_BIND_ON_PICKUP or textLeft==ITEM_SOULBOUND then
					_ItemInfo[itemRef].soulbound = true;
				elseif textLeft==ITEM_BIND_QUEST or textLeft==ITEM_STARTS_QUEST then
					_ItemInfo[itemRef].questitem = true;
				elseif textLeft==ITEM_SPELL_KNOWN then
					_ItemInfo[itemRef].spellKnown = true;
				elseif textLeft==ITEM_CONJURED then
					_ItemInfo[itemRef].conjured = true;
				end
			end
		end
	end
	
	_ITT:SetScript("OnShow", ItemReady);
end

---------------------------------------------------------------------------------
--
-- GuildAds_ImplodeItemRef
--
---------------------------------------------------------------------------------
function GuildAds_ImplodeItemRef(color, ref, name)
	color = color or "ffffffff";
	name = name or "??";
	if (ref) then
		return "|c"..color.."|H"..ref.."|h["..name.."]|h|r";
	elseif (color) then
		return "|c"..color.."["..name.."]|r";
	end
end

---------------------------------------------------------------------------------
--
-- GuildAds_ExplodeItemRef
--
---------------------------------------------------------------------------------
function GuildAds_ExplodeItemRef(itemRef)
	local start, _, color, ref, name = string.find(itemRef, "|c([%w]+)|H([^|]+)|h%[([^|]+)%]|h|r");
	if (start) then
		return color, ref, name;
	else
		local _, _, color, name = string.find(itemRef, "|c([%w]+)%[([^|]+)%]|r");
		return color, nil, name;
	end
end

---------------------------------------------------------------------------------
--
-- GuildAds_GetItemQualityColor
-- GALMOK: Use this if the quality comes from item.quality and not from GetItemInfo.
--
---------------------------------------------------------------------------------
function GuildAds_GetItemQualityColor(quality)
	if quality>=0 and quality<=6 then -- item colours
		return GetItemQualityColor(quality)
	elseif quality==-1 then -- enchant color
		return 1.0,208/255,0,"|cffffd000";
	end
end

--[[
	GuildAds_ItemInfo[itemRef]
	GuildAds_GetItemInfo(itemRef, needTooltipInformation)
]]

---------------------------------------------------------------------------------
--
-- GuildAds_GetItemInfo
-- Get item information
--
-- fill when needTooltipInformation~=true
-- *name, type, subtype, slot, quality, stackcount, minlevel, texture
--
-- fill when needTooltipInformation==true
-- *_tt, soulbound, questitem, spellKnown
--
-- if the item is not in the itemcache.wdb file, you have to wait for GAS_EVENT_ITEMINFOREADY
-- 
-- test : /dump GuildAds_GetItemInfo("item:9387:0:1200:0")
---------------------------------------------------------------------------------
function GuildAds_GetItemInfo(itemRef, needTooltipInformation)
	if itemRef and not(rawget(_ItemInfo, itemRef) and (not needTooltipInformation or rawget(_ItemInfo, itemRef)._tt))  then
		local found, _, itemLink1, itemLink2, itemLink3, itemLink4 = string.find(itemRef, "item:(%d+):(%d+):(%d+):(%d+)");
		if not found then
			-- for enchant:xxx
			found, _, itemLink1 = string.find(itemRef, "enchant:(%d+)");
			if found then
				AddItem(itemRef);
			end
			return;
		end
		itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemSlot, itemTexture = GetItemInfo(itemRef);
		if (not itemName) or needTooltipInformation then
			AddItem(itemRef);
		end
		if itemName then
			if itemSlot then
				local itemSlotLocal = _G[itemSlot]
				if itemSlotLocal then
					itemSlot = itemSlotLocal;
				end
			end
		
			if not rawget(_ItemInfo, itemRef) then
				rawset(_ItemInfo, itemRef, {});
			end
			
			_ItemInfo[itemRef].name = itemName;
			_ItemInfo[itemRef].type = itemType;
			_ItemInfo[itemRef].subtype = itemSubType;
			_ItemInfo[itemRef].slot = itemSlot;
			_ItemInfo[itemRef].quality = itemRarity; 
			_ItemInfo[itemRef].stackcount = itemStackCount;
			_ItemInfo[itemRef].minlevel = itemMinLevel;
			_ItemInfo[itemRef].texture = itemTexture;
		end
	end
	
	return rawget(_ItemInfo, itemRef);
end
