----------------------------------------------------------------------------------
--
-- GuildAdsTradeFrame.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- --  pour le menu contextuel dans "Echange"
-- flamentalexandre: j'ai proposition :
-- flamentalexandre: Sélectioner l'auteur dans l'onglet Guilde
-- flamentalexandre: Créer une annonce à partir de celle çi
local g_AdFilters = {}; 

GuildAdsTrade = {
	metaInformations = { 
		name = "Trade",
        guildadsCompatible = 200,
		ui = {
			main = {
				frame = "GuildAdsTradeFrame",
				tab = "GuildAdsTradeTab",
				tooltip = "Trade tab",
				priority = 1
			},
			options = {
				frame = "GuildAdsTradeOptionsFrame",
				tab = "GuildAdsTradeOptionsTab",
				priority = 2
			}
		}
	};
	
	g_DateFilter = {
		1,
		60,
		24*60,
		24*60*2,
		24*60*7,
		24*60*14,
		24*60*30
	};
	
	ADMAXLENGTH = 59;
	MaxTradeColumnHeader = 6;
	
	TAB_REQUEST = 1;
	TAB_AVAILABLE = 2;
	TAB_MY_ADS = 3;
	
	GUILDADS_NUM_GLOBAL_AD_BUTTONS = 20;
	GUILDADS_ADBUTTONSIZEY = 22;
	
	filter_color = {
		["everything"] = { ["r"] = 0.75,    ["g"] = 0.75,    ["b"] = 0.75 },
		["everythingelse"] ={ ["r"] = 0.75,    ["g"] = 0,    ["b"] = 0.75 },
		["gather"] ={ ["r"] = 0,    ["g"] = 1,    ["b"] = 1 },
		["monster"] = { ["r"] = 1,    ["g"] = 0,    ["b"] = 0.70 },
		["vendor"] = { ["r"] = 0,    ["g"] = 0,    ["b"] = 0.40 },
		["classReagent"] = { ["r"] = 0,    ["g"] = 1,    ["b"] = 0 },
		["tradeReagent"] = { ["r"] = 0,    ["g"] = 0.5,    ["b"] = 0 },
		["trade"] = { ["r"] = 0.75,    ["g"] = 0.75,    ["b"] = 0.75 }
	};
	
	GuildAds_ItemFilterOrder = {
		"everything",
		"everythingelse",
		"gather",
		"monster",
		"classReagent",
		"tradeReagent",
		"vendor",
		"trade"
	};
	
	currentTab = GuildAds.TAB_REQUEST;
	currentAdType = 0;
	currentPlayerName = "";
	currentItem = "";
	
	TabToAdType = {
		[1] = GUILDADS_MSG_TYPE_REQUEST;
		[2] = GUILDADS_MSG_TYPE_AVAILABLE;
	};
	g_sortBySubType = true;
	
	administrator = false;
	
	onShowOptions = function()
		if GuildAdsTrade.getProfileValue(nil, "PublishMyAds", true) then
			GuildAds_PublishMyAdsCheckButton:SetChecked(1);
		else
			GuildAds_PublishMyAdsCheckButton:SetChecked(0);
		end
		
		if GuildAdsTrade.getProfileValue(nil, "HideOfflinePlayer") then
			GuildAds_ShowOfflinePlayerCheckButton:SetChecked(0);
		else
			GuildAds_ShowOfflinePlayerCheckButton:SetChecked(1);
		end
		
		if GuildAdsTrade.getProfileValue(nil, "HideMyAds") then
			GuildAds_ShowMyAdsCheckButton:SetChecked(0);
		else
			GuildAds_ShowMyAdsCheckButton:SetChecked(1);
		end
	end;
	
	saveOptions = function()
		GuildAdsTrade.setProfileValue(nil, "PublishMyAds", GuildAds_PublishMyAdsCheckButton:GetChecked());
		GuildAdsTrade.setProfileValue(nil, "HideOfflinePlayer", not GuildAds_ShowOfflinePlayerCheckButton:GetChecked());
		GuildAdsTrade.setProfileValue(nil, "HideMyAds", not GuildAds_ShowMyAdsCheckButton:GetChecked());
	end;
	
	defaultsOptions = function()
		GuildAds_PublishMyAdsCheckButton:SetChecked(1);
		GuildAds_ShowOfflinePlayerCheckButton:SetChecked(1);
		GuildAds_ShowMyAdsCheckButton:SetChecked(1);
	end;
	
	onShow = function()
		GuildAdsTrade.debug("onShow");
		GuildAdsTrade.updateCurrentTab();
	end;
	
	onItemInfoReady = function()
		GuildAdsTrade.updateCurrentTab();
	end;
	
	onInit = function() 
		GuildAdsTrade.initialized = true;
		
		GuildAdsTrade.filterClass.init();
		
		if ReagentData then
			UIDropDownMenu_Initialize( getglobal("GuildAds_Filter_ZoneDropDown"), GuildAdsTrade.ItemFilter.init);
			UIDropDownMenu_SetText(FILTER, getglobal("GuildAds_Filter_ZoneDropDown"));
			UIDropDownMenu_SetWidth(100,  getglobal("GuildAds_Filter_ZoneDropDown"));
		end
		
		-- TODO : todo on first show of the frame, not now
		GuildAdsTrade.selectTab(GuildAdsTrade.TAB_REQUEST);
		
		-- Init date filter
		
		local range = table.getn(GuildAdsTrade.g_DateFilter)+1;
		GuildAds_DateFilter:SetMinMaxValues(1,range);
		GuildAds_DateFilter:SetValueStep(1);
		local dateFilter = GuildAdsTrade.getProfileValue(nil, "HideAdsOlderThan", nil);
		if dateFilter then
			for value, time in GuildAdsTrade.g_DateFilter do
				if dateFilter==time then
					GuildAds_DateFilter:SetValue(value);
				end
			end
		else
			GuildAds_DateFilter:SetValue(range);
		end
		
		local t1,t2,t3 = GuildControlGetRankFlags();
		
		if (t3) then 
			GuildAdsTrade.administrator = true;
			GuildAdsTradeAdminDeleteButton:Show();
		
		end
		GuildAdsTrade.PrepareSortArrow();
	end;
	
	onChannelJoin = function()
		GuildAdsTrade.debug("onChannelJoin("..GuildAds.channelName..")");
		-- Register for events
		GuildAdsDB.channel[GuildAds.channelName].TradeNeed:registerEvent(GuildAdsTrade.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName].TradeOffer:registerEvent(GuildAdsTrade.onDBUpdate);
	end;
	
	onChannelLeave = function()
		GuildAdsTrade.debug("onChannelLeave");
		-- Unregister for events
		GuildAdsDB.channel[GuildAds.channelName].TradeNeed:unregisterEvent(GuildAdsTrade.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName].TradeOffer:unregisterEvent(GuildAdsTrade.onDBUpdate);
	end;
	
	onConfigChanged = function(path, key, value)
		if key=="HideOfflinePlayer" or key=="HideMyAds" then
			GuildAdsTrade.data.resetCache();
			GuildAdsTrade.updateCurrentTab();
		elseif key=="PublishMyAds" then
			-- TODO : delete or implement this feature
			if value then
				-- Broadcast all my ads
				-- GAC_SendAllAdsType(nil, nil);
			else
				-- Broadcast a message to remove all my ads
				-- GAC_SendRemoveAll(nil);
			end			
		end
	end;
	
	onDBUpdate = function(dataType, playerName, item)
		GuildAdsTrade.debug("onDBUpdate");
		-- refresh tabs (offer, need, my ads)
		GuildAdsTrade.data.resetCache();
		
		-- TODO : actuellement 100 nouvelles annonces = 100 refresh de la selection même si la fenêtre est cachée
		GuildAdsTrade.select(GuildAdsTrade.currentAdType, GuildAdsTrade.currentPlayerName, GuildAdsTrade.currentItem)
		
		-- 
		if playerName ~= GuildAds.playerName then
			local tochat;
			local data = dataType:get(playerName, item);
			if data then
				if dataType.metaInformations.name=="Need" and GuildAdsTrade.getProfileValue(nil, "ShowNewAsk") then
					tochat = GUILDADS_HEADER_REQUEST..": ";
				end
				if dataType.metaInformations.name=="Offer" and GuildAdsTrade.getProfileValue(nil, "ShowNewHave") then
					tochat = GUILDADS_HEADER_AVAILABLE..": ";
				end
			end
			if (tochat ~= nil) then
				local info = GuildAds_ItemInfo[item] or {};
				local _, _, _, hex = GetItemQualityColor(info.quality or 1)
				tochat = tochat .. hex.."|H"..item.."|h["..info.name.."]|r";
				if data.q then
					tochat = tochat.." x "..data.q;
				end
				GuildAdsUITools:AddChatMessage("["..playerName.."]\32"..tochat);
			end			
		end
	end;
	
	-- ItemFilter	
	onDateChange = function() 
		if GuildAdsTrade.g_DateFilter[GuildAds_DateFilter:GetValue()] then
			GuildAds_DateFilterLabel:SetText(GuildAdsDB:FormatTime(GuildAdsTrade.g_DateFilter[this:GetValue()], true));
			GuildAdsTrade.setProfileValue(nil, "HideAdsOlderThan", GuildAdsTrade.g_DateFilter[this:GetValue()]);
		else
 			GuildAds_DateFilterLabel:SetText(GUILDADS_ITEMS.everything);
 			GuildAdsTrade.setProfileValue(nil, "HideAdsOlderThan", nil);
 		end
 		GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentTab, true);
 	end;
	
	PrepareSortArrow = function() 
		local i = 1;
		for key,value in GuildAdsTrade.sortData.currentWay do
			GuildAdsTrade.sortAdsArrow(getglobal("GuildAdsTradeColumnHeader"..i),GuildAdsTrade.sortData.currentWay[key]);
			i = i+1;
		end;
	end;
	
	sortAdsArrow = function (button,way)
		if ( way == "normal" ) then
			getglobal(button:GetName().."Arrow"):SetTexCoord(0, 0.5625, 1.0, 0);
		else
			getglobal(button:GetName().."Arrow"):SetTexCoord(0, 0.5625, 0, 1.0);
		end
	end;
	
	sortTrade = function(sortValue)
		GuildAdsTrade.sortData.current = sortValue;
		if (GuildAdsTrade.sortData.currentWay[sortValue]=="normal") then 
			GuildAdsTrade.sortData.currentWay[sortValue]="up";
		else 
			GuildAdsTrade.sortData.currentWay[sortValue]="normal";
		end
		GuildAdsTrade.sortAdsArrow(this,GuildAdsTrade.sortData.currentWay[sortValue]);
		GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentTab,true);
	end;
	
	ItemFilter = {
	
		init = function()
			local FilterNames = {};
			if (ReagentData) then
				FilterNames = GUILDADS_ITEMS;
			else
				FilterNames = GUILDADS_ITEMS_SIMPLE;
			end
			for i, key in GuildAdsTrade.GuildAds_ItemFilterOrder do
				if (FilterNames[key]) then
					tinsert(g_AdFilters, {id = key, name=FilterNames[key] });
				end
			end
			local filters = g_AdFilters;
			if not GuildAdsTrade.getProfileValue(nil, "Filters") then
				GuildAdsTrade.setProfileValue("Filters", "everything", true);
			end
	
			local index = 1;
			FilterNames = GUILDADS_ITEMS;
			for k,instance in GuildAdsTrade.GuildAds_ItemFilterOrder do
				local info = { };
				info.text = GUILDADS_ITEMS[instance];
				if (FilterNames[instance]) then
					info.value = filters[index].id;
					if GuildAdsTrade.getProfileValue("Filters", filters[index].id) then
						info.checked = 1;--:SetChecked(1);
					else
						info.checked = nil;
					end
					info.textR = GuildAdsTrade.filter_color[filters[index].id]["r"];
					info.textG = GuildAdsTrade.filter_color[filters[index].id]["g"];
					info.textB = GuildAdsTrade.filter_color[filters[index].id]["b"];
					info.keepShownOnClick = 1;
					info.func = GuildAdsTrade.ItemFilter.onClick;
					UIDropDownMenu_AddButton(info);
					index = index + 1;
				end 
			end
		end;
		
		onClick = function()
			if ( UIDropDownMenuButton_GetChecked() ) then	
				PlaySound("igMainMenuOptionCheckBoxOn");
			else
				PlaySound("igMainMenuOptionCheckBoxOff");
			end
		
			if GuildAdsTrade.getProfileValue("Filters", this.value) then
				GuildAdsTrade.setProfileValue("Filters", this.value, nil)
			else
				GuildAdsTrade.setProfileValue("Filters", this.value, true)
			end
		
			GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentTab,true);
		end;
	
	};
	
	exchangeButtonsUpdateScroll = function()
		GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentTab, false);
	end;
	
	exchangeButtonsUpdate = function(tab, updateData)
		if (tab == GuildAdsTrade.currentTab) then
			local adType = GuildAdsTrade.TabToAdType[tab];
			local offset = FauxScrollFrame_GetOffset(GuildAdsGlobalAdScrollFrame);
			local linear = GuildAdsTrade.data.get(tab,updateData);
			local linearSize = table.getn(linear);
			
			-- init
			local i = 1;    -- TODO : replacer while (i<= ...)  par un "for"
			local j = i + offset;
		
			-- for each buttons   
			while (i <= GuildAdsTrade.GUILDADS_NUM_GLOBAL_AD_BUTTONS) do
				local button = getglobal("GuildAdsGlobalAdButton"..i);
			
				if (j <= linearSize) then
					-- update internal data
					button.adType = adType;
					button.item = linear[j].i;
					button.playerName = linear[j].p;
					button.data = linear[j].d;
					-- update button
					local selected = 	(GuildAdsTrade.currentPlayerName == button.playerName) 
									and (GuildAdsTrade.currentItem == button.item)
									and (GuildAdsTrade.currentAdType == adType);
					GuildAdsTrade.exchangeButton.update(button, selected, linear[j].i, linear[j].p, linear[j].d);
					button:Show();
					j = j+1;
				else
					button.adType = nil;
					button.item = nil;
					button.playerName = nil;
					button.data = nil;
					button:Hide();
				end
			
				i = i+1;
			end
	
			FauxScrollFrame_Update(GuildAdsGlobalAdScrollFrame, linearSize, GuildAdsTrade.GUILDADS_NUM_GLOBAL_AD_BUTTONS, GuildAdsTrade.GUILDADS_ADBUTTONSIZEY);
		else
			-- update another tab than the visible one
			if updateData then
				-- but data needs to be reseted
				GuildAdsTrade.data.resetCache(tab);
			end
		end
	end;
	
	selectTab = function(tab)
		GuildAdsTrade.debug("selectTab("..tostring(tab)..")");
		
		GuildAdsTrade.currentTab = tab;	
		
		if (tab == GuildAdsTrade.TAB_REQUEST) then
			GuildAdsTrade.debug("request");
			PanelTemplates_SelectTab(GuildAds_MyTab1);
			PanelTemplates_DeselectTab(GuildAds_MyTab2);
			PanelTemplates_DeselectTab(GuildAds_MyTab3);
		
			GuildListAdMyAdsFrame:Hide();
			GuildListAdExchangeListFrame:Show();
			GuildAdsTradeFilterFrame:Show();
			if (ReagentData) then
				getglobal("GuildAds_Filter_ZoneDropDown"):Show();
			else 
				getglobal("GuildAds_Filter_ZoneDropDown"):Hide();
			end
			
			GuildAdsTrade.exchangeButtonsUpdate(tab,true);

		elseif (tab == GuildAdsTrade.TAB_AVAILABLE) then 
			GuildAdsTrade.debug("available");
			PanelTemplates_SelectTab(GuildAds_MyTab2);
			PanelTemplates_DeselectTab(GuildAds_MyTab1);
			PanelTemplates_DeselectTab(GuildAds_MyTab3);

			GuildListAdMyAdsFrame:Hide();
			GuildListAdExchangeListFrame:Show();
			GuildAdsTradeFilterFrame:Show();
			if (ReagentData) then
				getglobal("GuildAds_Filter_ZoneDropDown"):Show();
			else 
				getglobal("GuildAds_Filter_ZoneDropDown"):Hide();
			end
			
			GuildAdsTrade.exchangeButtonsUpdate(tab,true);

		elseif (tab == GuildAdsTrade.TAB_MY_ADS) then
			GuildAdsTrade.debug("my");
			PanelTemplates_SelectTab(GuildAds_MyTab3);
			PanelTemplates_DeselectTab(GuildAds_MyTab1);
			PanelTemplates_DeselectTab(GuildAds_MyTab2);
			
			GuildListAdExchangeListFrame:Hide();
			GuildAdsTradeFilterFrame:Hide();
			getglobal("GuildAds_Filter_ZoneDropDown"):Hide();
			GuildListAdMyAdsFrame:Show();
			
			GuildAdsTrade.myAds.updateMyAdsFrame();
			
		end
	end;
	
	searchText = "";
	
	setSearch = function(text) 
		GuildAdsTrade.searchText = text;
		GuildAdsTrade.data.resetCache();
		GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentAdType,true);
	end;
	
	select = function(adType, playerName, item, count)
		-- choose best adtype if not defined
		if adType == nil then
			local channelDB = GuildAdsDB.channel[GuildAds.channelName];
			if channelDB.TradeOffer:get(GuildAds.playerName, item) then
				adType = GUILDADS_MSG_TYPE_AVAILABLE;
			elseif channelDB.TradeNeed:get(GuildAds.playerName, item) then
				adType = GUILDADS_MSG_TYPE_REQUEST;
			end
		end
		
		GuildAdsTrade.debug("select("..tostring(adType)..","..tostring(playerName)..","..tostring(item)..","..tostring(count)..")");
		
		-- set selection
		GuildAdsTrade.currentPlayerName = playerName;
		GuildAdsTrade.currentItem = item;
		GuildAdsTrade.currentAdType = adType;
		
		-- update edit item
		GuildAdsTrade.edit(adType, playerName, item, count);
		
		-- update tab
		if GuildAdsTradeFrame and GuildAdsTradeFrame.IsVisible and GuildAdsTradeFrame:IsVisible() then
			if GuildAdsTrade.currentTab==GuildAdsTrade.TAB_MY_ADS then
				GuildAdsTrade.myAds.updateMyAdsFrame();
			elseif GuildAdsTrade.currentTab==GuildAdsTrade.TAB_REQUEST or GuildAdsTrade.currentTab==GuildAdsTrade.TAB_AVAILABLE then
				GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentTab);
			end;
		end;
	end;
	
	edit = function(adType, playerName, item, count)
		local datatype;
		local info = GuildAds_ItemInfo[item];
		if adType == GUILDADS_MSG_TYPE_AVAILABLE then
			datatype = GuildAdsDB.channel[GuildAds.channelName].TradeOffer;
		elseif adType == GUILDADS_MSG_TYPE_REQUEST then
			datatype = GuildAdsDB.channel[GuildAds.channelName].TradeNeed;
		end
		local data;
		if datatype then
			data = datatype:get(GuildAds.playerName, item);
		end
		if data then
			-- existing information
			GuildAdsTradeHighlight:Show();
			if adType == GUILDADS_MSG_TYPE_AVAILABLE then
				GuildAdsAddButtonLookFor:Disable();
				GuildAdsAddButtonAvailable:Enable();
			else
				GuildAdsAddButtonLookFor:Enable();
				GuildAdsAddButtonAvailable:Disable();			
			end
			GuildAdsRemoveButton:Enable();
		else
			-- no information : new ad.
			GuildAdsTradeHighlight:Hide();
			GuildAdsAddButtonLookFor:Enable();
			GuildAdsAddButtonAvailable:Enable();
			GuildAdsRemoveButton:Disable();
			data = {};
		end
		
		if count or data.c then
			count = (count or 0) + (data.q or 0);
		else
			count = data.q or count or "";
		end
		
		GuildAdsTrade.setEditItem(item, count, data.c or "", data~=nil);
	end;
	
	setEditItem = function(item, count, text)
		if text then
			GuildAdsEditBox:SetText(text);
		end
		if count then
			GuildAdsEditCount:SetText(count);
		end
		
		if item then
			local info = GuildAds_ItemInfo[item];
			if info then
				GuildAdsEditTexture:SetNormalTexture(info.texture);
				local _, _, _, hex = GetItemQualityColor(info.quality or 1)
				GuildAdsEditTextureName:SetText(hex..info.name.."|r");
			else
				GuildAdsEditTexture:SetNormalTexture("");
				GuildAdsEditTextureName:SetText(item);
			end
		end
	end;
	
	updateCurrentTab = function()
		GuildAdsTrade.debug("onItemInfoReady");
		if (GuildAdsTrade.currentTab == GuildAdsTrade.TAB_REQUEST or 
			GuildAdsTrade.currentTab == GuildAdsTrade.TAB_AVAILABLE) then
			GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentTab);
		else 
			GuildAdsTrade.myAds.updateMyAdsFrame();
			GuildAdsTrade.setEditItem(GuildAdsTrade.currentItem);
		end;
	end;
	
	myButton = {
	
		onClick = function(button)
			GuildAdsTrade.select(this.adType, this.playerName, this.item);
			
			if button == "RightButton" then
				GuildAdsTrade.contextMenu.show();
			end
			if this.item and button=="LeftButton" and IsControlKeyDown() then 
				DressUpItemLink(this.item); 
			end
		end;
		
		onEnter = function(obj)
			GuildAdsTrade.exchangeButton.onEnter(obj);
		end
	
	};
	
	exchangeButton = {
	
		onClick = function(button)
			GuildAdsTrade.select(this.adType, this.playerName, this.item);
			
			if button == "RightButton" then
				GuildAdsTrade.contextMenu.show();
			end
			if this.item and button=="LeftButton" and IsControlKeyDown() then 
				DressUpItemLink(this.item); 
			end
		end;
		
		update = function(button, selected, item, playerName, data)
			local buttonName= button:GetName();
		
			local titleField = buttonName.."Title";
			local ownerField = buttonName.."Owner";
			local dropField = buttonName.."Drop";
			local useField = buttonName.."Use";
			local textField = buttonName.."Text";
			local countField = buttonName.."Count";
			local sinceField =  buttonName.."Since";
			local ownerColor = GuildAdsUITools.onlineColor[GuildAdsComm:IsOnLine(playerName)];
			
			local texture = buttonName.."ItemIconTexture";
			if (GuildAdsTrade.administrator) then
				getglobal(buttonName.."CheckButton"):Show();
			end
				
			-- selected ?
			if selected then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			
			-- online/offline highlight
			getglobal(ownerField):SetText(playerName);
			getglobal(ownerField):SetTextColor(ownerColor.r, ownerColor.g, ownerColor.b);
			getglobal(ownerField):Show();
			getglobal(buttonName.."Highlight"):SetVertexColor(ownerColor.r, ownerColor.g, ownerColor.b);
			
			--
			local info = GuildAds_ItemInfo[item] or {};
			
			-- texture
			if (info.texture) then 
				getglobal(texture):SetTexture(info.texture);
			else
				getglobal(texture):SetTexture("");
			end;
			
			-- name with color
			if info.name then
				getglobal(textField):Show();
				if info.quality then
					local _, _, _, hex = GetItemQualityColor(info.quality)
					getglobal(textField):SetText(hex..info.name.."|r");
				else
					getglobal(textField):SetText(info.name);
				end
			else
				--[[
				if ad.text then
					getglobal(textField):Show();
					getglobal(textField):SetText(info.name);
				else
					getglobal(textField):Hide();
				end
				]]
			end
				
			-- quantity
			if (data.q) then 
				getglobal(countField):Show();
				getglobal(countField):SetText(data.q);
			else
				getglobal(countField):Hide();
			end;
				
			-- creationtime
			if data._t then
				getglobal(sinceField):Show();
				getglobal(sinceField):SetTextColor(ownerColor["r"], ownerColor["g"], ownerColor["b"]);
				getglobal(sinceField):SetText(GuildAdsDB:FormatTime(data._t));
			else
				getglobal(sinceField):Hide();
			end
				
			-- Drop/Use
			if info.name and ReagentData then
				-- Drop
				getglobal(dropField):Show();
				getglobal(dropField):SetText("D");
				if (ReagentData_IsVendorItem(info.name)) then 
					getglobal(dropField):SetTextColor(GuildAdsTrade.filter_color["vendor"]["r"],GuildAdsTrade.filter_color["vendor"]["g"], GuildAdsTrade.filter_color["vendor"]["b"]);
				elseif (ReagentData_IsMonsterDrop(info.name)) then 
					getglobal(dropField):SetTextColor(GuildAdsTrade.filter_color["monster"]["r"],GuildAdsTrade.filter_color["monster"]["g"], GuildAdsTrade.filter_color["monster"]["b"]);
				elseif (table.getn(ReagentData_GatheredBy(info.name)) > 0) then 
					getglobal(dropField):SetTextColor(GuildAdsTrade.filter_color["gather"]["r"],GuildAdsTrade.filter_color["gather"]["g"], GuildAdsTrade.filter_color["gather"]["b"]);
				else 
					getglobal(dropField):SetTextColor(GuildAdsTrade.filter_color["everything"]["r"],GuildAdsTrade.filter_color["everything"]["g"], GuildAdsTrade.filter_color["everything"]["b"]);
				end
				
				-- Use
				getglobal(useField):Show();
				getglobal(useField):SetText("U");
				if (table.getn(ReagentData_ClassSpellReagent(info.name)) >0 ) then 
					getglobal(useField):SetTextColor(GuildAdsTrade.filter_color["classReagent"]["r"],GuildAdsTrade.filter_color["classReagent"]["g"], GuildAdsTrade.filter_color["classReagent"]["b"]);
				elseif (table.getn(ReagentData_GetProfessions(info.name)) >0 ) then
					getglobal(useField):SetTextColor(GuildAdsTrade.filter_color["tradeReagent"]["r"],GuildAdsTrade.filter_color["tradeReagent"]["g"], GuildAdsTrade.filter_color["tradeReagent"]["b"]);
				else
					getglobal(useField):SetTextColor(GuildAdsTrade.filter_color["everything"]["r"],GuildAdsTrade.filter_color["everything"]["g"], GuildAdsTrade.filter_color["everything"]["b"]);		
				end
			else 
				getglobal(dropField):Hide();
				-- getglobal(dropField):SetText("D");
				-- getglobal(dropField):SetTextColor(filter_color["everything"]["r"],filter_color["everything"]["g"], filter_color["everything"]["b"]);
				
				getglobal(useField):Hide();
				-- getglobal(useField):SetText("U");
				-- getglobal(useField):SetTextColor(filter_color["everything"]["r"],filter_color["everything"]["g"], filter_color["everything"]["b"]);
			end
		end;	
		
		onEnter = function(obj) 
			obj = obj or this;
			
			local item = obj.item;
			local playerName = obj.playerName;
			local data = obj.data;
			
			-- set tooltip
			if item then
				GameTooltip:SetOwner(obj, "ANCHOR_BOTTOMRIGHT");
				if item then
					GameTooltip:SetHyperlink(item);
				end
				if data.c then
					GuildAdsUITools:TooltipAddText(GameTooltip, LABEL_NOTE..": "..data.c);
				end
				if data._t then
					GameTooltip:AddLine(string.format(GUILDADS_SINCE, GuildAdsDB:FormatTime(data._t)), GuildAdsUITools.noteColor.r, GuildAdsUITools.noteColor.g, GuildAdsUITools.noteColor.b);
				end
				GameTooltip:Show();
				local info = GuildAds_ItemInfo[item];
				if info then
					GuildAdsUITools:TooltipAddTT(GameTooltip, GetItemQualityColor(info.quality or 1), item, info.name, data.q or 1);
				end
			end
			
			-- update hightlight
			if playerName then
				local ownerColor = GuildAdsUITools.onlineColor[GuildAdsComm:IsOnLine(playerName)];
				getglobal(obj:GetName().."Highlight"):SetVertexColor(ownerColor.r, ownerColor.g, ownerColor.b);
			end
		end
	};
	
	itemFilterFunction = {
		everything = function(itemName)
			return true;
		end;
	
		everythingelse = function(itemName)
			if itemName then
				return not (
					   GuildAdsTrade.itemFilterFunction.monster(itemName)
					or GuildAdsTrade.itemFilterFunction.classReagent(itemName)
					or GuildAdsTrade.itemFilterFunction.tradeReagent(itemName)
					or GuildAdsTrade.itemFilterFunction.vendor(itemName)
					or GuildAdsTrade.itemFilterFunction.gather(itemName)
				);
			else
				return true;
			end
		end;
		
		monster = function(itemName)
			if itemName then
				return ReagentData_IsMonsterDrop(itemName);
			else
				return false;
			end
		end;
		
		classReagent = function (itemName)
			if itemName then
				return table.getn(ReagentData_ClassSpellReagent(itemName))>0;
			else
				return false;
			end
		end;
		
		tradeReagent = function(itemName)
			if itemName then
				return table.getn(ReagentData_GetProfessions(itemName))>0;
			else
				return false;
			end
		end;
		
		vendor = function(itemName)
			if itemName then
				return ReagentData_IsVendorItem(itemName);
			else
				return false;
			end
		end;
		
		gather = function(itemName)
			if itemName then
				return table.getn(ReagentData_GatheredBy(itemName)) > 0;
			else
				return false;
			end
		end;
	};
	
	data = {
		cache = {};
		
		resetCache = function(adtype)
			if adtype then
				GuildAdsTrade.data.cache[adtype] = nil;
			else
				GuildAdsTrade.data.cache = {};
			end
		end;
		
		adIsVisible = function(adtype, author, item, data)
			-- show offline player
			if GuildAdsTrade.getProfileValue(nil, "HideOfflinePlayer") and not GuildAdsComm:IsOnLine(author) then
				return false;
			end
			
			-- show my ads
			if GuildAdsTrade.getProfileValue(nil, "HideMyAds") and (GuildAds.playerName == author) then
				return false;
			end
			
			-- get item info
			local info = GuildAds_ItemInfo[item] or {};
			
			-- AH filter
			if (GuildAdsTrade.searchText ~= "" ) then
				if info.name then
					if (string.find(string.upper(info.name), string.upper(GuildAdsTrade.searchText)) == nil) then
						return false;
					end
				end
			end
				
			local dateFilter = GuildAdsTrade.getProfileValue(nil, "HideAdsOlderThan", nil);
			if dateFilter and data._t then
				local currentDelta = GuildAdsDB:GetCurrentTime()-data._t;
				-- Hack to avoid wrong display. Obviously there is a bug in offline/online sync about time.
				if currentDelta<0 then
					return false;
				end
				if currentDelta>dateFilter then
					return false;
				end
			end
			
			if GuildAdsTrade.filterClass.selectedClass and info.type == nil then
				return false;
			end
			
			if GuildAdsTrade.filterClass.selectedClass and info.type ~= GuildAdsTrade.filterClass.selectedClass then
				return false;
			end
				
			if GuildAdsTrade.filterClass.selectedSubclass and HIGHLIGHT_FONT_COLOR_CODE..info.subtype..FONT_COLOR_CODE_CLOSE ~= GuildAdsTrade.filterClass.selectedSubclass then
				return false;
			end
					
			-- TODO : bug here
			if GuildAdsTrade.filterClass.selectedInvtype then
				GuildAdsTrade.debug("slot="..tostring(HIGHLIGHT_FONT_COLOR_CODE..info.slot..FONT_COLOR_CODE_CLOSE).."//"..tostring(GuildAdsTrade.filterClass.selectedInvtype));
				if HIGHLIGHT_FONT_COLOR_CODE..info.slot..FONT_COLOR_CODE_CLOSE ~= GuildAdsTrade.filterClass.selectedInvtype then
					return false;
				end
			end
			
			if ReagentData then
				-- ReagentData filter
				local filters = GuildAdsTrade.getProfileValue(nil, "Filters", {});
				for id, name in filters do
					filterFunction =  GuildAdsTrade.itemFilterFunction[id];
					if filterFunction and filterFunction(info.name) then
						return true;
					end
				end
				return false;
			else
				return true;
			end
		end;
	
		get = function(tab, updateData)
			if not GuildAdsTrade.data.cache[tab] or updateData then
				local datatype;
				local adtype = GuildAdsTrade.TabToAdType[tab];
				if tab == GuildAdsTrade.TAB_REQUEST then
					datatype = GuildAdsDB.channel[GuildAds.channelName].TradeNeed;
				elseif tab == GuildAdsTrade.TAB_AVAILABLE then
					datatype = GuildAdsDB.channel[GuildAds.channelName].TradeOffer;
				else
					error("bad tab for GuildAdsTrade.data.get("..tostring(tab)..")", 3);
				end
				GuildAdsTrade.data.cache[tab] = {};
				for _, item, playerName, data in datatype:iterator() do
					if GuildAdsTrade.data.adIsVisible(adtype, playerName, item, data) then
						tinsert(GuildAdsTrade.data.cache[tab], { i=item, p=playerName, d=data, t=adtype });
					end
				end
				GuildAdsTrade.sortData.doIt(GuildAdsTrade.data.cache[adtype]);
			end
			
			return GuildAdsTrade.data.cache[tab];
		end;
		
	};
	
	
	sortData = {
			
		current = "item";
	
		currentWay = {
			item = "up",
			count = "normal",
			drop = "up",
			use = "up",
			owner="normal",
			since="normal"
		};
		
		
		doIt = function(adTable)
 			table.sort(adTable, GuildAdsTrade.sortData.predicate);
		end;
		
		predicateFunctions = {
		
			item = function(a, b)
				local an=(GuildAds_ItemInfo[a.i] or {}).name or "";
				local bn=(GuildAds_ItemInfo[b.i] or {}).name or "";
				if (an < bn) then
					return false;
				elseif (an > bn) then
					return true;
				end
				return nil;
			end;
		
			count = function(a, b)
				local ac = a.d.q or 0;
				local bc = b.d.q or 0;
				
				if (ac < bc) then
					return false;
				elseif (ac > bc) then
					return true;
				end
				return nil;
			end;
			
			drop = function(a,b) 
				return nil;
			end;
			
			use = function(a,b) 
				return nil;
			end;
			
			owner = function(a, b)
				if a.p and b.p then
					if (a.p < b.p) then
						return false;
					elseif (a.p > b.p) then
						return true;
					end
				end
				return nil;
			end;
		
			since = function(a, b)
				if a.d._t and b.d._t then
					if (a.d._t < b.d._t ) then
						return false;
					elseif (a.d._t > b.d._t ) then
						return true;
					end
				end
				return nil;
			end;
		
		};
		
		wayFunctions = {
		
			normal = function(value)
				return value;
			end;
			
			up = function(value)
				if value==nil then
					return value;
				else
					return not value;
				end;
			end;
			
		};
	
		predicate = function(a, b)
			-- nil references are always less than
			local result = GuildAdsTrade.sortData.byNilAA(a, b);
			if result~=nil then
				return result;
			end
			
			result = GuildAdsTrade.sortData.predicateFunctions[GuildAdsTrade.sortData.current](a, b);
			result = GuildAdsTrade.sortData.wayFunctions[GuildAdsTrade.sortData.currentWay[GuildAdsTrade.sortData.current]](result);
			
			if result ~= nil then
				return result;
			else
				return false;
			end
		end;
		
		byNilAA = function(a, b)
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
			return nil;
		end;
		
	};
	
	filterClass = {
		NUM_BROWSE_TO_DISPLAY = 9;
		NUM_FILTERS_TO_DISPLAY = 15;
		MAXACTIONITEM = 1;
		BROWSE_FILTER_HEIGHT = 20;
		
		onClick = function()
			if ( this.type == "class" ) then
				if ( GuildAdsTrade.filterClass.selectedClass == this:GetText() ) then
					GuildAdsTrade.filterClass.selectedClass = nil;
					GuildAdsTrade.filterClass.selectedClassIndex = nil;
				else
					GuildAdsTrade.filterClass.selectedClass = this:GetText();
					GuildAdsTrade.filterClass.selectedClassIndex = this.index;
				end
				GuildAdsTrade.filterClass.selectedSubclass = nil;
				GuildAdsTrade.filterClass.selectedSubclassIndex = nil;
				GuildAdsTrade.filterClass.selectedInvtype = nil;
				GuildAdsTrade.filterClass.selectedInvtypeIndex = nil;
			elseif ( this.type == "guildadsclass" ) then
				if ( GuildAdsTrade.filterClass.selectedClass == this:GetText() ) then
					GuildAdsTrade.filterClass.selectedClass = nil;
					GuildAdsTrade.filterClass.selectedClassIndex = nil;
				else
					GuildAdsTrade.filterClass.selectedClass = this:GetText();
					GuildAdsTrade.filterClass.selectedClassIndex = this.index;
				end
				GuildAdsTrade.filterClass.selectedSubclass = nil;
				GuildAdsTrade.filterClass.selectedSubclassIndex = nil;
				GuildAdsTrade.filterClass.selectedInvtype = nil;
				GuildAdsTrade.filterClass.selectedInvtypeIndex = nil;
			elseif ( this.type == "subclass" ) then
				if ( GuildAdsTrade.filterClass.selectedSubclass == this:GetText() ) then
					GuildAdsTrade.filterClass.selectedSubclass = nil;
					GuildAdsTrade.filterClass.selectedSubclassIndex = nil;
				else
					GuildAdsTrade.filterClass.selectedSubclass = this:GetText();
					GuildAdsTrade.filterClass.selectedSubclassIndex = this.index;
				end
				GuildAdsTrade.filterClass.selectedInvtype = nil;
				GuildAdsTrade.filterClass.selectedInvtypeIndex = nil;
				
			elseif ( this.type == "invtype" ) then
				GuildAdsTrade.filterClass.selectedInvtype = this:GetText();
				GuildAdsTrade.filterClass.selectedInvtypeIndex = this.index;
			end
			GuildAdsTrade.filterClass.filterUpdate();
			GuildAdsTrade.data.resetCache();
			GuildAdsTrade.exchangeButtonsUpdate(GuildAdsTrade.currentAdType);
		end;
		
		init = function()
			GuildAdsTrade.filterClass.GA_CLASS_FILTERS = { GetAuctionItemClasses() };
			table.insert(GuildAdsTrade.filterClass.GA_CLASS_FILTERS, LABEL_NOTE);
			GuildAdsTrade.filterClass.filterUpdateClasses();
		end;
	
		filterUpdate = function() 
			GuildAdsTrade.filterClass.filterUpdateClasses();
			-- Update scrollFrame
			FauxScrollFrame_Update(BrowseFilterTradeScrollFrame, getn(GuildAdsTrade.filterClass.OPEN_FILTER_LIST), GuildAdsTrade.filterClass.NUM_FILTERS_TO_DISPLAY, GuildAdsTrade.filterClass.BROWSE_FILTER_HEIGHT);
		end;
	
		filterUpdateSubClasses = function(...) 
			local subClass;
			for i=1, arg.n do
				subClass = HIGHLIGHT_FONT_COLOR_CODE..arg[i]..FONT_COLOR_CODE_CLOSE; 
				if ( GuildAdsTrade.filterClass.selectedSubclass and GuildAdsTrade.filterClass.selectedSubclass == subClass ) then
					tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {arg[i], "subclass", i, 1});
					-- GuildAdsTrade.filterClass.selectedClassIndex-1 : -1 because the first class is "All"
					GuildAdsTrade.filterClass.filterUpdateInvTypes(GetAuctionInvTypes(GuildAdsTrade.filterClass.selectedClassIndex,i));
				else
					tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {arg[i], "subclass", i, nil});
				end
			end
		end;
		
		filterUpdateInvTypes = function(...)
			local invType, isLast;
			for i=1, arg.n do
			invType = HIGHLIGHT_FONT_COLOR_CODE..TEXT(getglobal(arg[i]))..FONT_COLOR_CODE_CLOSE; 
				if ( i == arg.n ) then
					isLast = 1;
				end
				if ( GuildAdsTrade.filterClass.selectedInvtypeIndex and GuildAdsTrade.filterClass.selectedInvtypeIndex == i ) then
					tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {invType, "invtype", i, 1, isLast});
				else
					tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {invType, "invtype", i, nil, isLast});
				end
			end
		end;
		
		
		filterButtonSetType = function(button, type, text, isLast)
			local normalText = getglobal(button:GetName().."NormalText");
			local highlightText = getglobal(button:GetName().."HighlightText");
			local normalTexture = getglobal(button:GetName().."NormalTexture");
			local line = getglobal(button:GetName().."Lines");
			if ( type == "guildadsmetaclass" ) then
				button:SetText(text);
				normalText:SetPoint("LEFT", button:GetName(), "LEFT", 4, 0);
				highlightText:SetPoint("LEFT", button:GetName(), "LEFT", 4, 0);
				normalTexture:SetAlpha(1.0);	
				line:Hide();
			elseif ( type == "class" or type =="guildadsclass" ) then
				button:SetText(text);
				normalText:SetPoint("LEFT", button:GetName(), "LEFT", 12, 0);
				highlightText:SetPoint("LEFT", button:GetName(), "LEFT", 12, 0);
				normalTexture:SetAlpha(1.0);	
				line:Hide();
			elseif ( type == "subclass" ) then
				button:SetText(HIGHLIGHT_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE);
				normalText:SetPoint("LEFT", button:GetName(), "LEFT", 20, 0);
				highlightText:SetPoint("LEFT", button:GetName(), "LEFT", 20, 0);
				normalTexture:SetAlpha(0.8);
				line:Hide();
			elseif ( type == "invtype" ) then
				button:SetText(HIGHLIGHT_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE);
				normalText:SetPoint("LEFT", button:GetName(), "LEFT", 28, 0);
				highlightText:SetPoint("LEFT", button:GetName(), "LEFT", 28, 0);
				normalTexture:SetAlpha(0.8);	
				if ( isLast ) then
					line:SetTexCoord(0.4375, 0.875, 0, 0.625);
				else
					line:SetTexCoord(0, 0.4375, 0, 0.625);
				end
				line:Show();
			end
			button.type = type; 
		end;
		
		filterUpdateClasses = function()
			-- Initialize the list of open filters
			GuildAdsTrade.filterClass.OPEN_FILTER_LIST = {};
			--tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {"Tout", "guildadsmetaclass", 1, ni1});
			index = 1;
			for i=1, getn(GuildAdsTrade.filterClass.GA_CLASS_FILTERS)-GuildAdsTrade.filterClass.MAXACTIONITEM do
				if ( GuildAdsTrade.filterClass.selectedClass and GuildAdsTrade.filterClass.selectedClass == GuildAdsTrade.filterClass.GA_CLASS_FILTERS[i] ) then
					tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {GuildAdsTrade.filterClass.GA_CLASS_FILTERS[i], "class", i, 1});
					GuildAdsTrade.filterClass.filterUpdateSubClasses(GetAuctionItemSubClasses(i));
				else
					tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {GuildAdsTrade.filterClass.GA_CLASS_FILTERS[i], "class", i, nil});
				end
				index = i;
			end
			if ( GuildAdsTrade.filterClass.selectedClass and GuildAdsTrade.filterClass.selectedClass == LABEL_NOTE) then
			tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {LABEL_NOTE, "guildadsclass", index+1, 1});
			
			else
			tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {LABEL_NOTE, "guildadsclass", index+1, nil});
			
			end
 			--for i=1, GuildAdsTrade.filterClass.MAXACTIONITEM  do 
			--	tinsert(GuildAdsTrade.filterClass.OPEN_FILTER_LIST, {GuildAdsTrade.filterClass.GA_CLASS_FILTERS[getn(GuildAdsTrade.filterClass.GA_CLASS_FILTERS)+i], "class", getn(GuildAdsTrade.filterClass.GA_CLASS_FILTERS)+i, nil});
			--end;
			-- Display the list of open filters
			local button, index, info, isLast;
			local offset = FauxScrollFrame_GetOffset(BrowseFilterTradeScrollFrame);
			for i=1, GuildAdsTrade.filterClass.NUM_FILTERS_TO_DISPLAY do
				button = getglobal("FilterTradeButton"..i);
				button:SetWidth(156);
				index = offset + i;
				if ( index <= getn(GuildAdsTrade.filterClass.OPEN_FILTER_LIST) ) then
					info = GuildAdsTrade.filterClass.OPEN_FILTER_LIST[index];
					GuildAdsTrade.filterClass.filterButtonSetType(button, info[2], info[1], info[5]);
					button.index = info[3];
					if ( info[4] ) then
						button:LockHighlight();
					else
						button:UnlockHighlight();
					end
					button:Show();
				else
					button:Hide();
				end
			end
		end
	};
	
	
	contextMenu = {
	
		onLoad = function()
			HideDropDownMenu(1);
			GuildAdsTradeContextMenu.initialize = GuildAdsTrade.contextMenu.initialize;
			GuildAdsTradeContextMenu.displayMode = "MENU";
			GuildAdsTradeContextMenu.name = "Titre";			
		end;
	
		show = function(owner)
			HideDropDownMenu(1);
			ToggleDropDownMenu(1, nil, GuildAdsTradeContextMenu, "cursor");			
		end;
		
		initialize = function()
			info = { };
			info.text =  GuildAdsTrade.currentPlayerName;
			info.isTitle = true;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, 1);
		end
	};
	
	
	
	-------------------
	-------------------
	------------------- MYADS
	
	myAds = {
	
	GUILDADS_NUM_MY_AD_BUTTONS = 16;
	cache = {};
	
	
	updateMyAdsFrame = function(updateData)
		table.setn(GuildAdsTrade.myAds.cache, 0);
		for item, author, data in GuildAdsDB.channel[GuildAds.channelName].TradeNeed:iterator(GuildAds.playerName) do
			table.insert(GuildAdsTrade.myAds.cache, {t=GUILDADS_MSG_TYPE_REQUEST, i=item, d=data});
		end
		for item, author, data in GuildAdsDB.channel[GuildAds.channelName].TradeOffer:iterator(GuildAds.playerName) do
			table.insert(GuildAdsTrade.myAds.cache, {t=GUILDADS_MSG_TYPE_AVAILABLE, i=item, d=data});
		end
		
		local offset = FauxScrollFrame_GetOffset(GuildAdsMyAdScrollFrame);
		local j;
		
		local button, checkButton, whatField, quantityField, commentField, sinceField, itemiconField, info;
		local onlineColor = GuildAdsUITools.onlineColor[true];
		
		-- for each line in "my ads" tab
		for i=1,GuildAdsTrade.myAds.GUILDADS_NUM_MY_AD_BUTTONS,1 do
			j = offset + i;
			
			-- Get the button on this row and set the index
			button = getglobal("GuildAdsMyAdButton"..i);
			checkButton = getglobal("GuildAdsMyAdButton"..i.."CheckButton");
			whatField = getglobal("GuildAdsMyAdButton"..i.."WhatIconTexture");
			quantityField = getglobal("GuildAdsMyAdButton"..i.."Quantity");
			commentField = getglobal("GuildAdsMyAdButton"..i.."Comment");
			sinceField = getglobal("GuildAdsMyAdButton"..i.."Since");
			itemiconField = getglobal("GuildAdsMyAdButton"..i.."ItemIconTexture");
			
			-- Is there a valid ad on this row?
			if j<=table.getn(GuildAdsTrade.myAds.cache) then
				button.adType = GuildAdsTrade.myAds.cache[j].t;
				button.playerName = GuildAds.playerName;
				button.item = GuildAdsTrade.myAds.cache[j].i;
				button.data = GuildAdsTrade.myAds.cache[j].d;
				checkButton.adType = GuildAdsTrade.myAds.cache[j].t;
				checkButton.playerName = GuildAds.playerName;
				checkButton.item = GuildAdsTrade.myAds.cache[j].i;
				checkButton.data = GuildAdsTrade.myAds.cache[j].d;
				
				-- Check the check box if appropriate
				if (button.data._h) then
					checkButton:SetChecked(0);
				else
					checkButton:SetChecked(1);
				end
				checkButton:Show();
					
				-- Update the need/offer button
				local textField = "GuildAdsMyAdButton"..i.."Text";
				if (button.adType == GUILDADS_MSG_TYPE_AVAILABLE) then 
					whatField:SetTexture("Interface\\AddOns\\GuildAds\\ui\\trade\\have");
				else
					whatField:SetTexture("Interface\\AddOns\\GuildAds\\ui\\trade\\ask");
				end
				
				-- Get item information
				info = GuildAds_ItemInfo[button.item] or {};
					
				-- Set name
				if (info.name) then
					local _, _, _, hex = GetItemQualityColor(info.quality or 1)
					getglobal(textField):SetText(hex..info.name.."|r");
				else
					getglobal(textField):SetText(button.item);
				end
				
				-- Set texture
				itemiconField:SetTexture(info.texture or "");				
				
				-- Set quantity, comment since field
				quantityField:SetText(button.data.q or "");				
				commentField:SetText(button.data.c or "");
				sinceField:SetText(GuildAdsDB:FormatTime(button.data._t) or "xxx");
				
				-- Highlight selected ad
				if (button.item == GuildAdsTrade.currentItem and button.adType == GuildAdsTrade.currentAdType) then
					button:LockHighlight();
					checkButton:LockHighlight();
				else
					button:UnlockHighlight();
					checkButton:UnlockHighlight();
				end
				
				-- Set hightlight color when mouse over this ad
				getglobal("GuildAdsMyAdButton"..i.."Highlight"):SetVertexColor(onlineColor.r, onlineColor.g, onlineColor.b);
				
				-- Show button
				button:Show();
			else
				-- Hide the button
				button.adType = nil;
				button.playerName = nil;
				button.item = nil;
				button.data = nil;
				checkButton.adType = nil;
				checkButton.playerName = nil;
				checkButton.item = nil;
				checkButton.data = nil;
		
				button:Hide();
				checkButton:Hide();
			end
		end
		
		-- Update the scroll bar
		FauxScrollFrame_Update(GuildAdsMyAdScrollFrame, table.getn(GuildAdsTrade.myAds.cache), GuildAdsTrade.myAds.GUILDADS_NUM_MY_AD_BUTTONS, GuildAdsTrade.GUILDADS_ADBUTTONSIZEY);
	end;

	----------------------------------------------------------------------------------
	--
	-- Add a new entry to MyAds
	-- 
	---------------------------------------------------------------------------------
	addButton_OnClick = function(adtype)
		GuildAdsTrade.debug("GuildAds_AddButton_OnClick("..tostring(request_type)..")");
		
		if not (GuildAdsTrade.currentItem and GuildAdsTrade.currentPlayerName) then
			GuildAdsTrade.debug("No item selected");
			return;
		end
		
		if GuildAdsTrade.currentAdType == nil then
			GuildAdsTrade.currentAdType = adtype;
		end;
		
		local datatype;
		local channelDB = GuildAdsDB.channel[GuildAds.channelName];
		if adtype == GUILDADS_MSG_TYPE_AVAILABLE then
			datatype = channelDB.TradeOffer;
		elseif adtype == GUILDADS_MSG_TYPE_REQUEST then
			datatype = channelDB.TradeNeed;
		end
		
		local count = GuildAdsEditCount:GetNumber();
		if (count == 0) then
			count = nil;
		end		
		
		local text = GuildAdsEditBox:GetText();
		if (text == "") then
			text = nil;
		end
		
		datatype:set(GuildAds.playerName, GuildAdsTrade.currentItem, {
			q = count;
			c = text;
			_t = GuildAdsDB:GetCurrentTime();
		});
	end;


	----------------------------------------------------------------------------------
	--
	-- Remove the currently selected MyAds
	-- 
	---------------------------------------------------------------------------------
	removeButton_OnClick =function()
		if not (GuildAdsTrade.currentItem and GuildAdsTrade.currentPlayerName and GuildAdsTrade.currentAdType) then
			GuildAdsTrade.debug("No item selected");
			return;
		end;
		
		local datatype;
		local channelDB = GuildAdsDB.channel[GuildAds.channelName];
		if GuildAdsTrade.currentAdType == GUILDADS_MSG_TYPE_AVAILABLE then
			datatype = channelDB.TradeOffer;
		elseif GuildAdsTrade.currentAdType == GUILDADS_MSG_TYPE_REQUEST then
			datatype = channelDB.TradeNeed;
		end
		
		-- delete current selection
		datatype:delete(GuildAds.playerName, GuildAdsTrade.currentItem);
		
		-- selection first ad in "my ads"
		local newSelection = GuildAdsTrade.myAds.cache[1];
		if newSelection then
			GuildAdsTrade.select(newSelection.t, GuildAds.playerName, newSelection.i);
		end;
	end;

	----------------------------------------------------------------------------------
	--
	-- Called when MyAds check button is clicked
	-- 
	---------------------------------------------------------------------------------
	myAdCheckButton_OnClick =function()
		local datatype;
		local channelDB = GuildAdsDB.channel[GuildAds.channelName];
		if adtype == GUILDADS_MSG_TYPE_AVAILABLE then
			datatype = channelDB.TradeOffer;
		elseif adtype == GUILDADS_MSG_TYPE_REQUEST then
			datatype = channelDB.TradeNeed;
		end
		
		local data = datatype:get(this.playerName, this.item);
		if this:GetChecked() then
			data._h = nil;
		else
			data._h = true;
		end;
		datatype:set(this.playerName, this.item, data);
	end;
	
	};
	
	
	};





---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsTrade);