----------------------------------------------------------------------------------
--
-- GuildAdsGuildFrame.lua
--
-- Author: Zarkan, Fka� of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local g_AdFilters = {};
local g_guildName;

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
	
	onlineCache = {},
	
	onConfigChanged = function(path, key, value)
		if key=="GroupByAccount" then
			GuildAdsGuild.peopleButtonsUpdate(true);
			GuildAdsGuild.peopleCountUpdate();
		elseif key=="ShowOfflines" then
			GuildAdsGuild.peopleButtonsUpdate(true);
			GuildAdsGuild.peopleCountUpdate();
		end
	end;
	
	onConnection = function(playerName, status) 
		GuildAdsGuild.peopleButtonsUpdate(true);
		GuildAdsGuild.peopleCountUpdate();
		
		-- show connected status except for my guild
		local gowner = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Guild);
		if (playerName ~= GuildAds.playerName and (gowner == nil or gowner ~= GetGuildInfo("player"))) then
			local msg;
			if (status) then
				msg = string.format(ERR_FRIEND_ONLINE_SS, playerName, playerName);
			else
				msg = string.format(ERR_FRIEND_OFFLINE_S, playerName);
			end
			GuildAdsUITools:AddChatMessage(msg);
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
		if not GuildAdsGuild.initialized then
			GuildAdsGuild.initialized = true;
			GuildAdsGuild.onInit();
		end
		GuildAdsGuild.delayedUpdate();
	end;
	
	onChannelLeave = function()
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
		g_guildName = GetGuildInfo("player");
		
		GuildAdsDB.profile.Main:registerEvent(GuildAdsGuild.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName]:registerEvent(GuildAdsGuild.onPlayerListUpdate);
		
		-- No selection
		GuildAdsGuild.debug("InitGuild");
		g_GlobalAdSelectedId = 0;
		g_GlobalAdSelectedType = 0;
		g_GlobalTitleSelectedId = 0;
		g_GlobalTitleSelectedType = 0;
		
		UIDropDownMenu_Initialize(GuildAds_Filter_ClassDropDown, GuildAdsGuild.classFilter.init);
		UIDropDownMenu_SetText(FILTER, GuildAds_Filter_ClassDropDown);
		UIDropDownMenu_SetWidth(100, GuildAds_Filter_ClassDropDown);
		
		if (GuildAdsGuild.getProfileValue(nil, "GroupByAccount")) then
			GuildAdsGroupByAccountCheckButton:SetChecked(1);
		else
			GuildAdsGroupByAccountCheckButton:SetChecked(0);
		end
		
		if (GuildAdsGuild.getProfileValue(nil, "ShowOfflines")) then
			GuildAdsGuildShowOfflinesCheckButton:SetChecked(1);
		else
			GuildAdsGuildShowOfflinesCheckButton:SetChecked(0);
		end
		
		GuildAdsGuild.peopleCountUpdate();
		
		-- Init g_AdFilters
		g_AdFilters = {};
		local playerFaction = GUILDADS_RACES_TO_FACTION[GuildAdsDB.profile.Main:getRaceIdFromName(UnitRace("player"))];
		for id, name in GUILDADS_CLASSES do
			if (GUILDADS_CLASS_TO_FACTION[id]==nil or GUILDADS_CLASS_TO_FACTION[id]==playerFaction) then
				tinsert(g_AdFilters, { id=id, name=name});
			end
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

	---------------------------------------------------------------------------------
	--
	-- For others plugins
	--
	---------------------------------------------------------------------------------		
	selectPlayer = function(playerName)
		local linear = GuildAdsGuild.data.get();
		for id, info in linear do
			if info==playerName then
				--
				g_GlobalAdSelected = info.adId;
				g_GlobalTitleSelected = 0;
				--[[
				local offset = FauxScrollFrame_GetOffset(GuildAdsPeopleGlobalAdScrollFrame);
				if g_GlobalAdSelected<offset or g_GlobalAdSelected>(offset+GuildAdsGuild.GUILDADS_NUM_GLOBAL_AD_BUTTONS) then
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
		g_GlobalAdSelected = 0;
		g_GlobalTitleSelected = 0;
		GuildAdsGuild.peopleButtonsUpdate();
		return false;
	end;
	
	
	--[[
	selectMainPlayer = function(rerollName)
		
	end;
	]]

	---------------------------------------------------------------------------------
	--
	-- Update people count
	--
	---------------------------------------------------------------------------------	
	peopleCountUpdate = function()
		local linear  = GuildAdsGuild.data.get();
		local count = 0;
		local countOnline = 0;
		for _, playerName in linear do
			if type(playerName)=="string" then
				count = count + 1;
				if GuildAdsGuild.isOnline(playerName) then
					countOnline = countOnline+1;
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
			local linearSize = table.getn(linear);
	
			-- init
			local i = 1;
			local j = i + offset;
			
			-- for each buttons
			while (i <= GuildAdsGuild.GUILDADS_NUM_GLOBAL_AD_BUTTONS) do
				local button = getglobal("GuildAdsPeopleGlobalAdButton"..i);
				
				if (j <= linearSize) then
					if type(linear[j]) == "string" then
						-- update internal data
						button.groupId = nil;
						button.owner = linear[j];
						
						-- create a ads
						GuildAdsGuild.peopleButton.update(button, g_GlobalAdSelected == linear[j], linear[j]);
					elseif type(linear[j]) == "table" then
						-- update internal data
						button.groupId = linear[j].groupId;
						button.owner = nil;

						-- create empty a line
						GuildAdsGuild.peopleButton.clear(button);
					end
					button:Show();
					j = j+1;
				else
					button.groupId = nil;
					button.owner = nil;
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
		
		onClick = function(button)
			if this.owner then
				-- an player name was clicked
				if (this.owner ~= g_GlobalAdSelected) then
					g_GlobalAdSelected = this.owner;
					g_GlobalTitleSelected = 0;
					GuildAdsGuild.peopleButtonsUpdate();
				end
				if button == "RightButton" then
					GuildAdsGuild.contextMenu.show(this.owner);
				end
			elseif this.groupId then
				-- a title was clicked
				-- do nothing
			end
		end;
		
		onEnter = function(obj)
			obj = obj or this;
			local owner = obj.owner;
			if (not owner) then
				return;
			end
			
			GameTooltip:SetOwner(obj, "ANCHOR_BOTTOMRIGHT");
			
			-- Add player name
			local ocolor = GuildAdsUITools.onlineColor[GuildAdsGuild.isOnline(owner)];
			GuildAdsGuild.debug(owner..":"..tostring(GuildAdsComm:IsOnLine(owner))..","..tostring(GuildAdsGuild.onlineCache[owner])..":"..type(ocolor));
			GameTooltip:AddLine(owner, ocolor.r, ocolor.g, ocolor.b);
			
			-- Add guild name
			local guild = GuildAdsDB.profile.Main:get(owner, GuildAdsDB.profile.Main.Guild);
			if guild then
				-- Add guild name
				GameTooltip:AddLine("<"..guild..">", 1, 1, 1);
			end
			
			-- Add AFK/DND flag
			local flag, message = GuildAdsComm:GetStatus(owner);
			if flag then
				GameTooltip:AddLine(flag..": "..message, 1.0, 1.0, 1.0);
			end
			
			-- show tooltip
			GameTooltip:Show();
		end;
		
		-- where ne sert � rien : se baser sur l'information .guild
		update =  function(button, selected, playerName)
			local buttonName= button:GetName();
			
			local ownerField = buttonName.."Owner";
			local classField = buttonName.."Class";
			local raceField = buttonName.."Race";
			local levelField = buttonName.."Level";
			
			-- 
			if selected then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			
			local ocolor = GuildAdsUITools.onlineColor[GuildAdsGuild.isOnline(playerName)];
			
			-- icon will be nicer
			local prefix;
			
			if g_guildName and GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Guild) == g_guildName then
				prefix = "G";
			else
				prefix = "A";
			end
			
			if GuildAdsDB.channel[GuildAds.channelName]:getPlayers()[playerName] then
				prefix = "["..prefix.."]";
			else
				prefix = " "..prefix.." ";
			end
			
			getglobal(ownerField):SetText(prefix..playerName);
			getglobal(ownerField):SetTextColor(ocolor.r, ocolor.g, ocolor.b);
			getglobal(ownerField):Show();
			
			-- update clas, race, level
			getglobal(levelField):SetText(GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level) or "");
			getglobal(levelField):Show();
			getglobal(classField):SetText(GuildAdsDB.profile.Main:getClassNameFromId(GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Class)));
			getglobal(classField):Show();
			getglobal(raceField):SetText(GuildAdsDB.profile.Main:getRaceNameFromId(GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Race)));
			getglobal(raceField):Show();
			
			-- update highlight
			getglobal(buttonName.."Highlight"):SetVertexColor(ocolor.r, ocolor.g, ocolor.b);
		end;
		
		clear = function(button)
			local buttonName = button:GetName();
			getglobal(buttonName.."Owner"):Hide();
			getglobal(buttonName.."Class"):Hide();
			getglobal(buttonName.."Level"):Hide();
			getglobal(buttonName.."Race"):Hide();
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
			local owner = this.owner;

			info = { };
			info.text =  owner;
			info.isTitle = true;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, 1);

			info = { };
			info.text =  WHISPER_MESSAGE;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsGuild.contextMenu.whisper;
			--[[
			if not GuildAdsGuild.isOnline(owner) then
				info.disabled = 1
			end
			]]
			UIDropDownMenu_AddButton(info, 1);

			info = { };
			info.text =  INSPECT;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsGuild.contextMenu.inspect;
			UIDropDownMenu_AddButton(info, 1);

			info = { };
			info.text =  CHAT_INVITE_SEND;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsGuild.contextMenu.invite;
			UIDropDownMenu_AddButton(info, 1);
		
			info = { };
			info.text =  WHO;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsGuild.contextMenu.who;
			UIDropDownMenu_AddButton(info, 1);
	
			info = { };
			info.text = CANCEL;
			info.notCheckable = 1;
			info.func = GuildAdsGuild.contextMenu.cancel;
			UIDropDownMenu_AddButton(info, 1);			
		end;
		
		cancel = function()
			HideDropDownMenu(1);
		end;
		
		whisper = function()
			local owner = this.value;
			if owner then
				if ( not ChatFrameEditBox:IsVisible() ) then
					ChatFrame_OpenChat("/w "..owner.." ");
				else
					ChatFrameEditBox:SetText("/w "..owner.." ");
				end
				ChatEdit_ParseText(ChatFrame1.editBox, 0);
			end
		end;
		
		inspect = function()
			local owner = this.value;
			if owner then
				GuildAdsInspectWindow:Inspect(owner);
				GuildAdsInventory:Update(true);
			end
		end;
		
		invite = function()
			local owner = this.value;
			if owner then
				InviteByName(owner);
			end
		end;
		
		who = function()
			local owner = this.value;
			if owner then
				local text = ChatFrameEditBox:GetText();
				ChatFrameEditBox:SetText("/who "..owner);
				ChatEdit_SendText(ChatFrameEditBox);
				ChatFrameEditBox:SetText(text);
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
			-- called only if Reagent is on
			if not GuildAdsGuild.getProfileValue(nil, "Filters") then
				for id, _ in GUILDADS_CLASSES do
					GuildAdsGuild.setProfileValue("Filters", id, true);
				end
			end;
			--local index = 1;
			FilterNames = GUILDADS_CLASSES;
			index = 1;
			for k,filterDesc in g_AdFilters do
				local info = { };
				--if (filters[k]) then
				--if (FilterNames[k]) then
				info.text = GUILDADS_CLASSES[filterDesc.id];
				info.value = filterDesc.id;
				if GuildAdsGuild.getProfileValue("Filters", filterDesc.id) then
					info.checked = 1;--:SetChecked(1);
				else
					info.checked = nil;
				end
				info.textR = 1;
				info.textG = 0.86;
				info.textB = 0;
				info.keepShownOnClick = 1;
				info.func = GuildAdsGuild.classFilter.onClick;
				UIDropDownMenu_AddButton(info);
				--end
			end
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
		end;

	};
	

	---------------------------------------------------------------------------------
	--
	-- data
	--
	---------------------------------------------------------------------------------		
	data = {
		cache = nil;
		
		getGroup = function(playerName) 
			if GuildAdsGuild.getProfileValue(nil, "GroupByAccount") then
				return GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account) or playerName;
			else
				return nil;
			end
		end;
		
		resetCache = function()
			GuildAdsGuild.debug("resetCache");
			GuildAdsGuild.data.cache = nil;
		end;
		
		adIsVisible = function(playerName)
			if not (GuildAdsGuild.getProfileValue(nil, "ShowOfflines") or GuildAdsGuild.isOnline(playerName)) then
				return false;
			end
			local class = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Class);
			local filters = GuildAdsGuild.getProfileValue(nil, "Filters", {});
			for id, name in filters do
				if id == class then
					return true;
				end
			end
			return false;
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
				
				if (IsInGuild()) then
					GuildRoster();
					-- should wait for the GUILD_ROSTER_UPDATE event
					local numAllGuildMembers = GetNumGuildMembers(true);
					if (numAllGuildMembers>=0) then 
						for currentplayer = 1,numAllGuildMembers do
							local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(currentplayer);
							if not players[name] then
								GuildAdsDB.profile.Main:set(name, GuildAdsDB.profile.Main.Guild, g_guildName);
								GuildAdsDB.profile.Main:set(name, GuildAdsDB.profile.Main.Class, GuildAdsDB.profile.Main:getClassIdFromName(class));
								GuildAdsDB.profile.Main:set(name, GuildAdsDB.profile.Main.CreationTime, GuildAdsDB:GetCurrentTime());
								if online then
									GuildAdsGuild.onlineCache[name] = true;
								else
									GuildAdsGuild.onlineCache[name] = false;
								end
								tinsert(workingTable, name);
							end
							GuildAdsDB.profile.Main:set(name, GuildAdsDB.profile.Main.GuildRank, rank);
							GuildAdsDB.profile.Main:set(name, GuildAdsDB.profile.Main.GuildRankIndex, rankIndex);
							GuildAdsDB.profile.Main:set(name, GuildAdsDB.profile.Main.Level, level);
						end
					end
				end
				
				-- sort data
				GuildAdsGuild.sortData.doIt(workingTable);
				
				-- create GuildAdsGuild.data.cache
				GuildAdsGuild.data.cache = {};

				local adGroup, currentGroup;
				for _, playerName in workingTable do
					if GuildAdsGuild.data.adIsVisible(playerName) then
						adGroup = GuildAdsGuild.data.getGroup(playerName);
						if currentGroup~=adGroup then
							tinsert(GuildAdsGuild.data.cache, { groupId=adGroup } );
							currentGroup = adGroup;
						end
						tinsert(GuildAdsGuild.data.cache, playerName );
					end
				end
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
			race = "up"
		};

		predicateFunctions = {
		
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
			GuildAdsGuild.sortData.initHigherLevel(adTable);
 			table.sort(adTable, GuildAdsGuild.sortData.predicate);
		end;
		
		predicate = function(a, b)
			-- nil references are always less than
			local result = GuildAdsGuild.sortData.byNilAA(a, b);
			if result~=nil then
				return result;
			end
			
			-- sortData by account first if need
			if result==nil and GuildAdsGuild.getProfileValue(nil, "GroupByAccount") then
				local ha, hb;
				ha = GuildAdsGuild.sortData.getHigherlevel(a) or a;
				hb = GuildAdsGuild.sortData.getHigherlevel(b) or b;
				
 				result = GuildAdsGuild.sortData.byNilAA(ha, hb);
				if result == nil then
					result = GuildAdsGuild.sortData.predicateFunctions[GuildAdsGuild.sortData.current](ha, hb);
					result = GuildAdsGuild.sortData.wayFunctions[GuildAdsGuild.sortData.currentWay[GuildAdsGuild.sortData.current]](result);
				end
				
				if result == nil then
					result = GuildAdsGuild.sortData.predicateFunctions.name(ha, hb);
					result = GuildAdsGuild.sortData.wayFunctions.up(result);
				end
				
				if result == nil then
					result = GuildAdsGuild.sortData.predicateFunctions.level(a, b);
					result = GuildAdsGuild.sortData.wayFunctions.normal(result);
				end
				
				if result == nil then
					result = GuildAdsGuild.sortData.predicateFunctions.name(a, b);
					result = GuildAdsGuild.sortData.wayFunctions.up(result);
				end
			else
				if result == nil then
					result = GuildAdsGuild.sortData.predicateFunctions[GuildAdsGuild.sortData.current](a, b);
					result = GuildAdsGuild.sortData.wayFunctions[GuildAdsGuild.sortData.currentWay[GuildAdsGuild.sortData.current]](result);
				end;
			end;
			
			return result or false;
		end;
		
		initHigherLevel = function(adTable)
			GuildAdsGuild.sortData.cacheHigherLevel = {};
			local higherLevel = GuildAdsGuild.sortData.cacheHigherLevel;
			local currentLevel = {};
			for _, playerName in adTable do
				local account = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account) or playerName;
				local level = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Level);
				if account and GuildAdsGuild.data.adIsVisible(playerName) then
					if not currentLevel[account] 
					    or level>currentLevel[account] 
						or (level==currentLevel[account] and playerName<higherLevel[account]) then
						currentLevel[account] = level;
						higherLevel[account] = playerName;
					end
				end
			end
		end;
		
		getHigherlevel = function(playerName)
			local account = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Account);
			if account then
				return GuildAdsGuild.sortData.cacheHigherLevel[account];
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
	
}

---------------------------------------------------------------------------------
--
-- Register plugin
-- 
---------------------------------------------------------------------------------
GuildAdsPlugin.UIregister(GuildAdsGuild);