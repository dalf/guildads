----------------------------------------------------------------------------------
--
-- GuildAdsCraftFrame.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local tradeskillPluginLoaded = false;

GuildAdsCraftFrame = {

	metaInformations = {
		name = "GuildAdsCraftFrame",
		guildadsCompatible = 100,
	};

	tradeskillPluginLoaded = false;

	onLoad = function(self)
		self:RegisterEvent("TRADE_SKILL_SHOW");		
		GuildAdsPlugin.UIregister(GuildAdsCraftFrame);
	end;
	
	onEvent = function(self, event)
		if event=="TRADE_SKILL_SHOW" then
			if not tradeskillPluginLoaded then
				GuildAdsTradeskillButton:ClearAllPoints();
				GuildAdsTradeskillButton:SetParent("TradeSkillFrame");
				GuildAdsTradeskillButton:SetPoint("BOTTOMRIGHT", TradeSkillCancelButton, "TOPRIGHT");
				GuildAdsTradeskillButton:Show();
				tradeskillPluginLoaded = true;
			end
		end
	end;
	
    onChannelJoin = function()
		if tradeskillPluginLoaded then
			GuildAdsTradeskillButton:Show();
		end
    end;

    onChannelLeave = function()
		if tradeskillPluginLoaded then
			GuildAdsTradeskillButton:Hide();
		end
    end;
	
	askItem = function(item)
		if item and item.ref then
			local data = GuildAdsDB.channel[GuildAds.channelName].TradeNeed:get(GuildAds.playerName, item.ref);
			if data then
				data.q = data.q + item.count;
			else
				data = { q=item.count, _t=GuildAdsDB:GetCurrentTime() };
			end
			GuildAdsDB.channel[GuildAds.channelName].TradeNeed:set(GuildAds.playerName, item.ref, data);
		end
	end;
	
	onClickHave = function(self)
		local item = self.value;
		local data = GuildAdsDB.channel[GuildAds.channelName].TradeOffer:get(GuildAds.playerName, item.ref);
		if not data then
			GuildAdsDB.channel[GuildAds.channelName].TradeOffer:set(GuildAds.playerName, item.ref, { _t=GuildAdsDB:GetCurrentTime() });
		end
	end;
	
	onClickAskItem = function(self)
		local item = self.value;
		GuildAdsCraftFrame.askItem(item);
	end;
	
	onClickAskEverything = function(self)
		for k,item in pairs(self.value) do
			GuildAdsCraftFrame.askItem(item);
		end
	end;
	
	buttons = {
		onClick = function(initializeMenu)
			HideDropDownMenu(1);
			GuildAdsCraftFrameMenu.initialize = initializeMenu;
			GuildAdsCraftFrameMenu.displayMode = "MENU";
			GuildAdsCraftFrameMenu.name = "Titre";
			ToggleDropDownMenu(1, nil, GuildAdsCraftFrameMenu, "cursor");	
		end;
		
		initializeTradeskillMenu = function(level)
			local id = TradeSkillFrame.selectedSkill;
			local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(id);
			local count = TradeSkillInputBox:GetNumber();
		
			------
			local composants = { };
			local menu = { };
		
			local count = TradeSkillInputBox:GetNumber();
			local numReagents = GetTradeSkillNumReagents(id);
			for i=1, numReagents, 1 do
				local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i);
				local link = GetTradeSkillReagentItemLink(id, i);
				local itemColor, itemRef, itemName = GuildAds_ExplodeItemRef(link);
				
				local info = {
					notCheckable = 1;
					func = GuildAdsCraftFrame.onClickAskItem;
					tooltipText = GUILDADS_TS_ASKITEMS_TT;
					value = {
						ref = itemRef;
						count = reagentCount
					}
				};
				if (count > 1) then
					info.value.count = (count*reagentCount)-playerReagentCount;
					info.text = GUILDADS_BUTTON_ADDREQUEST.." "..info.value.count.." "..reagentName;
					
				else
					info.text = GUILDADS_BUTTON_ADDREQUEST.." "..reagentName;
				end
				
				tinsert(composants, info.value);
				tinsert(menu, info);
			end
			
			---- Propose
			local link = GetTradeSkillItemLink(id);
			local itemColor, itemRef, itemName = GuildAds_ExplodeItemRef(link);
			
			info = {
				text = GUILDADS_BUTTON_ADDAVAILABLE.." "..skillName;
				notCheckable = 1;
				func = GuildAdsCraftFrame.onClickHave;
				value = { 
					ref=itemRef;
					count=count;
				};
			};
			UIDropDownMenu_AddButton(info, 1);
			
			---- Demande tous les composants
			info = {
				notCheckable = 1;
				text = string.format(GUILDADS_TS_ASKITEMS, count, skillName);
				tooltipTitle = skillName;
				tooltipText = GUILDADS_TS_ASKITEMS_TT;
				func = GuildAdsCraftFrame.onClickAskEverything;
				value = composants;
			};
			UIDropDownMenu_AddButton(info, 1);
			
			---- Demande un composant en particulier
			for k,info in pairs(menu) do
				UIDropDownMenu_AddButton(info, 1);
			end
			
			PlaySound("igMainMenuOpen");
		end;		
	};
};