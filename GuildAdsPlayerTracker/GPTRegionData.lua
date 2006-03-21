GPT_ZoneShift = {
	[0] = { [0] = 0 },
	[1] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
	[2] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 },
};

GPT_ZoneShift[1][0] = 0;
GPT_ZoneShift[2][0] = 0;

GPT_WARSONGGULCH = "Warsong Gulch";
GPT_ALTERACVALLEY = "Alterac Valley";


if ( GetLocale() == "deDE" ) then
	GPT_ZoneShift = {
		[0] = { [0] = 0 },
		[1] = { 1, 2, 3, 4, 17, 14, 20, 5, 7, 6, 8, 9, 10, 11, 12, 13, 15, 16, 18, 19, 21 },
		--[2] = { 1, 2, 20, 14, 25, 3, 6, 16, 10, 15, 19, 5, 4, 23, 9, 7, 8, 11, 12, 13, 17, 18, 21, 22, 24, 26 },
		-- above values from MapNotes seem to be wrong
		[2] = { 1, 2, 20, 14, 25, 3, 6, 16, 10, 15, 19, 11, 5, 4, 23, 9, 7, 8, 12, 13, 17, 18, 21, 22, 24, 26 },
	};

	GPT_ZoneShift[1][0] = 0;
	GPT_ZoneShift[2][0] = 0;

    GPT_WARSONGGULCH = "Warsong-Schlucht";
    GPT_ALTERACVALLEY = "Alteractal";
end


if ( GetLocale() == "frFR" ) then
	GPT_ZoneShift = { 
		[0] = { [0] = 0 },
		[1] = { 1, 2, 21, 20, 4, 6, 5, 9, 8, 14, 17, 7, 18, 11, 12, 10, 13, 3, 15, 16, 19 },
		[2] = { 8, 17, 21, 11, 7, 6, 10, 16, 15, 2, 12, 14, 20, 25, 13, 9, 23, 19, 24, 1, 5, 4, 3, 22, 18, 26 },
	};

	GPT_ZoneShift[1][0] = 0;
	GPT_ZoneShift[2][0] = 0;

	GPT_WARSONGGULCH = "Goulet des Warsong";
	GPT_ALTERACVALLEY = "Vall\195\169e d\226\128\153Alterac";
end

