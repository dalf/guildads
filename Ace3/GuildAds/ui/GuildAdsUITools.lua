----------------------------------------------------------------------------------
--
-- GuildAdsUITools.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsUITools = {}

GuildAdsUITools.onlineColor = {
	[true]				= { ["r"] = 1,    ["g"] = 0.86, ["b"] = 0 },
	[false]				= { ["r"] = 0.5,  ["g"] = 0.5,  ["b"] = 0.5 },
}

GuildAdsUITools.accountOnlineColor = {
	[true]				= { ["r"] = 0.75, ["g"] = 0.75,	["b"] = 0.90 },
	[false]				= { ["r"] = 0.5,  ["g"] = 0.5,  ["b"] = 0.5 },
}

GuildAdsUITools.onlineColorHex = {
	[true]				= string.format("|cff%02x%02x%02x", GuildAdsUITools.onlineColor[true].r*255, GuildAdsUITools.onlineColor[true].g*255, GuildAdsUITools.onlineColor[true].b*255),
	[false]				= string.format("|cff%02x%02x%02x", GuildAdsUITools.onlineColor[false].r*255, GuildAdsUITools.onlineColor[false].g*255, GuildAdsUITools.onlineColor[false].b*255)
}

GuildAdsUITools.accountOnlineColorHex = {
	[true]				= string.format("|cff%02x%02x%02x", GuildAdsUITools.accountOnlineColor[true].r*255, GuildAdsUITools.accountOnlineColor[true].g*255, GuildAdsUITools.accountOnlineColor[true].b*255),
	[false]				= string.format("|cff%02x%02x%02x", GuildAdsUITools.accountOnlineColor[false].r*255, GuildAdsUITools.accountOnlineColor[false].g*255, GuildAdsUITools.accountOnlineColor[false].b*255)
}

GuildAdsUITools.noteColor = { ["r"] = 0.3,	["g"] = 0.6,	["b"] = 1.0 };
GuildAdsUITools.white	  = { ["r"] = 1.0,	["g"] = 1.0, 	["b"] = 1.0 };

GuildAdsUITools.invalid   = { ["r"] = 1.0,	["g"] = 0.5, 	["b"] = 0.5 };
GuildAdsUITools.invalidHex = string.format("|cff%02x%02x%02x", GuildAdsUITools.invalid.r*255, GuildAdsUITools.invalid.g*255, GuildAdsUITools.invalid.b*255);

GuildAdsUITools.MAX_LINE_SIZE = 60;

-- getChatFrame	 
local function getChatFrame(lookForChannelName)	 
	lookForChannelName = strupper(lookForChannelName)	 
	local i=1	 
	while getglobal("ChatFrame"..i) ~= nil do	 
		local chatFrame = getglobal("ChatFrame"..i)	 
	    local channelList = chatFrame.channelList	 
	    if type(channelList)=="table" then	 
			for _, channelName in ipairs(channelList) do	 
				if strupper(channelName) == lookForChannelName then	 
					return chatFrame	 
				end	 
			end	 
		end	 
	    i = i + 1	 
	end	 
	return nil	 
end

-- Add a long text to a tooltip : word wrap each line to GuildAdsUITools.MAX_LINE_SIZE char.
function GuildAdsUITools:TooltipAddText(tooltip, text, r, g, b)
	if tooltip and text then
		r = r or self.noteColor.r;
		g = g or self.noteColor.g;
		b = b or self.noteColor.b;
		line = "";
		text = string.gsub(text, "|(%w+)|H([%w:]+)|h([^|]+)|h|r", "%3");
		for word in string.gmatch(text,"[^ ]+") do
			if (string.len(line) > self.MAX_LINE_SIZE) then
				GameTooltip:AddLine(line, r, g, b);
				line = word;
			else
				line = line.." "..word;
			end
		end
		if (string.len(line) > 0) then
			tooltip:AddLine(line, r, g, b);
		end
	end
end

function GuildAdsUITools:TooltipAddTT(tooltip, color, ref, name, count)
	if (EnhTooltip and ref and name) then
		local link = GuildAds_ImplodeItemRef(color, ref, name);
		-- EnhTooltip.TooltipCall(frame,name,link,quality,count,price,forcePopup,hyperlink)
		EnhTooltip.TooltipCall(tooltip, name, link, -1, count, 0);
	end
end

function GuildAdsUITools:AddChatMessage(message)
	local info = ChatTypeInfo["CHANNEL"..GetChannelName( GuildAds.channelName )]
	local frame = getChatFrame(GuildAds.channelName) or DEFAULT_CHAT_FRAME
	frame:AddMessage(message, info.r, info.g, info.b, info.id);
end

function GuildAdsUITools:AddSystemMessage(message)
	local info = ChatTypeInfo["SYSTEM"];
	DEFAULT_CHAT_FRAME:AddMessage(message, info.r, info.g, info.b, info.id);
end

function GuildAdsUITools:HexaToRGBColor(hexaColor)
	local red = tonumber(strsub(hexaColor, 3, 4), 16) / 255;
	local green = tonumber(strsub(hexaColor, 5, 6), 16) / 255;
	local blue = tonumber(strsub(hexaColor, 7, 8), 16) / 255;
	return red, green, blue;
end