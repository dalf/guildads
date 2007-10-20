----------------------------------------------------------------------------------
--
-- GuildAdsTask.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- based on TimeXCore.lua, revision 637 from https://opensvn.csie.org/traccgi/Ace/trac.cgi/browser/trunk/Timex/Core

GuildAdsTask = { };

local emptyArray = {};
local frame;
local timerDB = {};

local OnUpdate = function()
	for k, v in pairs(timerDB) do
		v.e = v.e + (arg1 or 0.015)
		if not v.t then elseif v.e >= v.t then v.e = 0
			if v.c then
				v.c = v.c - 1
				if v.c <= 0 then
					tremove(timerDB, k)
				end
			elseif not v.r then
				tremove(timerDB, k)
			end
			if v.f then 
				v.f(unpack(v.a or emptyArray))
			end
		end
	end
	if not next(timerDB) then
		frame:Hide()
	end
end

function GuildAdsTask:Initialize()
	frame = CreateFrame("Frame")
	frame:SetScript("OnUpdate", OnUpdate)
end

function GuildAdsTask:NamedScheduleCheck(n, r)
    for k, v in pairs(timerDB) do
		if v.n == n then
			r = r and (v.e or 0) or TRUE
			return r
		end
	end
end

function GuildAdsTask:AddNamedSchedule(n, t, r, c, f, ...)
	if not n and not t then return end
    self:DeleteNamedSchedule(n)
    tinsert(timerDB, {
		n = n or this:GetName(),
        t = tonumber(t),
        r = r,
        c = tonumber(c),
        e = 0,
        f = f,
		a = { select(1, ...) }
	})
	frame:Show()
end

function GuildAdsTask:DeleteNamedSchedule(n)
	for k, v in pairs(timerDB) do
		if v.n == n then tremove(timerDB, k) end
	end
	if not next(timerDB) then
		frame:Hide()
	end
end

function GuildAdsTask:ChangeDuration(n, t)
	for k, v in pairs(timerDB) do
		if v.n == n then v.t = t or v.t end
	end
end

