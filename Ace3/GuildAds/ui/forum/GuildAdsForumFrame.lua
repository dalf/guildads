----------------------------------------------------------------------------------
--
-- GuildAdsForumFrame.lua
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

GuildAdsForum = {
	metaInformations = { 
		name = "Forum",
        	guildadsCompatible = 100,
		ui = {
			main = {
				frame = "GuildAdsForumFrame",
				tab = "GuildAdsForumTab",
				tooltiptitle = GUILDADSTOOLTIPS_FORUM_TITLE,
                		tooltip = GUILDADSTOOLTIPS_FORUM,--"Guild tab",
				priority = 60
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
		GuildAdsForum.libCompress=LibStub:GetLibrary("LibCompress");
		
		GuildAdsForum.UpdatePermissions();
		GuildAdsForum.updateButtons();
	end;
	
	onShow = function()
		GuildAdsForum.postButtonsUpdate();
	end;
	
	onConfigChanged = function(path, key, value)
	end;
	
	onDBUpdate = function(dataType, playerName, id)
		GuildAdsForum.data.resetCache();
		GuildAdsForum.delayedUpdate();
		-- if window is open, update it
		--GuildAdsForum.postButtonsUpdate();
		--GuildAdsForum.updateButtons();
	end;
	
	onReceivedTransaction = function(dataType, playerName, newKeys, deletedKeys)
		GuildAdsForum.data.resetCache();
		GuildAdsForum.delayedUpdate();
		if newKeys and #newKeys>0 then
			for _, id in pairs(newKeys) do
				GuildAdsMinimapButtonCore.addAlertText("Forum: New posting by "..tostring(playerName));
			end
		end
	end;
	
	onChannelJoin = function()
		GuildAdsDB.channel[GuildAds.channelName].Forum:registerUpdate(GuildAdsForum.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName].Forum:registerTransactionReceived(GuildAdsForum.onReceivedTransaction);
		GuildAdsForum.delayedUpdate();
	end;
	
	onChannelLeave = function()
		GuildAdsDB.channel[GuildAds.channelName].Forum:unregisterUpdate(GuildAdsForum.onDBUpdate);
		GuildAdsDB.channel[GuildAds.channelName].Forum:unregisterTransactionReceived(GuildAdsForum.onReceivedTransaction);
		--GuildAdsDB.profile.Main:unregisterUpdate(GuildAdsGuild.onDBUpdate);
		--GuildAdsDB.channel[GuildAds.channelName]:unregisterEvent(GuildAdsGuild.onPlayerListUpdate);
		GuildAdsForum.delayedUpdate();
	end;
	
	onUpdate = function(self, elapsed)
		if self.update then
			self.update = self.update - elapsed;
			if self.update<=0 then
				self.update = nil;
				GuildAdsForum.updateWindow();
			end;
		end;
	end;

	delayedUpdate = function()
		GuildAdsForumFrame.update = 1;
	end;
	
	updateWindow = function()
		GuildAdsTrade.debug("updateWindow");
		if GuildAdsForumFrame and GuildAdsForumFrame.IsVisible and GuildAdsForumFrame:IsVisible() then
			-- update forum posting lines
			GuildAdsForum.postButtonsUpdate();
			-- update selected forum post ONLY if a new post isn't being written
			-- NOT written yet (no update happens)
			-- GuildAdsForum.updateButtons()
		end
	end;
	
	-- update display post (lower 2/3 of forum UI)
	updateButtons = function(data)
		if GuildAdsForumFrame:IsVisible() then
			if not GuildAdsForum.currentSelectedPostId or not data then
				-- no post selected
				GuildAdsForumBodyText:SetText("");
				GuildAdsForumSubjectEditBox:SetText("");
				GuildAdsForumStickyCheckButton:SetChecked(0);
				GuildAdsForumLockedCheckButton:SetChecked(0);
				GuildAdsForumOfficerCheckButton:SetChecked(0);
				GuildAdsForumNewPostButton:Enable();
				GuildAdsForumReplyButton:Disable();
				GuildAdsForumPostButton:SetText(GUILDADS_FORUM_POST);
				GuildAdsForumPostButton:Disable();
			else
				-- some post selected
				local checksumOK, text = GuildAdsForum.decompressWithChecksumCheck(data.d or "")
				if checksumOK then
					-- some form of highlighting here
				end
				GuildAdsForumBodyText:SetText(text);
				GuildAdsForumBodyText:SetCursorPosition(0);
				GuildAdsForumSubjectEditBox:SetText(data.s or "");
				GuildAdsForumStickyCheckButton:SetChecked(bit.band(data.f or 0, F_STICKY)==F_STICKY and 1 or 0);
				GuildAdsForumLockedCheckButton:SetChecked(bit.band(data.f or 0, F_LOCKED)==F_LOCKED and 1 or 0);
				GuildAdsForumOfficerCheckButton:SetChecked(bit.band(data.f or 0, F_OFFICERONLY)==F_OFFICERONLY and 1 or 0);
				GuildAdsForumNewPostButton:Enable();
				if bit.band(data.f or 0, F_LOCKED)==F_LOCKED then
					GuildAdsForumReplyButton:Disable();
				else
					GuildAdsForumReplyButton:Enable();
				end
				local start, _, expectedAuthor = string.find(GuildAdsForum.currentSelectedPostId, "([^:]-)[0-9]+$");
				if expectedAuthor == GuildAds.playerName then
					GuildAdsForumPostButton:SetText(GUILDADS_FORUM_EDITPOST);
					GuildAdsForumPostButton:Enable();
				else
					GuildAdsForumPostButton:SetText(GUILDADS_FORUM_POST);
					GuildAdsForumPostButton:Disable();
				end
			end
		end
	end;
	
	UpdatePermissions = function()
		-- am I allowed to read officer notes?
		if CanViewOfficerNote() then
			GuildAdsForum.viewOfficer = true
			GuildAdsForumOfficerCheckButton:Show();
		else
			GuildAdsForum.viewOfficer = false
			GuildAdsForumOfficerCheckButton:Hide();
		end
		
		if CanEditOfficerNote() then
			GuildAdsForum.editOfficer = true
			GuildAdsForumStickyCheckButton:Enable();
			GuildAdsForumLockedCheckButton:Enable();
			GuildAdsForumOfficerCheckButton:Enable();
		else
			GuildAdsForum.editOfficer = false
			GuildAdsForumStickyCheckButton:Disable();
			GuildAdsForumLockedCheckButton:Disable();
			GuildAdsForumOfficerCheckButton:Disable();
		end
	end;
		
	sortPosts = function(sortValue)
		GuildAdsForum.sortData.current = sortValue;
		if (GuildAdsForum.sortData.currentWay[sortValue]=="normal") then 
			GuildAdsForum.sortData.currentWay[sortValue]="up";
		else 
			GuildAdsForum.sortData.currentWay[sortValue]="normal";
		end
		GuildAdsForum.postButtonsUpdate(nil, true);
	end;
	
	-- update forum posting lines (upper 1/3 of forum UI)
	postButtonsUpdate = function(self, updateData)
		--if GuildAdsForumFrame:IsVisible() then
			GuildAdsForum.debug("postButtonsUpdate("..tostring(updateData)..")");
			local offset = FauxScrollFrame_GetOffset(GuildAdsForumPostLineScrollFrame);
		
			local linear = GuildAdsForum.data.get(updateData);
			local linearSize = #linear;
	
			-- init
			local i = 1;
			local j = i + offset;
			local currentPost, currentSelection, button;
			
			-- for each buttons
			while (i <= GuildAdsForum.GUILDADS_NUM_POST_BUTTONS) do
				button = getglobal("GuildAdsForumPostLineButton"..i);
				
				currentPost = linear[j];
				j = j +1;
				
				if (currentPost ~= nil) then
					button.postId = currentPost.id;
					button.data = currentPost;
					
					currentSelection = GuildAdsForum.currentSelectedPostId;
					GuildAdsForum.postLineButton.update(button, currentSelection==currentPost.id, currentPost);
					button:Show();
				else
					button.postId = nil;
					button.data = nil;
					button:Hide();
				end;
				i = i+1;
			end;
			FauxScrollFrame_Update(GuildAdsForumPostLineScrollFrame, linearSize, GuildAdsForum.GUILDADS_NUM_POST_BUTTONS, GuildAdsForum.GUILDADS_POSTBUTTONSIZEY);
		--end;
	end;
				
	postLineButton = {
		
		onClick = function(self, button)
			if self.postId then
				if self.postId==GuildAdsForum.currentSelectedPostId and button~="RightButton" then
					-- same player was clicked = unselect
					GuildAdsForum.currentSelectedPostId = nil;
				else
					-- another player was clicked = select
					GuildAdsForum.currentSelectedPostId = self.postId;
					-- mark selected post as read
					local datatype = GuildAdsDB.channel[GuildAds.channelName].Forum;
					datatype:markAsRead(self.data.a, self.data.id)
				end
				if button == "RightButton" then
					GuildAdsForum.contextMenu.show(self.data);
				end

				GuildAdsForum.updateButtons(self.data);
				GuildAdsForum.postButtonsUpdate(self, true);				
			end
		end;

		update = function(button, selected, post)
			local buttonName= button:GetName();
			
			local subjectField = getglobal(buttonName.."Subject");
			local authorField = getglobal(buttonName.."Author");
			local dateField = getglobal(buttonName.."Date");
			local textureField = getglobal(buttonName.."Texture");

			local datatype = GuildAdsDB.channel[GuildAds.channelName].Forum;

			if selected then
				button:LockHighlight();
			else
				button:UnlockHighlight();
			end
			
			local ocolor = colors.officer[bit.band(post.f or 0, F_OFFICERONLY)]
			textureField:SetTexture(ocolor[1], ocolor[2], ocolor[3], ocolor[4]);

			local lcolor = colors.locked[bit.band(post.f or 0, F_LOCKED)]
			local subjectText = post.s or GUILDADS_FORUM_EMPTYSUBJECT;
			if bit.band(post.f or 0, F_STICKY)==F_STICKY then
				subjectText = "\124TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0\124t" .. subjectText;
			end
			subjectText = string.rep("   ",(post.l or 1)-1)..subjectText;
			subjectField:SetText(subjectText);
			subjectField:SetTextColor(lcolor[1], lcolor[2], lcolor[3], lcolor[4]);
			--if not datatype:isRead(post.a, post.id) then
			if post.n then
				subjectField:SetFontObject("Tooltip_Med")
			else
				subjectField:SetFontObject("GameFontNormalSmall")
			end
			subjectField:Show();
			
			local _, colorHex = GuildAdsUITools:GetPlayerColor(post.a)
			authorField:SetText(colorHex..post.a.."|r");
			authorField:Show();
			
			dateField:SetText(GuildAdsDB:FormatTime(post.t or 0));
			dateField:Show();
			
		end;
	};
	
	---------------------------------------------------------------------------------
	--
	-- context menu
	--
	---------------------------------------------------------------------------------	
	contextMenu = {
	
		onLoad = function()
			GuildAdsForumContextMenu.initialize = GuildAdsForum.contextMenu.initialize;
			GuildAdsForumContextMenu.displayMode = "MENU";
		end;
	
		show = function(data)
			HideDropDownMenu(1);
			GuildAdsForumContextMenu.name = "Title";
			GuildAdsForumContextMenu.data = data;
			ToggleDropDownMenu(1, nil, GuildAdsForumContextMenu, "cursor");
		end;
		
		initialize = function()
			-- default menu
			GuildAdsPlayerMenu.header(GuildAdsForumContextMenu.data.a, 1);
			GuildAdsPlayerMenu.menus(GuildAdsForumContextMenu.data.a, 1);
			-- 
			if CanGuildRemove() then
				info = UIDropDownMenu_CreateInfo();
				info.text = GUILDADS_FORUM_DELETEPOST;
				info.notCheckable = 1;
				info.value = GuildAdsForumContextMenu.data;
				info.func = GuildAdsForum.contextMenu.deletePost;
				UIDropDownMenu_AddButton(info, 1);
			end
			
			GuildAdsPlayerMenu.footer(GuildAdsForumContextMenu.data.a, 1);
		end;
		
		deletePost = function(self)
			if self.value then
				GuildAdsGuild.debug("Deleting post by "..self.value.a.." (id="..self.value.id..") from GuildAds database");
				local datatype = GuildAdsDB.channel[GuildAds.channelName].Forum;
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
			GuildAdsForum.data.cache = nil;
		end;
		
		get = function(updateData)
			local ret = GuildAdsForum.data.get2(updateData)
			if #ret == 0 then
				GuildAdsForum.currentSelectedPostId = nil
				ret = GuildAdsForum.data.get2(true);
			end
			return ret
		end;
		
		get2 = function(updateData)
			if GuildAdsForum.data.cache==nil or updateData==true then
				-- delete old postID (should it exist)
				GuildAdsForum.postID=nil
				-- calculate reply and post ID now (less code to maintain)
				local replyID = 0;
				local newPostID = 0;
				
				local players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
				
				-- make table with parent and grandparent post id's of the selected post id.
				local parentTable = {}
				if GuildAdsForum.currentSelectedPostId then
					local t = ""
					for k,v in pairs({strsplit(":", GuildAdsForum.currentSelectedPostId)}) do
						t = t..v
						parentTable[t]=true;
						t = t..":"
					end
				end
				
				GuildAdsForum:UpdatePermissions();
				
				-- create linear list of visible posts
				local workingTable = {}
				local unreadPosts = {}
				local datatype = GuildAdsDB.channel[GuildAds.channelName].Forum;
				for postid in datatype:iteratorIds() do
					local start, _, expectedAuthor = string.find(postid, "([^:]-)[0-9]+$");
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
						if GuildAdsForum.currentSelectedPostId then
							start, _, number = string.find(postid, "^"..GuildAdsForum.currentSelectedPostId..":[^:]-([0-9]+)$");
							if number and tonumber(number) > replyID then
								replyID = tonumber(number);
							end							
						end
					   if (bit.band(data.f or 0, F_OFFICERONLY)==0 or 
					    (bit.band(data.f or 0, F_OFFICERONLY)==F_OFFICERONLY and GuildAdsForum.viewOfficer)) then 
						local level = select("#", string.split(":",postid))
						local visiblePost = false
						if GuildAdsForum.currentSelectedPostId then
							-- show any 1. level replies to the selected post
							start = string.find(postid, "^"..GuildAdsForum.currentSelectedPostId..":[^:]*$");
							if not start and GuildAdsForum.currentSelectedPostId == postid then
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
						GuildAdsForum.debug("post.id = "..post.id)
						post.n = true
					end
				end
				GuildAdsForum.newPostID = GuildAds.playerName..tostring((newPostID + 1));
				if GuildAdsForum.currentSelectedPostId then
					GuildAdsForum.replyID = GuildAdsForum.currentSelectedPostId..":"..GuildAds.playerName..tostring((replyID + 1));
				else
					GuildAdsForum.replyID = nil;
				end
				GuildAdsForum.data.cache = workingTable;
				GuildAdsForum.sortData.doIt(GuildAdsForum.data.cache);
			end
			return GuildAdsForum.data.cache ;
		end;
	
	};
	
	sortData = {
			
		current = "subject";
	
		currentWay = {
			subject = "normal",
			author = "normal",
			date = "normal",
		};

		predicateFunctions = {
		
			subject2 = function(a, b)
				if a.s and b.s then
					if (a.s < b.s) then
						return false;
					elseif (a.s > b.s) then
						return true;
					end
					return nil;
				elseif a.s and not b.s then
					return false
				elseif not a.s and b.s then
					return true
				end
				return nil;
			end;

			subject = function(a, b)
				if a.n and not b.n then
					return true;
				elseif not a.n and b.n then
					return false;
				else
					return GuildAdsForum.sortData.predicateFunctions.date(a, b);
				end
			end;
			
			author = function(a, b)
				if a.a and b.a then
					if (a.a < b.a) then
						return false;
					elseif (a.a > b.a) then
						return true;
					end
				end
				return nil;
			end;
			
			date = function(a, b)
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
 			table.sort(postTable, GuildAdsForum.sortData.predicate);
		end;
		
		predicate = function(a, b)
			-- nil references are always less than
			local result = GuildAdsForum.sortData.byNilAA(a, b);
			if result~=nil then
				return result;
			end
			-- parent posts always on top
			local result = GuildAdsForum.sortData.byLevel(a, b);
			if result~=nil then
				return result;
			end
			-- sticky posts listed first
			local result = GuildAdsForum.sortData.bySticky(a, b);
			if result~=nil then
				return result;
			end
			
			result = GuildAdsForum.sortData.predicateFunctions[GuildAdsForum.sortData.current](a, b);
			result = GuildAdsForum.sortData.wayFunctions[GuildAdsForum.sortData.currentWay[GuildAdsForum.sortData.current]](result);
			
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
		GuildAdsForum.postButtonsUpdate(self, true);
		
		-- data.get has calculated newPostID. Make a short verification of validity.
		local start, _ = string.find(GuildAdsForum.newPostID, "^[^:]+[0-9]+$");
		if start then
			GuildAdsForumBodyText:SetText("Enter subject here");
			GuildAdsForumBodyText:HighlightText();
			GuildAdsForumSubjectEditBox:SetText("Enter message here");
			GuildAdsForumSubjectEditBox:HighlightText();
			GuildAdsForumSubjectEditBox:SetFocus();
			GuildAdsForumStickyCheckButton:SetChecked(0);
			GuildAdsForumLockedCheckButton:SetChecked(0);
			GuildAdsForumOfficerCheckButton:SetChecked(0);
			GuildAdsForumReplyButton:Disable();
			GuildAdsForumNewPostButton:Disable();
			GuildAdsForumPostButton:SetText(GUILDADS_FORUM_POST);
			GuildAdsForumPostButton:Enable();
			GuildAdsForum.postID = GuildAdsForum.newPostID;
		end
	end;
	
	replyButtonClicked = function()
		if GuildAdsForum.replyID then
			GuildAdsForumBodyText:SetText("Enter subject here");
			GuildAdsForumBodyText:HighlightText();
			GuildAdsForumSubjectEditBox:SetText("Enter message here");
			GuildAdsForumSubjectEditBox:HighlightText();
			GuildAdsForumSubjectEditBox:SetFocus();
			GuildAdsForumStickyCheckButton:SetChecked(0);
			GuildAdsForumLockedCheckButton:SetChecked(0);
			GuildAdsForumOfficerCheckButton:SetChecked(0);
			GuildAdsForumReplyButton:Disable();
			GuildAdsForumNewPostButton:Disable();
			GuildAdsForumPostButton:SetText(GUILDADS_FORUM_POST);
			GuildAdsForumPostButton:Enable();
			GuildAdsForum.postID = GuildAdsForum.replyID;
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
			text = GuildAdsForum.libCompress:Decode7bit(text or "");
			text = GuildAdsForum.libCompress:Decompress(text or "");
			if GuildAdsForum.calcChecksum(text) == checksumBytes then
				return true, text
			end
		end
		return nil, "Checksum mismatch"
	end;
	
	postButtonClicked = function()
		if GuildAdsForum.postID then
			local data = {}
			data.s = GuildAdsForumSubjectEditBox:GetText();
			data.d = GuildAdsForumBodyText:GetText();
			local checksum = GuildAdsForum.calcChecksum(data.d);
			data.d = GuildAdsForum.libCompress:Compress(data.d); -- this will make the data use at most 1 byte more and hopefully somewhat less
			data.d = GuildAdsForum.libCompress:Encode7bit(data.d); -- this will expand data approx 14% in memory, BUT use approx 35% less bandwidth than raw compressed data
			data.d = data.d..checksum;
			data.t = GuildAdsDB:GetCurrentTime();
			data.f = bit.bor(bit.bor(GuildAdsForumStickyCheckButton:GetChecked() and 1 or 0, 
						GuildAdsForumLockedCheckButton:GetChecked() and 2 or 0),
						GuildAdsForumOfficerCheckButton:GetChecked() and 4 or 0);
			
			local datatype = GuildAdsDB.channel[GuildAds.channelName].Forum;
			datatype:set(GuildAds.playerName, GuildAdsForum.postID, data);
			if GuildAdsForum.postID == GuildAdsForum.newPostID then
				GuildAdsForum.currentSelectedPostId = nil;
			end
			GuildAdsForum.postID = nil
			GuildAdsForumSubjectEditBox:ClearFocus();
			GuildAdsForumBodyText:ClearFocus();
			GuildAdsForum.updateButtons();
			GuildAdsForum.postButtonsUpdate(self, true);
		end
		if GuildAdsForumPostButton:GetText() == GUILDADS_FORUM_EDITPOST then
			GuildAdsForumPostButton:SetText(GUILDADS_FORUM_POST)
			GuildAdsForum.postID = GuildAdsForum.currentSelectedPostId
			GuildAdsForumSubjectEditBox:SetFocus();
			GuildAdsForumReplyButton:Disable();
			GuildAdsForumNewPostButton:Disable();
			GuildAdsForumPostButton:Enable();
		end

	end;
}

GuildAdsPlugin.UIregister(GuildAdsForum);