--[[

:: This file allows for the live decoding & datamining of the Blizzard Tradeskill Link. 
After scanning all available tradeskills it then populates the data into "LibTradeLinks-1.0" by Maldivia (hosted on WoWI in "TradeLinks Addon)

However, the {TradeLink} table as seen below is actually adapted from the Scanning code found in Gnomish Yellow Pages by lilsparky (hosted on WoWAce).
--Scanning code from GYP is used with permission (Aug 30th, 2009). Thanks lilsparky

--This file is provided by OrionShock, author of Guild Craft.
]]--

local client_build = tonumber( (select(2, GetBuildInfo())))
local PortToLTL
if not client_build then
	error("NO CLIENT BUILD")
	return
end

local TradeLink = {}



	local function OpenTradeLink(tradeString)
	--	ShowUIPanel(ItemRefTooltip)
	--	if ( not ItemRefTooltip:IsShown() ) then
	--		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
	--	end
		ItemRefTooltip:SetHyperlink(tradeString)
	end

	local tradeList = { 2259, 2018, 7411, 4036, 45357, 25229, 2108, 3908,  2550, 3273 }
	local spellList = {}
	local extendedInfo = {}
	local guid, playerGUID

	local encodedByte = {
							'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
							'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
							'0','1','2','3','4','5','6','7','8','9','+','/'
						}

	local decodedByte = {}

	for i=1,#encodedByte do
		local b = string.byte(encodedByte[i])

		decodedByte[b] = i - 1
	end


	local bitMapSizeGuess = { 40, 80, 45, 45, 60, 75, 80, 65, }

	local tradeIndex = 1
	local spellBit = 0
	local countDown = 5
	local bitMapSizes = {}
	local bitMapSize = bitMapSizeGuess[tradeIndex] or 0
	local timeToClose = 0
	local frameOpen = false

	local framesRegistered

	local progressBar

	local OnScanCompleteCallback


	local function ScanComplete(frame)
		frame:SetScript("OnUpdate", nil)
		frame:UnregisterEvent("TRADE_SKILL_UPDATE")
		frame:UnregisterEvent("TRADE_SKILL_CLOSE")
		frame:UnregisterEvent("TRADE_SKILL_SHOW")

		frame:Hide()

		for k,f in pairs(framesRegistered) do
			f:RegisterEvent("TRADE_SKILL_SHOW")
		end

		progressBar:Hide()

		if OnScanCompleteCallback then
			OnScanCompleteCallback(spellList)
		end
	end


	local function OnTradeSkillShow()
		if not bitMapSizes[tradeIndex] then
			bitMapSizes[tradeIndex] = bitMapSize
			spellBit = 0
			spellList[tradeList[tradeIndex]] = {}

--DEFAULT_CHAT_FRAME:AddMessage("Scanning "..GetTradeSkillLine().." "..(bitMapSize*6).." spells")
			progressBar.textLeft:SetText("Scanning "..GetTradeSkillLine().." ("..(bitMapSize*6)..")")

			timeToClose = 90				-- let's hope it doesn't come to that
		end
	end


	local function OnTradeSkillClose(frame)
		frameOpen = false
--DEFAULT_CHAT_FRAME:AddMessage("CLOSE")
		if bitMapSizes[tradeIndex] then
			spellBit = spellBit + 1

			if spellBit <= bitMapSizes[tradeIndex]*6 then
				local percentComplete = spellBit/(bitMapSizes[tradeIndex]*6)

				progressBar.fg:SetWidth(300*percentComplete)
				progressBar.textRight:SetText(spellBit)


				local bytes = floor((spellBit-1)/6)
				local bits = (spellBit-1) - bytes*6

				local bmap = string.rep("A", bytes) .. encodedByte[bit.lshift(1, bits)+1] .. string.rep("A", bitMapSizes[tradeIndex]-bytes-1)

--				bmap = string.rep("A", bytes)

				local tradeString = string.format("trade:%d:%d:%d:%s:%s", tradeList[tradeIndex], 450, 450, playerGUID, bmap)

--local link = "|cffffd000|H"..tradeString.."|h["..GetSpellInfo(tradeList[tradeIndex]).."]|h|r"
--DEFAULT_CHAT_FRAME:AddMessage(tradeString)
--DEFAULT_CHAT_FRAME:AddMessage(link)

				timeToClose = 30


				OpenTradeLink(tradeString)
			else
				tradeIndex = tradeIndex + 1
				bitMapSize = bitMapSizeGuess[tradeIndex] or 0

				if tradeIndex <= #tradeList then
					OnTradeSkillClose()
				else
					ScanComplete(frame)
				end
			end
		else
			bitMapSize = bitMapSize + 1
			bmap = string.rep("/", bitMapSize)

			local tradeString = string.format("trade:%d:%d:%d:%s:%s", tradeList[tradeIndex], 450, 450, playerGUID, bmap)

			OpenTradeLink(tradeString)
			timeToClose = .01
		end
	end


	local function OnTradeSkillUpdate(frame)
		if not bitMapSizes[tradeIndex] then
--			bitMapSizes[tradeIndex] = bitMapSize
--			spellBit = 0
--			spellList[tradeList[tradeIndex]] = {}

--			DEFAULT_CHAT_FRAME:AddMessage("Scanning "..GetTradeSkillLine().." "..(bitMapSize*6).." spells")
--			timeToClose = 30
		elseif spellBit > 0 then

			local numSkills = GetNumTradeSkills()


--DEFAULT_CHAT_FRAME:AddMessage("skills = "..tonumber(numSkills))

			spellList[tradeList[tradeIndex]][spellBit] = tradeList[tradeIndex] -- placeHolder

			if numSkills then
				for i=1,numSkills do
					local recipeLink = GetTradeSkillRecipeLink(i)

					if recipeLink then
						local id = string.match(recipeLink,"enchant:(%d+)")
--DEFAULT_CHAT_FRAME:AddMessage(spellBit.." = "..id.."-"..recipeLink)
						progressBar.textLeft:SetText(recipeLink)
						spellList[tradeList[tradeIndex]][spellBit] = tonumber(id)
						--extendedInfo[tradeList[tradeIndex]][tonumber(id)] = 
					end
				end

				timeToClose = .001
			end
		end
	end


	local function OnUpdate(frame, elapsed)
--DEFAULT_CHAT_FRAME:AddMessage("UPDATE")
		countDown = countDown - elapsed
		timeToClose = timeToClose - elapsed

--DEFAULT_CHAT_FRAME:AddMessage("countDown = "..countDown)
--		if countDown < 0 then
--			OnTradeSkillClose()
--		end

		if timeToClose < 0 then
			timeToClose = 1000
			CloseTradeSkill()
		end
	end

	function TradeLink:Scan(callback)
		OnScanCompleteCallback = callback

		framesRegistered = { GetFramesRegisteredForEvent("TRADE_SKILL_SHOW") }

		for k,f in pairs(framesRegistered) do
			f:UnregisterEvent("TRADE_SKILL_SHOW")
		end


		progressBar = CreateFrame("Frame", nil, UIParent)

		progressBar:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                                            tile = true, tileSize = 16, edgeSize = 16,
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
		progressBar:SetBackdropColor(0,0,0,1);


		progressBar:SetFrameStrata("DIALOG")

		progressBar:SetWidth(310)
		progressBar:SetHeight(30)

		progressBar:SetPoint("CENTER",0,-150)

		progressBar.fg = progressBar:CreateTexture()
		progressBar.fg:SetTexture(.8,.7,.2,.5)
		progressBar.fg:SetPoint("LEFT",progressBar,"LEFT",5,0)
		progressBar.fg:SetHeight(20)
		progressBar.fg:SetWidth(300)

		progressBar.textLeft = progressBar:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
		progressBar.textLeft:SetText("Scanning...")
		progressBar.textLeft:SetPoint("LEFT",10,0)

		progressBar.textRight = progressBar:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
		progressBar.textRight:SetText("0%")
		progressBar.textRight:SetPoint("RIGHT",-10,0)

		progressBar:EnableMouse()
		progressBar.titleText = progressBar:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
		progressBar.titleText:SetText("GuildAds (relog or /resetltldata if scan doesn't start)")
		progressBar.titleText:SetPoint("BOTTOMLEFT", progressBar, "TOPLEFT",10, 0)
		

		progressBar:SetScript("OnEnter", function(frame)
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")

			GameTooltip:AddLine("GuildAds is scanning...")
			GameTooltip:AddLine("|ca0ffffffA comprehensive scan of trade skills is required.")
			GameTooltip:AddLine("|ca0ffffffThis will take a few minutes and may pause while")
			GameTooltip:AddLine("|ca0ffffffdata is collected from the server.  A scan should")
			GameTooltip:AddLine("|ca0ffffffonly be required on initial install, when a new")
			GameTooltip:AddLine("|ca0ffffffgame patch has been released, or when GuildAds's")
			GameTooltip:AddLine("|ca0ffffffsaved variables file has been purged.")
			GameTooltip:AddLine("|ca0ffffffDuring the scan, trade skill interaction is blocked.")
			GameTooltip:AddLine("|ca0ffffffFor best result, relog once the scan is complete.")

			GameTooltip:Show()
		end)

		progressBar:SetScript("OnLeave", function(frame)
			GameTooltip:Hide()
		end)

		local scanFrame = CreateFrame("Frame")


		scanFrame:RegisterEvent("TRADE_SKILL_SHOW")
		scanFrame:RegisterEvent("TRADE_SKILL_UPDATE")
		scanFrame:RegisterEvent("TRADE_SKILL_CLOSE")

		scanFrame:SetScript("OnEvent", function(frame,event)
--DEFAULT_CHAT_FRAME:AddMessage(tostring(event))
			if event == "TRADE_SKILL_SHOW" then
				OnTradeSkillShow(frame)
			end

			if event == "TRADE_SKILL_CLOSE" then
				OnTradeSkillClose(frame)
			end

			if event == "TRADE_SKILL_UPDATE" then
				OnTradeSkillUpdate(frame)
			end
		end)

		scanFrame:SetScript("OnUpdate", OnUpdate)

		OnTradeSkillClose()
	end


	function TradeLink:BitmapEncode(data, mask)
		local v = 0
		local b = 1
		local bitmap = ""

		for i=1,#data do
			if mask[data[i]] == true then
				v = v + b
			end

			b = b * 2

			if b == 64 then
				bitmap = bitmap .. encodedByte[v+1]
				v = 0
				b = 1
			end
		end

		if b>1 then
			bitmap = bitmap .. encodedByte[v+1]
		end

		return bitmap
	end


	function TradeLink:BitmapDecode(data, bitmap, maskTable)
		local mask = maskTable or {}
		local index = 1

		for i=1, string.len(bitmap) do
			local b = decodedByte[string.byte(bitmap, i)]
			local v = 1

			for j=1,6 do
				if index <= #data and data[index] then
					if bit.band(v, b) == v then
						mask[data[index]] = true
					else
						mask[data[index]] = false
					end
				end
				v = v * 2

				index = index + 1
			end
		end

		return mask
	end


	function TradeLink:BitmapBitLogic(A,B,logic)
		local length = math.min(string.len(A), string.len(B))
		local R = ""

		for i=1, length do
			local a = decodedByte[string.byte(A, i)]
			local b = decodedByte[string.byte(B, i)]

			local r = logic(a,b)

			R = R..encodedByte[r+1]
		end

		return R
	end


	function TradeLink:DumpSpells(data, bitmap)
		local index = 1
--		Config.testOut = {}

		for i=1, string.len(bitmap) do
			local b = decodedByte[string.byte(bitmap, i)]
			local v = 1

			for j=1,6 do
				if index <= #data then
					if bit.band(v, b) == v then
						DEFAULT_CHAT_FRAME:AddMessage("bit "..index.." = spell:"..data[index].." "..GetSpellLink(data[index]))
--						Config.testOut[#Config.testOut+1] = "bit "..index.." = spell:"..data[index].." ["..GetSpellInfo(data[index]).."]"
					end
				end
				v = v * 2

				index = index + 1
			end
		end
	end



	function TradeLink:BitmapCompress(bitmap)
		if not bitmap then return end

		local len = string.len(bitmap)
		local compressed = {}
		local n = 1

		for i=1,len,5 do
			local map = 0

			map = decodedByte[string.byte(bitmap, i) or 65]

			v = decodedByte[string.byte(bitmap,i+1) or 65]
			map = bit.lshift(map, 6) + v


			v = decodedByte[string.byte(bitmap,i+2) or 65]
			map = bit.lshift(map, 6) + v


			v = decodedByte[string.byte(bitmap,i+3) or 65]
			map = bit.lshift(map, 6) + v


			v = decodedByte[string.byte(bitmap,i+4) or 65]
			map = bit.lshift(map, 6) + v

			compressed[n] = map

			n = n + 1
		end

		return compressed
	end



-- the following only operate on COMPRESSED bitmaps
	function TradeLink:BitsShared(b1, b2)
		local sharedBits = 0
		local len = math.min(#b1,#b2)

		for i=1,len do
			result = bit.band(b1[i],b2[i] or 0)
--DEFAULT_CHAT_FRAME:AddMessage(tostring(b1[i]).." "..tostring(b2[i]).." result "..result)

			if result~=0 then
				for b=0,29 do
					if bit.band(result, 2^b)~=0 then
						sharedBits = sharedBits + 1
					end
				end
			end
		end
--DEFAULT_CHAT_FRAME:AddMessage("shared "..sharedBits)
		return sharedBits
	end


	function TradeLink:CountBits(bmap)
		local bits = 0
		local len = #bmap

		for i=1,len do
			if result~=0 then
				for b=0,29 do
					if bit.band(bmap[i], 2^b)~=0 then
						bits = bits + 1
					end
				end
			end
		end
		return bits
	end

local function scanCompletedCallback(spellData)
	LIB_TRADE_LINKS_PATCH_DATA[client_build] = spellData
	--[===[@alpha@
	if not LIB_TRADE_LINKS_PATCH_DATA[client_build.."BoPList"] then
		updateLTLBoPList()
	end
	--@end-alpha@]===]
	PortToLTL(spellData)
end

local delay, interval = 0, 60
local function GYP_OnUpdate_Scan(self, elapsed)
	delay = delay + elapsed
	if delay > interval then 
		if Config.spellList then
			PortToLTL(Config.spellList)
			LIB_TRADE_LINKS_PATCH_DATA[client_build] = Config.spellList
			self:SetScript("OnUpdate", nil)
		end
		delay = 0
	end
end

local frame = CreateFrame("Frame")
--frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ALIVE")

frame:SetScript("OnEvent", function(self, event, ...)
--	print(event, ...)
	if not IsLoggedIn() then return end
	LIB_TRADE_LINKS_PATCH_DATA = LIB_TRADE_LINKS_PATCH_DATA or {}

	if LIB_TRADE_LINKS_PATCH_DATA and LIB_TRADE_LINKS_PATCH_DATA[client_build] then
		self:SetScript("OnEvent", nil)
		PortToLTL(LIB_TRADE_LINKS_PATCH_DATA[client_build])

		return
	end
	if IsAddOnLoaded("GnomishYellowPages") then
		self:SetScript("OnEvent", nil)
		self:SetScript("OnUpdate", GYP_OnUpdate_Scan)
		return
	end
	if UnitGUID("player") and (not LIB_TRADE_LINKS_PATCH_DATA[client_build] ) then
		local guid = UnitGUID("player")
		if guid then
			playerGUID = string.gsub(UnitGUID("player"),"0x0+", "")
			TradeLink:Scan(scanCompletedCallback)
			self:SetScript("OnEvent", nil)
		end
	end
end)

local LTL = LibStub("LibTradeLinks-1.0")
local LTL_BoPist = {
34543, 47046, 35587, 15596, 36129, 36137, 46106, 46114, 46130, 46138, 68067, 41317, 15628, 36257, 26882, 55183, 46776, 34544, 35580, 35588, 16969, 36122, 36130, 16985, 13628, 46107, 46115, 60403, 46131,
46139, 41318, 36258, 31082, 41135, 55184, 34537, 36075, 47048, 35589, 32808, 36131, 60619, 8770, 46108, 60396, 56089, 56077, 13702, 58144, 41311, 41319, 58143, 56203, 56202, 36078, 36259, 42589, 18456,
26875, 56086, 59759, 26873, 41160, 34538, 36076, 47049, 35582, 35590, 41208, 32801, 36124, 56087, 16986, 11459, 56085, 46109, 56084, 60405, 56083, 15296, 56081, 41312, 41320, 7795, 60971, 46778, 56076,
36260, 30565, 31079, 31083, 34534, 56056, 56055, 55186, 56469, 34547, 47050, 56054, 35591, 56053, 56052, 36125, 36133, 56484, 46779, 17632, 46110, 58868, 46126, 56079, 46142, 46777, 42588, 41321, 46775,
46125, 32259, 42592, 36261, 15633, 18457, 42591, 42593, 42590, 56199, 36317, 34540, 34548, 35576, 35584, 36357, 56481, 32810, 36126, 36134, 32809, 20051, 32807, 46111, 56574, 46127, 67025, 56088, 26914,
41314, 26912, 26911, 36355, 26900, 34541, 36262, 30566, 31080, 30574, 26872, 32667, 32665, 36318, 12906, 36079, 35577, 35585, 36358, 32664, 55185, 62271, 36135, 56487, 56486, 56049, 46112, 56483, 42558,
46136, 46144, 56480, 41315, 54353, 34530, 46116, 12897, 64054, 36263, 34529, 18458, 34533, 26881, 34545, 56201, 41164, 34542, 12717, 36077, 26909, 36359, 40274, 16980, 36128, 36391, 55187, 30575, 12908,
46113, 58871, 56074, 46137, 34546, 36074, 41316, 41162, 12755, 12718, 12759, 36256, 36392, 41206, 31081, 41133, 7421, 35575, 41157, 34535, 36136,
	--end auto gen data as of patch r10482

}
local LTL_BlackList = {
3273, 3274, 7924, 10846, 27028, 45542, 10846, 2018, 3100, 3538, 9785, 9788, 9787, 17039, 17040, 17041, 29844, 51300, 2108, 3104, 3811, 10656, 10660, 10658, 10662, 32549, 51302, 2259, 3101, 3464, 11611,
28596, 28677, 28675, 28672, 51304, 53042, 60893, 2550, 3102, 3413, 818, 18260, 33359, 51296, 2580, 2575, 2576, 2656, 3564, 8388, 10248, 29354, 32606, 50310, 53120, 53121, 53122, 53123, 53124, 53040,
3908, 3909, 3910, 12180, 26801, 26798, 26797, 26790, 51309, 59390, 4036, 4037, 4038, 12656, 20222, 20219, 4073, 12749, 19804, 13166, 13258, 30350, 49383, 51306, 56273, 7411, 7412, 7413, 13262, 13920,
28029,51313, 25229, 25230, 28894, 28895, 28897, 31252, 51311, 55534, 45357, 45358, 45359, 45360, 45361, 45363, 51005, 52175, 61177, 61288,
}


function PortToLTL(spellData)
--	print("porting data to LTL")
	LTL:RegisterBuild(client_build);
	LTL:SetBlackList(client_build,	LTL_BlackList )	
	LTL:SetBoPList(client_build, LIB_TRADE_LINKS_PATCH_DATA[client_build.."BoPList"] or LTL_BoPist )
--	print("set the BoP and Blacklists")
	local extraId = {
		[LTL.SKILL_COOKING] = { 2550,3102,3413,18260,33359,51296,88053 }, -- Cataclysm: 88053
		[LTL.SKILL_JEWELCRAFTING] = { 25229,25230,28894,28895,28897,51311,73318 }, -- Cataclysm: 73318
		[LTL.SKILL_ENGINEERING] = { 4036,4037,4038,12656,20222,20219,30350,51306,82774 }, -- Cataclysm: 82774
		[LTL.SKILL_BLACKSMITHING] = { 2018,3100,3538,9785,9788,9787,17039,17040,17041,29844,51300,76666 }, -- Cataclysm: 76666
		[LTL.SKILL_FIRSTAID] = { 3273,3274,7924,10846,27028,45542,10846,74559 }, -- Cataclysm: 74559
		[LTL.SKILL_LEATHERWORKING] = { 2108,3104,3811,10656,10660,10658,10662,32549,51302,81199 }, -- Cataclysm: 81199
		[LTL.SKILL_TAILORING] = { 3908,3909,3910,12180,26801,26798,26797,26790,51309,75156 }, -- Cataclysm: 75156
		[LTL.SKILL_INSCRIPTION] = { 45357,45358,45359,45360,45361,45363,86008 }, -- Cataclysm 86008
		[LTL.SKILL_ENCHANTING] = { 7411,7412,7413,13920,28029,51313,74258 }, -- Cataclysm: 74258
		[LTL.SKILL_ALCHEMY] = { 2259,3101,3464,11611,28596,28677,28675,28672,51304,80731 }, -- Cataclysm: 80731
		[LTL.SKILL_MINING] = { 2656 },
	}
--	print("Pairing though")
	for spellID, spellList in pairs(spellData) do
--		print("Eval", (GetSpellInfo(spellID)) )
		for name, specList in pairs(extraId) do
			for i = 1, #specList do
				if specList[i] == spellID then
--					print("Adding", (GetSpellInfo(spellID)) )
					LTL:AddData(client_build, name, specList, spellList)
				end
			end
		end
	end
end

local temBoPList = {}
for i,v in ipairs(LTL_BoPist) do
	temBoPList[v] = true
end

local LibGratuity = LibStub("LibGratuity-3.0")
function updateLTLBoPList()	
	for trade, spellList in pairs(LIB_TRADE_LINKS_PATCH_DATA[client_build]) do
		--print("Scanning", GetSpellInfo(trade), "for BoP")
		for i, id in ipairs(spellList) do
			LibGratuity:SetHyperlink("spell:"..id)
			if LibGratuity:Find(ITEM_BIND_ON_PICKUP) then
				--print("Found", GetSpellInfo(id), " is BoP, adding")
				temBoPList[id] = true
			end
		end
	end
	local newBoPList = {}
	for k,v in pairs(temBoPList) do
		tinsert(newBoPList, k)
	end
	LIB_TRADE_LINKS_PATCH_DATA[client_build.."BoPList"] = newBoPList
end
