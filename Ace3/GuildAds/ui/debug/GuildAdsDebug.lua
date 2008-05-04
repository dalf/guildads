----------------------------------------------------------------------------------
--
-- GuildAdsDebug.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

--[[
    Debug module
]]
local usageStats = {};
local scriptProfile = GetCVar("scriptProfile") == "1"
local startTime = GetTime()
local lastTime = 0
local lastSentMessages, lastSentBytes, lastReceivedMessages, lastReceivedBytes = 0,0,0,0
local lastBandwidthOut, lastBandwidthIn = 0,0
local instantMeasure = false

local getObjectCPUUsage = function(obj, includeSubroutines)
	local t, c = 0,0
	for _, f in pairs(obj) do
		if type(f) == "function" then
			local tt, cc = GetFunctionCPUUsage(f, includeSubroutines);
			t = t + tt
			c = c + cc
		end
	end
	return t,c
end

local getStatColor = function(main, includeSub, included)
	local r, g, b
	if main then
		r, g, b = 1, 1, 0
	elseif included then
		r, g, b = 0.6, 0.6, 0.6
	else
		r, g, b = 1, 1, 1
	end
	return r, g, b
end

local predicateDB = function(db1, db2)
	local count = GuildAdsComm.stats.TransactionPerDatabase.count
	local c1 = db1 and db1[1] and count[db1[1]] or 0
	local c2 = db2 and db2[1] and count[db2[1]] or 0
	return c1>c2
end

