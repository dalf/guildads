----------------------------------------------------------------------------------
--
-- GuildAdsAdminOptions.lua
--
-- Author: Zarkan, Fka� of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsAdminOptions = {
	
	metaInformations = { 
		name = "AdminOptions",
        guildadsCompatible = 200,
		ui = {
			options = {
				frame = "GuildAdsAdminOptionsFrame",
				tab = "GuildAdsAdminOptionsTab",
				tooltip = "Gestion des droits",
				priority = 3
			}
		}
	};
	
	defaultsOptions = function()
		--[[
			faire confiance � sa guilde
			faire confiance � ses amis ?
		]]
	end;
	
	saveOptions = function()
	end;
	
	onShowOptions = function()	
	end;
	
}

GuildAdsPlugin.UIregister(GuildAdsAdminOptions);