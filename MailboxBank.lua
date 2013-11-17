--@@ TODO: solve COD item, maybe displaying COD amount above the slot icon or using tool-tip
	--UC..don't know how to layout in tool-tip..
--@@ TODO: change frame's layout!
	--holy shit..
--@@ TODO: should stacked attachments can be collect??
	--UC.. new window to produce? or pop-up ? COD to collect?
--@@ TODO: should attachments be alerted to player to collect when almost in deadline?
	--UC.. to optimize

--@@ TODO: optimize & combine same action in function Filter() UpdateRevIdxTb() InsToIdxTb()
--local MB = LibStub("AceAddon-3.0"):NewAddon("MailboxBank")
local L = LibStub("AceLocale-3.0"):GetLocale("MailboxBank")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local len, sub, find, format, match = string.len, string.sub, string.find, string.format, string.match
local playername = GetUnitName("player")..'-'..GetRealmName()
local selectChar = playername
local slotDB, subIdxTb, revSubIdxTb, sumQuality
local selectSortChanged
local codMoney, codMailIndex, codAttachmentIndex

local MB = CreateFrame("Frame", nil , UIParent)

MB.config_const = {
	daysLeftYellow = 7,
	daysLeftRed = 3,
	daysLeftWarning = 5,
	buttonSize = 36,
	buttonSpacing = 4,
	numItemsPerRow = 8,
	numItemsRows = 5,
	itemsSlotDisplay = 40,
	frameWidth = 360,
	frameHeight = 580,
	rowcount = 8,
}

MB.config_init = {
	px = 0,
	py = 0,
	isStacked = false,
}

function MB:AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, money, CODAmount, wasReturned, recipient, firstItem)
	local reciever
	if recipient then
		reciever = recipient
		if firstItem == true then
			local t ={}
			tinsert(MB_DB[reciever], 1, t)
		end
	else
		reciever = playername
	end
	
	if not MB_DB[reciever][mailIndex] or firstItem then
		MB_DB[reciever][mailIndex] = {}
		MB_DB[reciever][mailIndex].sender = sender
		MB_DB[reciever][mailIndex].daysLeft = daysLeft
		MB_DB[reciever][mailIndex].wasReturned = wasReturned
		if money > 0 then MB_DB[reciever][mailIndex].money = money end
		if CODAmount > 0 then MB_DB[reciever][mailIndex].CODAmount = CODAmount end
		MB_DB[reciever].mailCount = MB_DB[reciever].mailCount + 1
	end
	
	if not itemLink then return end
	MB_DB[reciever][mailIndex][attachIndex] = {}
	MB_DB[reciever][mailIndex][attachIndex].count = count
	MB_DB[reciever][mailIndex][attachIndex].itemLink = itemLink
	MB_DB[reciever].itemCount = MB_DB[reciever].itemCount + 1