GuildAds_DebugPlugin = {
	metaInformations = { 
		name = "Debug",
        guildadsCompatible = 200,
		ui = {
			main = {
				frame = "GuildAdsDebugFrame",
				tab = "GuildAdsDebugTab",
				priority = 10000
			}
		}
	};
	
	colors = {
		{0.57,0.57,0.11},
		{0.3, 0.3, 0.44},
		{0.23,0.34,0.44},
		{0.11,0.34,0.6},
		{0.1, 0.5, 0.1},
		{1,   0.5, 0},
		{1,   0,   1},
		{1,   1,   1},
	};
	
	showDebug = function()
		return GuildAdsDatabase and GuildAdsDatabase.Config and GuildAdsDatabase.Config.Debug;
	end;
	
	setShowDebug = function(status)
		if status then
			GuildAdsDB:SetConfigValue({"Config"}, "Debug", true);
		else
			GuildAdsDB:SetConfigValue({"Config"}, "Debug", nil);
		end
	end;
	
	onLoad = function()
		GuildAds_ChatDebug = GuildAds_DebugPlugin.addDebugMessageReal;
		this:RegisterEvent("VARIABLES_LOADED");
		GuildAdsPlugin.UIregister(GuildAds_DebugPlugin);
	end;
	
	onVariablesLoaded = function()
		if GuildAds_DebugPlugin.showDebug() then
			GuildAds_DebugPlugin.logMessages(true);
		else
			GuildAds_DebugPlugin.logMessages(false);
		end;
		
		GuildAds_DebugPlugin.addAddonUsage("GuildAds");
		GuildAds_DebugPlugin.addObjectUsage("Show debug informations", GuildAds_DebugPlugin, false, false);
		GuildAds_DebugPlugin.addObjectUsage("GuildAdsComm", GuildAdsComm, false, false);
		GuildAds_DebugPlugin.addObjectUsage("GuildAdsDTS", GuildAdsDTS, false, false);
		GuildAds_DebugPlugin.addObjectUsage("GuildAdsHash", GuildAdsHash, false, false);
		GuildAds_DebugPlugin.addObjectUsage("GuildAdsList", GuildAdsList, false, false);
		
		if GuildAdsTask.GetOnUpdate then
			GuildAds_DebugPlugin.addFunctionUsage("GuildAdsTask (onUpdate)", GuildAdsTask:GetOnUpdate(), false);
			GuildAds_DebugPlugin.addObjectUsage("GuildAdsTask", GuildAdsTask, false);
		end
		
		GuildAds_DebugPlugin.addFunctionUsage("GuildAdsComm.FilterText", GuildAdsComm.FilterText, false, true);
		GuildAds_DebugPlugin.addFrameUsage("GuildAdsITT", GuildAdsITT, false, true);
	end;
	
	logMessages = function(mode)
		if mode then
			if not GuildAds_DebugPlugin.showDebug() then
				GuildAds_DebugPlugin.addDebugMessageReal(GA_DEBUG_GLOBAL, "Log debug messages : true");
				GuildAds_DebugPlugin.setShowDebug(true);
			end
			GuildAds_ChatDebug = GuildAds_DebugPlugin.addDebugMessageReal;
			GuildAdsDebugTab:Show();
		else
			if GuildAds_DebugPlugin.showDebug() then
				GuildAds_DebugPlugin.addDebugMessageReal(GA_DEBUG_GLOBAL, "Log debug messages : false");
				GuildAds_DebugPlugin.setShowDebug(nil);
			end
			GuildAds_ChatDebug = GuildAds_DebugPlugin.addDebugMessageFake;
			GuildAdsDebugTab:Hide();
		end
	end;
	
	addDebugMessageFake = function(dbg_type, str)
	end;
	
	addDebugMessageReal = function(dbg_type, fmt, ...)
		GuildAdsDebug_Log:AddMessage(date("[%H:%M:%S] ")..string.format(fmt, select(1, ...)), GuildAds_DebugPlugin.colors[dbg_type][1], GuildAds_DebugPlugin.colors[dbg_type][2], GuildAds_DebugPlugin.colors[dbg_type][3]);
	end;
	
	addObjectUsage = function(name, obj, includeSubroutines, included)
		local r, g, b = getStatColor(false, includeSubroutines, included)
		table.insert(usageStats, {
			func = getObjectCPUUsage,
			args = { obj, includeSubroutines },
			name = name,
			included = included,
			kind = "addon",
			t = 0,
			c = 0,
			colorR = r,
			colorG = g,
			colorB = b
		});		
	end;
	
	-- for accurate result on the GuildAds_DebugPlugin
	getObjectCPUUsage = getObjectCPUUsage;
	
	addAddonUsage = function(name)
		local r, g, b = getStatColor(true, false, false)
		table.insert(usageStats, {
			func = GetAddOnCPUUsage,
			args = { name },
			name = name,
			included = true,
			kind = "addon",
			t = 0,
			c = 0,
			colorR = r,
			colorG = g,
			colorB = b
		});
	end;
	
	addFrameUsage = function(name, frame, includeChildren, included)
		local r, g, b = getStatColor(false, includeChildren, included)
		table.insert(usageStats, {
			func = GetFrameCPUUsage,
			args = { frame, includeChildren},
			name = name,
			included = included,
			kind = "frame",
			t = 0,
			c = 0,
			colorR = r,
			colorG = g,
			colorB = b
		});
	end;
	
	addFunctionUsage = function(name, func, includeSubroutines, included)
		local r, g, b = getStatColor(false, includeSubroutines, included)
		table.insert(usageStats, {
			func = GetFunctionCPUUsage,
			args = { func, includeSubroutines},
			name = name,
			included = included,
			kind = "function",
			t = 0,
			c = 0,
			colorR = r,
			colorG = g,
			colorB = b
		});
	end;
	
	onClickStats = function()
		if (arg1 == "LeftButton") then
			GuildAdsStatsTooltip:SetOwner(UIParent,"ANCHOR_PRESERVE")
			if not scriptProfile then
				GuildAdsSwitchMeasureButton:Hide();
			end
			GuildAds_DebugPlugin.displayStats()
		else
			GuildAds_DebugPlugin.toggleScriptProfile();
		end
	end;
	
	onClickSwitchMeasure = function()
		instantMeasure = not instantMeasure;
		if instantMeasure then
			GuildAdsSwitchMeasureButton:SetText("Cumulative");
		else
			GuildAdsSwitchMeasureButton:SetText("Instant");
		end
	end;
	
	toggleScriptProfile = function()
		if scriptProfile then
			SetCVar("scriptProfile", "0")
		else
			SetCVar("scriptProfile", "1")
		end
		ReloadUI()
	end;
	
	displayStats = function()
		local tooltip = GuildAdsStatsTooltip
		tooltip:SetText("GuildAds");
		local sessionTime = GetTime() - startTime;  -- in second
		local sentMessages, sentBytes, receivedMessages, receivedBytes = SimpleComm_GetStats()
		local sentBytesPerSecond = sentBytes / sessionTime
		local receivedBytesPerSecond = receivedBytes / sessionTime
		
		local since = sessionTime - lastTime
		local instantSentMessages, instantSentBytes, instantReceivedMessages, instantReceivedBytes = 
				sentMessages-lastSentMessages, sentBytes-lastSentBytes, receivedMessages-lastReceivedMessages, receivedBytes-lastReceivedBytes;
		
		local instantSentBytesPerSecond, instantReceivedBytesPerSecond = -1, -1
		if since>0 then
			instantSentBytesPerSecond, instantReceivedBytesPerSecond = instantSentBytes / since, instantReceivedBytes / since
		end
		
		local bandwidthIn, bandwidthOut, latency = GetNetStats()
		local instantBandwidthIn  = (sessionTime*bandwidthIn  - lastTime*lastBandwidthIn) / since
		local instantBandwidthOut = (sessionTime*bandwidthOut - lastTime*lastBandwidthOut) / since
		lastBandwidthIn, lastBandwidthOut = bandwidthIn, bandwidthOut
		
		lastSentMessages, lastSentBytes, lastReceivedMessages, lastReceivedBytes =
				sentMessages, sentBytes, receivedMessages, receivedBytes;
		lastTime = sessionTime
		
		tooltip:AddLine(string.format("Session duration: %i seconds", sessionTime), 1, 1, 0);
		tooltip:AddLine("Messages during the session", 1, 0.75, 0);
		tooltip:AddDoubleLine(string.format("Sent: %i messages, %i bytes", sentMessages, sentBytes), string.format("%.2f bytes/sec ", sentBytesPerSecond), 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine(string.format("Received: %i messages, %i bytes", receivedMessages, receivedBytes), string.format("%.2f bytes/sec", receivedBytesPerSecond), 1, 1, 1, 1, 1, 1)
		tooltip:AddLine(string.format("Messages in %i seconds", since), 1, 0.75, 0);
		tooltip:AddDoubleLine(string.format("Sent: %i messages, %i bytes", instantSentMessages, instantSentBytes), string.format("%.2f bytes/sec ", instantSentBytesPerSecond), 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine(string.format("Received: %i messages, %i bytes", instantReceivedMessages, instantReceivedBytes), string.format("%.2f bytes/sec", instantReceivedBytesPerSecond), 1, 1, 1, 1, 1, 1)
		
		tooltip:AddLine("Network (Instant)", 1, 0.75, 0)
		tooltip:AddDoubleLine("Bandwidth - out", string.format("%i bytes/sec", instantBandwidthOut*1024), 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Bandwidth - in ", string.format("%i bytes/sec", instantBandwidthIn*1024), 1, 1, 1, 1, 1, 1)
		
		tooltip:AddLine("Database", 1, 0.75, 0)
		
		local t = GuildAdsComm.hashSearchQueue[1]:Length()  * 17 + GuildAdsComm.hashSearchQueue[2]:Length()  
		tooltip:AddDoubleLine("Max hash searches left", string.format("%i/288", t), 1, 1, 1, 1, 1, 1) -- 288=17*16+16 or may be 272 =15*17+16+1 ?
		
		local gacs = GuildAdsComm.stats
		tooltip:AddLine("GuildAdsComm", 1, 0.75, 0)
		tooltip:AddDoubleLine("Tick", gacs.Tick, 								1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Level 0 hash search", gacs.HashSearch[0], 		0.5, 1, 1, 0.5, 1, 1)
		tooltip:AddDoubleLine("Level 1 hash search", gacs.HashSearch[1], 		1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Level 2 hash search", gacs.HashSearch[2], 		0.5, 1, 1, 0.5, 1, 1)
		tooltip:AddDoubleLine("Revision search", gacs.RevisionSearch, 			1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Transaction", gacs.Transaction, 					0.5, 1, 1, 0.5, 1, 1)
		tooltip:AddDoubleLine("Join", gacs.Join, 								0.5, 1, 1, 0.5, 1, 1)
		tooltip:AddDoubleLine("Leave", gacs.Leave, 								1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine("Token problem", gacs.TokenProblem, 				0.5, 1, 1, 0.5, 1, 1)
		
		local odd = true
		local r, g, b
		for name, count in pairs(gacs.Timeout) do
			if odd then
				r, g, b = 0.5, 1, 1
			else
				r, g , b = 1, 1, 1
			end
			odd = not odd
			tooltip:AddDoubleLine("Timeout "..name, count, 		r, g, b)
		end
		local statsPerDB = gacs.TransactionPerDatabase
		if #statsPerDB.db > 0 then
			if statsPerDB.changed then
				table.sort(statsPerDB.db, predicateDB)
				statsPerDB.changed = nil
			end
			local tmp = "Transactions send by "
			local n = math.min(#statsPerDB.db, 5)
			for i=1,n,1 do
				local db = statsPerDB.db[i]
				tmp = tmp..string.format("%s (%i), ", db[2], statsPerDB.count[db[1]])
			end
			tooltip:AddLine(tmp, 1, 1, 1)
		end
		
		if not scriptProfile then
			tooltip:Show();
			return
		end
		
		if instantMeasure then
			tooltip:AddLine("CPU Usage (Instant)", 1, 0.75, 0);
		else
			tooltip:AddLine("CPU Usage (Cumulative)", 1, 0.75, 0);
		end
		UpdateAddOnCPUUsage();
		local baseTime, other, toPercent
		for lineNumber, spec in ipairs(usageStats) do
			local t, c = spec.func(unpack(spec.args))
			c = c or 0
			local dt, dc = t-spec.t, c-spec.c
			local p
			local misc = ""
			local tt, cc
			if instantMeasure then
				tt, cc = dt, dc
			else
				tt, cc = t, c
			end
			
			if lineNumber>1 then
				p = t / toPercent
				dp = dt / toPercent
			else
				baseTime = tt
				other = baseTime
				toPercent = baseTime / 100
				p = 100
				dp = 0
				misc = string.format(", %.4f%% of the session", (t/10) / sessionTime); -- sessionTime in second, t in millesecond
			end
			
			if not spec.included then
				other = other - tt
			end
			
			local r, g, b = spec.colorR, spec.colorG, spec.colorB
			if instantMeasure then
				tooltip:AddDoubleLine(string.format("%s %s",spec.name, misc), string.format("[%i] %.4f ms", dc, dt), r, g, b, r, g, b);
			else
				tooltip:AddDoubleLine(string.format("%s %s",spec.name, misc), string.format("[%i] %ims %00i%%", c, t, p), r, g, b, r, g, b);
			end
			
			spec.t, spec.c = t, c
		end
		
		if instantMeasure then
			tooltip:AddDoubleLine("Other functions", string.format("%.4f ms", other, 1, 1, 1,1,1,1));
		else
			tooltip:AddDoubleLine("Other functions", string.format("%ims %i%%", other, (other*100)/baseTime), 1, 1, 1,1,1,1);
		end
		tooltip:Show();
	end;
}
