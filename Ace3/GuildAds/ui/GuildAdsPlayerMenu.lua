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
		info = { };
		info.text =  "";
		info.notClickable = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info, level);		
	end;
	
	header = function(owner, level)
		currentLevel = level;
		local color = GuildAdsUITools:GetPlayerColor(owner)
		
		info = { };
		info.text =  owner;
		info.notCheckable = 1;
		info.textR = color.r;
		info.textG = color.g;
		info.textB = color.b;
		UIDropDownMenu_AddButton(info, level);
	end;
	
	menus = function(owner, level, online)
		currentLevel = level;
		if online == nil then
			online = true
		end
		
		if online then
			info = { };
			info.text =  WHISPER_MESSAGE;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.whisper;
			UIDropDownMenu_AddButton(info, level);
		end

		if GuildAdsInspectWindow then
			info = { };
			info.text =  INSPECT;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.inspect;
			UIDropDownMenu_AddButton(info, level);
		end

		if online then
			info = { };
			info.text =  CHAT_INVITE_SEND;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.invite;
			UIDropDownMenu_AddButton(info, level);
	
			info = { };
			info.text =  WHO;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.who;
			UIDropDownMenu_AddButton(info, level);
		end
	end;
	
	footer = function(owner, level)
		currentLevel = level;
		info = { };
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
			if ( not ChatFrameEditBox:IsVisible() ) then
				ChatFrame_OpenChat("/w "..owner.." ");
			else
				ChatFrameEditBox:SetText("/w "..owner.." ");
			end
			ChatEdit_ParseText(ChatFrame1.editBox, 0);
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
			local text = ChatFrameEditBox:GetText();
			ChatFrameEditBox:SetText("/who "..owner);
			ChatEdit_SendText(ChatFrameEditBox);
			ChatFrameEditBox:SetText(text);
		end
	end;

};
