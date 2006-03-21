-- WOW CONSTANTS
GAM_BANK_CONTAINER = BANK_CONTAINER;
GAM_NUM_BANKGENERIC_SLOTS = NUM_BANKGENERIC_SLOTS;

local myAdsCache = {};
local TTtoUpdate = {};

GuildAdsMule = {

	metaInformations = { 
		name = "GuildAdsMule",
        guildadsCompatible = 200,
	};	

	getAllAds = function()
		myAdsCache = {};
		TTtoUpdate = {};
		local myadsinframe = GAS_GetMyAds();
		-- class all ads by itemID
		for i, ads in ipairs(myadsinframe[GUILDADS_MSG_TYPE_AVAILABLE]) do
			if (ads.itemRef) then
				local _, _, itemLink1, itemLink2, itemLink2, itemLink4 = string.find(ads.itemRef, "item:(%d+):(%d+):(%d+):(%d+)");
				myAdsCache[itemLink1]= {};	
				myAdsCache[itemLink1]["quantity"] = 0;
				myAdsCache[itemLink1]["edit"]=true; 
				myAdsCache[itemLink1]["id"]=i;
				myAdsCache[itemLink1]["g_color"]=ads.itemColor;
				myAdsCache[itemLink1]["g_ref"]=ads.itemRef; 
				myAdsCache[itemLink1]["g_name"]=ads.itemName;
				myAdsCache[itemLink1]["texture"]=ads.texture;
				myAdsCache[itemLink1]["visited"]=false;
				myAdsCache[itemLink1]["speid"]=ads.id;
			else
				myAdsCache[ads.id]= {};
				myAdsCache[ads.id]["edit"]=true; 
				myAdsCache[ads.id]["gaobject"]=true;
				myAdsCache[ads.id]["id"]=i;
				myAdsCache[ads.id]["visited"] = true;
				myAdsCache[ads.id]["speid"]=ads.id;
			end
		end
	
	end;
	
	onInit = function()
		GAS_NotifyListeners(GAS_EVENT_ITEMINFOREADY, "GAMule", GuildAdsMule.onTooltipUpdated);
	end;
	
	onChannelJoin = function()
		GuildAdsMuleButton:Show();
	end;
	
	onChannelLeave = function()
		GuildAdsMuleButton:Hide();
	end;

	-- callback on iteminfo	
	onTooltipUpdated = function()
		for itemID,value in TTtoUpdate do 
			local info = GAS_GetItemInfo(itemID);
			if (not myAdsCache[value]) then
				myAdsCache[value]= {};
				myAdsCache[value]["soul"]=info.soulbound;
			else 
				myAdsCache[value]["soul"]=info.soulbound;
			end
		end
	end;

	-- update one item	
	updateAdsList = function(bagitemlink,itemCount) 
		local _, _, itemLink1, itemLink2, itemLink3, itemLink4 = string.find(bagitemlink, "item:(%d+):(%d+):(%d+):(%d+)");
		if (itemLink1) then
			local sName, sLink, iQuality, iLevel, sType, sSubType, iCount, e, iTexture = GetItemInfo(itemLink1);
			if (not myAdsCache[itemLink1]) then
				myAdsCache[itemLink1]= {};
				local color,ref,name = GAS_UnpackLink(bagitemlink);
				myAdsCache[itemLink1]["g_color"] = color;
				myAdsCache[itemLink1]["g_ref"] = ref;
				myAdsCache[itemLink1]["g_name"]= name;
				myAdsCache[itemLink1]["name"] = NoNil(sName);
				myAdsCache[itemLink1]["quantity"] = itemCount;
				myAdsCache[itemLink1]["texture"] = iTexture;
				myAdsCache[itemLink1]["quality"] = iQuality;
				myAdsCache[itemLink1]["visited"] = true;
			else
				myAdsCache[itemLink1]["quantity"]= myAdsCache[itemLink1]["quantity"]+ itemCount;
				myAdsCache[itemLink1]["visited"] = true;
			end
			local info = GAS_GetItemInfo("item:"..itemLink1..":"..itemLink2..":"..itemLink3..":"..itemLink4, true);
			if (info.soulbound == nil) then 
				TTtoUpdate["item:"..itemLink1..":"..itemLink2..":"..itemLink3..":"..itemLink4]="itemLink1";
			else
				myAdsCache[itemLink1]["soul"]=info.soulbound;
			end
		end
	end;

	-- explore all bag inspired by WOW character
	refresh = function()
		GuildAdsMule.getAllAds();
		
		local texture, itemCount, locked, quality, readable, link;
		local bagitemlink, bagname;
	
		for i=1, GAM_NUM_BANKGENERIC_SLOTS do
			texture, itemCount, locked, quality, readable = GetContainerItemInfo(GAM_BANK_CONTAINER, i);
			bagitemlink = GetContainerItemLink(GAM_BANK_CONTAINER, i);
			if (bagitemlink) then
--~ 				GuildAdsMule.debug("BANK"..bagitemlink..":"..itemCount);
				GuildAdsMule.updateAdsList(bagitemlink,itemCount);
			end
		end
	
		-- WFRCharacterprofiler
		for bag = 5, 10 do
			link = GetContainerItemLink(BANK_CONTAINER, (bag+20));
			texture, itemCount, locked, quality = GetContainerItemInfo(BANK_CONTAINER, (bag+20));
			if( link ) then
				for color, item, bagname in string.gfind(link, "|c(%x+)|Hitem:(%d+:%d+:%d+:%d+)|h%[(.-)%]|h|r") do
					if( color ~= nil and item ~= nil and bagname ~= nil ) then
						for slot = 1,GetContainerNumSlots(bag) do	-- loop through all slots in this bag and get items
							texture, itemCount, locked, quality = GetContainerItemInfo(bag,slot);
							link = GetContainerItemLink(bag, slot);
							if (link) then
--~ 								GuildAdsMule.debug("BANK++"..link..":"..itemCount);
								GuildAdsMule.updateAdsList(link,itemCount);
							end
						end
	
					end
				end
			end			
		end

		for bag = 0,4 do
			if (bag == 0) then
				bagname = __CP_BACKPACK;
				for slot = 1,GetContainerNumSlots(bag) do	-- loop through all slots in this bag and get items
					texture, itemCount, locked, quality = GetContainerItemInfo(bag,slot);
					link = GetContainerItemLink(bag, slot);
					if (link) then
--~ 						GuildAdsMule.debug("BAG"..link..":"..itemCount);
						GuildAdsMule.updateAdsList(link,itemCount);
					end
				end
			else
				link = GetInventoryItemLink("player", (bag+19));
				texture = GetInventoryItemTexture("player", (bag+19));
				if( link ) then
					for color, item, bagname in string.gfind(link, "|c(%x+)|Hitem:(%d+:%d+:%d+:%d+)|h%[(.-)%]|h|r") do
						if( color ~= nil and item ~= nil and bagname ~= nil ) then
							for slot = 1,GetContainerNumSlots(bag) do	-- loop through all slots in this bag and get items
								texture, itemCount, locked, quality = GetContainerItemInfo(bag,slot);
								link = GetContainerItemLink(bag, slot);
								if (link) then
--~ 									GuildAdsMule.debug("BAGSUP"..link..":"..itemCount);
									GuildAdsMule.updateAdsList(link,itemCount);
								end
							end
						end
					end
				end			
			end
		end	

		---- Add the ADS
		for itemID,value in myAdsCache do 
			
			if (value["soul"] == false) then
				if (value["edit"]) then
					if (value["gaobject"]) then
					else
						GAS_EditMyAd(GUILDADS_MSG_TYPE_AVAILABLE, value["id"], nil, value["g_color"],value["g_ref"], value["g_name"], value["texture"], value["quantity"]);
					end
				else
					GAS_AddMyAd(GUILDADS_MSG_TYPE_AVAILABLE,nil ,value["g_color"],value["g_ref"], value["g_name"], value["texture"], value["quantity"]);
				end
			end
		end
		-- remove old
		for itemID,value in myAdsCache do 
			if (value["visited"]==false) then
				GAS_RemoveMyAd(GUILDADS_MSG_TYPE_AVAILABLE,value["speid"]);
			end
		end
	end
	
}

GuildAdsPlugin.UIregister(GuildAdsMule);