GPT_Const = {};
GPT_Const[1] = {};
GPT_Const[2] = {};
-- first approach with some inaccurate coordinates for the world map
-- GPT_Const[1][0] = { xscale = 11016.6, yscale = 7399.9 };
GPT_Const[1][0] = { scale = 0.825, xoffset = -0.19, yoffset = 0.06, xscale = 11016.6, yscale = 7399.9 };
GPT_Const[1][1] = { scale = 0.15670371525706, xoffset = 0.41757282062541, yoffset = 0.33126468682991, xscale = 12897.3, yscale = 8638.1 };
GPT_Const[1][2] = { scale = 0.13779501505279, xoffset = 0.55282036918049, yoffset = 0.30400571307545, xscale = 15478.8, yscale = 10368.0 };
GPT_Const[1][3] = { scale = 0.17799008894522, xoffset = 0.38383175154516, yoffset = 0.18206216123156, xscale = 19321.8, yscale = 12992.7 };
GPT_Const[1][4] = { scale = 0.02876626176374, xoffset = 0.38392150175204, yoffset = 0.10441296545475, xscale = 25650.4, yscale = 17253.2 };
GPT_Const[1][5] = { scale = 0.12219839120669, xoffset = 0.34873187115693, yoffset = 0.50331046935371, xscale = 38787.7, yscale = 26032.1 };
GPT_Const[1][6] = { scale = 0.14368294970080, xoffset = 0.51709782709100, yoffset = 0.44802818134926 };
GPT_Const[1][7] = { scale = 0.14266384095509, xoffset = 0.49026338351379, yoffset = 0.60461876174686 };
GPT_Const[1][8] = { scale = 0.15625084006464, xoffset = 0.41995800144849, yoffset = 0.23097545880609 };
GPT_Const[1][9] = { scale = 0.18885970960818, xoffset = 0.31589651244686, yoffset = 0.61820581746798 };
GPT_Const[1][10] = { scale = 0.06292695969921, xoffset = 0.50130287793373, yoffset = 0.17560823085517 };
GPT_Const[1][11] = { scale = 0.13960673216274, xoffset = 0.40811854919226, yoffset = 0.53286226907346 };
GPT_Const[1][12] = { scale = 0.03811449638057, xoffset = 0.56378554142668, yoffset = 0.42905218646258 };
GPT_Const[1][13] = { scale = 0.18885969712845, xoffset = 0.33763582469211, yoffset = 0.75815224951929 };
GPT_Const[1][14] = { scale = 0.13272833611061, xoffset = 0.37556627748617, yoffset = 0.40285135292988 };
GPT_Const[1][15] = { scale = 0.18750104661175, xoffset = 0.46971301480866, yoffset = 0.76120931364891 };
GPT_Const[1][16] = { scale = 0.13836131003639, xoffset = 0.36011098024729, yoffset = 0.03948322979210 };
GPT_Const[1][17] = { scale = 0.27539211944292, xoffset = 0.39249347333450, yoffset = 0.45601063260257 };
GPT_Const[1][18] = { scale = 0.11956582877920, xoffset = 0.47554411191734, yoffset = 0.68342356389650 };
GPT_Const[1][19] = { scale = 0.02836291430658, xoffset = 0.44972878210917, yoffset = 0.55638479002362 };
GPT_Const[1][20] = { scale = 0.10054401185671, xoffset = 0.44927594451520, yoffset = 0.76494573629405 };
GPT_Const[1][21] = { scale = 0.19293573573141, xoffset = 0.47237382938446, yoffset = 0.17390990272233 };
-- first approach with some inaccurate coordinates for the world map
-- GPT_Const[2][0] = { xscale = 10448.3, yscale = 7072.7, cityscale = 1.565 };
GPT_Const[2][0] = { scale = 0.77, xoffset = 0.38, yoffset = 0.09, xscale = 10448.3, yscale = 7072.7, cityscale = 1.565 };
GPT_Const[2][1] = { scale = 0.07954563533736, xoffset = 0.43229874660542, yoffset = 0.25425926375262, xscale = 12160.5, yscale = 8197.8, cityscale = 1.687 };
GPT_Const[2][2] = { scale = 0.10227310921644, xoffset = 0.47916793249546, yoffset = 0.32386170078419, xscale = 14703.1, yscale = 9825.0, cityscale = 1.882 };
GPT_Const[2][3] = { scale = 0.07066771883566, xoffset = 0.51361415033147, yoffset = 0.56915717993261, xscale = 18568.7, yscale = 12472.2, cityscale = 2.210 };
GPT_Const[2][4] = { scale = 0.09517074521836, xoffset = 0.48982154167011, yoffset = 0.76846519986510, xscale = 24390.3, yscale = 15628.5, cityscale = 2.575 };
GPT_Const[2][5] = { scale = 0.08321525646393, xoffset = 0.46212246701740, yoffset = 0.61780780524905, xscale = 37012.2, yscale = 25130.6, cityscale = 2.651 };
GPT_Const[2][6] = { scale = 0.07102298961531, xoffset = 0.47822105868635, yoffset = 0.73863555048516 };
GPT_Const[2][7] = { scale = 0.13991525534426, xoffset = 0.40335096278072, yoffset = 0.48339696712179 };
GPT_Const[2][8] = { scale = 0.07670475476181, xoffset = 0.43087243362495, yoffset = 0.73224350550454 };
GPT_Const[2][9] = { scale = 0.10996723642661, xoffset = 0.51663255550387, yoffset = 0.15624753972085 };
GPT_Const[2][10] = { scale = 0.09860350595046, xoffset = 0.41092682316676, yoffset = 0.65651531970162 };
GPT_Const[2][11] = { scale = 0.09090931690055, xoffset = 0.42424361247460, yoffset = 0.30113436864162 };
GPT_Const[2][12] = { scale = 0.02248317426784, xoffset = 0.47481923366335, yoffset = 0.51289242617182 };
GPT_Const[2][13] = { scale = 0.07839152145224, xoffset = 0.51118749188138, yoffset = 0.50940913489577 };
GPT_Const[2][14] = { scale = 0.06170112311456, xoffset = 0.49917278340928, yoffset = 0.68359285304999 };
GPT_Const[2][15] = { scale = 0.06338794005823, xoffset = 0.46372051266487, yoffset = 0.57812379382509 };
GPT_Const[2][16] = { scale = 0.11931848806212, xoffset = 0.35653502290090, yoffset = 0.24715695496522 };
GPT_Const[2][17] = { scale = 0.03819701270887, xoffset = 0.41531450060561, yoffset = 0.67097280492581 };
GPT_Const[2][18] = { scale = 0.18128603034401, xoffset = 0.39145470225916, yoffset = 0.79412224886668 };
GPT_Const[2][19] = { scale = 0.06516347991404, xoffset = 0.51769795272070, yoffset = 0.72815974701615 };
GPT_Const[2][20] = { scale = 0.10937523495111, xoffset = 0.49929119700867, yoffset = 0.25567971676068 };
GPT_Const[2][21] = { scale = 0.12837403412087, xoffset = 0.36837217317549, yoffset = 0.15464954319582 };
GPT_Const[2][22] = { scale = 0.02727719546939, xoffset = 0.42973999245660, yoffset = 0.23815358517831 };
GPT_Const[2][23] = { scale = 0.12215946583965, xoffset = 0.44270955019641, yoffset = 0.17471356786018 };
GPT_Const[2][24] = { scale = 0.09943208435841, xoffset = 0.36884571674582, yoffset = 0.71874918595783 };
GPT_Const[2][25] = { scale = 0.11745423014662, xoffset = 0.46561438951659, yoffset = 0.40971063365152 };

GPT_Const[GPT_WARSONGGULCH] = { scale = 0.035, xoffset = 0.41757282062541, 
                         yoffset = 0.33126468682991, xscale = 12897.3, yscale = 8638.1 };
