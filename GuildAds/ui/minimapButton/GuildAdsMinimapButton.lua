----------------------------------------------------------------------------------
--
-- GuildAdsMinimapButton.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsMinimapButtonCore = {
	
	metaInformations = { 
		name = "MinimapButton",
        guildadsCompatible = 100,
		ui = {
			options = {
				frame = "GuildAdsMinimapButtonOptions",
				tab = "GuildAdsMinimapButtonTab",
				tooltip = GUILDADS_ICON_OPTIONS,
				priority = 4
			}
		}
	};
	
	onLoad = function()
		-- support for ButtonHole
		if ButtonHole then
			GuildAdsMinimapButton:Show();
			ButtonHole.application.RegisterMod({
				id="GUILDADS",
				name=GUILDADS_TITLE,
				tooltip=GUILDADS_TITLE,
				buttonFrame="GuildAdsMinimapButton",
				updateFunction="GuildAdsMinimapButton_Update"
			});
		end	
	end;
	
	onInit = function()
		-- init config value
		if not GuildAdsMinimapButtonCore.getConfigValue(nil, "RadiusOffset") then
			GuildAdsMinimapButtonCore.defaultsOptions();
		end
	end;
	
	onChannelJoin = function()
		-- Show button
		if not ButtonHole then
			GuildAdsMinimapButtonCore.update();
			GuildAdsMinimapButton:Show();
		end
	end;
	
	onConfigChanged = function(path, key, value)
		GuildAdsMinimapButtonCore.update();
	end;
	
	update = function()
		local radius = GuildAdsMinimapButtonCore.getConfigValue(nil, "RadiusOffset");
		local arc = GuildAdsMinimapButtonCore.getConfigValue(nil, "ArcOffset");
		if radius and arc and not ButtonHole then
			GuildAdsMinimapButton:SetPoint( "TOPLEFT", "Minimap", "TOPLEFT",
				55 - ( radius * cos( arc ) ),
				( radius * sin( arc ) ) - 55
			);
		end
	end;
	
	defaultsOptions = function()
		GuildAdsMinimapButtonCore.setConfigValue(nil, "RadiusOffset", 77);
		GuildAdsMinimapButtonCore.setConfigValue(nil, "ArcOffset", 296);		
	end;
	
	onShowOptions = function()
		GuildAds_MinimapArcSlider:SetValue(GuildAdsMinimapButtonCore.getConfigValue(nil, "ArcOffset"));
		GuildAds_MinimapRadiusSlider:SetValue(GuildAdsMinimapButtonCore.getConfigValue(nil, "RadiusOffset"));
	end
	
};

GuildAdsMinimapButton_Update = GuildAdsMinimapButtonCore.update;
GuildAdsPlugin.UIregister(GuildAdsMinimapButtonCore);