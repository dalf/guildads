local currentLevel;

GuildAdsPlayerMenu = {

	initialize = function(owner, level)
		GuildAdsPlayerMenu.header(owner, level);
		GuildAdsPlayerMenu.menus(owner, level);
		GuildAdsPlayerMenu.footer(owner, level);
	end;
	
	header = function(owner, level)
		currentLevel = level;
		local online = GuildAdsComm:IsOnLine(owner);
		
		info = { };
		info.text =  owner;
		info.notCheckable = 1;
		info.textR = GuildAdsUITools.onlineColor[online].r;
		info.textG = GuildAdsUITools.onlineColor[online].g;
		info.textB = GuildAdsUITools.onlineColor[online].b;
		UIDropDownMenu_AddButton(info, level);
	end;
	
	menus = function(owner, level)
		info = { };
		info.text =  WHISPER_MESSAGE;
		info.notCheckable = 1;
		info.value = owner;
		info.func = GuildAdsPlayerMenu.whisper;
		UIDropDownMenu_AddButton(info, level);

		if GuildAdsInspectWindow then
			info = { };
			info.text =  INSPECT;
			info.notCheckable = 1;
			info.value = owner;
			info.func = GuildAdsPlayerMenu.inspect;
			UIDropDownMenu_AddButton(info, level);
		end

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
	end;
	
	footer = function(owner, level)
		info = { };
		info.text = CANCEL;
		info.notCheckable = 1;
		info.func = GuildAdsPlayerMenu.cancel;
		UIDropDownMenu_AddButton(info, level);
	end;
	
	cancel = function()
		HideDropDownMenu(currentLevel);
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
			InviteUnit(owner);
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