end
--[[
new structure:
				mailIndex	attachIndex
[charName] = {	[1]			[1]			{	.count
				[n]			.sender			.itemLink
				.daysLeft 	.wasReturned
				.mailCount	.CODAmount?
				.itemCount	.money?
enum:
for i = 1, getn(mailIndex) do
	curr.sender, curr.daysLeft, curr.wasReturned, curr.CODAmount
	for j = 1, ATTACHMENTS_MAX_RECEIVE do
		if MB_DB[charName].i.j then
			
		end
	end
end

get position(sortDB, filter, updateContainer):
from i, j (mailIndex, attachIndex)

old:
[charName] = {	[1]		{	.sender .count .itemLink .daysLeft .mailIndex
							.attachIndex .wasReturned .CODAmount?
]]
function MB:CheckMail(isCollectMoney)
	if isCollectMoney and MB_DB[playername].money == 0 then return end
	MB_DB[playername] = {mailCount = 0, itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			--local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			local _, _, sender, _, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, _, _, _ = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then
				if isCollectMoney then
					TakeInboxMoney(mailIndex)
				else
					MB_DB[playername].money = MB_DB[playername].money + money
				end
			end
			if hasItem then
				if sender == nil then
					sender = L["UNKNOWN SENDER"]
				end
				for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
					local itemLink = GetInboxItemLink(mailIndex, attachIndex)
					if itemLink then
						local _, _, count, _, _ = GetInboxItem(mailIndex, attachIndex)
						self:AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, money, CODAmount, wasReturned)
					end
				end
			elseif money > 0 then
				self:AddItem(sender, nil, nil, daysLeft, mailIndex, nil, money, CODAmount, wasReturned)
			
			end
		end
	end
	MB_DB[playername].checkMailTick = time()
	--return true
end

function MB:CalcLeftDay(player, mailIndex)
	return floor(difftime(floor(MB_DB[player][mailIndex].daysLeft * 86400) + MB_DB[player].checkMailTick,time()) / 86400)
end

function MB:UpdateSearch()
	local MIN_REPEAT_CHARACTERS = 3;
	local searchString = self.searchingBar:GetText();
	if (len(searchString) > MIN_REPEAT_CHARACTERS) then
		local repeatChar = true;
		for i=1, MIN_REPEAT_CHARACTERS, 1 do 
			if ( sub(searchString,(0-i), (0-i)) ~= sub(searchString,(-1-i),(-1-i)) ) then
				repeatChar = false;
				break;
			end
		end
		if ( repeatChar ) then
			self:SearchBarResetAndClear();
			self:Update();
			return;
		end
	end
	self:Update();
end

function MB:OpenEditbox()
	self.searchingBarText:Hide();
	self.searchingBar:Show();
	self.searchingBar:SetText(SEARCH);
	self.searchingBar:HighlightText();
end

function MB:SearchBarResetAndClear()
	self.searchingBarText:Show();
	self.searchingBar:ClearFocus();
	self.searchingBar:SetText("");
end

function MB:CollectMoney()
	self:CheckMail(true)
end

---- Sorting ----

function MB:BuildSortOrder()
	self.AhSortIndex = {}
	local c = 0;
	for i, iType in ipairs({GetAuctionItemClasses()}) do
		self.AhSortIndex[iType] = i
		for ii, isType in ipairs({GetAuctionItemSubClasses(i)}) do
			c = c + 1;
			self.AhSortIndex[isType] = c;
		end
	end
end

function MB:UpdateRevIndexTable(keyword, method) --keyword as [sender], "uncommom"
	local insertIndex
	if revSubIdxTb.__count == 0 then --table is nil(money can add only once)
		revSubIdxTb.__count = revSubIdxTb.__count + 1
		insertIndex = revSubIdxTb.__count
	elseif not method then --add to last
		revSubIdxTb.__count = revSubIdxTb.__count + 1
		insertIndex = revSubIdxTb.__count
	elseif method == "AH" then--table is not empty
		local AhIndex = self.AhSortIndex[keyword]
		for i, v in ipairs(subIdxTb) do --table is not empty
			if self.AhSortIndex[subIdxTb[i].keyword] > AhIndex then --can insert before end of table
				for ii = i, revSubIdxTb.__count do --move items after current key
					revSubIdxTb[subIdxTb[ii].keyword] = ii + 1
				end
				revSubIdxTb.__count = revSubIdxTb.__count + 1
				insertIndex = i
				break
			elseif i == getn(subIdxTb) then --insert to end of table
				revSubIdxTb.__count = revSubIdxTb.__count + 1
				insertIndex = revSubIdxTb.__count
				break
			end
		end
	elseif method == "quality" or method == "left day" then --keyword is sortable
		for i, v in ipairs(subIdxTb) do --table is not empty
			if subIdxTb[i].keyword > keyword then --can insert before end of table
				for ii = i, revSubIdxTb.__count do --move items after current key
					revSubIdxTb[subIdxTb[ii].keyword] = ii + 1
				end
				revSubIdxTb.__count = revSubIdxTb.__count + 1
				insertIndex = i
				break
			elseif i == getn(subIdxTb) then --insert to end of table
				revSubIdxTb.__count = revSubIdxTb.__count + 1
				insertIndex = revSubIdxTb.__count
				break
			end
		end
	end
	revSubIdxTb[keyword] = insertIndex
	local t = {}
	t.keyword = keyword
	t.itemslotCount = 0
	tinsert(subIdxTb, insertIndex, t)
end

function MB:InsertToIndexTable(keyword, mailIndex, attachIndex, method)
	if not keyword or not mailIndex then return end
	if not revSubIdxTb[keyword] then
		 self:UpdateRevIndexTable(keyword, method)
	end
	local subIdx = revSubIdxTb[keyword]
	if method == "money" then
		if keyword then
			tinsert(subIdxTb[subIdx], mailIndex)
			print("done!")
		end
		return
	end
	if not attachIndex then return end
	local itemID = tonumber(match(MB_DB[selectChar][mailIndex][attachIndex].itemLink, "item:(%d+)"))
	local itemIdxTb = {mailIndex = mailIndex,attachIndex = attachIndex}
	if getn(subIdxTb[subIdx]) == 0 then --no items in this type yet..
		subIdxTb[subIdx][1] = {["itemID"] = itemID}--,["count"] = 1}
		subIdxTb[subIdx][1][1] = itemIdxTb
		subIdxTb[subIdx].itemslotCount = 1
		return
	else
		for i, v in ipairs(subIdxTb[subIdx]) do
			if subIdxTb[subIdx][i].itemID > itemID then --can insert before end of table
				local t = {[1] = itemIdxTb, itemID = itemID}
				tinsert(subIdxTb[subIdx], i, t)
				subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
				return
			elseif subIdxTb[subIdx][i].itemID == itemID then --same itemID
				for ii, v in ipairs(subIdxTb[subIdx][i]) do
					if MB_DB[selectChar][v.mailIndex][v.attachIndex].count >  MB_DB[selectChar][mailIndex][attachIndex].count then --can insert before this count
						tinsert(subIdxTb[subIdx][i], ii, itemIdxTb)
						subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
						return
					elseif ii == getn(subIdxTb[subIdx][i]) then --insert to end of this itemID
						tinsert(subIdxTb[subIdx][i], itemIdxTb)
						subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
						return
					end
				end
			elseif i == getn(subIdxTb[subIdx]) then  --insert to end of table
				local t = {[1] = itemIdxTb, itemID = itemID}
				tinsert(subIdxTb[subIdx], t)
				subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
				return
			end
		end
	end
end

MB.SelectSortMethod = {
	["AH"] = function(self, mailIndex, attachIndex)
		if not self.AhSortIndex then self:BuildSortOrder() end
		local itemID = tonumber(match(MB_DB[selectChar][mailIndex][attachIndex].itemLink, "item:(%d+)"))
		local _, _, itemRarity, _, _, _, itemSubType, _, _, _, _ = GetItemInfo(itemID)
		self:InsertToIndexTable(itemSubType, mailIndex, attachIndex, "AH")	
	end,
	["sender"] = function(self, mailIndex, attachIndex)
		local sender = MB_DB[selectChar][mailIndex].sender
		self:InsertToIndexTable(sender, mailIndex, attachIndex)	
	end,
	["quality"] = function(self, mailIndex, attachIndex)
		local _, _, quality, _, _, _, _, _, _, _ = GetItemInfo(MB_DB[selectChar][mailIndex][attachIndex].itemLink)
		self:InsertToIndexTable(quality, mailIndex, attachIndex, "quality")
	end,
	["left day"] = function(self, mailIndex, attachIndex)
		local leftday = self:CalcLeftDay(selectChar, mailIndex)
		self:InsertToIndexTable(leftday, mailIndex, attachIndex, "left day")
	end,
	["C.O.D."] = function(self, mailIndex, attachIndex)
		local isCOD
		if MB_DB[selectChar][mailIndex].CODAmount then
			isCOD = "is C.O.D."
		else
			isCOD = "not C.O.D."
		end
		self:InsertToIndexTable(isCOD, mailIndex, attachIndex)
	end,
	["money"] = function(self, mailIndex)
		local hasMoney
		if MB_DB[selectChar][mailIndex].money then
			hasMoney = "has money"
		end
		self:InsertToIndexTable(hasMoney, mailIndex, nil, "money")
	end,
}

--[[ subIdxTb structure
			subType		itemsID			sameID items	slot?
						(sort by ID)	(sort by count)
subIdxTb{	[1]		{ 	[1]			{	[1]		=		{ [mailIndex, attachIndex](.itemCount)
			[2]			[2]				[2]
			...			...				...
			[n]			[n]				[n]
			/.method	.keyword		.itemID
						.itemslotCount
]]
--insert and return position (c)!
--先排序，再看过滤器，最后看堆叠
--排序已经完成，过滤器就是从排序当中得到子表。
--堆叠就是把同itemID的当做一个表插入到sortDB
--[[ revSubIdxTb structure
				subTypeName		subType
revSubIdxTb{	["a"] 		=	1
				["b"]		=	2
				...			
				["n"]		=	n
				.__count = count
]]
--build filter menu base on subType!

function MB:SummingForQuality(slotdb)
	local mailIndex, attachIndex = slotdb.mailIndex, slotdb.attachIndex
	if not mailIndex or not attachIndex or not selectChar then return end
	local _, _, quality, _, _, _, _, _, _, _ = GetItemInfo(MB_DB[selectChar][mailIndex][attachIndex].itemLink)
	if not quality then return end
	if not sumQuality[quality] then sumQuality[quality] = 0 end
	local count = MB_DB[selectChar][mailIndex][attachIndex].count
	sumQuality[quality] = sumQuality[quality] + count
end
--[[
structure of slotDB:
case1: isStack
slotDB{		[1]		{	[1].mailIndex .attachIndex
			[2]			[2].mailIndex .attachIndex
case2: not stack
slotDB{		[1]		{	[1].mailIndex .attachIndex
			[2]		{	[1].mailIndex .attachIndex
case3: money only
slotDB{		[1]		.mailIndex
			[2]		
]]

function MB:SubFilter(i, c)
	for j = 1, getn(subIdxTb[i]) do
		if not MB_config.isStacked then
			for k = 1, getn(subIdxTb[i][j]) do
				c = c + 1
				slotDB[c] = {}
				slotDB[c][1] = subIdxTb[i][j][k]--??
				self:SummingForQuality(slotDB[c][1])
			end
		else
			c = c + 1
			slotDB[c] = subIdxTb[i][j]
			for k = 1, getn(subIdxTb[i][j]) do
				self:SummingForQuality(subIdxTb[i][j][k])
			end
		end
	end
end

function MB:Filter()
	if not subIdxTb then return end
	slotDB = {}
	sumQuality = {}
	local filter = UIDropDownMenu_GetSelectedValue(MailboxBankFrameFilterDropDown)
	if not filter then filter = "__all" end
	local c = 0
	
	local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
	if method == "money" then
		for i = 1, getn(subIdxTb[1]) do
			c = c + 1
			print(subIdxTb[1][i])
			slotDB[c] = subIdxTb[1][i]
		end
		return
	end
	if filter == "__all" then
		for i = 1, getn(subIdxTb) do
			self:SubFilter(i, c)
		end
	else
		i = revSubIdxTb[filter]
		self:SubFilter(i, c)
	end
end

function MB:SortDB()
	local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
	if not method then return end
	subIdxTb = {}
	--subIdxTb.method = method
	revSubIdxTb = {__count = 0}
	if not MB_DB[selectChar] then return end
	for mailIndex = 1, MB_DB[selectChar].mailCount do
		if not MB_DB[selectChar][mailIndex] then return end
		if method == "money" then
			if MB_DB[selectChar][mailIndex].money then
				self.SelectSortMethod[method](self, mailIndex)
			end
		else
			for attachIndex, t in pairs(MB_DB[selectChar][mailIndex]) do
				if type(t) == "table" then
					self.SelectSortMethod[method](self, mailIndex, attachIndex)
				end
			end
		end
	end
	local f = self
	UIDropDownMenu_Initialize(MailboxBankFrameFilterDropDown, function(self)
		f:FilterMenuInitialize(self, f)
	end)
	self:Filter()
end

function MB:InsertToSlot(slot, slotdb, isInit, isMoney)
	local mailIndex, attachIndex
	if isMoney then
		mailIndex = slotdb
	else
		mailIndex, attachIndex = slotdb.mailIndex, slotdb.attachIndex
	end
	
	if not mailIndex then return end
	if isInit then
		if not isMoney then
			slot.link = MB_DB[selectChar][mailIndex][attachIndex].itemLink ----wrong!!?
		else
			slot.link = nil
		end
		slot.checkMailTick = MB_DB[selectChar].checkMailTick
		slot.sender = {}
		slot.dayLeft = {}
		slot.countNum = {}
		slot.wasReturned = nil
		slot.CODAmount = nil
		slot.mailIndex = nil
		slot.attachIndex = nil
		-- slot.wasReturned = {}
		-- slot.CODAmount = {}
		if not MB_config.isStacked then
			slot.wasReturned = MB_DB[selectChar][mailIndex].wasReturned
			slot.CODAmount = MB_DB[selectChar][mailIndex].CODAmount
		end
	end
	if selectChar == playername then
		if not slot.mailIndex then slot.mailIndex = {} end
		tinsert(slot.mailIndex , mailIndex)
		if not isMoney then
			if not slot.attachIndex then slot.attachIndex = {} end
			tinsert(slot.attachIndex , attachIndex)
		end
	end
	tinsert(slot.sender , MB_DB[selectChar][mailIndex].sender)
	tinsert(slot.dayLeft , MB_DB[selectChar][mailIndex].daysLeft)
	if not isMoney then
		tinsert(slot.countNum , MB_DB[selectChar][mailIndex][attachIndex].count)
	end
	-- local index = getn(slot.dayLeft)
	-- tinsert(slot.wasReturned, index, MB_DB[selectChar][itemIndexCount].wasReturned)
	-- tinsert(slot.CODAmount, index, MB_DB[selectChar][itemIndexCount].CODAmount)
	return slot
end

function MB:UpdateContainer()
	if not self or not self.Container then return end
	for i = 1, self.config_const.itemsSlotDisplay do
		if self.Container[i] then
			self.Container[i]:Hide()
		end
	end
	if not slotDB then return end
	
	local sumQ = ""
	for i = 1, 7 do
		if sumQuality[i] then
			local _,_,_,colorCode = GetItemQualityColor(i)
			sumQ = sumQ.."|c"..colorCode.._G["ITEM_QUALITY"..i.."_DESC"]..": "..sumQuality[i].."|r "
		end
	end
	self.mailboxGoldText:SetText(L["Mailbox gold: "]..GetCoinTextureString(MB_DB[selectChar].money).."\r\n"..sumQ)
	--self.mailboxTime:SetText(floor(difftime(time(),sorted_db[selectChar].checkMailTick)/60).." 分鐘前掃描" or "");

	local offset = FauxScrollFrame_GetOffset(self.scrollBar)
	
	local iconDisplayCount
	if (getn(slotDB) - offset * 8) > self.config_const.itemsSlotDisplay then
		iconDisplayCount = self.config_const.itemsSlotDisplay
	else
		iconDisplayCount = getn(slotDB) - offset * 8
	end
	
--[[
structure of slotDB:
case1: isStack
slotDB{		[1]		{	[1].mailIndex .attachIndex
			[2]			[2].mailIndex .attachIndex
case2: not stack
slotDB{		[1]		{	[1].mailIndex .attachIndex
			[2]		{	[1].mailIndex .attachIndex
case3: money only
slotDB{		[1]		.mailIndex
			[2]

				mailIndex	attachIndex
[charName] = {	[1]			[1]			{	.count
				[n]			.sender			.itemLink
				.daysLeft 	.wasReturned?
				.mailCount	.CODAmount?
				.itemCount
]]
	for i = 1, iconDisplayCount do
		local itemIndex = i + offset * 8
		local slot = self.Container[i]
		
		local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
		----to clear this slot!
		slot.count:SetText("")
		slot.tex:SetTexture("")
		slot.tex:SetVertexColor(1, 1, 1)
		slot.count:SetTextColor(1, 1, 1)
		slot.cod:Hide()
		slot.mailIndex, slot.attachIndex = nil, nil
		----ending
		if method == "money" then
			local mailIndex = slotDB[itemIndex]
			slot.mailIndex = mailIndex
			slot = self:InsertToSlot(slot, slotDB[itemIndex], true, true)
			local money = MB_DB[selectChar][mailIndex].money
			slot.tex:SetTexture(GetCoinIcon(money))
			
		else
			slot.mailIndex = {}
			slot.attachIndex = {}
			for i = 1, getn(slotDB[itemIndex]) do
				tinsert(slot.mailIndex, slotDB[itemIndex][i].mailIndex)
				tinsert(slot.attachIndex, slotDB[itemIndex][i].attachIndex)
			end
			--local mailIndex, attachIndex = slotDB[itemIndex].mailIndex, slotDB[itemIndex].attachIndex--!!!!
			slot.data = slotDB[itemIndex]
			--slot.tex:SetTexture(GetCoinIcon(money))
			slot.link = MB_DB[selectChar][slot.mailIndex[1]][slot.attachIndex[1]].itemLink
			if slot.link then
				slot.name, _, slot.rarity, _, _, _, _, _, _, slot.texture = GetItemInfo(slot.link);
				if rarity and rarity > 1 then
					local r, g, b = GetItemQualityColor(rarity);
					slot:SetBackdropBorderColor(r, g, b);
				else
					slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
				end
				slot.tex:SetTexture(slot.texture)
			else
				slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
			end
			
			local countnum = 0
			for i = 1 , getn(slot.mailIndex) do
				countnum = countnum + MB_DB[selectChar][slot.mailIndex[i]][slot.attachIndex[i]].count
				if MB_DB[selectChar][slot.mailIndex[i]].CODAmount then
				slot.tex:SetDesaturated(1)
				slot.cod:Show()
				end
			end
			slot.count:SetText(countnum > 1 and countnum or '');
			
			if self.searchingBar:HasFocus() then
				if not slot.name then break end
				local searchingStr = self.searchingBar:GetText();
				if not find(slot.name, searchingStr) then
					slot.tex:SetVertexColor(0.25, 0.25, 0.25)
					slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
					slot.count:SetTextColor(0.3, 0.3, 0.3)
				end
			end
			
		end
		
		slot:Show()
	end
	FauxScrollFrame_Update(self.scrollBar, ceil(getn(slotDB) / self.config_const.numItemsPerRow) , self.config_const.numItemsRows, self.config_const.buttonSize + self.config_const.buttonSpacing );
end

function MB:Update(isSortDB)
	if not MB:IsVisible() then return end
	if not self.SortDB then return end
	--if not selectChar then return end
	if isSortDB == "sort" then
		self:SortDB()
	elseif isSortDB == "filter" then
		self:Filter()
	end
	
	self:UpdateContainer()
end

---- GUI ----

function MB:Filter_OnClick(self, f)
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameFilterDropDown, self.value);
	f:Update("filter")
end

function MB:FilterMenuInitialize(self, f)
	if not revSubIdxTb then return end
	local info = UIDropDownMenu_CreateInfo();
	info = UIDropDownMenu_CreateInfo()
	info.text = ALL
	info.value = "__all"
	info.func = function(self)
		f:Filter_OnClick(self, f)
	end;
	UIDropDownMenu_AddButton(info, level)

	for k, v in ipairs(subIdxTb) do
		info = UIDropDownMenu_CreateInfo()
		local t
		local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
		if method == "quality" then
			t = _G["ITEM_QUALITY"..v.keyword.."_DESC"]
		elseif method == "left day" then
			t = format("%d "..DAYS, v.keyword)
		else
			t = v.keyword
		end
		info.text = t
		info.value = v.keyword
		info.func = function(self)
			f:Filter_OnClick(self, f)
		end;
		UIDropDownMenu_AddButton(info, level)
	end
	if UIDropDownMenu_GetSelectedValue(MailboxBankFrameFilterDropDown) == nil or selectSortChanged == true then
		UIDropDownMenu_SetSelectedValue(MailboxBankFrameFilterDropDown, "__all");
		selectSortChanged = nil
	end
	--UIDropDownMenu_SetSelectedValue(MailboxBankFrameFilterDropDown, "__all");
end

function MB:SortMethod_OnClick(self, f)
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameSortDropDown, self.value);
	selectSortChanged = true
	f:Update("sort")
	--local text = MailboxBankFrameSortDropDownText;
	--local width = text:GetStringWidth();
	--UIDropDownMenu_SetWidth(MailboxBankFrameSortDropDown, width+40);
	--MailboxBankFrameSortDropDown:SetWidth(width+60)	
end

function MB:SortMenuInitialize(self, f)
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(f.SelectSortMethod) do
			info = UIDropDownMenu_CreateInfo()
			info.text = L[k]
			info.value = k
			info.func = function(self)
				f:SortMethod_OnClick(self, f)
			end;
			UIDropDownMenu_AddButton(info, level)
	end
	if UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown) == nil then
		UIDropDownMenu_SetSelectedValue(MailboxBankFrameSortDropDown, "left day");
	end
	--local text = MailboxBankFrameSortDropDownText;
	--local width = text:GetStringWidth();
	--UIDropDownMenu_SetWidth(MailboxBankFrameSortDropDown, width+40);
	--MailboxBankFrameSortDropDown:SetWidth(width+60)
end

function MB:ChooseChar_OnClick(self, f) ---!!!
	selectChar = self.value
	UIDropDownMenu_SetSelectedValue(f.chooseChar, self.value);
	f:SearchBarResetAndClear()
	f:Update("sort")
	
	local text = MailboxBankFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(f.chooseChar, width+40);
	f.chooseChar:SetWidth(width+60)	
end

function MB:ChooseCharMenuInitialize(self, f)
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			local info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = function(self)
				f:ChooseChar_OnClick(self, f)
			end;
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(f.chooseChar, selectChar);
	local text = MailboxBankFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(f.chooseChar, width+40);
	f.chooseChar:SetWidth(width+60)
end


function MB:CreateMailboxBankFrame()
	----Create mailbox bank frame
	local E
	if ElvUI then E = unpack(ElvUI) end
	local f = self
	if E then
		f:SetTemplate(E.db.bags.transparent and "notrans" or "Transparent")
	else
		f:SetBackdrop({
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }
		})
	end
	f:EnableMouse(true)
	f:SetFrameStrata("DIALOG");
	f:SetWidth(self.config_const.frameWidth)
	f:SetHeight(self.config_const.frameHeight)
	f:SetPoint(MB_config.pa or "CENTER", MB_config.px or 0, MB_config.py or 0)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		MB_config.p, MB_config.pf, MB_config.pa, MB_config.px, MB_config.py = self:GetPoint()
	end)
	f:Hide()
	
	local name = "MailboxBankFrame"
		
	----Create headline
	f.headline = f:CreateFontString(nil, 'OVERLAY');
	if E then
		f.headline:FontTemplate()
	else
		f.headline:SetFont(STANDARD_TEXT_FONT, 14);
	end
	f.headline:SetPoint("TOPLEFT", 10, -10);
	f.headline:SetText(L["MailboxBank"])
	
	----Create choose char dropdown menu
	f.chooseChar = CreateFrame('Frame', name..'ChooseCharDropDown', f, 'UIDropDownMenuTemplate')
	f.chooseChar:SetPoint("LEFT", f.headline, f.headline:GetStringWidth(), -5)
	--UIDropDownMenu_Initialize(f.chooseChar, self:DropDownMenuInitialize());
	--UIDropDownMenu_SetWidth(MailboxBankFrameDropDown, 200);
	
	----Create close button
	f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton");
	f.closeButton:SetPoint("TOPRIGHT", -2, -2);
	f.closeButton:HookScript("OnClick", function()
		f:SearchBarResetAndClear()
		collectgarbage("collect")
	end)
	
	----Search
	if E then
		f.searchingBar = CreateFrame('EditBox', nil, f);
		f.searchingBar:CreateBackdrop('Default', true);
	else
		f.searchingBar = CreateFrame('EditBox', nil, f, "BagSearchBoxTemplate");
	end
	f.searchingBar:SetFrameLevel(f:GetFrameLevel() + 2);
	f.searchingBar:SetHeight(15);
	f.searchingBar:SetWidth(180);
	f.searchingBar:Hide();
	f.searchingBar:SetPoint('BOTTOMLEFT', f.headline, 'BOTTOMLEFT', 0, -30);
	if E then
		f.searchingBar:FontTemplate()
	else
		f.searchingBar:SetFont(STANDARD_TEXT_FONT, 12);
	end

	f.searchingBarText = f:CreateFontString(nil, "ARTWORK");
	if E then
		f.searchingBarText:FontTemplate()
	else	
		f.searchingBarText:SetFont(STANDARD_TEXT_FONT, 12);
	end
	f.searchingBarText:SetAllPoints(f.searchingBar);
	f.searchingBarText:SetJustifyH("LEFT");
	f.searchingBarText:SetText("|cff9999ff" .. SEARCH);
	
	f.searchingBar:SetAutoFocus(true);
	f.searchingBar:SetText(SEARCH);
		
	local button = CreateFrame("Button", nil, f)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetAllPoints(f.searchingBarText);
	button:SetScript("OnClick", function(self, btn)
		if btn == "RightButton" then
			f:OpenEditbox();
		else
			if f.searchingBar:IsShown() then
				f:SearchBarResetAndClear()
			else
				f:OpenEditbox();
			end
		end
	end)
	
	----Create stack up button
	f.stackUpCheckButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.stackUpCheckButton:SetPoint("LEFT",f.searchingBar, 200, 0)
	f.stackUpCheckButton.text:SetText(L["Stack items"])
	f.stackUpCheckButton:SetChecked(MB_config.isStacked or false)
	f.stackUpCheckButton:SetScript("OnClick", function(self)
		MB_config.isStacked = self:GetChecked()
		f:Update("filter")
	end)

	----Create sort dropdown menu
	tinsert(UISpecialFrames, f)
	f.sortmethod = CreateFrame('Frame', name..'SortDropDown', f, 'UIDropDownMenuTemplate')
	f.sortmethod:SetPoint("BOTTOMLEFT", f.searchingBar, 0, -36)
	
	----Create filter dropdown menu
	f.filter = CreateFrame('Frame', name..'FilterDropDown', f, 'UIDropDownMenuTemplate')
	f.filter:SetPoint("LEFT", f.sortmethod, 150, 0)
	--UIDropDownMenu_Initialize(f.filter, f:FilterMenuInitialize);
	
	----Create collect mailbox gold button
	--[[f.CollectGoldButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.CollectGoldButton:SetWidth(100)
	f.CollectGoldButton:SetHeight(30)
	f.CollectGoldButton:SetPoint("BOTTOMLEFT", 10, 5);
	f.CollectGoldButton:SetText(L["Collect gold"])]]
	
	----Create mailbox gold text
	f.mailboxGoldText = f:CreateFontString(nil, 'OVERLAY');
	if E then
		f.mailboxGoldText:FontTemplate()
	else
		f.mailboxGoldText:SetFont(STANDARD_TEXT_FONT, 14);
	end
	--f.mailboxGoldText:SetPoint("LEFT", f.CollectGoldButton, "RIGHT", 20, 0);
	f.mailboxGoldText:SetPoint("BOTTOMLEFT", 10, 5);
	f.mailboxGoldText:SetJustifyH("LEFT");
	
	----Create check time text
	-- f.checktime = f:CreateFontString(nil, 'OVERLAY');
	-- f.checktime:FontTemplate()
	-- f.checktime:SetPoint("BOTTOMLEFT", 20, 5);
	
	----Create scroll frame
	f.scrollBar = CreateFrame("ScrollFrame", name.."ScrollBar", f, "FauxScrollFrameTemplate")
	f.scrollBar:SetPoint("TOPLEFT", 0, -64)
	f.scrollBar:SetPoint("BOTTOMRIGHT", -28, 40)
	f.scrollBar:SetHeight( self.config_const.numItemsRows * self.config_const.buttonSize + (self.config_const.numItemsRows - 1) * self.config_const.buttonSpacing)
	f.scrollBar:Hide()
	--f.scrollBar:EnableMouseWheel(true)
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, self.config_const.buttonSize + self.config_const.buttonSpacing);
		f:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		f:Update()
	end)
	
	if E then
		local S = E:GetModule("Skins")
		if S then
			S:HandleCloseButton(f.closeButton);
			S:HandleCheckBox(f.stackUpCheckButton);
			S:HandleDropDownBox(f.sortmethod)
			S:HandleDropDownBox(f.filter)
			S:HandleDropDownBox(f.chooseChar)
			S:HandleButton(f.CollectGoldButton)
			S:HandleScrollBar(f.scrollBar);
		end
	end
	
	----Create Container
	f.Container = CreateFrame('Frame', nil, f);
	f.Container:SetPoint('TOPLEFT', f, 'TOPLEFT', 12, -90);
	f.Container:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 8);
	f.Container:Show()
	
	local numContainerRows = 0;
	local lastButton;
	local lastRowButton;
	for i = 1, self.config_const.itemsSlotDisplay do
		local slot
		if E then
			slot = CreateFrame('Button', nil, f.Container);
			slot:SetTemplate('Default');
			slot:StyleButton();
			slot:Size(self.config_const.buttonSize);
		else
			slot = CreateFrame('Button', nil, f.Container, "ItemButtonTemplate");
			slot:SetSize(self.config_const.buttonSize, self.config_const.buttonSize);
		end
		slot:Hide()
		
		slot.count = slot:CreateFontString(nil, 'OVERLAY');
		slot.cod = slot:CreateFontString(nil, 'OVERLAY');
		if E then
			slot.count:FontTemplate()
			slot.cod:FontTemplate()
		else
			slot.count:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE');
			slot.cod:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE');
		end
		slot.count:SetPoint('BOTTOMRIGHT', 0, 2);
		slot.cod:SetPoint('TOPLEFT', 0, 2);
		slot.cod:SetText("C.O.D.")
		slot.cod:Hide()
		
		slot.tex = slot:CreateTexture(nil, "OVERLAY", nil)
		slot.tex:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
		slot.tex:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
		slot.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		
		slot:SetScript("OnEnter", function(self)
			f:TooltipShow(self)----???
		end)
		slot:HookScript("OnClick", function(self,button)
			f:SlotClick(self,button)----???
		end)
		slot:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		f.Container[i] = slot
		
		if lastButton then
			if (i - 1) % self.config_const.numItemsPerRow == 0 then
				slot:SetPoint('TOP', lastRowButton, 'BOTTOM', 0, -self.config_const.buttonSpacing);
				lastRowButton = f.Container[i];
				numContainerRows = numContainerRows + 1;
			else
				slot:SetPoint('LEFT', lastButton, 'RIGHT', self.config_const.buttonSpacing, 0);
			end
		else
			slot:SetPoint('TOPLEFT', f.Container, 'TOPLEFT',0, 0)
			--slot:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -60);
			lastRowButton = f.Container[i];
			numContainerRows = numContainerRows + 1;
		end
		lastButton = f.Container[i];
	end
	
	
	---- SetScript
	
	f.searchingBar:SetScript("OnEscapePressed", function()
		f:SearchBarResetAndClear()
		f:Update()
	end);
	f.searchingBar:SetScript("OnEnterPressed", function()
		f:SearchBarResetAndClear()
		f:Update()
	end);
	f.searchingBar:SetScript("OnEditFocusLost", f.searchingBar.Hide);
	f.searchingBar:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
		f:UpdateSearch()
	end);
	f.searchingBar:SetScript("OnTextChanged", function()
		f:UpdateSearch()
	end);
	f.searchingBar:SetScript('OnChar', function()
		f:UpdateSearch()
	end);
	
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, f.config_const.buttonSize + f.config_const.buttonSpacing);
		f:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		f:Update()
	end)
	
--[[	f.CollectGoldButton:SetScript("OnClick", function()
		f:CollectMoney()
	end)]]
	
	UIDropDownMenu_Initialize(f.chooseChar, function(self)
		f:ChooseCharMenuInitialize(self, f)
	end)
	
	UIDropDownMenu_Initialize(f.sortmethod, function(self)
		f:SortMenuInitialize(self, f)
	end)
end

function MB:CreatePopupFrame()
	self.PopupFrame = CreateFrame("Frame", nil , UIParent)
	local f = self.PopupFrame
	local E
	if ElvUI then E = unpack(ElvUI) end
	if E then
		f:SetTemplate(E.db.bags.transparent and "notrans" or "Transparent")
	else
		f:SetBackdrop({
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }
		})
	end
	f:EnableMouse(true)
	f:SetFrameStrata("DIALOG");
	f:SetWidth(333)
	f:SetHeight(200)
	f:SetPoint("CENTER", 0, 0)
	--f:SetFrameLevel(self:GetFrameLevel() + 20);
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	f:Hide()
	
	f.accept = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.accept:SetWidth(100)
	f.accept:SetHeight(30)
	f.accept:SetPoint("BOTTOMLEFT", 10, 5);
	f.accept:SetText(ACCEPT)
	
	f.cancle = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.cancle:SetWidth(100)
	f.cancle:SetHeight(30)
	f.cancle:SetPoint("BOTTOMRIGHT", -10, -5);
	f.cancle:SetText(CANCEL)
end
--[[
Tool-tip format
Left				Right
sender1				count
+lefttime1			count
 -was returned
+lefttime2			count
(is cod)			amount
sender2				count
+lefttime1			count
]]
--[[
structure of slotDB:
case1: isStack
slotDB{		[1]		{	[1].mailIndex .attachIndex
			[2]			[2].mailIndex .attachIndex
case2: not stack
slotDB{		[1]		{	[1].mailIndex .attachIndex
			[2]		{	[1].mailIndex .attachIndex
case3: money only
slotDB{		[1]		.mailIndex
			[2]

				mailIndex	attachIndex
[charName] = {	[1]			[1]			{	.count!
				[n]			.sender!		.itemLink
				.mailCount	.wasReturned!
				.itemCount	.CODAmount!
							.money?
							.daysLeft!
]]
function MB:TooltipShow(self)--self=slot
	local f = self:GetParent():GetParent()
	local mIdx, aIdx = self.mailIndex, self.attachIndex
	local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
	--local sender, wasReturned
	if method =="money" then
		local money = MB_DB[selectChar][mIdx].money ---should have
	else
		if self and self.link then
			local x = self:GetRight();
			if ( x >= ( GetScreenWidth() / 2 ) ) then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			else
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			end
			GameTooltip:SetHyperlink(self.link)
		end
		
		--local sender, countNum, dayLeft, CODAmount, wasReturned = 
		
	end
	
	local formatList = {}
	for i = 1 , getn(mIdx) do
		if formatList[MB_DB[selectChar][mIdx[i]].sender] == nil then
			formatList[MB_DB[selectChar][mIdx[i]].sender] = {}
			local row = {}
			row.lefttext = L["Sender: "] ..MB_DB[selectChar][mIdx[i]].sender
			row.righttext = 0 ---summary count
			tinsert(formatList[MB_DB[selectChar][mIdx[i]].sender], row)
		end
		
		local lefttext = L["+ Left time: "]
		local dayLeftTick = difftime(floor(MB_DB[selectChar][mIdx[i]].daysLeft * 86400) + MB_DB[selectChar].checkMailTick,time())
		local leftday = floor(dayLeftTick / 86400)
		if leftday > 0 then
			lefttext = lefttext..format("> %d "..DAYS,leftday)
		else
			local lefthour = floor((dayLeftTick-leftday*86400) / 3600) 
			local leftminute = floor((dayLeftTick-leftday*86400-lefthour*3600) / 60)
			lefttext = lefttext..format( lefthour > 0 and "%d"..HOURS or "" ,lefthour)..format( leftminute > 0 and "%d"..MINUTES or "",leftminute)--tostring(lefthour)..HOURS..tostring(leftminute)..MINUTES
		end
		
		local foundSameLefttime = false
		for j = 1, getn(formatList[MB_DB[selectChar][mIdx[i]].sender]) do
			if formatList[MB_DB[selectChar][mIdx[i]].sender][j].lefttext == lefttext and not MB_DB[selectChar][mIdx[i]][aIdx[i]].CODAmount and not MB_DB[selectChar][mIdx[i]][aIdx[i]].wasReturned then----!!should add cod and was returned
				formatList[MB_DB[selectChar][mIdx[i]].sender][j].righttext = formatList[MB_DB[selectChar][mIdx[i]].sender][j].righttext + MB_DB[selectChar][mIdx[i]][aIdx[i]].count
				formatList[MB_DB[selectChar][mIdx[i]].sender][1].righttext = formatList[MB_DB[selectChar][mIdx[i]].sender][1].righttext + MB_DB[selectChar][mIdx[i]][aIdx[i]].count
				foundSameLefttime = true
			end
		end
		
		if foundSameLefttime == false then
			local row = {}
			row.lefttext = lefttext
			row.righttext = MB_DB[selectChar][mIdx[i]][aIdx[i]].count
			row.leftday = leftday
			formatList[MB_DB[selectChar][mIdx[i]].sender][1].righttext = formatList[MB_DB[selectChar][mIdx[i]].sender][1].righttext + MB_DB[selectChar][mIdx[i]][aIdx[i]].count
			tinsert(formatList[MB_DB[selectChar][mIdx[i]].sender], row)
			
			if MB_DB[selectChar][mIdx[i]][aIdx[i]].CODAmount then
				row = {}
				row.lefttext = COD.." "..ITEMS
				row.righttext = L["pay for: "]..GetCoinTextureString(MB_DB[selectChar][mIdx[i]].CODAmount)
				row.cod = true
				tinsert(formatList[MB_DB[selectChar][mIdx[i]].sender], row)
				--GameTooltip:AddDoubleLine(COD.." "..ITEMS, L["pay for: "]..GetCoinTextureString(self.CODAmount), 1, 0, 0.5)
			end
			
			if MB_DB[selectChar][mIdx[i]][aIdx[i]].wasReturned then
				row = {}
				row.lefttext = ""
				row.righttext = L["was returned"]
				row.wasreturned = true
				tinsert(formatList[MB_DB[selectChar][mIdx[i]].sender], row)
				--GameTooltip:AddLine(L["was returned"])
			end
		end
		
	end
	
	for k in pairs(formatList) do
		for i = 1, getn(formatList[k]) do
			local rL, gL, bL = 1, 1, 1
			if i > 1 then
				if formatList[k][i].leftday then
					local leftday = formatList[k][i].leftday
					if leftday < f.config_const.daysLeftRed then
						rL, gL, bL = 1, 0, 0
					elseif leftday < f.config_const.daysLeftYellow then
						rL, gL, bL = 1, 1, 0
					else
						rL, gL, bL = 0, 1, 0
					end
				elseif formatList[k][i].cod then
					rL, gL, bL = 1, 0, 0.5
				elseif formatList[k][i].wasreturned then
				
				end
			end
			GameTooltip:AddDoubleLine(formatList[k][i].lefttext, formatList[k][i].righttext, rL, gL, bL)
		end
	end
	GameTooltip:Show()
end

StaticPopupDialogs["MAILBOXBANK_ACCEPT_COD_MAIL"] = {
    text = COD_CONFIRMATION,
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function(self)
        TakeInboxItem(codMailIndex, codAttachmentIndex);
    end,
    OnShow = function(self)
        MoneyFrame_Update(self.moneyFrame, codMoney);
    end,
    hasMoneyFrame = 1,
    timeout = 0,
    hideOnEscape = 1
};

function MB:SlotClick(self,button)----self=slot
	local msg = self.link
	if not msg then return; end
	if IsShiftKeyDown() and button == 'LeftButton' then
		if AuctionFrame and AuctionFrame:IsVisible() then
			BrowseName:SetText(GetItemInfo(msg))
			return;
		end
		if ChatFrame1EditBox:IsShown() then
			ChatFrame1EditBox:Insert(msg);
		else
			local ExistMSG = ChatFrame1EditBox:GetText() or "";
			ChatFrame1EditBox:SetText(ExistMSG..msg);
			ChatEdit_SendText(ChatFrame1EditBox);
			ChatFrame1EditBox:SetText("");
			ChatFrame1EditBox:Hide();
		end
	elseif button == 'LeftButton' and not MB_config.isStacked then
		if self.CODAmount then
			if self.CODAmount > GetMoney() then
				SetMoneyFrameColor("GameTooltipMoneyFrame1", "red");
				StaticPopup_Show("COD_ALERT");
			else
				codMoney, codMailIndex, codAttachmentIndex = self.CODAmount, self.mailIndex[1], self.attachIndex[1]
				SetMoneyFrameColor("GameTooltipMoneyFrame1", "white");
				StaticPopup_Show("MAILBOXBANK_ACCEPT_COD_MAIL")
			end
		else
			if self.mailIndex and self.attachIndex then
				for i = getn(self.mailIndex), 1, -1 do
					TakeInboxItem(self.mailIndex[i], self.attachIndex[i])
				end
				MB:Update("sort")
			end
		end
	end
end

function MB:AlertDeadlineMails()
	local DeadlineList = {["__count"] = 0}
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
		--.mailCount .itemCount
			for i = MB_DB[k].mailCount , 1, -1 do
				local dayLeft = self:CalcLeftDay(k, i)
				if dayLeft < self.config_const.daysLeftWarning then
					if not DeadlineList[k] then 
						DeadlineList[k] = {}
						DeadlineList.__count = DeadlineList.__count +1
					end
					for j, u in pairs(MB_DB[k][i]) do
						if type(u) == "table" then
							tinsert(DeadlineList[k], u.itemLink)
						end
					end
				else
					break
				end
			end
		end
	end
	if DeadlineList.__count > 0 then
		local alertText = L["MailboxBank"] .. L[": |cff00aabbYou have mails soon expire: |r"]
		for k, t in pairs(DeadlineList) do
			if k ~= "__count" then
				alertText = alertText.."\r\n\[".. k .. "\]: "
				for i, v in pairs(t) do
					alertText = alertText .. v
				end
			end
		end
		print(alertText)
	end
end

function MB:HookSendMail(recipient, subject, body)
	--print("HookSendMail"..SendMailNameEditBox:GetText())
	if not recipient then recipient = SendMailNameEditBox:GetText() end
	if not recipient then return end
	recipient = string.upper(string.sub(recipient, 1, 1))..string.sub(recipient, 2, -1)
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			if recipient..'-'..GetRealmName() == k then
				local Getmoney = GetSendMailMoney()
				local Sendmoney, Codmoney = 0, 0
				if Getmoney then
					if SendMailSendMoneyButton:GetChecked() then
						Sendmoney = Getmoney
						MB_DB[recipient..'-'..GetRealmName()].money = MB_DB[recipient..'-'..GetRealmName()].money + Sendmoney
					else
						Codmoney = Getmoney
					end
				end
				local firstItem = true
				for i = ATTACHMENTS_MAX_RECEIVE, 1, -1 do
					local Name, _, count, _ = GetSendMailItem(i)
					if Name then
						local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(Name or "")
						--AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, money, CODAmount, wasReturned, recipient, firstItem)
						self:AddItem(GetUnitName("player"), itemLink, count, 31, 1, i, Sendmoney, Codmoney, nil, k, firstItem)
						firstItem = false
					end
				end
				if self:IsVisible() and selectChar == k then
					self:Update("sort")
				end
				return
			end
		end
	end
end

function MB:FrameShow()
	self:UpdateContainer()
	self:Show()
end

function MB:FrameHide()
	self:Hide()
	self:SearchBarResetAndClear()
	collectgarbage("collect")
end

---- Event ----

local function MailboxBank_OnEvent(self, event)
	if event == "MAIL_INBOX_UPDATE" then
		self:CheckMail()
		if selectChar == playername then
			self:Update("sort")
		end
	end
	if event == "MAIL_SHOW" then
		if not self:IsVisible() then 
			self:FrameShow();
		end
	end
	if event == "MAIL_CLOSED" then
		self:FrameHide()
	end
	-- if event == "ADDON_LOADED" then
		-- print("MailboxBank loaded")
	-- end
	if event == "PLAYER_ENTERING_WORLD" then
		self:RegisterEvent("MAIL_INBOX_UPDATE")
		self:RegisterEvent("MAIL_SHOW")
		self:RegisterEvent("MAIL_CLOSED")
		if MB_config == nil then MB_config = {} end
		--[[if self.config_const == nil then
			self.config_const = {}
			for k ,v in pairs(self.config_init) do
				self.config_const[k] = v;
			end
		end]]
		if not MB_DB then MB_DB = {} end
		self:CreateMailboxBankFrame()
		self:AlertDeadlineMails()
		hooksecurefunc("SendMail", function() self:HookSendMail() end)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end
MB:RegisterEvent("PLAYER_ENTERING_WORLD")
MB:SetScript("OnEvent", MailboxBank_OnEvent)
---- Slash command ----

SLASH_MAILBOXBANK1 = "/mb";
SLASH_MAILBOXBANK2 = "/mailbox";
SlashCmdList["MAILBOXBANK"] = function()
	if MB:IsVisible() then
		MB:FrameHide()
	else
		MB:Update("sort")
		MB:FrameShow()
	end
end;