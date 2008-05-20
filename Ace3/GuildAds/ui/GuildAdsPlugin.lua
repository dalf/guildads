----------------------------------------------------------------------------------
--
-- GuildAdsPlugin.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

--[[
Plugin = {
	metaInformations = {
		name = "GuildAdsPlayerTracker",
		guildadsCompatible = 100,
	}
	
	-- others functions that can be defined
	-- those functions will be called when the event occured
	onChannelJoin();
	onChannelLeave();
	onOnline(playerName, status)
}
]]

GAS_EVENT_ITEMINFOREADY = 7;		-- TODO : Event associé à data\GuildAdsItem
GAS_EVENT_ONLINE = 6;				-- TODO : Event associé à network\GuildAdsComm
GAS_EVENT_CONNECTION = 8;			-- TODO : Event associé à network\GuildAdsComm
GAS_EVENT_CHANNELSTATUSCHANGED = 9;	-- TODO : Event associé à network\GuildAdsComm

local pluginsToRegister = {};

-- Dispatcher ----------------------------------------------
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
	local code = [[
		local xpcall, eh = ...	-- our arguments are received as unnamed values in "..." since we don't have a proper function declaration
		local method, ARGS
		local function call() return method(ARGS) end
	
		local function dispatch(func, ...)
			 method = func
			 if not method then return end
			 ARGS = ...
			 return xpcall(call, eh)
		end
	
		return dispatch
	]]
	
	local ARGS = {}
	for i = 1, argCount do ARGS[i] = "arg"..i end
	code = code:gsub("ARGS", table.concat(ARGS, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {
	__index=function(self, argCount)
		local dispatcher = CreateDispatcher(argCount)
		rawset(self, argCount, dispatcher)
		return dispatcher
	end
})
Dispatchers[0] = function(func)
	return xpcall(func, errorhandler)
end
 
local function safecall(func, ...)
	return Dispatchers[select('#', ...)](func, ...)
end

-- GuildAdsPlugin ----------------------------------------------

GuildAdsPlugin = {

	debugOn = false;

	PluginsList = {};
	
	isPluginValid  = function(plugin)
    	-- Every plugin needs to be a table
        if type(plugin) ~= "table" then
            return false, "Plugin type check failed.";
        end

    	-- Check metainformations
        if type(plugin.metaInformations) == "table" then
			local metainfo = plugin.metaInformations;
			-- check name
			if type(metainfo.name)~="string" then
				return false, "Plugin name check failed.";
			end
			-- check version
			if type(metainfo.guildadsCompatible)~="number" or metainfo.guildadsCompatible>GUILDADS_REVISION_NUMBER then
				return false, "Plugin incompatible with this version of GuildAds";
			end
		else
            return false, "Plugin Metainformations check failed.";
        end

        return true;
	end;
	
	_register = function(plugin)
		local valid, errorMessage = GuildAdsPlugin.isPluginValid(plugin);
		if valid then			
			local pluginName = plugin.metaInformations.name;
			
			-- add plugin to GuildAdsPlugin.PluginsList
			GuildAdsPlugin.PluginsList[pluginName] = plugin;
			
			-- set debug function
			plugin.debug = function(message)
				GuildAdsPlugin.debug(pluginName..":"..message);
			end;
			
			-- set config function
			plugin.setConfigValue = function(path, key, value)
				if GuildAdsDB:SetConfigValue({ GuildAdsDB.CONFIG_PATH, pluginName, path }, key, value) then
					if type(plugin.onConfigChanged) == "function" then
						safecall(plugin.onConfigChanged, path, key, value);
					end
				end
				return value;
			end;
	
			plugin.getConfigValue = function(path, key, defaultValue)
				return GuildAdsDB:GetConfigValue({ GuildAdsDB.CONFIG_PATH, pluginName, path }, key, defaultValue)
			end;
			
			plugin.setProfileValue = function(path, key, value)
				if GuildAdsDB:SetConfigValue({ GuildAdsDB.PROFILE_PATH, pluginName, path}, key, value) then
					if type(plugin.onConfigChanged) == "function" then
						safecall(plugin.onConfigChanged, path, key, value);
					end
				end
				return value;
			end;
	
			plugin.getProfileValue = function(path, key, defaultValue)
				return GuildAdsDB:GetConfigValue({ GuildAdsDB.PROFILE_PATH, pluginName, path}, key, defaultValue)
			end;
			
			-- GALMOK -- needed a way to read the raw db value
			plugin.getRawProfileValue = function(path, key)
				return GuildAdsDB:GetRawConfigValue({ GuildAdsDB.PROFILE_PATH, pluginName, path}, key)
			end;
			
			-- call onChannelJoin() ??
			
			GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "Register plugin: "..pluginName);
			return true;
		else
			return false, errorMessage;
		end
	end;
	
    register = function(plugin)
  	    if pluginsToRegister then
			tinsert(pluginsToRegister, plugin)
  	        return true;
		else
			return GuildAdsPlugin._register(plugin);
		end
	end;
	
	UIregister = function(plugin)
		local status, errorMessage = GuildAdsPlugin.register(plugin);
		if not status then
			if errorMessage then
				error(errorMessage,2);
			else
				error("error", 2);
			end
		end
	end;
	
	deregister = function(plugin)
		local valid, errorMessage = GuildAdsPlugin.isPluginValid (plugin);
		if valid then
			GuildAdsPlugin.PluginsList[plugin.metaInformations.name] = nil;
			-- call onChannelLeave()
			return true;
		else
			return false, errorMessage;
		end
	end;
	
	-- setDebug
	setDebug = function(status)
		if status then
			GuildAdsPlugin.debugOn = true;
		else
			GuildAdsPlugin.debugOn = false;
		end
	end;
	
	-- debug
	debug = function(message)
		GuildAds_ChatDebug(GA_DEBUG_PLUGIN, message);
	end
};

