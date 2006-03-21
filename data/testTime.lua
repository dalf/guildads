function GetGameTime()
	return 16,59;
end

function GetPCTime()
	return 15,0;
end

-- dofile("C:\\Program Files\\World of Warcraft\\Interface\\AddOns\\GuildAds\\data\\GuildAdsTime.lua")

local HourMin = 60;
local DayMin = HourMin * 24;
local MonthMin = DayMin * 30;
local TimeRef = 18467940; 	-- Nombre de minutes entre 1/1/1970 et 11/2/2005

function GAS_currentTime()
	local hours,minutes = GetGameTime();
	local t = os.date("!*t");
	t.wday = nil;
	t.yday = nil;
	t.isdst = nil;
	t.sec = nil;
	
	local local_min = t.hour*60+t.min;
	
	local TimeShift = hours*60+minutes-local_min;
	if math.abs(TimeShift)>=12*60 then
		if local_min<server_min then
			TimeShift = TimeShift-DayMin;
		else
			TimeShift = TimeShift+DayMin;
		end
	end
	
	t.hour, t.min = hours, minutes;
	-- local_min+TimeShift : server time not round between 0 and DayMin
	return math.floor(os.time(t) / 60)+math.floor((local_min+TimeShift)/DayMin)*DayMin-TimeRef;
end

local r = (GAS_currentTime()+TimeRef)*60;
print(os.date("%d/%m/%y %H:%M", r));