----------------------------------------------------------------------------------
--
-- GuildAdsCodecs.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

GuildAdsCodecs = {}

-------------------------------------------
GuildAdsCodec = {};

function GuildAdsCodec:new(o, id, version)
	o = o or {};
	o.version = version;
	self.__index = self;
	setmetatable(o, self);
	if GuildAdsCodecs[id] then
		if tonumber(version or 0)>GuildAdsCodecs[id].version then
			GuildAdsCodecs[id] = o;
		end
	else
		GuildAdsCodecs[id] = o;
	end
	return o;
end

function GuildAdsCodec.encode(o)
	error("call to an undefined codec", 2);
end;

function GuildAdsCodec.decode(s)
	error("call to an undefined codec", 2);
end;

-------------------------------------------
GuildAdsCodecTable = GuildAdsCodec:new({}, "Table", 1);

local t = {};
function GuildAdsCodecTable.encode(o)
	local s = self.schema;
	table.setn(t, table.getn(s));
	local l;
	for i, d in ipairs(s) do
		t[i] = GuildAdsCodecs[d.codec].encode(o[d.key]);
		if t[i] ~= "" then
			l = i;
		end
	end
	if l then
		return table.concat(t, ">", 1, l)..">";
	else
		return "";
	end
end

function GuildAdsCodecTable.decode(o)
	local o;
	local s = self.schema;
	local i=1;
	
	for str in string.gfind(text, "([^\>]*)>") do
		o = o or {};
		local d = s[i];
		if d then
			o[d.key] = GuildAdsCodecs[d.codec].decode(str);
		end
		
		i = i + 1;
	end
	
	return o;
end

-------------------------------------------
GuildAdsCodecGeneric = GuildAdsCodec:new({}, "Generic", 1);

function GuildAdsCodecGeneric.encode(obj)
	if obj == nil then 
		return "";
	elseif ( type(obj) == "string" ) then
		return "s"..GuildAdsCodecString.encode(str);
	elseif ( type(obj) == "number" ) then
		return "n"..obj;
	elseif ( type(obj) == "boolean" ) then
		if (value) then
			return "1";
		else
			return "0";
		end
	elseif ( type(obj) == "function" ) then
		return ""; -- nil
	elseif ( type(obj) == "table" ) then
		return ""; -- nil
	end
	return "";
end

function GuildAdsCodecGeneric.decode(str)
	if (str == "") then
		return nil;
	else
		typeString = string.sub(str, 0, 1);
		valueString = string.sub(str, 2);
		if (typeString == "s") then
			return GuildAdsCodecString.decode(str);
		elseif (typeString == "n") then
			return tonumber(valueString);
		elseif (typeString == "1") then
			return true;
		elseif (typeString == "0") then
			return false;
		else
			GuildAds_ChatDebug(GA_DEBUG_PROTOCOL,"GuildAds_Unserialize: Type non reconnu:"..str);
			return nil;
		end
	end
end

-------------------------------------------
GuildAdsCodecInteger = GuildAdsCodec:new({}, "Integer", 1);

function GuildAdsCodecInteger.encode(obj)
	if obj then
		return tostring(obj)
	end
	return "";
end

function GuildAdsCodecInteger.decode(str)
	if str then
		return tonumber(str);
	end
end

-------------------------------------------
GuildAdsCodecBigInteger = GuildAdsCodec:new({}, "BigInteger", 1);

function GuildAdsCodecBigInteger.encode(obj)
	if obj then
		-- convertion en base 52
		value = "";
		while (obj ~= 0) do
			i = math.floor(obj / 52);
			j = obj - i*52;
			if (j>=26) then
				value = string.char(65+j-26)..value;
			else
				value = string.char(96+j)..value;
			end
			obj = i;
		end
		return value;
	end
	return "";
end

function GuildAdsCodecBigInteger.decode(str)
	if str == "" then
		return nil;
	else
		number = 0;
		for i=1, string.len(str),1  do
			o = string.byte(str, i);
			if (o> 95) then
				j = o-96;
			else
				j = o-65+26;
			end
			number = number*52 + j;
		end
		return number;
	end
end

-------------------------------------------
GuildAdsCodecString = GuildAdsCodec:new({}, "String", 1);

GuildAdsCodecString.SpecialChars = "|>,/:;&|\n";

GuildAdsCodecString.SpecialCharMap =
{
	p = "|",
	gt = ">",
	c = ",",
	s = "/",
	cn = ":",
	sc = ";",
	a = "&",
	b = "|",
	n = "\n",
};

function GuildAdsCodecString.encode(pString)
	return string.gsub(
					pString or "",
					"(["..GuildAdsCodecString.SpecialChars.."])",
					function (pField)
						for vName, vChar in GuildAdsCodecString.SpecialCharMap do
							if vChar == pField then
								return "&"..vName..";";
							end
						end
						
						return "";
					end);
end

function GuildAdsCodecString.decode(pString)
	return string.gsub(
					pString,
					"&(%w+);", 
					function (pField)
						local	vChar = GuildAdsCodecString.SpecialCharMap[pField];
						
						if vChar ~= nil then
							return vChar;
						else
							return pField;
						end
					end);
end

-------------------------------------------
GuildAdsCodecTexture = GuildAdsCodec:new({}, "Texture", 1);

function GuildAdsCodecTexture.encode(str)
	if obj == nil then
		return "";
	else
		return string.gsub(obj, "Interface\\Icons\\", "\@");
	end
end

function GuildAdsCodecTexture.decode(str)
	if str == "" then
		return nil;
	else
		return string.gsub(str, "\@", "Interface\\Icons\\");
	end
end

-------------------------------------------
GuildAdsCodecItemRef = GuildAdsCodec:new({}, "ItemRef", 1);

function GuildAdsCodecItemRef.encode(str)
	if obj == nil then
		return "";
	else
		return string.gsub(string.gsub(obj, "item\:", "\@"), ":0:0:0", "\*");
	end
end

function GuildAdsCodecItemRef.decode(str)
	if str == "" then
		return nil;
	else
		return string.gsub(string.gsub(str, "\@", "item\:"), "\*", ":0:0:0");
	end
end

-------------------------------------------
GuildAdsCodecColor = GuildAdsCodec:new({}, "Color", 1);

GuildAdsCodecColor.SerializeColorData = {
	["ffa335ee"]="E";
	["ff0070dd"]="R";
	["ff1eff00"]="U";
	["ffffffff"]="C";
	["ff9d9d9d"]="P";
};

GuildAdsCodecColor.UnserializeColorData = {
	["E"]="ffa335ee";
	["R"]="ff0070dd";
	["U"]="ff1eff00";
	["C"]="ffffffff";
	["P"]="ff9d9d9d";
};

GuildAdsCodecColor.ColorMetaTable = {
	__index = function(t, i)
		return i;
	end;
};
setmetatable(GuildAdsCodecColor.SerializeColorData, GuildAdsCodecColor.ColorMetaTable);
setmetatable(GuildAdsCodecColor.UnserializeColorData, GuildAdsCodecColor.ColorMetaTable);

function GuildAdsCodecColor.encode(obj)
	if obj then
		return GuildAdsCodecColor.SerializeColorData[obj];
	end
	return "";
end

function GuildAdsCodecColor.decode(str)
	if str then
		return GuildAdsCodecColor.UnserializeColorData[str];
	end
end