local EventIdToMethod = {
	[GAS_EVENT_ONLINE] = "onOnline";
	[GAS_EVENT_CONNECTION] = "onConnection";
	[GAS_EVENT_ITEMINFOREADY] = "onItemInfoReady";
	[GAS_EVENT_CHANNELSTATUSCHANGED] = "onStatusChannelChange";
}

local function pluginToRealCommand(command)
	return "P"..command;
end

local function realToPluginCommand(command)
	local iStart, iEnd, realCommand = string.find(command, "P(.*)");
	if (iStart) then
		return realCommand;
	else
		return false;
	end
end

local function methodToEventId(method)
	for ltype, lmethod in pairs(EventIdToMethod) do
		if method == lmethod then
			return ltype;
		end
	end
	return nil;
end

function GuildAdsPlugin_RegisterPlugins()
	-- register plugins
	if pluginsToRegister then
		for _, plugin in ipairs(pluginsToRegister) do
			local status, errorMessage = GuildAdsPlugin._register(plugin);
			if not status then
				local pluginName;
				if plugin.metaInformations and plugin.metaInformations.name then
					pluginName = plugin.metaInformations.name..": ";
				else
					pluginName = "GuildAds(unknown plugin):";
				end
				if errorMessage then
					message(pluginName..errorMessage);
				else
					message(pluginName.."error");
				end
			end
		end
	end
	
  	-- GuildAdsPlugin.register : now register immediatly
  	pluginsToRegister = nil;
end

function GuildAdsPlugin_OnInit()
	-- call onInit
  	for pluginName, plugin in pairs(GuildAdsPlugin.PluginsList) do
		if type(plugin.onInit) == "function" then
			GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "onInit: "..pluginName);
			safecall(plugin.onInit)
		end
	end
end

function GuildAdsPlugin_OnChannelJoin()
	for pluginName, plugin in pairs(GuildAdsPlugin.PluginsList) do
		if type(plugin.onChannelJoin) == "function" then
			GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "onChannelJoin: "..pluginName);
			safecall(plugin.onChannelJoin)
		end
	end
end

function GuildAdsPlugin_OnChannelLeave()
	for pluginName, plugin in pairs(GuildAdsPlugin.PluginsList) do
		if type(plugin.onChannelLeave) == "function" then
			GuildAds_ChatDebug(GA_DEBUG_PLUGIN, "onChannelLeave: "..pluginName);
			safecall(plugin.onChannelLeave)
		end
	end
end

function GuildAdsPlugin_OnEvent(ltype, ...)
	local method = EventIdToMethod[ltype];
	for pluginName, plugin in pairs(GuildAdsPlugin.PluginsList) do
		if type(plugin[method]) == "function" then
			safecall(plugin[method], ...)
		end
	end
end

function GuildAdsPlugin_UIPredicate(a, b)
	-- nil references are always less than
	if (a == nil) then
		if (b == nil) then
			return false;
		else
			return true;
		end
	elseif (b == nil) then
		return false;
	end
	
	-- sort by prority
	if a.priority and b.priority then
		if a.priority < b.priority then
			return true;
		elseif a.priority > b.priority then
			return false;
		end
	end
	
	
	-- sort by frame name
	if a.frame and b.frame then
		if a.frame < b.frame then
			return true;
		elseif a.frame > b.frame then
			return false;
		end
	end

	-- same plugin twice ?
	return false;
end

function GuildAdsPlugin_GetUI(where)
	local result = {};
	for pluginName, plugin in pairs(GuildAdsPlugin.PluginsList) do
		if plugin.metaInformations and plugin.metaInformations.ui and plugin.metaInformations.ui[where] then
			tinsert(result, plugin.metaInformations.ui[where]);
		end
	end
	table.sort(result, GuildAdsPlugin_UIPredicate);
	return result;
end
