----------------------------------------------------------------------------------
--
-- GuildAdsChannelOptions.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsChannelOptions = {
	
	metaInformations = { 
		name = "ChannelOptions",
        guildadsCompatible = 200,
		ui = {
			options = {
				frame = "GuildAdsChannelOptionsFrame",
				tab = "GuildAdsChannelOptionsTab",
				tooltip = "Configuration du cannal à utiliser",
				priority = 1
			}
		}
	};
	
	defaultsOptions = function()
		GuildAds_ChatUseThisCheckButton:SetChecked(false);
		GuildAds_ChannelCommandEditBox:SetText("ga");
		GuildAds_ChannelAliasEditBox:SetText("GuildAds");
	end;
	
	saveOptions = function()
		if ( GuildAds_ChatUseThisCheckButton:GetChecked() ) then
			local name = GuildAds_ChannelEditBox:GetText();
			local password = GuildAds_ChannelPasswordEditBox:GetText();
			if (name == "") then
				name = nil;
				password = nil;
			else
				if (password == "") then
					password = nil;
				end
			end
			GuildAds:SetDefaultChannel(name, password);
		else
			GuildAds:SetDefaultChannel(nil, nil);
		end
	
		local channelCommand = GuildAds_ChannelCommandEditBox:GetText();
		local channelAlias = GuildAds_ChannelAliasEditBox:GetText();
		GuildAds:SetDefaultChannelAlias(channelCommand, channelAlias);
	end;
	
	onShowOptions = function()
		-- TODO : ShowNewAsk/ShowNewHave : dépend de trade, rien à faire la
		if (GuildAdsTrade.getProfileValue(nil, "ShowNewAsk")) then
			GuildAds_ChatShowNewAskCheckButton:SetChecked(1);
		else
			GuildAds_ChatShowNewAskCheckButton:SetChecked(0);
		end
	
		if (GuildAdsTrade.getProfileValue(nil, "ShowNewHave")) then
			GuildAds_ChatShowNewHaveCheckButton:SetChecked(1);
		else
			GuildAds_ChatShowNewHaveCheckButton:SetChecked(0);
		end
	
		local channelName = GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelName");
		if (channelName) then
			GuildAds_ChatUseThisCheckButton:SetChecked(1);
			GuildAds_ChannelEditBox:Show();
			GuildAds_ChannelPasswordEditBox:Show();
			GuildAds_ChannelEditBox:SetText(channelName);
			local password = GuildAdsDB:GetConfigValue(GuildAdsDB.PROFILE_PATH, "ChannelPassword") or "";
			GuildAds_ChannelPasswordEditBox:SetText(password);
		else
			GuildAds_ChatUseThisCheckButton:SetChecked(0);
			GuildAds_ChannelEditBox:Hide();
			GuildAds_ChannelPasswordEditBox:Hide();
		end

		local channelCommand, channelAlias = GuildAds:GetDefaultChannelAlias();
		GuildAds_ChannelAliasEditBox:SetText(channelAlias);
		GuildAds_ChannelCommandEditBox:SetText(channelCommand);		
	end;
	
}

GuildAdsPlugin.UIregister(GuildAdsChannelOptions);