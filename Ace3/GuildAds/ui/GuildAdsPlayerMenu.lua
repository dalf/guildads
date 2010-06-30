local currentLevel;

GuildAdsPlayerMenu = {

	initialize = function(playerName, level)
		local isOnline = GuildAdsComm:IsOnLine(playerName)
		local onlinePlayerName = GuildAdsUITools:IsAccountOnline(playerName)
		
		GuildAdsPlayerMenu.header(playerName, level)
		GuildAdsPlayerMenu.menus(playerName, level, isOnline)
		
		if isOnline or not onlinePlayerName then
			GuildAdsPlayerMenu.footer(playerName, level)
		else
			GuildAdsPlayerMenu.empty(playerName, level)
			GuildAdsPlayerMenu.header(onlinePlayerName, level)
			GuildAdsPlayerMenu.menus(onlinePlayerName, level, true)
			GuildAdsPlayerMenu.footer(onlinePlayerName, level)
		end
		
	end;
	
	empty = function(owner, level)
		info = UIDropDownMenu_CreateInfo();
		info.text =  "";
		info.notClickable = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info, level);		
	end;
	
	header = function(owner, level)
		currentLevel = level;
		local _, colorHex = GuildAdsUITools:GetPlayerColor(owner)
		
		info = UIDropDownMenu_CreateInfo();
		info.text =  owner;
		info.notCheckable = 1;
		info.colorCode = colorHex;
		UIDropDownMenu_AddButton(info, level);
	end;
	
	menus = function(owner, level, online)
		currentLevel = level;
		if online == nil then
			online = true
		end
		
		if online then
			info = UIDropDownMenu_CreateInfo();
			info.text =  WHISPER_MESSAGE;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.whisper;
			UIDropDownMenu_AddButton(info, level);
		end

		if GuildAdsInspectWindow then
			info = UIDropDownMenu_CreateInfo();
			info.text =  INSPECT;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.inspect;
			UIDropDownMenu_AddButton(info, level);
		end

		if online then
			info = UIDropDownMenu_CreateInfo();
			info.text =  CHAT_INVITE_SEND;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.invite;
			UIDropDownMenu_AddButton(info, level);
	
			info = UIDropDownMenu_CreateInfo();
			info.text =  WHO;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.who;
			UIDropDownMenu_AddButton(info, level);
		end
	end;
	
	footer = function(owner, level)
		currentLevel = level;
		info = UIDropDownMenu_CreateInfo();
		info.text = CANCEL;
		info.notCheckable = 1;
		info.func = GuildAdsPlayerMenu.cancel;
		UIDropDownMenu_AddButton(info, level);
	end;
	
	cancel = function()
		HideDropDownMenu(currentLevel);
	end;
	
	whisper = function(self)
		local owner = self.value;
		if owner then
			local editbox = ChatEdit_GetActiveWindow()
			if ( not editbox ) then
				ChatFrame_OpenChat("/w "..owner.." ");
			else
				editbox:SetText("/w "..owner.." ");
				ChatEdit_ParseText(editbox, 0);
			end
		end
	end;
	
	inspect = function(self)
		local owner = self.value;
		if owner then
			GuildAdsInspectWindow:Inspect(owner);
			GuildAdsInventory:Update(true);
			GuildAdsTalentUI:Update();
		end
	end;
	
	invite = function(self)
		local owner = self.value;
		if owner then
			InviteUnit(owner);
		end
	end;
	
	who = function(self)
		local owner = self.value;
		if owner then
			local editbox = ChatEdit_GetActiveWindow() or ChatEdit_GetLastActiveWindow() or ChatFrame1EditBox
			local oldtext = editbox:GetText();
			local oldshow = editbox:IsShown();
			local oldfocus = editbox:HasFocus();
			editbox:SetText("/who "..owner);
			ChatEdit_SendText(editbox);
			editbox:SetText(oldtext);
			if oldshow then
				editbox:Show();
			end
			if oldfocus then
				editbox:SetFocus();
			end
		end
	end;

};
