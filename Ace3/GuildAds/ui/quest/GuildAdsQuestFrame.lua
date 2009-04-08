----------------------------------------------------------------------------------
--
-- GuildAdsQuestFrame.lua
--
-- Author: Galmok of Stormrage-EU (horde)
-- URL : http://guildads.sourceforge.net
-- Email : galmok@gmail.com, guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local F_STICKY = 1
local F_LOCKED = 2
local F_OFFICERONLY = 4

local colors = {
	locked = { 
		[0] = { 1, 209/255, 0, 1 },
		[2] = { 0.8, 0.8, 0.8, 1 }
	},
	officer = {
		[0] = { 0, 0, 0, 0 },
		[4] = { 1, 0, 0, 0.4 }
	}
};

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
				priority = 5
			}
		}
	};

	GUILDADS_NUM_POST_BUTTONS = 8;
	GUILDADS_POSTBUTTONSIZEY = 16;
	
	-- initial values are nil. These lines are just to remember which variables to look out for.
	--currentSelectedPostId = nil; 
	--replyID = nil;
	--newPostID = nil;
	
	onInit = function()
		GuildAdsQuest.libCompress=LibStub:GetLibrary("LibCompress");
		
		GuildAdsQuest.UpdatePermissions();
		GuildAdsQuest.updateButtons();
	end;
	
	onShow = function()
		GuildAdsQuest.postButtonsUpdate();
	end;
	
	onConfigChanged = function(path, key, value)
	end;
	
	onDBUpdate = function(dataType, playerName, id)
		GuildAdsQuest.data.resetCache();
		GuildAdsQuest.delayedUpdate();
		-- if window is open, update it
		--GuildAdsQuest.postButtonsUpdate();
		--GuildAdsQuest.updateButtons();
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
		--GuildAdsDB.profile.Main:unregisterUpdate(GuildAdsGuild.onDBUpdate);
		--GuildAdsDB.channel[GuildAds.channelName]:unregisterEvent(GuildAdsGuild.onPlayerListUpdate);
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
			-- update forum posting lines
			GuildAdsQuest.postButtonsUpdate();
			-- update selected forum post ONLY if a new post isn't being written
			-- NOT written yet (no update happens)
			-- GuildAdsQuest.updateButtons()
		end
	end;
	
	-- update display post (lower 2/3 of forum UI)
	updateButtons = function(data)
		if GuildAdsQuestFrame:IsVisible() then
			if not GuildAdsQuest.currentSelectedPostId or not data then
				-- no post selected
				GuildAdsQuestBodyText:SetText("");
				GuildAdsQuestSubjectEditBox:SetText("");
				GuildAdsQuestStickyCheckButton:SetChecked(0);
				GuildAdsQuestLockedCheckButton:SetChecked(0);
				GuildAdsQuestOfficerCheckButton:SetChecked(0);
				GuildAdsQuestNewPostButton:Enable();
				GuildAdsQuestReplyButton:Disable();
				GuildAdsQuestPostButton:SetText(GUILDADS_FORUM_POST);
				GuildAdsQuestPostButton:Disable();
			else
				-- some post selected
				local checksumOK, text = GuildAdsQuest.decompressWithChecksumCheck(data.d or "")
				if checksumOK then
					-- some form of highlighting here
				end
				GuildAdsQuestBodyText:SetText(text);
				GuildAdsQuestBodyText:SetCursorPosition(0);
				GuildAdsQuestSubjectEditBox:SetText(data.s or "");
				GuildAdsQuestStickyCheckButton:SetChecked(bit.band(data.f or 0, F_STICKY)==F_STICKY and 1 or 0);
				GuildAdsQuestLockedCheckButton:SetChecked(bit.band(data.f or 0, F_LOCKED)==F_LOCKED and 1 or 0);
				GuildAdsQuestOfficerCheckButton:SetChecked(bit.band(data.f or 0, F_OFFICERONLY)==F_OFFICERONLY and 1 or 0);
				GuildAdsQuestNewPostButton:Enable();
				if bit.band(data.f or 0, F_LOCKED)==F_LOCKED then
					GuildAdsQuestReplyButton:Disable();
				else
					GuildAdsQuestReplyButton:Enable();
				end
				local start, _, expectedAuthor = string.find(GuildAdsQuest.currentSelectedPostId, "([^:]+)[0-9]+$");
				if expectedAuthor == GuildAds.playerName then
					GuildAdsQuestPostButton:SetText(GUILDADS_FORUM_EDITPOST);
					GuildAdsQuestPostButton:Enable();
				else
					GuildAdsQuestPostButton:SetText(GUILDADS_FORUM_POST);
					GuildAdsQuestPostButton:Disable();
				end
			end
		end
	end;
	
	UpdatePermissions = function()
		-- am I allowed to read officer notes?
		if CanViewOfficerNote() then
			GuildAdsQuest.viewOfficer = true
			GuildAdsQuestOfficerCheckButton:Show();
		else
			GuildAdsQuest.viewOfficer = false
			GuildAdsQuestOfficerCheckButton:Hide();
		end
		
		if CanEditOfficerNote() then
			GuildAdsQuest.editOfficer = true
			GuildAdsQuestStickyCheckButton:Enable();
			GuildAdsQuestLockedCheckButton:Enable();
			GuildAdsQuestOfficerCheckButton:Enable();
		else
			GuildAdsQuest.editOfficer = false
			GuildAdsQuestStickyCheckButton:Disable();
			GuildAdsQuestLockedCheckButton:Disable();
			GuildAdsQuestOfficerCheckButton:Disable();
		end
	end;
		
	sortPosts = function(sortValue)
		GuildAdsQuest.sortData.current = sortValue;
		if (GuildAdsQuest.sortData.currentWay[sortValue]=="normal") then 
			GuildAdsQuest.sortData.currentWay[sortValue]="up";
		else 
			GuildAdsQuest.sortData.currentWay[sortValue]="normal";
		end
		GuildAdsQuest.postButtonsUpdate(nil, true);
	end;
	
	-- update forum posting lines (upper 1/3 of forum UI)
	postButtonsUpdate = function(self, updateData)
		--if GuildAdsQuestFrame:IsVisible() then
			GuildAdsQuest.debug("postButtonsUpdate("..tostring(updateData)..")");
			local offset = FauxScrollFrame_GetOffset(GuildAdsQuestPostLineScrollFrame);
		
			local linear = GuildAdsQuest.data.get(updateData);
			local linearSize = #linear;
	
			-- init
			local i = 1;
			local j = i + offset;
			local currentPost, currentSelection, button;
			
			-- for each buttons
			while (i <= GuildAdsQuest.GUILDADS_NUM_POST_BUTTONS) do
				button = getglobal("GuildAdsQuestPostLineButton"..i);
				
				currentPost = linear[j];
				j = j +1;
				
				if (currentPost ~= nil) then
					button.postId = currentPost.id;
					button.data = currentPost;
					
					currentSelection = GuildAdsQuest.currentSelectedPostId;
					GuildAdsQuest.postLineButton.update(button, currentSelection==currentPost.id, currentPost);
					button:Show();
				else
					button.postId = nil;
					button.data = nil;
					button:Hide();
				end;
				i = i+1;
			end;
			FauxScrollFrame_Update(GuildAdsQuestPostLineScrollFrame, linearSize, GuildAdsQuest.GUILDADS_NUM_POST_BUTTONS, GuildAdsQuest.GUILDADS_POSTBUTTONSIZEY);
		--end;
	end;
				
	postLineButton = {
		
		onClick = function(self, button)
			if self.postId then
				if self.postId==GuildAdsQuest.currentSelectedPostId and button~="RightButton" then
					-- same player was clicked = unselect
					GuildAdsQuest.currentSelectedPostId = nil;
				else
					-- another player was clicked = select
					GuildAdsQuest.currentSelectedPostId = self.postId;
					-- mark selected post as read
					local datatype = GuildAdsDB.profile.Quest;
					datatype:markAsRead(self.data.a, self.data.id)
				end
				if button == "RightButton" then
					GuildAdsQuest.contextMenu.show(self.data);
				end

				GuildAdsQuest.updateButtons(self.data);
				GuildAdsQuest.postButtonsUpdate(self, true);				
			end
		end;

		update = function(button, selected, post)
			local buttonName= button:GetName();
			
			local groupField = getglobal(buttonName.."Group");
			local nameField = getglobal(buttonName.."Name");
			local typeField = getglobal(buttonName.."Type");
			local textureField = getglobal(buttonName.."Texture");

			local datatype = GuildAdsDB.profile.Quest;

			if selected then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			
			--local ocolor = colors.officer[bit.band(post.f or 0, F_OFFICERONLY)]
			--textureField:SetTexture(ocolor[1], ocolor[2], ocolor[3], ocolor[4]);

			--local lcolor = colors.locked[bit.band(post.f or 0, F_LOCKED)]
			local groupText = post.g;
			--if bit.band(post.f or 0, F_STICKY)==F_STICKY then
			--	subjectText = "\124TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0\124t" .. subjectText;
			--end
			--subjectText = string.rep("   ",(post.l or 1)-1)..subjectText;
			groupField:SetText(groupText);
			--subjectField:SetTextColor(lcolor[1], lcolor[2], lcolor[3], lcolor[4]);
			--if not datatype:isRead(post.a, post.id) then
			--if post.n then
			--	subjectField:SetFontObject("Tooltip_Med")
			--else
			--	subjectField:SetFontObject("GameFontNormalSmall")
			--end
			groupField:Show();
			
			local _, colorHex = GuildAdsUITools:GetPlayerColor(post.a)
			nameField:SetText(colorHex..post.a.."|r");
			nameField:Show();
			
			typeField:SetText(GuildAdsDB:FormatTime(post.t or 0));
			typeField:Show();
			
		end;
	};
	
	---------------------------------------------------------------------------------
	--
	-- context menu
	--
	---------------------------------------------------------------------------------	
	contextMenu = {
	
		onLoad = function()
			GuildAdsQuestContextMenu.initialize = GuildAdsQuest.contextMenu.initialize;
			GuildAdsQuestContextMenu.displayMode = "MENU";
		end;
	
		show = function(data)
			HideDropDownMenu(1);
			GuildAdsQuestContextMenu.name = "Title";
			GuildAdsQuestContextMenu.data = data;
			ToggleDropDownMenu(1, nil, GuildAdsQuestContextMenu, "cursor");
		end;
		
		initialize = function()
			-- default menu
			GuildAdsPlayerMenu.header(GuildAdsQuestContextMenu.data.a, 1);
			GuildAdsPlayerMenu.menus(GuildAdsQuestContextMenu.data.a, 1);
			-- 
			if CanGuildRemove() then
				info = UIDropDownMenu_CreateInfo();
				info.text = GUILDADS_FORUM_DELETEPOST;
				info.notCheckable = 1;
				info.value = GuildAdsQuestContextMenu.data;
				info.func = GuildAdsQuest.contextMenu.deletePost;
				UIDropDownMenu_AddButton(info, 1);
			end
			
			GuildAdsPlayerMenu.footer(GuildAdsQuestContextMenu.data.a, 1);
		end;
		
		deletePost = function(self)
			if self.value then
				GuildAdsGuild.debug("Deleting post by "..self.value.a.." (id="..self.value.id..") from GuildAds database");
				local datatype = GuildAdsDB.profile.Quest;
				if self.value.a and self.value.id then
					datatype:set(self.value.a, self.value.id, nil);
				end
			end
		end;
			
	};

	
	data = {
		cache = nil;
		cacheTree = nil;
		
		resetCache = function()
			GuildAdsQuest.data.cache = nil;
		end;
		
		get = function(updateData)
			local ret = GuildAdsQuest.data.get2(updateData)
			if #ret == 0 then
				GuildAdsQuest.currentSelectedPostId = nil
				ret = GuildAdsQuest.data.get2(true);
			end
			return ret
		end;
		
		get2 = function(updateData)
			if GuildAdsQuest.data.cache==nil or updateData==true then
				-- delete old postID (should it exist)
				GuildAdsQuest.postID=nil
				-- calculate reply and post ID now (less code to maintain)
				local replyID = 0;
				local newPostID = 0;
				
				local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
				
				-- make table with parent and grandparent post id's of the selected post id.
				local parentTable = {}
				if GuildAdsQuest.currentSelectedPostId then
					local t = ""
					for k,v in pairs({strsplit(":", GuildAdsQuest.currentSelectedPostId)}) do
						t = t..v
						parentTable[t]=true;
						t = t..":"
					end
				end
				
				GuildAdsQuest:UpdatePermissions();
				
				-- create linear list of visible posts
				local workingTable = {}
				local unreadPosts = {}
				local datatype = GuildAdsDB.profile.Quest;
				for postid in datatype:iteratorIds() do
					local start, _, expectedAuthor = string.find(postid, "([^:]*)[0-9]*$");
					local data, author = nil, nil;
					if expectedAuthor and players[expectedAuthor] then
						author = expectedAuthor;
						data = datatype:get(author, postid);
					end
					if not data then
						for actualAuthor, postid, postdata in datatype:iterator(nil, postid) do
							if players[actualAuthor] then
								data = postdata;
								author = actualAuthor;
								break;
							end
						end
					end
					if data then
						-- find largest number in the id's of root posts
						local start, _, number = string.find(postid, "^[^:]-([0-9]+)$");
						if number and tonumber(number) > newPostID then
							newPostID = tonumber(number);
						end
						-- find largest number in the id's of replies to the current selected post
						if GuildAdsQuest.currentSelectedPostId then
							start, _, number = string.find(postid, "^"..GuildAdsQuest.currentSelectedPostId..":[^:]-([0-9]+)$");
							if number and tonumber(number) > replyID then
								replyID = tonumber(number);
							end							
						end
					   if (bit.band(data.f or 0, F_OFFICERONLY)==0 or 
					    (bit.band(data.f or 0, F_OFFICERONLY)==F_OFFICERONLY and GuildAdsQuest.viewOfficer)) then 
						local level = select("#", string.split(":",postid))
						local visiblePost = false
						if GuildAdsQuest.currentSelectedPostId then
							-- show any 1. level replies to the selected post
							start = string.find(postid, "^"..GuildAdsQuest.currentSelectedPostId..":[^:]*$");
							if not start and GuildAdsQuest.currentSelectedPostId == postid then
								-- always show the selected post
								start = true
							end
							-- select the parent posts
							if not start then
								if parentTable[postid] then
									start = true;
								end
							end
							if start then
								visiblePost = true;
							end
						else
							-- show root posts
							start = string.find(postid, ":");
							if not start then
								visiblePost = true;
							end
						end
						if visiblePost then
							tinsert(workingTable, { id=postid, l=level, t=data.t, a=author, s=data.s, d=data.d, f=data.f, n=data.n});
						end
						if data.n then
							unreadPosts[postid] = true;
							local t=""
							for k in string.gmatch(postid, "([^:]+):") do
								t=t..k
								unreadPosts[t] = true
								t=t..":"
							end
						end
					   end
					end
				end
				for _, post in pairs(workingTable) do
					if unreadPosts[post.id] then
						GuildAdsQuest.debug("post.id = "..post.id)
						post.n = true
					end
				end
				GuildAdsQuest.newPostID = GuildAds.playerName..tostring((newPostID + 1));
				if GuildAdsQuest.currentSelectedPostId then
					GuildAdsQuest.replyID = GuildAdsQuest.currentSelectedPostId..":"..GuildAds.playerName..tostring((replyID + 1));
				else
					GuildAdsQuest.replyID = nil;
				end
				GuildAdsQuest.data.cache = workingTable;
				GuildAdsQuest.sortData.doIt(GuildAdsQuest.data.cache);
			end
			return GuildAdsQuest.data.cache ;
		end;
	
	};
	
	sortData = {
			
		current = "group";
	
		currentWay = {
			group = "normal",
			name = "normal",
			type = "normal",
		};

		predicateFunctions = {

			group = function(a, b)
				if a.g and not b.g then
					return true;
				elseif not a.g and b.g then
					return false;
				else
					return GuildAdsQuest.sortData.predicateFunctions.name(a, b);
				end
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
			
			type = function(a, b)
				if a.t and b.t then
					if (a.t < b.t) then
						return false;
					elseif (a.t > b.t) then
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
		
		doIt = function(postTable)
 			table.sort(postTable, GuildAdsQuest.sortData.predicate);
		end;
		
		predicate = function(a, b)
			-- nil references are always less than
			local result = GuildAdsQuest.sortData.byNilAA(a, b);
			if result~=nil then
				return result;
			end
			-- parent posts always on top
			local result = GuildAdsQuest.sortData.byLevel(a, b);
			if result~=nil then
				return result;
			end
			-- sticky posts listed first
			local result = GuildAdsQuest.sortData.bySticky(a, b);
			if result~=nil then
				return result;
			end
			
			result = GuildAdsQuest.sortData.predicateFunctions[GuildAdsQuest.sortData.current](a, b);
			result = GuildAdsQuest.sortData.wayFunctions[GuildAdsQuest.sortData.currentWay[GuildAdsQuest.sortData.current]](result);
			
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
		
		-- post depth, not player level
		byLevel = function(a, b)
			if a and b then
				if a.l < b.l then
					return true;
				elseif a.l > b.l then
					return false;
				end
				return nil;
			end
		end;
		
		bySticky = function(a, b)
			if a and b then
				local as=bit.band(a.f or 0, F_STICKY);
				local bs=bit.band(b.f or 0, F_STICKY);
				if as < bs then
					return false;
				elseif as > bs then
					return true;
				end
			end
			return nil;
		end;
	};

	newPostButtonClicked = function()
		-- make sure we operate on the newest data
		GuildAdsQuest.postButtonsUpdate(self, true);
		
		-- data.get has calculated newPostID. Make a short verification of validity.
		local start, _ = string.find(GuildAdsQuest.newPostID, "^[^:]+[0-9]+$");
		if start then
			GuildAdsQuestBodyText:SetText("Enter subject here");
			GuildAdsQuestBodyText:HighlightText();
			GuildAdsQuestSubjectEditBox:SetText("Enter message here");
			GuildAdsQuestSubjectEditBox:HighlightText();
			GuildAdsQuestSubjectEditBox:SetFocus();
			GuildAdsQuestStickyCheckButton:SetChecked(0);
			GuildAdsQuestLockedCheckButton:SetChecked(0);
			GuildAdsQuestOfficerCheckButton:SetChecked(0);
			GuildAdsQuestReplyButton:Disable();
			GuildAdsQuestNewPostButton:Disable();
			GuildAdsQuestPostButton:SetText(GUILDADS_FORUM_POST);
			GuildAdsQuestPostButton:Enable();
			GuildAdsQuest.postID = GuildAdsQuest.newPostID;
		end
	end;
	
	replyButtonClicked = function()
		if GuildAdsQuest.replyID then
			GuildAdsQuestBodyText:SetText("Enter subject here");
			GuildAdsQuestBodyText:HighlightText();
			GuildAdsQuestSubjectEditBox:SetText("Enter message here");
			GuildAdsQuestSubjectEditBox:HighlightText();
			GuildAdsQuestSubjectEditBox:SetFocus();
			GuildAdsQuestStickyCheckButton:SetChecked(0);
			GuildAdsQuestLockedCheckButton:SetChecked(0);
			GuildAdsQuestOfficerCheckButton:SetChecked(0);
			GuildAdsQuestReplyButton:Disable();
			GuildAdsQuestNewPostButton:Disable();
			GuildAdsQuestPostButton:SetText(GUILDADS_FORUM_POST);
			GuildAdsQuestPostButton:Enable();
			GuildAdsQuest.postID = GuildAdsQuest.replyID;
		end
	end;
	
	-- returns two checksum bytes
	calcChecksum = function(str)
		local checksum = GuildAdsHash:fcs16init();
		checksum = GuildAdsHash:fcs16update(checksum, str or "");
		checksum = GuildAdsHash:fcs16final(checksum);
		return string.char(bit.band(checksum,255))..string.char(bit.band(bit.rshift(checksum,8),255));
	end;
	
	-- 
	decompressWithChecksumCheck = function(data)
		if type(data)=="string" and #data >= 2 then
			local checksumBytes = data:sub(-2)
			local text = data:sub(1, #data-2)
			text = GuildAdsQuest.libCompress:Decode7bit(text or "");
			text = GuildAdsQuest.libCompress:Decompress(text or "");
			if GuildAdsQuest.calcChecksum(text) == checksumBytes then
				return true, text
			end
		end
		return nil, "Checksum mismatch"
	end;
	
	postButtonClicked = function()
		if GuildAdsQuest.postID then
			local data = {}
			data.s = GuildAdsQuestSubjectEditBox:GetText();
			data.d = GuildAdsQuestBodyText:GetText();
			local checksum = GuildAdsQuest.calcChecksum(data.d);
			data.d = GuildAdsQuest.libCompress:Compress(data.d); -- this will make the data use at most 1 byte more and hopefully somewhat less
			data.d = GuildAdsQuest.libCompress:Encode7bit(data.d); -- this will expand data approx 14% in memory, BUT use approx 35% less bandwidth than raw compressed data
			data.d = data.d..checksum;
			data.t = GuildAdsDB:GetCurrentTime();
			data.f = bit.bor(bit.bor(GuildAdsQuestStickyCheckButton:GetChecked() and 1 or 0, 
						GuildAdsQuestLockedCheckButton:GetChecked() and 2 or 0),
						GuildAdsQuestOfficerCheckButton:GetChecked() and 4 or 0);
			
			local datatype = GuildAdsDB.profile.Quest;
			datatype:set(GuildAds.playerName, GuildAdsQuest.postID, data);
			if GuildAdsQuest.postID == GuildAdsQuest.newPostID then
				GuildAdsQuest.currentSelectedPostId = nil;
			end
			GuildAdsQuest.postID = nil
			GuildAdsQuestSubjectEditBox:ClearFocus();
			GuildAdsQuestBodyText:ClearFocus();
			GuildAdsQuest.updateButtons();
			GuildAdsQuest.postButtonsUpdate(self, true);
		end
		if GuildAdsQuestPostButton:GetText() == GUILDADS_FORUM_EDITPOST then
			GuildAdsQuestPostButton:SetText(GUILDADS_FORUM_POST)
			GuildAdsQuest.postID = GuildAdsQuest.currentSelectedPostId
			GuildAdsQuestSubjectEditBox:SetFocus();
			GuildAdsQuestReplyButton:Disable();
			GuildAdsQuestNewPostButton:Disable();
			GuildAdsQuestPostButton:Enable();
		end

	end;
}

GuildAdsPlugin.UIregister(GuildAdsQuest);