GPT_Const[GPT_ALTERACVALLEY] = { scale = 0.13, xoffset = 0.41757282062541, 
                         yoffset = 0.33126468682991, xscale = 12897.3, yscale = 8638.1 };

GPT_ZoneNames = {};

GPTRegionData = {
    -- don't know how to get these in one function (hanvn't tried often)
    loadZones = function(continent, ...)
	    GPT_ZoneNames[continent] = {};
	    for i=1, arg.n, 1 do
		    GPT_ZoneNames[continent][GPT_ZoneShift[continent][i]] = arg[i];
	    end
    end;


    getMapZone = function()
	    local mapContinent = GetCurrentMapContinent();
	    local mapZone = GetCurrentMapZone();
	
	    if (mapContinent > 0) then
		    mapZone = GPT_ZoneShift[mapContinent][mapZone];
	    end

	    return mapContinent, mapZone;
    end;


    getCurrentZone = function()
	    local currentZoneName = GetRealZoneText();

	    for continent, zoneData in GPT_ZoneNames do
		    for zone, zoneName in zoneData do
			    if (currentZoneName == zoneName) then
				    return continent, zone;
			    end
		    end
	    end

	    return 0,0;
    end;


    isMinimapInCity = function()
	    local tempzoom = 0;
	    local inCity = false;
	    if (GetCVar("minimapZoom") == GetCVar("minimapInsideZoom")) then
		    if (GetCVar("minimapInsideZoom")+0 >= 3) then 
			    Minimap:SetZoom(Minimap:GetZoom() - 1);
			    tempzoom = 1;
		    else
			    Minimap:SetZoom(Minimap:GetZoom() + 1);
			    tempzoom = -1;
		    end
	    end
	    if (GetCVar("minimapInsideZoom")+0 == Minimap:GetZoom()) then inCity = true; end
	    Minimap:SetZoom(Minimap:GetZoom() + tempzoom);
	    return inCity;
    end;


    initRegionData = function()
	    for i = 1, 2 do
		    GPTRegionData.loadZones(i, GetMapZones(i));
	    end

	    CurrentZoneFix_SetupFix();
    end;


    localToAbs = function(continent, zone, localx, localy)
	    local absx = localx * GPT_Const[continent][zone].scale + GPT_Const[continent][zone].xoffset;
	    local absy = localy * GPT_Const[continent][zone].scale + GPT_Const[continent][zone].yoffset;
	    return absx, absy;
    end;

    absToLocal = function(continent, zone, absx, absy)
	    local localx = (absx - GPT_Const[continent][zone].xoffset) / GPT_Const[continent][zone].scale;
	    local localy = (absy - GPT_Const[continent][zone].yoffset) / GPT_Const[continent][zone].scale;
	    return localx, localy;
    end;


    ensureZoneMap = function()
	    local mapContinent, mapZone = GPTRegionData.getMapZone();
	
	    local playerContinent, playerZone = GPTRegionData.getCurrentZone();
	
	    if (playerContinent ~= 0 and playerZone ~= 0 and (mapContinent ~= playerContinent or mapZone ~= playerZone)) then
		    --SetMapZoom(playerContinent, playerZone);
		    SetMapToCurrentZone();
	    end
    end;
};


function CurrentZoneFix_SetupFix()
	-- CurrentZoneFix v2.0 by Legorol
	-- email: legorol@cosmosui.org

	local versionID = 20;
	local id = CurrentZoneFix_FixInPlace;

	if ( id ) then
		id = tonumber(id);
		if ( id and id >= versionID ) then
			return;
		elseif ( not SetMapToCurrentZone(true) ) then
			DEFAULT_CHAT_FRAME:AddMessage("Warning! Obsolete version "..
				"of CurrentZoneFix function detected. The old "..
				"version is being loaded either as a standalone "..
				"AddOn, or as code embedded inside another AddOn. "..
				"You must update it to avoid bugs with the map!",1,0,0)
			return;
		end
	end

	local continent,zone,name
	local zoneID={};
	local orig_SetMapToCurrentZone;

	for continent in ipairs{GetMapContinents()} do
		for zone,name in ipairs{GetMapZones(continent)} do
			zoneID[name] = zone;
		end
	end

	orig_SetMapToCurrentZone = SetMapToCurrentZone;
	SetMapToCurrentZone = function(deactivate)
		if (deactivate) then
			SetMapToCurrentZone = orig_SetMapToCurrentZone;
			CurrentZoneFix_FixInPlace = nil;
			return true;
		end
	
		orig_SetMapToCurrentZone();
		if ( GetCurrentMapZone()==0 and GetCurrentMapContinent()>0 ) then
			SetMapZoom(GetCurrentMapContinent(),zoneID[GetRealZoneText()]);
		else
			SetMapToCurrentZone = orig_SetMapToCurrentZone;
			CurrentZoneFix_FixInPlace = "Deactivated "..versionID;
		end
	end

	CurrentZoneFix_FixInPlace = versionID;
end
