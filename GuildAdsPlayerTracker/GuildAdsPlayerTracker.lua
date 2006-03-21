-- GuildAds Comms message definitions.
GUILDADSPLAYERTRACKER_CMD_LOC = "GMap";

-- seconds after which the UI shall be repainted
GUILDADSPLAYERTRACKER_UPDATE_INTERVAL = 0.25;

-- seconds to wait between announces when a player is moving
GUILDADSPLAYERTRACKER_EARLIEST_ANNOUNCE = 3.0;
-- seconds after which an announce must take place when a player is standing still
GUILDADSPLAYERTRACKER_LATEST_ANNOUNCE = 30.0;

-- seconds after which a player without updated status info will be removed
GUILDADSPLAYERTRACKER_PLAYER_TIMEOUT = 45.0;

-- main data table
GuildAdsPlayerTrackerData = {
	self = {continent = 0, zone = 0, x = 0, y = 0, inCity = false},
	players = {},
    joined = false,
	now = 0,
	timeDelta = 0,
	lastAnnounce = 0,
	pendingAnnounce = false,
	worldMapOpen = false,
};

--[[
-- GuildAdsPlayerTracker
--     The main GuildAdsPlayerTracker object
--]]
GuildAdsPlayerTracker = {

	metaInformations = {
		name = "GuildAdsPlayerTracker",
		guildadsCompatible = 100,
		version = "1.0",
		author = "Zarkan",
		email = "guildads@gmail.com",
		website = "http://guildads.sf.net"		
	};
	
	getCommands = function()
		return {
			[GUILDADSPLAYERTRACKER_CMD_LOC] = {
				{
					[1] = { ["key"]="continent", ["fout"]=GuildAdsPlugin.serializeInteger, ["fin"]=GuildAdsPlugin.unserializeInteger },
					[2] = { ["key"]="zone", 	 ["fout"]=GuildAdsPlugin.serializeInteger, ["fin"]=GuildAdsPlugin.unserializeInteger },
					[3] = { ["key"]="x", 		 ["fout"]=GuildAdsPlugin.serializeInteger, ["fin"]=GuildAdsPlugin.unserializeInteger },
					[4] = { ["key"]="y", 		 ["fout"]=GuildAdsPlugin.serializeInteger, ["fin"]=GuildAdsPlugin.unserializeInteger },
				},
				GuildAdsPlayerTracker.onMessage
			}
		};
	end;


    --[[
    -- onMessage(author, message)
    --     Parse any required data messages.
	--]]
    onMessage = function(author, message)
		-- do not care about messages from myself
		local playerName = UnitName("player");
		if (playerName and playerName == author) then
			return;
		end
		
		if (	message.continent 
			and message.zone 
			and message.x 
			and message.y 
			and GuildAdsPlayerTracker.isValidPosition(message.continent, message.zone, message.x, message.y)) then
			-- if we don't have the player, set the show flag
			if (GuildAdsPlayerTrackerData.players[author] == nil) then
				GuildAdsPlayerTrackerData.players[author] = { 
						show = true
					};
			end
			
			--  do update
			GuildAdsPlayerTrackerData.players[author].continent = message.continent;
			GuildAdsPlayerTrackerData.players[author].zone = message.zone;
			GuildAdsPlayerTrackerData.players[author].x = message.x;
			GuildAdsPlayerTrackerData.players[author].y = message.y;
			GuildAdsPlayerTrackerData.players[author].lastUpdate = GuildAdsPlayerTrackerData.now;
		end
    end;


    --[[
    -- onChannelJoin()
    --     Executed on joining the GuildAds channel.
	--]]
    onChannelJoin = function()
        GuildAdsPlayerTrackerData.joined = true;
    end;


    --[[
    -- onChannelLeave()
    --     Executed on leaving the GuildAds channel.
	--]]
    onChannelLeave = function()
        GuildAdsPlayerTrackerData.joined = false;
    end;


    --[[
    -- onUpdate(timeDelta)
    --     Execute onUpdate.
	--]]
    onUpdate = function(timeDelta)
	    if (GuildAdsPlayerTrackerData.joined == false) then
		    return;
	    end
	
	    GuildAdsPlayerTrackerData.now = GuildAdsPlayerTrackerData.now + timeDelta;
	    GuildAdsPlayerTrackerData.timeDelta = GuildAdsPlayerTrackerData.timeDelta + timeDelta;
	
		if (GuildAdsPlayerTrackerData.timeDelta > GUILDADSPLAYERTRACKER_UPDATE_INTERVAL) then
			GuildAdsPlayerTrackerData.timeDelta = 0;
		
			GuildAdsPlayerTracker.updatePartyOrRaid();
		
			local announceDelta = GuildAdsPlayerTrackerData.now - GuildAdsPlayerTrackerData.lastAnnounce;
			local positionChanged = GuildAdsPlayerTracker.updatePlayerPos();
			-- an announce is scheduled if the player position has changed or 
			-- the maximum time without an announce was exceeded
			GuildAdsPlayerTrackerData.pendingAnnounce =
				GuildAdsPlayerTrackerData.pendingAnnounce or
				positionChanged or
				(announceDelta > GUILDADSPLAYERTRACKER_LATEST_ANNOUNCE);

			if (GuildAdsPlayerTrackerData.pendingAnnounce and announceDelta > GUILDADSPLAYERTRACKER_EARLIEST_ANNOUNCE) then
				GuildAdsPlayerTracker.announcePosition();
			end
		
			-- garbage collect timed out players
			GuildAdsPlayerTracker.removeOldPlayers();
		
			GuildAdsPlayerTrackerData.worldMapOpen = GuildAdsPlayerTracker.isWorldMapOpen();
			if (GuildAdsPlayerTrackerData.worldMapOpen) then
				GuildAdsPlayerTracker.updateWorldMap();
			else
				GPTRegionData.ensureZoneMap();
				GuildAdsPlayerTracker.updateMiniMap();
			end;
	    end
    end;


    --[[
    -- onLoad()
    --     Executed onLoad.
	--]]
    onLoad = function()
		-- Add GuildAds to myAddOns addons list
		if(myAddOnsFrame) then
			local pluginName = GuildAdsPlayerTracker.metaInformations.name;
			local pluginVersion = GuildAdsPlayerTracker.metaInformations.version;
			myAddOnsList.GuildAdsPlayerTracker = {
				name = pluginName,
				version = pluginVersion,
				category = MYADDONS_CATEGORY_GUILD,
				author = "Zarkan",
				email = "guildads@gmail.com",
				website = "http://guildads.sf.net"
			};
		end
	
		-- Init
	    GPTRegionData.initRegionData();

	    this:RegisterEvent("MINIMAP_UPDATE_ZOOM");
	    this:RegisterEvent("WORLD_MAP_UPDATE");
	    this:RegisterEvent("RAID_ROSTER_UPDATE");
	    this:RegisterEvent("PARTY_MEMBERS_CHANGED");	
		
		GuildAdsPlugin.UIregister(GuildAdsPlayerTracker);
    end;


    --[[
    -- onEvent(event)
    --     Execute onEvent.
	--]]
    onEvent = function(event)
	    if (GuildAdsPlayerTrackerData.joined) then
		    return;
	    end

	    if (event == "MINIMAP_UPDATE_ZOOM") then
		    GuildAdsPlayerTrackerData.self.inCity = GPTRegionData.isMinimapInCity();
	    elseif (event == "WORLD_MAP_UPDATE") then
		    GuildAdsPlayerTrackerData.worldMapOpen = GuildAdsPlayerTracker.isWorldMapOpen();
		    if (GuildAdsPlayerTrackerData.worldMapOpen) then
			    GuildAdsPlayerTracker.updateWorldMap();
		    end
	    elseif ((event == "RAID_ROSTER_UPDATE") or (event == "PARTY_MEMBERS_CHANGED")) then
		    GuildAdsPlayerTracker.updatePartyOrRaid();
	    end
    end;
	
	onShowAd = function(tooltip, adtype, ad)
		if (adtype == GUILDADS_MSG_TYPE_ANNONCE or adtype == GUILDADS_MSG_TYPE_EVENT) then
			if GuildAdsPlayerTrackerData.players[ad.owner] then
				local position = GuildAdsPlayerTrackerData.players[ad.owner];
				
				local continentNames = { GetMapContinents() } ;
				local contientName = continentNames[position.continent];
				
				local zoneNames = { GetMapZones(position.continent) };
				local zoneName = "??";
				for u,v in GPT_ZoneShift[position.continent] do
					if (v == position.zone) then
						zoneName = zoneNames[u];
					end
				end
				
				currentX = ceil(position.x / 100);
				currentY = ceil(position.y / 100);
				
				tooltip:AddLine(ZONE..": "..zoneName.." ("..currentX..","..currentY..")", 1, 1, 1);
			end
		end
	end;
	
	announcePosition = function()
		if (GuildAdsPlayerTracker.isValidPosition(
				GuildAdsPlayerTrackerData.self.continent, 
				GuildAdsPlayerTrackerData.self.zone, 
				GuildAdsPlayerTrackerData.self.x, 
				GuildAdsPlayerTrackerData.self.y)
			) then 
			GuildAdsPlayerTrackerData.pendingAnnounce = false;
			GuildAdsPlayerTrackerData.lastAnnounce = GuildAdsPlayerTrackerData.now;
			GuildAdsPlugin.send( 
					nil,
					{
						command = GUILDADSPLAYERTRACKER_CMD_LOC,
						continent = GuildAdsPlayerTrackerData.self.continent,
						zone = GuildAdsPlayerTrackerData.self.zone,
						x = GuildAdsPlayerTrackerData.self.x,
						y = GuildAdsPlayerTrackerData.self.y
					}
				);
		end
	end;


    --[[
    -- isWorldMapOpen()
    --     Check if world map is visible.
	--]]
    isWorldMapOpen = function()
	    if (WorldMapFrame:IsVisible()) then
		    return true;
	    else
		    return false;
	    end
    end;


    --[[
    -- updateWorldMap()
    --     Update the world map display.
	--]]
    updateWorldMap = function()
	    local currFrame = 1;	
	    local currentContinent, currentZone = GPTRegionData.getMapZone();
	
	    -- there was a crash for battlegrounds (which return -1 for continent I think)
	    if (currentContinent < 0 or currentContinent > 2) then
		    for i = 1, 250 do
			    local poi = getglobal("GuildAdsPlayerTrackerMain" .. i);
			    poi:Hide();		
		    end
		    return;
	    end
	
	    for player, playerData in GuildAdsPlayerTrackerData.players do
		    if (playerData.show) then
			    -- world map
			    if (currentContinent == 0) then
				    local playerX = playerData.x / 10000;
				    local playerY = playerData.y / 10000;
				    local mnX,mnY;

				    local absx, absy = GPTRegionData.localToAbs(playerData.continent, playerData.zone, playerX, playerY);
				    local worldx, worldy = GPTRegionData.localToAbs(playerData.continent, 0, absx, absy);

				    mnX = worldx * WorldMapDetailFrame:GetWidth();
				    mnY = -worldy * WorldMapDetailFrame:GetHeight();

				    local poi = getglobal("GuildAdsPlayerTrackerMain" .. currFrame);
				    poi:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", mnX, mnY);
				    poi:Show();

				    poi.unit = player;
				    currFrame = currFrame + 1;		

			    -- continent map
			    elseif (currentZone == 0) then
				    -- only players on the same continent are taken into account
				    if (playerData.continent == currentContinent) then
					    local playerX = playerData.x / 10000;
					    local playerY = playerData.y / 10000;
					    local mnX,mnY;

					    local absx, absy = GPTRegionData.localToAbs(playerData.continent, playerData.zone, playerX, playerY);

					    mnX = absx * WorldMapDetailFrame:GetWidth();
					    mnY = -absy * WorldMapDetailFrame:GetHeight();

					    local poi = getglobal("GuildAdsPlayerTrackerMain" .. currFrame);
					    poi:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", mnX, mnY);
					    poi:Show();

					    poi.unit = player;
					    currFrame = currFrame + 1;
				    end

			    -- zone map
			    else 
				    -- only players on the same continent are taken into account
				    if (playerData.continent == currentContinent) then

					    local playerX = playerData.x / 10000;
					    local playerY = playerData.y / 10000;
					    if (playerData.zone ~= currentZone) then
						    -- players which are not directly in the zone have to be checked too
						    -- example: map of Mulgore should still show people in thunder bluff (though different zone)
						    local absx, absy = GPTRegionData.localToAbs(playerData.continent, playerData.zone, playerX, playerY);
						    playerX, playerY = GPTRegionData.absToLocal(currentContinent, currentZone, absx, absy);
					    end

					    -- only use players that are really visible
					    if (playerX >= 0 and playerX <= 1 and playerY >= 0 and playerY <= 1) then
						    local mnX,mnY;
						    mnX = playerX * WorldMapDetailFrame:GetWidth();
						    mnY = -playerY * WorldMapDetailFrame:GetHeight();

						    local poi = getglobal("GuildAdsPlayerTrackerMain" .. currFrame);
						    poi:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", mnX, mnY);
						    poi:Show();

						    poi.unit = player;
						    currFrame = currFrame + 1;
					    end				
				    end
			    end
		    end
		
		    -- no more than 250 players on world map
		    if (currFrame == 250) then
			    break;
		    end
	    end

	    for i = currFrame, 250 do
		    local poi = getglobal("GuildAdsPlayerTrackerMain" .. i);
		    poi:Hide();		
	    end
    end;


    --[[
    -- updateMiniMap()
    --     Update the minimap display.
	--]]
    updateMiniMap = function()
	    local currFrame = 1;	

	    local continent = GuildAdsPlayerTrackerData.self.continent;
	    local zone = GuildAdsPlayerTrackerData.self.zone;
	
	    if (continent == 0 or zone == 0) then
		    return;
	    end

	    for player, playerData in GuildAdsPlayerTrackerData.players do
		    if (playerData.show and continent == playerData.continent and zone == playerData.zone) then
			    local x = GuildAdsPlayerTrackerData.self.x / 10000;
			    local y = GuildAdsPlayerTrackerData.self.y / 10000;

			    local playerX = playerData.x / 10000;
			    local playerY = playerData.y / 10000;

			    local xscale = GPT_Const[continent][Minimap:GetZoom()].xscale;
			    local yscale = GPT_Const[continent][Minimap:GetZoom()].yscale;
			    if (GuildAdsPlayerTrackerData.self.inCity) then
				    xscale = xscale * GPT_Const[2][Minimap:GetZoom()].cityscale;
				    yscale = yscale * GPT_Const[2][Minimap:GetZoom()].cityscale;
			    end
			    local xpos = playerX * GPT_Const[continent][zone].scale + GPT_Const[continent][zone].xoffset;
			    local ypos = playerY * GPT_Const[continent][zone].scale + GPT_Const[continent][zone].yoffset;

			    x = x * GPT_Const[continent][zone].scale + GPT_Const[continent][zone].xoffset;
			    y = y * GPT_Const[continent][zone].scale + GPT_Const[continent][zone].yoffset;

			    local deltax = (xpos - x) * xscale;
			    local deltay = (y - ypos) * yscale;

			    local poi = getglobal("GuildAdsPlayerTrackerMini" .. currFrame);
			    local distFromCenter = sqrt( (deltax * deltax) + (deltay * deltay) );
			
			    if (distFromCenter < 256.5) then	
				    local alpha = 1.0;
				    if (distFromCenter > 56.5) then
					    deltax = deltax * 56.5 / distFromCenter;
					    deltay = deltay * 56.5 / distFromCenter;
					    alpha = 0.6667 - ((distFromCenter - 56.5) / 300);
				    end

				    poi:SetPoint("CENTER", "MinimapCluster", "TOPLEFT", 107 + deltax, -92 + deltay);
				    poi:SetAlpha(alpha);
				
				    poi:Show();
				    poi.unit = player;
				    currFrame = currFrame + 1;
			    end
		
		    end

		    -- no more than 25 players on mini map
		    if (currFrame == 25) then
			    break;
		    end
	    end
	
	    for i = currFrame, 25 do
		    local poi = getglobal("GuildAdsPlayerTrackerMini" .. i);
		    poi:Hide();		
	    end
    end;


    --[[
    -- updatePlayerPos(timeDelta)
    --     Execute onUpdate.
	--]]
    updatePlayerPos = function(timeDelta)
	    local continent, zone = GPTRegionData.getCurrentZone();
	
	    if (continent == 0 or zone == 0) then
		    return;
	    end
	
	    local x, y = GetPlayerMapPosition("player");
	    x = math.floor(x * 10000);
	    y = math.floor(y * 10000);
	
	    if ((GuildAdsPlayerTrackerData.self.x ~= x) or
		    (GuildAdsPlayerTrackerData.self.y ~= y)) then
		    GuildAdsPlayerTrackerData.self.continent = continent;
		    GuildAdsPlayerTrackerData.self.zone = zone;
		    GuildAdsPlayerTrackerData.self.x = x;
		    GuildAdsPlayerTrackerData.self.y = y;
		    return true;
	    end
	
	    return false;
    end;

    --[[
    -- miniMap_OnClick(arg1)
    --     Execute miniMap_OnClick.
	--]]
    miniMap_OnClick = function(arg1)
	    if (arg1 == "RightButton") then
		    TargetByName(this.unit);
	    else
		    -- ping thru
		    local x, y = GetCursorPosition();
		    x = x / Minimap:GetScale();
		    y = y / Minimap:GetScale();

		    local cx, cy = Minimap:GetCenter();
		    x = x + CURSOR_OFFSET_X - cx;
		    y = y + CURSOR_OFFSET_Y - cy;
		    if ( sqrt(x * x + y * y) < (Minimap:GetWidth() / 2) ) then
			    Minimap:PingLocation(x, y);
		    end
	    end
    end;


    --[[
    -- removeOldPlayers()
    --     Execute onUpdate.
	--]]
    removeOldPlayers = function()
	    for player, playerData in GuildAdsPlayerTrackerData.players do
		    if (GuildAdsPlayerTrackerData.now - playerData.lastUpdate > GUILDADSPLAYERTRACKER_PLAYER_TIMEOUT) then
			    GuildAdsPlayerTrackerData.players[player] = nil;
		    end
	    end	
    end;


    --[[
    -- isValidPosition(continent, zone, x, y)
    --     Execute isValidPosition.
	--]]
    isValidPosition = function(continent, zone, x, y)
	    if (continent < 1 or continent > 2) then
		    return false;
	    end
	    if (continent == 1 and (zone < 1 or zone > 21)) then
		    return false;
	    end
	    if (continent == 2 and (zone < 1 or zone > 26)) then
		    return false;
	    end
	
	    if (x < 1 or x > 9999) then
		    return false;
	    end
	    if (y < 1 or y > 9999) then
		    return false;
	    end	

	    return true;
    end;


    --[[
    -- showMiniMapToolTip()
    --     Execute showMiniMapToolTip.
	--]]
    showMiniMapToolTip = function()
	    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT");

	    local unitButton;
	    local newLineString = "";
	    local tooltipText = "";
	
	    for i=1, 25 do
		    unitButton = getglobal("GuildAdsPlayerTrackerMini"..i);
		    if ( unitButton:IsVisible() and MouseIsOver(unitButton) ) then
			    tooltipText = tooltipText .. newLineString .. unitButton.unit;
			    newLineString = "\n";
		    elseif (not unitButton:IsVisible()) then
			    break;
		    end
	    end

	    GameTooltip:SetText(tooltipText, 1.0, 0.82, 0.0, 1,1);
	    GameTooltip:Show();
    end;


    --[[
    -- showWorldMapToolTip()
    --     Execute showWorldMapToolTip.
	--]]
    showWorldMapToolTip = function()
	    -- determine tooltip anchor
	    local x, y = this:GetCenter();
	    local parentX, parentY = this:GetParent():GetCenter();
	    if ( x > parentX ) then
		    WorldMapTooltip:SetOwner(this, "ANCHOR_LEFT");
	    else
		    WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT");
	    end	
	
	    local unitButton;
	    local newLineString = "";
	    local tooltipText = "";
	
	    for i=1, 250 do
		    unitButton = getglobal("GuildAdsPlayerTrackerMain"..i);
		    if ( unitButton:IsVisible() and MouseIsOver(unitButton) ) then
			    tooltipText = tooltipText .. newLineString .. unitButton.unit;
			    newLineString = "\n";
		    elseif (not unitButton:IsVisible()) then
			    break;
		    end
	    end

	    WorldMapTooltip:SetText(tooltipText, 1.0, 0.82, 0.0, 1,1);
	    WorldMapTooltip:Show();
    end;


    --[[
    -- updatePartyOrRaid()
    --     Execute updatePartyOrRaid.
	--]]
    updatePartyOrRaid = function() 
	    for player, playerData in GuildAdsPlayerTrackerData.players do
		    playerData.show = true;
	    end	

	    local numRaidMembers = GetNumRaidMembers();
	    for i = 1, numRaidMembers do
		    local name = GetRaidRosterInfo(i);
		    if (name and GuildAdsPlayerTrackerData.players[name]) then
			    GuildAdsPlayerTrackerData.players[name].show = false;	
		    end
	    end

	    local numPartyMembers = GetNumPartyMembers();
	    for i = 1, numPartyMembers do
		    local name = UnitName("party" .. i);
		    if (name and GuildAdsPlayerTrackerData.players[name]) then
			    GuildAdsPlayerTrackerData.players[name].show = false;	
		    end
	    end
    end;
};
