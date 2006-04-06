----------------------------------------------------------------------------------
--
-- GuildAdsInventoryFrame.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local currentInventory = {};
local SlotIdText = {
		[1]  = "HeadSlot",
		[2]  = "NeckSlot", 
		[3]  = "ShoulderSlot",
		[4]  = "ShirtSlot",
		[5]  = "ChestSlot",
		[6]  = "WaistSlot",
		[7]  = "LegsSlot",
		[8]  = "FeetSlot",
		[9]  = "WristSlot",
		[10] = "HandsSlot",
		[11] = "Finger0Slot",
		[12] = "Finger1Slot",
		[13] = "Trinket0Slot",
		[14] = "Trinket1Slot",
		[15] = "BackSlot",
		[16] = "MainHandSlot",
		[17] = "SecondaryHandSlot",
		[18] = "RangedSlot",
		[19] = "TabardSlot",
			};
		-- [19] = "AmmoSlot",
		
GuildAdsInventory = {
	metaInformations = { 
		name = "Inventory",
        guildadsCompatible = 200,
		ui = {
			inspect = {
				frame = "GuildAdsInventoryFrame",
				tab = "GuildAdsInventoryTab",
				tooltip = "Inventory tab",
				priority = 1
			}
		}
	};
	
	onInit = function()
		GuildAdsDB.profile.Inventory:registerEvent(GuildAdsInventory.onDBUpdate);
	end;
	
	onDBUpdate = function(dataType, playerName, slot)
		if slot ~= "_t" then
			GuildAdsInventory.SlotOnUpdate(playerName, slot);
		end
	end;
	
	SlotOnLoad = function()
		local slotName = this:GetName();
		local id, textureName = GetInventorySlotInfo(strsub(slotName,16));
		this:SetID(id);
		local texture = getglobal(slotName.."IconTexture");
		texture:SetTexture(textureName);
		this.backgroundTextureName = textureName;		
	end;

	SlotOnUpdate = function(playerName, slot)
		if playerName == GuildAdsInspectWindow.playerName then
			local data = GuildAdsDB.profile.Inventory:get(playerName, slot);
			if data then
				GuildAdsInventory.SlotUpdate(slot,  data.i, data.q);
			else
				GuildAdsInventory.SlotUpdate(slot,  nil, nil);
			end
		end;
	end;
	
	SlotOnEnter = function()
		if (currentInventory[this:GetID()] ~= nil) then
			GuildAdsInventory.SetTooltip(currentInventory[this:GetID()]);
		end
	end;
	
	SlotOnLeave = function()
		GameTooltip:Hide();
	end;
	
	SlotOnClick = function()
		if ( button == "LeftButton" ) then
			if ( IsShiftKeyDown() ) then
				if ( ChatFrameEditBox:IsVisible() ) then
					ChatFrameEditBox:Insert(currentInventory[this:GetID()]);
				end
			end
		end
	end;
	
	SlotUpdate = function(slot, item, count)
		button = getglobal("GuildAdsInspect"..SlotIdText[slot]);
		currentInventory[slot]= item;
		if (item) then
			info = GuildAds_ItemInfo[item] or {};
			SetItemButtonTexture(button, info.texture or "");
			SetItemButtonCount(button, count);
		else
			SetItemButtonTexture(button, button.backgroundTextureName);
			SetItemButtonCount(button, 0);
		end
		
		if ( GameTooltip:IsOwned(button) ) then
			if ( item ) then
				GuildAdsInventory.SetTooltip(itemRef);
			else
				GameTooltip:Hide();
			end
		end
	end;
	
	SetTooltip = function(item)
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		if (item) then
			GameTooltip:SetHyperlink(item);
			GuildAdsUITools:TooltipAddTT(GameTooltip, nil, item, nil, 1);
		end		
	end;
	
	Update = function(sendRequest)
-- 		GuildAdsInspectWindow:SetTime(GuildAdsDB:FormatTime(inventory.creationtime));
		for slot=1,19,1 do
			GuildAdsInventory.SlotOnUpdate(GuildAdsInspectWindow.playerName, slot);
		end
		if sendRequest then
			-- Send inspect request
			-- GuildAdsInventory.debug("sending request");
			-- TODO : update on demand
		end;
	end;
	
	OnShow = function()
		GuildAdsInventory.Update(false);
	end;
	
}

---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsInventory);