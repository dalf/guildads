----------------------------------------------------------------------------------
--
-- GuildAdsQuestFrame.lua
--
-- Author: Galmok of Stormrage-EU (horde)
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local new = GuildAds.new
local new_kv = GuildAds.new_kv
local del = GuildAds.del
local deepDel = GuildAds.deepDel

GuildAdsQuest = {
	metaInformations = { 
		name = "Quest",
        	guildadsCompatible = 100,
		ui = {
			main = {
				frame = "GuildAdsQuestFrame",
				tab = "GuildAdsQuestTab",
				tooltiptitle = GUILDADSTOOLTIPS_QUEST_TITLE,
                		tooltip = GUILDADSTOOLTIPS_QUEST,
				priority = 40
			}
		}
	};

	GUILDADS_NUM_QUEST_BUTTONS = 27;
	GUILDADS_QUESTBUTTONSIZEY = 16;
	
	onInit = function()
	end;
	
	onShow = function()
		GuildAdsQuest.questButtonsUpdate();
	end;
	
	onConfigChanged = function(path, key, value)
	end;
	
	onDBUpdate = function(dataType, playerName, id)
		GuildAdsQuest.data.resetCache();
		GuildAdsQuest.delayedUpdate();
	end;
	
	onReceivedTransaction = function(dataType, playerName, newKeys, deletedKeys)
		GuildAdsQuest.data.resetCache();
		GuildAdsQuest.delayedUpdate();
	end;
	
	onChannelJoin = function()
		GuildAdsDB.profile.Quest:registerUpdate(GuildAdsQuest.onDBUpdate);
		GuildAdsDB.profile.Quest:registerTransactionReceived(GuildAdsQuest.onReceivedTransaction);
		GuildAdsQuest.delayedUpdate();
	end;
	
	onChannelLeave = function()
		GuildAdsDB.profile.Quest:unregisterUpdate(GuildAdsQuest.onDBUpdate);
		GuildAdsDB.profile.Quest:unregisterTransactionReceived(GuildAdsQuest.onReceivedTransaction);
		GuildAdsQuest.delayedUpdate();
	end;
	
	onUpdate = function(self, elapsed)
		if self.update then
			self.update = self.update - elapsed;
			if self.update<=0 then
				self.update = nil;
				GuildAdsQuest.updateWindow();
			end;
		end;
	end;

	delayedUpdate = function()
		GuildAdsQuestFrame.update = 1;
	end;
	
	updateWindow = function()
		GuildAdsTrade.debug("updateWindow");
		if GuildAdsQuestFrame and GuildAdsQuestFrame.IsVisible and GuildAdsQuestFrame:IsVisible() then
			-- update quest lines
			GuildAdsQuest.questButtonsUpdate();
		end
	end;
		
	sortQuests = function(sortValue)
		local prevSortValue = GuildAdsQuest.sortData.current
		GuildAdsQuest.sortData.current = sortValue;
		if (GuildAdsQuest.sortData.currentWay[sortValue]=="normal") then 
			GuildAdsQuest.sortData.currentWay[sortValue]="up";
		else 
			GuildAdsQuest.sortData.currentWay[sortValue]="normal";
		end
		if sortValue ~= prevSortValue then
			GuildAdsQuest.sortData.current2 = prevSortValue
		end
		GuildAdsQuest.questButtonsUpdate(nil, true);
	end;
	
	-- update quest lines
	questButtonsUpdate = function(self, updateData)
		--if GuildAdsQuestFrame:IsVisible() then
			GuildAdsQuest.debug("questButtonsUpdate("..tostring(updateData)..")");
			local offset = FauxScrollFrame_GetOffset(GuildAdsQuestScrollFrame);
		
			local linear = GuildAdsQuest.data.get(updateData);
			local linearSize = #linear;
	
			-- init
			local i = 1;
			local j = i + offset;
			local k = 0;
			local currentQuest, button, currentIndex, numPlayers;
			local currentSelection = GuildAdsQuest.currentSelectedQuestId;
			if currentSelection then
				currentIndex = GuildAdsQuest.getLinearIndex(linear, currentSelection)
				if type(linear[currentIndex].p) == "string" then
					numPlayers = 1
				else
					numPlayers = #linear[currentIndex].p
				end
				linearSize = linearSize + numPlayers
				belowCurrent = currentIndex + numPlayers
			end

			-- for each buttons
			while (i <= GuildAdsQuest.GUILDADS_NUM_QUEST_BUTTONS) do
				button = getglobal("GuildAdsQuestButton"..i);
				
				currentQuest = linear[j];
				if currentSelection then
					if j <= currentIndex then
						k = 0
						currentQuest = linear[j];
					elseif j<= belowCurrent then
						k = j - currentIndex
						currentQuest = linear[j-k];
					else
						currentQuest = linear[j - numPlayers];
						k = 0
					end
				end
				j=j+1
				
				if (currentQuest ~= nil) then
					button.questId = currentQuest.id;
					button.data = currentQuest;
					
					GuildAdsQuest.questLineButton.update(button, currentSelection==currentQuest.id, currentQuest, k);
					button:Show();
				else
					button.questId = nil;
					button.data = nil;
					button:Hide();
				end;
				
				i = i+1;
			end;
			FauxScrollFrame_Update(GuildAdsQuestScrollFrame, linearSize, GuildAdsQuest.GUILDADS_NUM_QUEST_BUTTONS, GuildAdsQuest.GUILDADS_QUESTBUTTONSIZEY);
		--end;
	end;
	
	getLinearIndex= function(linear, questID)
		if questID then
			for idx, data in pairs(linear) do
				if data.id == questID then
					return idx
				end
			end
		end
	end;
	
	questLineButton = {
		
		t = {};
		
		onClick = function(self, button)
			if self.questId then
				if self.questId==GuildAdsQuest.currentSelectedQuestId and button~="RightButton" then
					-- same player was clicked = unselect
					GuildAdsQuest.currentSelectedQuestId = nil;
				else
					-- another quest was clicked = select
					GuildAdsQuest.currentSelectedQuestId = self.questId;
				end
				if button=="LeftButton" and IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
					local questLink = "quest:"..self.questId..":"..self.data.l
					local color = GetDifficultyColor(self.data.l);
					color = string.format("ff%2x%2x%2x",color.r*255,color.g*255,color.b*255)
					local questLink = "|c"..color.."|H"..questLink.."|h["..self.data.n.."]|h|r"
					ChatFrameEditBox:Insert(questLink);
				end
				if button == "RightButton" then
					GuildAdsQuest.contextMenu.show(self.data);
				end
				GuildAdsQuest.questButtonsUpdate(self, true);				
			end
		end;

		update = function(button, selected, quest, subPlayer)
			local buttonName= button:GetName();
			
			local groupField = getglobal(buttonName.."Group");
			local nameField = getglobal(buttonName.."Name");
			local tagField = getglobal(buttonName.."Tag");
			local playerField = getglobal(buttonName.."Player");
			local levelField = getglobal(buttonName.."Level");
			local textureField = getglobal(buttonName.."Texture");

			local datatype = GuildAdsDB.profile.Quest;

			local expanded
			if subPlayer > 0 and subPlayer <= #quest.p then
				expanded = true
			end

			if selected and not expanded then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			if expanded then
				groupField:SetText("   "..quest.g);
			else
				groupField:SetText(quest.g);
			end
			local color = QuestDifficultyColor["header"];
			groupField:SetTextColor(color.r, color.g, color.b);
			groupField:Show();
			
			local dcolor = GetDifficultyColor(quest.l);
			local color = new_kv("r", dcolor.r, "g", dcolor.g, "b", dcolor.b)
			if expanded and quest.c then
				local c = quest.c
				if type(c)=="table" then
					c = c[quest.p[subPlayer]]
				end
				local start,_,a,r,g,b=string.find(c, "(..)(..)(..)(..)")
				if start then
					color.r = tonumber(r,16)/255
					color.g = tonumber(g,16)/255
					color.b = tonumber(b,16)/255
				end
			end
			nameField:SetTextColor(color.r, color.g, color.b);
			nameField:SetText(quest.n);
			nameField:Show();
			GuildAdsQuestTagDummyText:SetText(quest.n);
			
			-- questTag
			local isDaily
			if type(quest.s) ~= "table" then
				isDaily = quest.s
			else
				if expanded then
					isDaily = quest.s[quest.p[subPlayer]]
				else
					isDaily = select(2,next(quest.s)) -- just pick the first one
				end
			end
			isDaily = bit.band(isDaily, 4)==4 and true or false
			
			local isComplete
			if expanded then
				if type(quest.s) ~= "table" then
					isComplete = bit.band(quest.s, 3) - 1
				else
					isComplete = bit.band(quest.s[quest.p[subPlayer]], 3) - 1
				end
			else
				isComplete = 0
			end
			local questTag = GuildAdsDB.profile.Quest:GetVerboseQuestTag(quest.r)
			if ( isComplete and isComplete < 0 ) then
				questTag = FAILED;
			elseif ( isComplete and isComplete > 0 ) then
				questTag = COMPLETE;
			elseif ( isDaily ) then
				if ( questTag ) then
					questTag = format(DAILY_QUEST_TAG_TEMPLATE, questTag);
				else
					questTag = DAILY;
				end
			end
			if questTag then
				tagField:SetText("("..questTag..")");
				
				-- Shrink text to accomodate quest tags without wrapping or overlapping
				local tempWidth = 200 - 10 - tagField:GetWidth();
				local textWidth;
				
				if ( GuildAdsQuestTagDummyText:GetWidth() > tempWidth ) then
					textWidth = tempWidth;
				else
					textWidth = QuestLogDummyText:GetWidth();
				end
				
				nameField:SetWidth(textWidth);
				
			else
				nameField:SetWidth(200); -- Must match XML file
				tagField:SetText("");
			end
			tagField:SetTextColor(color.r, color.g, color.b);
			tagField:Show();
			
		
			-- online/offline highlight
			local player = quest.p
			if expanded then
				if type(player)~="string" then
					player = quest.p[subPlayer]
				end
			end
			if type(player)=="string" then
				ownerColor = GuildAdsUITools:GetPlayerColor(player)
				playerField:SetText(player);
			else
				ga_table_erase(GuildAdsQuest.questLineButton.t);
				local online, accountOnline, atLeastOneOnline, atLeastOneOnlineAccount;
				for _, name in ipairs(quest.p) do
					online = GuildAdsComm:IsOnLine(name);
					accountOnline = GuildAdsUITools:IsAccountOnline(name)
					atLeastOneOnline = atLeastOneOnline or online
					atLeastOneOnlineAccount = atLeastOneOnlineAccount or accountOnline
					local _, c = GuildAdsUITools:GetPlayerColor(name)
					tinsert(GuildAdsQuest.questLineButton.t, c..name.."|r")
				end
				if atLeastOneOnline then
					ownerColor = GuildAdsUITools.onlineColor[true]
				elseif atLeastOneOnlineAccount then
					ownerColor = GuildAdsUITools.accountOnlineColor[true]
				else
					ownerColor = GuildAdsUITools.onlineColor[false]
				end
				playerField:SetText(table.concat(GuildAdsQuest.questLineButton.t, ", "));
			end
			playerField:SetTextColor(ownerColor.r, ownerColor.g, ownerColor.b);
			playerField:Show();
			getglobal(buttonName.."Highlight"):SetVertexColor(ownerColor.r, ownerColor.g, ownerColor.b);
						
			levelField:SetText(quest.l)
			levelField:Show()
			
			del(color)
		end;
		
		onEnter = function(self, button)
			if self.questId then
				-- show quest tooltip
				local questLink = "quest:"..self.questId..":"..self.data.l
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
				GameTooltip:SetHyperlink(questLink);
			end
		end;
	};
	
	---------------------------------------------------------------------------------
	--
	-- context menu
	--
	---------------------------------------------------------------------------------	
	contextMenu = {
		
		onLoad = function()
			HideDropDownMenu(1);
			GuildAdsQuestContextMenu.initialize = GuildAdsQuest.contextMenu.initialize;
			GuildAdsQuestContextMenu.displayMode = "MENU";
		end;
	
		show = function(data)
			HideDropDownMenu(1);
			GuildAdsQuestContextMenu.name = "Title";
			GuildAdsQuestContextMenu.data = data;
			ToggleDropDownMenu(1, nil, GuildAdsQuestContextMenu, "cursor");	
		end;
		
		addPlayer = function(playerName)
			local _, color = GuildAdsUITools:GetPlayerColor(playerName);
			local info = new();
			info.text =  color..playerName.."|r";
			info.value = playerName;
			info.notCheckable = 1;
			--info.notClickable = 1; --will make the button white...
			info.hasArrow = 1;
			-- info.func = ToggleDropDownMenu;
			-- info.arg1 = 2;
			-- info.arg2 = playerName
			UIDropDownMenu_AddButton(info, 1);
			del(info)
		end;
		
		initialize = function(frame, level)
			if level==1 then
				if type(GuildAdsQuestContextMenu.data.p)=="string" then
					GuildAdsPlayerMenu.initialize(GuildAdsQuestContextMenu.data.p, 1);
				elseif type(GuildAdsQuestContextMenu.data.p)=="table" then
					for _, name in ipairs(GuildAdsQuestContextMenu.data.p) do
						GuildAdsQuest.contextMenu.addPlayer(name);
					end
				end
			else
				GuildAdsPlayerMenu.initialize(UIDROPDOWNMENU_MENU_VALUE, level);
			end
		end
	};
	
	data = {
		cache = nil;
		cacheTree = nil;
		
		resetCache = function()
			GuildAdsQuest.data.cacheReset = true
		end;
		
		get = function(updateData)
			local ret = GuildAdsQuest.data.get2(updateData)
			if #ret == 0 then
				GuildAdsQuest.currentSelectedQuestId = nil
				ret = GuildAdsQuest.data.get2(true);
			end
			return ret
		end;
		
		get2 = function(updateData)
			if GuildAdsQuest.data.cache==nil or updateData==true or GuildAdsQuest.data.cacheReset==true then
				GuildAdsQuest.data.cacheReset = false
				local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
				
				-- reuse table to avoid memory fragmentation
				deepDel(GuildAdsQuest.data.cache)
				workingTable = new()
				
				-- create linear list of all quests				
				local datatype = GuildAdsDB.profile.Quest;
				for playerName in pairs(players) do
					for questId, _, data in datatype:iterator(playerName, nil) do
						--GuildAdsQuest.debug("playerName = "..playerName.."   questId = "..questId);
						if workingTable[questId] then
							if type(workingTable[questId].s) ~= "table" then
								workingTable[questId].s = new_kv(workingTable[questId].p, workingTable[questId].s )
							end
							workingTable[questId].s[playerName] = data.s
							
							if type(workingTable[questId].c) ~= "table" then
								workingTable[questId].c = new_kv(workingTable[questId].p, workingTable[questId].c)
							end
							workingTable[questId].c[playerName] = data.c

							if type(workingTable[questId].p) ~= "table" then
								workingTable[questId].p = new(workingTable[questId].p)
							end
							tinsert(workingTable[questId].p, playerName)
						else
							workingTable[questId] = new_kv("id", questId, "g", data.g, "n", data.n, "r", data.r, "l", data.l, "c", data.c, "s", data.s, "p", playerName)
						end
					end
				end
				-- create sortable list
				local tmp = new()
				for questId, data in pairs(workingTable) do
					if type(workingTable[questId].p) == "table" then
						table.sort(data.p, GuildAdsQuest.sortData.predicateFunctions.quester);
					end
					tinsert(tmp, data)
				end
				del(workingTable) -- free memory
				GuildAdsQuest.data.cache = tmp;
				GuildAdsQuest.sortData.doIt(GuildAdsQuest.data.cache);
			end
			return GuildAdsQuest.data.cache ;
		end;
	
	};
	
	sortData = {
			
		current = "level";
		
		current2 = "name";
		
		currentWay = {
			group = "normal",
			name = "up",
			difficulty = "normal",
			player = "normal",
			level = "normal",
		};

		predicateFunctions = {

			group = function(a, b)
				if a.g and b.g then
					if (a.g < b.g) then
						return false;
					elseif (a.g > b.g) then
						return true;
					end
				end
				return nil;
			end;
			
			name = function(a, b)
				if a.n and b.n then
					if (a.n < b.n) then
						return false;
					elseif (a.n > b.n) then
						return true;
					end
				end
				return nil;
			end;
			
			difficulty = function(a, b)
				if ((a.r or "") < (b.r or "")) then
					return false;
				elseif ((a.r or "") > (b.r or "")) then
					return true;
				end
				return nil;
			end;
			
			quester = function(a, b)
				local oa = GuildAdsComm:IsOnLine(a);
				local ob = GuildAdsComm:IsOnLine(b);
				if oa~=ob then
					return oa and not ob;
				end
				oa = GuildAdsUITools:IsAccountOnline(a);
				ob = GuildAdsUITools:IsAccountOnline(b);
				if oa~=ob then
					return oa and not ob;
				end				
				return a<b;
			end;
			
			player = function(a, b)
				if a.p and b.p then
					if type(a.p)=="table" then
						-- take the first on the list (player online, account online, offline)
						local ap = a.p[1]
						local bp = b.p[1]
						-- compare the online status on the first player
						local oa = 	(GuildAdsComm:IsOnLine(ap) and 2) or 
									(GuildAdsUITools:IsAccountOnline(ap) and 1) or
									0
						local ob = 	(GuildAdsComm:IsOnLine(bp) and 2) or 
									(GuildAdsUITools:IsAccountOnline(bp) and 1) or
									0
						if oa~=ob then
							return oa<ob
						end
						-- compare by name
						local ap = table.concat(a.p,", ");	-- BUG : string/table problem
						local bp = table.concat(b.p,", ");
						if ap<bp then
							return false;
						elseif ap>bp then
							return true;
						end
					elseif (type(a.p)=="string") then
						if (a.p < b.p) then
							return false;
						elseif (a.p > b.p) then
							return true;
						end
					end
				end
				return nil;
			end;
			
			level = function(a, b)
				if a and b then
					if tonumber(a.l) < tonumber(b.l) then
						return false;
					elseif tonumber(a.l) > tonumber(b.l) then
						return true;
					end
					return nil;
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
		
		doIt = function(questTable)
 			table.sort(questTable, GuildAdsQuest.sortData.predicate);
		end;
		
		predicate = function(a, b)
			-- primary sort
			result = GuildAdsQuest.sortData.predicateFunctions[GuildAdsQuest.sortData.current](a, b);
			result = GuildAdsQuest.sortData.wayFunctions[GuildAdsQuest.sortData.currentWay[GuildAdsQuest.sortData.current]](result);
			
			-- secondary sort
			if result == nil then
				result = GuildAdsQuest.sortData.predicateFunctions[GuildAdsQuest.sortData.current2](a,b);
				result = GuildAdsQuest.sortData.wayFunctions[GuildAdsQuest.sortData.currentWay[GuildAdsQuest.sortData.current2]](result);
			end
			
			return result or false;
		end;
	};

}

GuildAdsPlugin.UIregister(GuildAdsQuest);