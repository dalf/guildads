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
	
	alerts = {
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
		
		GuildAdsMinimapButton:SetAlpha(0.6);
		this:RegisterForClicks("LeftButtonDown", "RightButtonDown");
	end;
	
	onInit = function()
		-- init config value
		if not GuildAdsMinimapButtonCore.getConfigValue(nil, "RadiusOffset") then
			GuildAdsMinimapButtonCore.defaultsOptions();
		end
		
		if not ButtonHole then
			GuildAdsMinimapButtonCore.update();
			-- as GuildAds object : wait 8 seconds before initialization...
			GuildAdsTask:AddNamedSchedule("GuildAdsMinimapButtonShow", 8, nil, nil, GuildAdsMinimapButton.Show, GuildAdsMinimapButton)
		end
	end;
	
	onChannelJoin = function()
		GuildAdsMinimapButton:SetAlpha(1);
	end;
	
	onChannelLeave = function()
		GuildAdsMinimapButton:SetAlpha(0.6);
	end;
	
	onConfigChanged = function(path, key, value)
		GuildAdsMinimapButtonCore.update();
	end;
	
	onEnter = function()
		local this = GuildAdsMinimapButton;
		GameTooltip:SetOwner(this, "ANCHOR_LEFT");
		GameTooltip:SetText(GUILDADS_TITLE);
		local thereIsNoAlert = true;
		for i, alert in ipairs(GuildAdsMinimapButtonCore.alerts) do
			local text = alert.text;
			local r = alert.r;
			local g = alert.g;
			local b = alert.b;
			if not text and type(alert.func)=="function" then
				local rf, gf, bf;
				text, rf, gf, bf = alert.func();
				r = rf or r;
				g = gf or g;
				b = bf or b;
			end
			GameTooltip:AddLine(text, r, g, b);
			thereIsNoAlert = false;
		end
		if thereIsNoAlert then
			local status, message = GuildAdsComm:GetChannelStatus();
			if status~="Connected" then
				if GuildAds.channelName then
					GameTooltip:AddLine(GuildAds.channelName..": "..(status or ""), 1, 0, 0);
				else
					GameTooltip:AddLine(status or "", 1, 0, 0);
				end
				if message then
					GameTooltip:AddLine(GuildAdsComm.message, 1, 0, 0);
				end
			else
				GameTooltip:AddLine(GuildAds.channelName..": "..(status or ""), 0, 1, 0);
			end			
		end
		GameTooltip:Show();
		GuildAdsTask:AddNamedSchedule("GuildAdsMinimapButtonUpdate", 1, true, nil, GuildAdsMinimapButtonCore.onEnter)
	end;
	
	onLeave = function()
		GuildAdsTask:DeleteNamedSchedule("GuildAdsMinimapButtonUpdate");
		GameTooltip:Hide();
	end;
	
	onClick = function()
		if (arg1 == "LeftButton") then
			local alert = GuildAdsMinimapButtonCore.alerts[1];
			if alert and type(alert.onClick)=="function" then
				alert.onClick(unpack(alert.onClickArgs or {}));
			else
				GuildAds:ToggleMainWindow();
			end
			GuildAdsMinimapButtonCore.removeAllAlerts();
		else
			GuildAds:ToggleOptionsWindow()
		end
	end;
	
	onBlink = function()
		if GuildAdsMinimapButton.s then
			GuildAdsMinimapButton:UnlockHighlight();
			GuildAdsMinimapButton.s = nil
		else
			GuildAdsMinimapButton:LockHighlight();
			GuildAdsMinimapButton.s = 1;
		end
	end;
	
	addAlertText = function(text, r, g, b, onClick, ...)
		GuildAdsMinimapButtonCore.addAlert(text, nil, r, g, b, onClick, ...);
	end;
	
	addAlertFunction = function(func, onClick, ...)
		GuildAdsMinimapButtonCore.addAlert(nil, func, nil, nil, nil, onClick, ...);
	end;
	
	addAlert = function(text, func, r, g, b, onClick, ...)
		GuildAdsTask:AddNamedSchedule("GuildAdsMinimapButtonBlink", 1, true, nil, GuildAdsMinimapButtonCore.onBlink)
		local alert = {};
		GuildAdsMinimapButtonCore.updateAlert(alert, text, func, r, g, b, onClick, ...)
		table.insert(GuildAdsMinimapButtonCore.alerts, alert);
		return alert;
	end;
	
	updateAlert = function(alert, text, func, r, g, b, onClick, ...)
		alert = alert or {};
		alert.text = text;
		alert.func = func;
		alert.r = r or 1;
		alert.g = g or 1;
		alert.b = b or 1;
		alert.onClick = onClick;
		alert.onClickArgs = { select(1, ...) };
	end;
	
	removeAlert = function(alert)
		local t = GuildAdsMinimapButtonCore.alerts;
		if #t > 1 then
			for i,a in pairs(t) do
				if a==alert then
					table.remove(t, i);
				end
			end
		else
			GuildAdsMinimapButtonCore.removeAllAlerts();
		end
	end;
	
	removeAllAlerts = function()
		GuildAdsMinimapButtonCore.alerts = {};
		GuildAdsMinimapButton.s = nil;
		GuildAdsMinimapButton:UnlockHighlight();
		GuildAdsTask:DeleteNamedSchedule("GuildAdsMinimapButtonBlink");
	end;
	
	-------------------------------------------------------------
	-- options
	-------------------------------------------------------------
	
	update = function()
		local radius = GuildAdsMinimapButtonCore.getConfigValue(nil, "RadiusOffset", 77);
		local arc = GuildAdsMinimapButtonCore.getConfigValue(nil, "ArcOffset", 296);
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
		GuildAds_MinimapArcSlider:SetValue(GuildAdsMinimapButtonCore.getConfigValue(nil, "ArcOffset", 77));
		GuildAds_MinimapRadiusSlider:SetValue(GuildAdsMinimapButtonCore.getConfigValue(nil, "RadiusOffset", 296));
	end
	
};

GuildAdsMinimapButton_Update = GuildAdsMinimapButtonCore.update;
GuildAdsPlugin.UIregister(GuildAdsMinimapButtonCore);