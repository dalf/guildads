----------------------------------------------------------------------------------
--
-- GuildAdsGuildFrame.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local g_AdFilters = {};
FRIEND_OFFLINE_FILTER = string.format(ERR_FRIEND_OFFLINE_S, "(.*)");
FRIEND_ONLINE_FILTER = string.gsub(string.format(ERR_FRIEND_ONLINE_SS, "(.*)", "(.*)"), "([%[%]])", "%%%1");

GuildAdsGuild = {

	GUILDADS_NUM_GLOBAL_AD_BUTTONS = 27;
	GUILDADS_ADBUTTONSIZEY = 16;
	
	metaInformations = { 
		name = "Guild",
        guildadsCompatible = 100,
		ui = {
			main = {
				frame = "GuildAdsGuildFrame",
				tab = "GuildAdsGuildTab",
				tooltip = "Guild tab",
				priority = 4
			}
		}
	};
	
	onlineCache = {};
	accountOnlineCache = {};
	
	onConfigChanged = function(path, key, value)
		if key=="GroupByAccount" then
			GuildAdsGuild.peopleButtonsUpdate(true);
			GuildAdsGuild.peopleCountUpdate();
		elseif key=="HideOfflines" then
			GuildAdsGuild.peopleButtonsUpdate(true);
			GuildAdsGuild.peopleCountUpdate();
		end
	end;
	
	onLoad = function()
		this:RegisterEvent("CHAT_MSG_SYSTEM");
		this:RegisterEvent("GUILD_ROSTER_UPDATE");
	end;
	
	onConnection = function(playerName, status) 
		GuildAdsGuild.peopleButtonsUpdate(true);
		GuildAdsGuild.peopleCountUpdate();
		
		-- show connected status except for my guild
		local gowner = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Guild);
		if (playerName ~= GuildAds.playerName and (gowner == nil or gowner ~= GuildAds.guildName)) then
			local msg;
			if (status) then
				msg = string.format(ERR_FRIEND_ONLINE_SS, playerName, playerName);
			else
				msg = string.format(ERR_FRIEND_OFFLINE_S, playerName);
			end
			GuildAdsUITools:AddSystemMessage(msg);
		end		
	end;
	
	onEvent = function()
		if event=="CHAT_MSG_SYSTEM" then
			local _, _, playerName = string.find(arg1, FRIEND_OFFLINE_FILTER);
			if not playerName then
				_, _, playerName = string.find(arg1, FRIEND_ONLINE_FILTER);
			end
			if playerName and IsInGuild() then
				GuildAdsGuild.debug("connect/disconnect:"..playerName);
				GuildRoster();
			end
		elseif event=="GUILD_ROSTER_UPDATE" then
			GuildAdsGuild.delayedUpdate();			
		end
	end;
	
	onUpdate = function()
		if this.update then
			this.update = this.update - arg1;
			if this.update<=0 then
				this.update = nil;
				GuildAdsGuild.peopleButtonsUpdate(true);
				GuildAdsGuild.peopleCountUpdate();
			end;
		end;
	end;
	
	delayedUpdate = function()
		GuildAdsGuildFrame.update = 1;
	end;
	
	onDBUpdate = function(dataType, playerName, id)
		if id ~= GuildAdsMainDataType.CreationTime then
			GuildAdsGuild.debug("onDBUpdate("..playerName..","..id..")");
			GuildAdsGuild.delayedUpdate();
		end
	end;
	
	onPlayerListUpdate = function(channel, list, name)
		if list == channel.PLAYER then
			GuildAdsGuild.debug("add/delete player("..name..")");
			GuildAdsGuild.delayedUpdate();
		end
	end;
	
	onChannelJoin = function()
		GuildAdsDB.profile.Main:registerUpdate(GuildAdsGuild.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName]:registerEvent(GuildAdsGuild.onPlayerListUpdate);
		GuildAdsGuild.delayedUpdate();
	end;
	
	onChannelLeave = function()
		GuildAdsDB.profile.Main:unregisterUpdate(GuildAdsGuild.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName]:unregisterEvent(GuildAdsGuild.onPlayerListUpdate);
		GuildAdsGuild.delayedUpdate();
	end;
	
	onShow = function()
		GuildAdsGuild.peopleButtonsUpdate();
	end;
	
	sortGuildAdsRoster = function(sortValue)
		GuildAdsGuild.sortData.current = sortValue;
		if (GuildAdsGuild.sortData.currentWay[sortValue]=="normal") then 
			GuildAdsGuild.sortData.currentWay[sortValue]="up";
		else 
			GuildAdsGuild.sortData.currentWay[sortValue]="normal";
		end
		GuildAdsGuild.peopleButtonsUpdate(true);
	end;
	
	---------------------------------------------------------------------------------
	--
	-- Init
	--
	---------------------------------------------------------------------------------
	onInit = function()
		UIDropDownMenu_Initialize(GuildAds_Filter_ClassDropDown, GuildAdsGuild.classFilter.init);
		UIDropDownMenu_SetText(FILTER, GuildAds_Filter_ClassDropDown);
		UIDropDownMenu_SetWidth(100, GuildAds_Filter_ClassDropDown);
		
		if (GuildAdsGuild.getProfileValue(nil, "GroupByAccount")) then
			GuildAdsGroupByAccountCheckButton:SetChecked(1);
		else
			GuildAdsGroupByAccountCheckButton:SetChecked(0);
		end
		
		if (GuildAdsGuild.getProfileValue(nil, "HideOfflines")) then
			GuildAdsGuildShowOfflinesCheckButton:SetChecked(0);
		else
			GuildAdsGuildShowOfflinesCheckButton:SetChecked(1);
		end
		
		-- Init g_AdFilters
		g_AdFilters = {};
		for id, name in pairs(GUILDADS_CLASSES) do
			tinsert(g_AdFilters, { id=id, name=name});
		end
	end;
	
	---------------------------------------------------------------------------------
	--
	-- isOnline
	--
	---------------------------------------------------------------------------------		
	isOnline = function(playerName)
		return GuildAdsComm:IsOnLine(playerName) or GuildAdsGuild.onlineCache[playerName] or false;
	end;
	
	isAccountOnline = function(account)
		return GuildAdsGuild.accountOnlineCache[account] or false;
	end;

	---------------------------------------------------------------------------------
	--
	-- For others plugins
	--
	---------------------------------------------------------------------------------		
	selectPlayer = function(playerName)
		local linear = GuildAdsGuild.data.get();
		for id, info in pairs(linear) do
			if info==playerName then
				--
				GuildAdsGuild.currentPlayerName = info;
				GuildAdsGuild.currentRerollName = nil;
				--[[
				local offset = FauxScrollFrame_GetOffset(GuildAdsPeopleGlobalAdScrollFrame);
				if id<offset or id>(offset+GuildAdsGuild.GUILDADS_NUM_GLOBAL_AD_BUTTONS) then
					local offset = min(id, table.getn(linear)-GuildAdsGuild.GUILDADS_NUM_GLOBAL_AD_BUTTONS);
					GuildAdsGuild.debug("offset="..tostring(offset));
					GuildAdsPeopleGlobalAdScrollFrame:SetVerticalScroll(offset)
					GuildAdsPeopleGlobalAdScrollFrame:SetHorizontalScroll(offset)
				else
					GuildAdsGuild.peopleButtonsUpdate();
				end
				]]
				GuildAdsGuild.peopleButtonsUpdate();
				return true;
			end
		end
		GuildAdsGuild.currentPlayerName = 0;
		GuildAdsGuild.currentRerollName = nil;
		GuildAdsGuild.peopleButtonsUpdate();
		return false;
	end;

	---------------------------------------------------------------------------------
	--
	-- Update people count
	--
	---------------------------------------------------------------------------------	
	peopleCountUpdate = function()
		local linear  = GuildAdsGuild.data.get();
		local count = 0;
		local countOnline = 0;
		local account;
		if GuildAdsGuild.getProfileValue(nil, "GroupByAccount") then
			for _, playerName in pairs(linear) do
				if type(playerName)=="string" then
					count = count + 1;
					account = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account) or playerName;
					if GuildAdsGuild.isAccountOnline(account) then
						countOnline = countOnline+1;
					end
				end
			end
		else
			for _, playerName in pairs(linear) do
				if type(playerName)=="string" then
					count = count + 1;
					if GuildAdsGuild.isOnline(playerName) then
						countOnline = countOnline+1;
					end
				end
			end			
		end
		GuildAdsCountText:SetText(string.format(GetText("GUILD_TOTAL", nil, count),count));
		GuildAdsCountOnlineText:SetText(string.format(GUILD_TOTALONLINE, countOnline));
	end;
	
	---------------------------------------------------------------------------------
	--
	-- Update global ad buttons in the UI
	-- 
	---------------------------------------------------------------------------------
	peopleButtonsUpdate = function(updateData)
		if GuildAdsGuildFrame:IsVisible() then
			GuildAdsGuild.debug("peopleButtonsUpdate("..tostring(updateData)..")");
			local offset = FauxScrollFrame_GetOffset(GuildAdsPeopleGlobalAdScrollFrame);
		
			local linear = GuildAdsGuild.data.get(updateData);
			local linearSize = #linear;
			
			local linearAccount;
	
			-- init
			local i = 1;
			local j = i + offset;
			local k;
			local currentPlayer, currentAccount, mainPlayer;
			
			-- for each buttons
			while (i <= GuildAdsGuild.GUILDADS_NUM_GLOBAL_AD_BUTTONS) do
				local button = getglobal("GuildAdsPeopleGlobalAdButton"..i);
				
				-- update currentPlayer from linear or linearAccount
				currentPlayer = nil;
				if (linearAccount) then
					currentPlayer = linearAccount[k];
					k = k+1;
					if currentPlayer==GuildAdsGuild.currentPlayerName then
						currentPlayer = linearAccount[k];
						k = k+1;
					end
					if not currentPlayer  then
						linearAccount = nil;
						k = nil;
						mainPlayer = nil;
					end
				end
				if (not currentPlayer) then
					currentPlayer = linear[j];
					j = j +1;
				end
				
				-- update current button with currentPlayer
				if (currentPlayer ~= nil) then
					if type(currentPlayer) == "string" then
						-- update internal data
						button.owner = mainPlayer or currentPlayer;
						button.reroll = mainPlayer and currentPlayer or nil;
						
						-- create a ads
						currentSelection = GuildAdsGuild.currentRerollName or GuildAdsGuild.currentPlayerName;
						GuildAdsGuild.peopleButton.update(button, currentSelection==currentPlayer, linearAccount~=nil, currentPlayer);
						
						--
						if not linearAccount and GuildAdsGuild.currentPlayerName==currentPlayer then
							currentAccount = GuildAdsDB.profile.Main:get(currentPlayer, GuildAdsDB.profile.Main.Account)
							linearAccount = GuildAdsGuild.data.cacheByAccount[currentAccount]
							if linearAccount then
								mainPlayer = currentPlayer;
								k = 1
								linearSize = linearSize + #linearAccount;
							end
						end						
					else
						-- update internal data
						button.owner = nil;
						button.reroll = nil;

						-- create empty a line
						GuildAdsGuild.peopleButton.clear(button);
					end
					button:Show();
				else
					button.owner = nil;
					button.reroll= nil;
					button:Hide();
				end
			
				i = i+1;
			end
			FauxScrollFrame_Update(GuildAdsPeopleGlobalAdScrollFrame, linearSize, GuildAdsGuild.GUILDADS_NUM_GLOBAL_AD_BUTTONS, GuildAdsGuild.GUILDADS_ADBUTTONSIZEY);
		else
			-- update another tab than the visible one
			if updateData then
				-- but data needs to be reseted
				GuildAdsGuild.data.resetCache();
			end
		end
	end;
	
	
	---------------------------------------------------------------------------------
	--
	-- peopleButton
	--
	---------------------------------------------------------------------------------	
	peopleButton = {
		
		onClick = function()
			if this.owner then
				if IsControlKeyDown() and arg1=="LeftButton" and GuildAdsGuild.currentPlayerName then
					-- ctrl-click = group with an account
					local playerName = this.owner;
					local linkToPlayerName = GuildAdsGuild.currentPlayerName;
					if GuildAdsDB.profile.Main:getRevision(playerName)==0 then
						local account = GuildAdsDB.profile.Main:get(linkToPlayerName, GuildAdsDB.profile.Main.Account) or GuildAdsDB:CreateAccount();
						if GuildAdsDB.profile.Main:getRevision(linkToPlayerName)==0 then
							GuildAdsDB.profile.Main:setRaw(linkToPlayerName, GuildAdsDB.profile.Main.Account, account);
						end
						GuildAdsDB.profile.Main:setRaw(playerName, GuildAdsDB.profile.Main.Account, account);
					end
					GuildAdsGuild.peopleButtonsUpdate(true);
					GuildAdsGuild.peopleCountUpdate();
					
				elseif this.owner==GuildAdsGuild.currentPlayerName and this.reroll==GuildAdsGuild.currentRerollName and arg1~="RightButton" then
					-- same player was clicked = unselect
					GuildAdsGuild.currentPlayerName = nil;
					GuildAdsGuild.currentRerollName = nil;
					GuildAdsGuild.peopleButtonsUpdate();
				else
					-- another player was clicked = select
					GuildAdsGuild.currentPlayerName = this.owner;
					GuildAdsGuild.currentRerollName = this.reroll;
					GuildAdsGuild.peopleButtonsUpdate();
				end
				
				SetCursor(nil);
				
				if arg1 == "RightButton" then
					GuildAdsGuild.contextMenu.show(GuildAdsGuild.currentRerollName or GuildAdsGuild.currentPlayerName);
				end
			end
		end;
		
		onEnter = function(obj)
			obj = obj or this;
			local owner = obj.reroll or obj.owner;
			if (not owner) then
				return;
			end
			
			GameTooltip:SetOwner(obj, "ANCHOR_BOTTOMRIGHT");
			
			-- Add player name
			local ocolor = GuildAdsUITools.onlineColor[GuildAdsGuild.isOnline(owner)];
			if IsControlKeyDown() and GuildAdsGuild.currentPlayerName then
				GameTooltip:AddLine(string.format(GUILDADS_GUILD_GROUPWITHACCOUNT, owner, GuildAdsGuild.currentPlayerName), 1, 1, 1);
				GameTooltip:AddLine(owner, ocolor.r, ocolor.g, ocolor.b);
				SetCursor("CAST_CURSOR");
			else
				GameTooltip:AddLine(owner, ocolor.r, ocolor.g, ocolor.b);
				SetCursor(nil);
			end;
			
			-- Add guild name
			local guild = GuildAdsDB.profile.Main:get(owner, GuildAdsDB.profile.Main.Guild);
			if guild then
				-- Add guild name
				GameTooltip:AddLine("<"..guild..">", 1, 1, 1);
			end
			
			-- Add AFK/DND flag
			local flag, message = GuildAdsComm:GetStatus(owner);
			if flag and flag~="" then
				GameTooltip:AddLine(flag..": "..message, 1.0, 1.0, 1.0);
			end
			
			-- Reroll
			local account = GuildAdsDB.profile.Main:get(owner, GuildAdsDB.profile.Main.Account) or owner;
			local otherChars = GuildAdsGuild.data.cacheByAccount[account];
			if otherChars and #otherChars > 1 then
				GameTooltip:AddLine(" ");
				for _, playerName in ipairs(otherChars) do
					if playerName ~= owner then
						ocolor = GuildAdsUITools.onlineColor[GuildAdsGuild.isOnline(playerName)];
						GameTooltip:AddLine(playerName, ocolor.r, ocolor.g, ocolor.b);
					end
				end
			end
			
			-- show tooltip
			GameTooltip:Show();
		end;
		
		update =  function(button, selected, reroll, playerName)
			local buttonName= button:GetName();
			
			local ownerField = buttonName.."Owner";
			local classField = buttonName.."Class";
			local raceField = buttonName.."Race";
			local levelField = buttonName.."Level";
			local infoField = buttonName.."Info";
			
			-- 
			if selected then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			
			local online = GuildAdsGuild.isOnline(playerName);
			local ocolor, lcolor;
			local account = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account);
			if online then
				ocolor = GuildAdsUITools.onlineColor[online];
				lcolor = GuildAdsUITools.white;
			else
				ocolor = GuildAdsUITools.accountOnlineColor[GuildAdsGuild.isAccountOnline(account)];
				lcolor = ocolor;
			end
			
			local prefix, suffix, suffixGuild;
			if GuildAdsDB.channel[GuildAds.channelName]:getPlayers()[playerName] then
				suffixGuild = "";
			else
				suffixGuild = "*";
			end

			if not reroll and account and #GuildAdsGuild.data.cacheByAccount[account]>1 then
				suffix = "+"
			else
				suffix = "";
			end
			
			if reroll then
				prefix = "    ";
			else
				prefix = "";
			end
			
			getglobal(ownerField):SetText(prefix..playerName..suffix);
			getglobal(ownerField):SetTextColor(ocolor.r, ocolor.g, ocolor.b);
			getglobal(ownerField):Show();
			
			-- update clas, race, level
			getglobal(levelField):SetText(GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or "");
			getglobal(levelField):SetTextColor(lcolor.r, lcolor.g, lcolor.b);
			getglobal(levelField):Show();
			getglobal(classField):SetText(GuildAdsDB.profile.Main:getClassNameFromId(GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Class)));
			getglobal(classField):SetTextColor(lcolor.r, lcolor.g, lcolor.b);
			getglobal(classField):Show();
			getglobal(raceField):SetText(GuildAdsDB.profile.Main:getRaceNameFromId(GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Race)));
			getglobal(raceField):SetTextColor(lcolor.r, lcolor.g, lcolor.b);
			getglobal(raceField):Show();
			getglobal(infoField):SetText((GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Guild) or "")..suffixGuild);
			getglobal(infoField):SetTextColor(lcolor.r, lcolor.g, lcolor.b);
			getglobal(infoField):Show();
			
			-- update highlight
			getglobal(buttonName.."Highlight"):SetVertexColor(ocolor.r, ocolor.g, ocolor.b);
		end;
		
		clear = function(button)
			local buttonName = button:GetName();
			getglobal(buttonName.."Owner"):Hide();
			getglobal(buttonName.."Class"):Hide();
			getglobal(buttonName.."Level"):Hide();
			getglobal(buttonName.."Race"):Hide();
			getglobal(buttonName.."Info"):Hide();
			button:UnlockHighlight();
			local ocolor = GuildAdsUITools.onlineColor[false];
			getglobal(buttonName.."Highlight"):SetVertexColor(ocolor.r, ocolor.g, ocolor.b);
		end;
		
	};
	
	---------------------------------------------------------------------------------
	--
	-- context menu
	--
	---------------------------------------------------------------------------------	
	contextMenu = {
	
		onLoad = function()
			GuildAdsGuildContextMenu.initialize = GuildAdsGuild.contextMenu.initialize;
			GuildAdsGuildContextMenu.displayMode = "MENU";
		end;
	
		show = function(owner)
			HideDropDownMenu(1);
			GuildAdsGuildContextMenu.name = "Title";
			GuildAdsGuildContextMenu.owner = owner;
			ToggleDropDownMenu(1, nil, GuildAdsGuildContextMenu, "cursor");
		end;
		
		initialize = function()
			-- default menu
			GuildAdsPlayerMenu.header(GuildAdsGuildContextMenu.owner, 1);
			GuildAdsPlayerMenu.menus(GuildAdsGuildContextMenu.owner, 1);
			-- 
			if 		GuildAdsDB.profile.Main:getRevision(GuildAdsGuildContextMenu.owner)==0 
				and GuildAdsDB.profile.Main:get(GuildAdsGuildContextMenu.owner, GuildAdsDB.profile.Main.Account) ~= nil then
				info = { };
				info.text =  GUILDADS_GUILD_DEGROUP;
				info.notCheckable = 1;
				info.value = GuildAdsGuildContextMenu.owner;
				info.func = GuildAdsGuild.contextMenu.resetAccount;
				UIDropDownMenu_AddButton(info, 1);
			end
			-- 
			GuildAdsPlayerMenu.footer(GuildAdsGuildContextMenu.owner, 1);
		end;
		
		resetAccount = function()
			if this.value then
				GuildAdsDB.profile.Main:setRaw(this.value, GuildAdsDB.profile.Main.Account, nil);
				GuildAdsGuild.peopleButtonsUpdate(true);
				GuildAdsGuild.peopleCountUpdate();
			end
		end;
			
	};
	
	---------------------------------------------------------------------------------
	--
	-- classFilter
	--
	---------------------------------------------------------------------------------	
	classFilter = {

		init = function()
			if not GuildAdsGuild.getProfileValue(nil, "Filters") then
				for id, _ in pairs(GUILDADS_CLASSES) do
					GuildAdsGuild.setProfileValue("Filters", id, true);
				end
			end;
			FilterNames = GUILDADS_CLASSES;
			local index = 1;
			for k,filterDesc in pairs(g_AdFilters) do
				local info = { };
				info.text = GUILDADS_CLASSES[filterDesc.id];
				info.value = filterDesc.id;
				if GuildAdsGuild.getProfileValue("Filters", filterDesc.id) then
					info.checked = 1;
				else
					info.checked = nil;
				end
				info.textR = 1;
				info.textG = 0.86;
				info.textB = 0;
				info.keepShownOnClick = 1;
				info.func = GuildAdsGuild.classFilter.onClick;
				UIDropDownMenu_AddButton(info);
			end
			-- hack : add an option : filter guild roster
			info = { };
			info.text =  "";
			info.notCheckable = 1;
			info.textR = 0;
			info.textG = 0;
			info.textB = 0;
			info.keepShownOnClick = 1;
			UIDropDownMenu_AddButton(info);
			
			local info = { };
			info.text = GUILD;
			info.value = "guild";
			info.checked = GuildAdsGuild.getProfileValue("Filters", "guild") and 1 or nil;
			info.textR = 1;
			info.textG = 0.86;
			info.textB = 0;
			info.keepShownOnClick = 1;
			info.func = GuildAdsGuild.classFilter.onClick;
			UIDropDownMenu_AddButton(info);		
		end;
		
		onClick = function()
			if GuildAdsGuild.getProfileValue("Filters", this.value) then
				PlaySound("igMainMenuOptionCheckBoxOff");
				GuildAdsGuild.setProfileValue("Filters", this.value, nil);
			else
				PlaySound("igMainMenuOptionCheckBoxOn");
				GuildAdsGuild.setProfileValue("Filters", this.value, true);
			end
			GuildAdsGuild.peopleButtonsUpdate(true);
			GuildAdsGuild.peopleCountUpdate();
		end;
		
	};
	

	---------------------------------------------------------------------------------
	--
	-- data
	--
	---------------------------------------------------------------------------------		
	data = {
		cache = nil;
		cacheByAccount = nil;
		
		resetCache = function()
			GuildAdsGuild.debug("resetCache");
			GuildAdsGuild.data.cache = nil;
			GuildAdsGuild.data.cacheByAccount = nil;
		end;
		
		isVisible = function(playerName)
			if GuildAdsGuild.getProfileValue(nil, "HideOfflines") then
				if GuildAdsGuild.getProfileValue(nil, "GroupByAccount") then
					local playerAccount = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account) or playerName;
					if not GuildAdsGuild.isAccountOnline(playerAccount) then
						return false;
					end
				else
					if not GuildAdsGuild.isOnline(playerName) then
						return false;
					end
				end
			end
			local class = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Class);
			local filters = GuildAdsGuild.getProfileValue(nil, "Filters");
			return filters[class] and true or false;
		end;
	
		get = function(updateData)
			if GuildAdsGuild.data.cache==nil or updateData==true then
				GuildAdsGuild.debug("recreate the cache");
				
				local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
				
			    -- in a guild a pseudo ads
				local workingTable = {};
				for playerName in pairs(players) do
					tinsert(workingTable, playerName);
				end
				
				if IsInGuild() and GuildAdsGuild.getProfileValue("Filters", "guild") then
					GuildRoster();
					-- TODO should wait for the GUILD_ROSTER_UPDATE event
					local guildName = GetGuildInfo("player");
					local numAllGuildMembers = GetNumGuildMembers(true);
					if (numAllGuildMembers>=0) then 
						for currentplayer = 1,numAllGuildMembers do
							local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(currentplayer);
							
							if name then
								if GuildAdsDB.profile.Main:getRevision(name)==0 then
									-- update profile only it doesn't exist
									GuildAdsDB.profile.Main:setRaw(name, GuildAdsDB.profile.Main.Guild, guildName);
									GuildAdsDB.profile.Main:setRaw(name, GuildAdsDB.profile.Main.Class, GuildAdsDB.profile.Main:getClassIdFromName(class));
									GuildAdsDB.profile.Main:setRaw(name, GuildAdsDB.profile.Main.GuildRank, rank);
									GuildAdsDB.profile.Main:setRaw(name, GuildAdsDB.profile.Main.GuildRankIndex, rankIndex);
									GuildAdsDB.profile.Main:setRaw(name, GuildAdsDB.profile.Main.Level, level);
								end
							
								if not players[name] then
									tinsert(workingTable, name);
								end
								
								GuildAdsGuild.onlineCache[name] = online and true or false;
							end
						end
					end
				end
				
				-- create GuildAdsGuild.data.cache
				GuildAdsGuild.data.cache = {};
				GuildAdsGuild.data.cacheByAccount = {};
				GuildAdsGuild.accountOnlineCache = {};
				
				local playerAccount;
				if GuildAdsGuild.getProfileValue(nil, "GroupByAccount") then
					for _, playerName in pairs(workingTable) do
						playerAccount = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account) or playerName;
						GuildAdsGuild.accountOnlineCache[playerAccount] = GuildAdsGuild.accountOnlineCache[playerAccount] or GuildAdsGuild.isOnline(playerName);
						if not GuildAdsGuild.data.cacheByAccount[playerAccount] then
							GuildAdsGuild.data.cacheByAccount[playerAccount] = {};
						end
						tinsert(GuildAdsGuild.data.cacheByAccount[playerAccount], playerName);
					end
					
					-- sort data
					for account, forAccount in pairs(GuildAdsGuild.data.cacheByAccount) do
						GuildAdsGuild.sortData.doForAccount(forAccount);
						if GuildAdsGuild.data.isVisible(forAccount[1]) then
							tinsert(GuildAdsGuild.data.cache, forAccount[1]);
						end
					end
					
					GuildAdsGuild.sortData.doIt(GuildAdsGuild.data.cache);
				else
					-- sort data
					for _, playerName in pairs(workingTable) do
						playerAccount = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account) or playerName;
						GuildAdsGuild.accountOnlineCache[playerAccount] = GuildAdsGuild.accountOnlineCache[playerAccount] or GuildAdsGuild.isOnline(playerName);
						if GuildAdsGuild.data.isVisible(playerName) then
							tinsert(GuildAdsGuild.data.cache, playerName);
						end
						if not GuildAdsGuild.data.cacheByAccount[playerAccount] then
							GuildAdsGuild.data.cacheByAccount[playerAccount] = {};
						end
						tinsert(GuildAdsGuild.data.cacheByAccount[playerAccount], playerName);
					end
					
					-- sort data
					for account, forAccount in pairs(GuildAdsGuild.data.cacheByAccount) do
						GuildAdsGuild.sortData.doForAccount(forAccount);
					end
					
					GuildAdsGuild.sortData.doIt(GuildAdsGuild.data.cache);
				end
				
				workingTable = nil;
			end
			
			return GuildAdsGuild.data.cache; 
		end;
		
	};
	
	---------------------------------------------------------------------------------
	--
	-- sort data
	--
	---------------------------------------------------------------------------------	
	sortData = {
			
		current = "name";
	
		currentWay = {
			name = "up",
			level = "normal",
			class = "up",
			race = "up",
			info = "up"
		};

		predicateFunctions = {
		
			mainPlayer = function(a, b)
				return a==GuildAdsGuild.sortData.mainPlayerForAccount;
			end;
		
			name = function(a, b)
				if (a < b) then
					return false;
				elseif (a > b) then
					return true;
				end
				return nil;
			end;
			
			level = function(a, b)
				local al = GuildAdsDB.profile.Main:get(a, GuildAdsDB.profile.Main.Level);
				local bl = GuildAdsDB.profile.Main:get(b, GuildAdsDB.profile.Main.Level);
				if al and bl then
					if (al < bl) then
						return false;
					elseif (al > bl) then
						return true;
					end
				end
				return nil;
			end;
			
			class = function(a, b)
				local ac = GuildAdsDB.profile.Main:get(a, GuildAdsDB.profile.Main.Class);
				local bc = GuildAdsDB.profile.Main:get(b, GuildAdsDB.profile.Main.Class);
				if ac and bc then
					if (ac < bc) then
						return false;
					elseif (ac > bc) then
						return true;
					end
				end
				return nil;
			end;
			
			race = function(a, b)
				local ar = GuildAdsDB.profile.Main:get(a, GuildAdsDB.profile.Main.Race);
				local br = GuildAdsDB.profile.Main:get(b, GuildAdsDB.profile.Main.Race);
				if ar and br then
					if (ar < br) then
						return false;
					elseif (ar > br) then
						return true;
					end
				end
				return nil;
			end;
			
			info = function(a, b)
				local ag = GuildAdsDB.profile.Main:get(a, GuildAdsDB.profile.Main.Guild) or "";
				local bg = GuildAdsDB.profile.Main:get(b, GuildAdsDB.profile.Main.Guild) or "";
				if (ag < bg) then
					return false;
				elseif (ag > bg) then
					return true;
				end
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
		
		cacheHigherLevel = {};
		
		doIt = function(adTable)
 			table.sort(adTable, GuildAdsGuild.sortData.predicate);
		end;
		
		doForAccount = function(adTable)
			local mainPlayerForAccount;
			local currentLevel;
			for _, playerName in pairs(adTable) do
				local level = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level);
				if not currentLevel 
					or level>currentLevel 
					or (level==currentLevel and playerName<mainPlayerForAccount) then
						currentLevel = level;
						mainPlayerForAccount = playerName;
				end
			end
			GuildAdsGuild.sortData.mainPlayerForAccount = mainPlayerForAccount;
			table.sort(adTable, GuildAdsGuild.sortData.predicateForAccount);
			GuildAdsGuild.sortData.mainPlayerForAccount = nil;
		end;
		
		predicate = function(a, b)
			-- nil references are always less than
			local result = GuildAdsGuild.sortData.byNilAA(a, b);
			if result~=nil then
				return result;
			end
			
			result = GuildAdsGuild.sortData.predicateFunctions[GuildAdsGuild.sortData.current](a, b);
			result = GuildAdsGuild.sortData.wayFunctions[GuildAdsGuild.sortData.currentWay[GuildAdsGuild.sortData.current]](result);
			
			return result or false;
		end;
		
		predicateForAccount = function(ha, hb)
			-- nil references are always less than
			local result = GuildAdsGuild.sortData.byNilAA(ha, hb);
			if result~=nil then
				return result;
			end
			
			result = GuildAdsGuild.sortData.predicateFunctions.mainPlayer(ha, hb);
			result = GuildAdsGuild.sortData.wayFunctions.normal(result);
				
			if result == nil then
				result = GuildAdsGuild.sortData.predicateFunctions.name(ha, hb);
				result = GuildAdsGuild.sortData.wayFunctions.up(result);
			end
			
			return result or false;
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
	
}

---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsGuild);