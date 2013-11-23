--@@ TODO: solve COD item, maybe displaying COD amount above the slot icon or using tool-tip
	--UC..don't know how to layout in tool-tip..
--@@ TODO: change frame's layout!
	--holy shit..
--@@ TODO: should stacked attachments can be collect??
	--UC.. new window to produce? or pop-up ? COD to collect?
--@@ TODO: should attachments be alerted to player to collect when almost in deadline?
	--UC.. to optimize

--@@ TODO: optimize & combine same action in function Filter() UpdateRevIdxTb() InsToIdxTb()
local MB = LibStub("AceAddon-3.0"):NewAddon("MailboxBank", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MailboxBank")
--local AT = LibStub("AceTimer-3.0"):NewAddon("MailboxBank")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local len, sub, find, format, match = string.len, string.sub, string.find, string.format, string.match
local playername = GetUnitName("player")..'-'..GetRealmName()
local selectChar = playername
local selectTab
local slotDB, subIdxTb, revSubIdxTb, sumQuality
local selectSortChanged
local codMoney, codMailIndex, codAttachmentIndex
local Textures = {
	["bag"] = "Interface\\AddOns\\MailboxBank\\Textures\\bag.tga", 
	["bank"] = "Interface\\AddOns\\MailboxBank\\Textures\\bank.tga", 
	["mail"] = "Interface\\AddOns\\MailboxBank\\Textures\\mailbox.tga",
}
local TabTooltip = {
	["bag"] = L['Offline Bag'], 
	["bank"] = L['Offline Bank'], 
	["mail"] = L['Offline MailBox'],
}
--local MB = CreateFrame("Frame", nil , UIParent)
local G_DB

MB.config_const = {
	daysLeftYellow = 7,
	daysLeftRed = 3,
	daysLeftWarning = 5,
	buttonSize = 36,
	buttonSpacing = 4,
	numItemsPerRow = 8,
	numItemsRows = 10,
	itemsSlotDisplay = 80,
	frameWidth = 360,
	frameHeight = 580,
	rowcount = 8,
}

function MB:AddItemBag(itemLink, count, bagID, slotID)
	if not BB_DB[playername][bagID] then
		BB_DB[playername][bagID] = {}
	end
	BB_DB[playername][bagID][slotID] = {count = count, itemLink = itemLink}
end
--[[
BB_DB structure:
				bagID		slotID
[charName] = {	[1]			[1]			{	.count
				[n]			.slotMAX		.itemLink
				.itemCountBank
				.itemCountBag
]]
function MB:AddItemMail(itemLink, count, mailIndex, attachIndex, sender, daysLeft, money, CODAmount, wasReturned, recipient, firstItem)
	if recipient and firstItem then
		local t ={}
		tinsert(MB_DB[recipient], 1, t)
	elseif not recipient then
		recipient = playername
	end
	
	if not MB_DB[recipient][mailIndex] or firstItem then
		MB_DB[recipient][mailIndex] = {
			sender = sender,
			daysLeft = daysLeft,
			wasReturned = wasReturned,
			money = (money > 0) and money or nil,
			CODAmount = (CODAmount > 0) and CODAmount or nil,}
		MB_DB[recipient].mailCount = MB_DB[recipient].mailCount + 1
	end
	
	if not itemLink then return end --for money only
	MB_DB[recipient][mailIndex][attachIndex] = {
		count = count,
		itemLink = itemLink,}
	MB_DB[recipient].itemCount = MB_DB[recipient].itemCount + 1
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
]]
--MB.BagIDs = {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

function MB:CheckBags()
	if not BB_DB[playername] then BB_DB[playername] = {} end
	local BagIDs = self.isBankOpened and {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11} or {0, 1, 2, 3, 4}
	local numSlots, full = GetNumBankSlots();
	BB_DB[playername].money = GetMoney()
	for k, bagID in pairs(BagIDs) do
		local numSlots = GetContainerNumSlots(bagID)
		if numSlots > 0 then
			BB_DB[playername][bagID] = {slotMAX = numSlots}
			local inbagItemCount = 0
			for slotIndex = 1, numSlots do
				local itemLink = GetContainerItemLink(bagID, slotIndex)
				if itemLink then
					local _, count, _, _, _ = GetContainerItemInfo(bagID, slotIndex)
					self:AddItemBag(itemLink, count, bagID, slotIndex)
					inbagItemCount = inbagItemCount + 1
				end
			end
			BB_DB[playername][bagID].inbagItemCount = inbagItemCount
		end
	end
end

function MB:CheckMail()
	MB_DB[playername] = {mailCount = 0, itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			--local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			local _, _, sender, _, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, _, _, _ = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then
				MB_DB[playername].money = MB_DB[playername].money + money
			end
			--self:AddItemMail(itemLink, count, mailIndex, attachIndex, sender, daysLeft, money, CODAmount, wasReturned, recipient, firstItem)
			self:AddItemMail(nil, nil, mailIndex, nil, sender, daysLeft, money, CODAmount, wasReturned)
			if hasItem then
				if sender == nil then
					sender = L["UNKNOWN SENDER"]
				end
				for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
					local itemLink = GetInboxItemLink(mailIndex, attachIndex)
					if itemLink then
						local _, _, count, _, _ = GetInboxItem(mailIndex, attachIndex)
						self:AddItemMail(itemLink, count, mailIndex, attachIndex)
					end
				end
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
	local searchString = self.Frame.searchingBar:GetText();
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
	self.Frame.searchingBarText:Hide();
	self.Frame.searchingBar:Show();
	self.Frame.searchingBar:SetText(SEARCH);
	self.Frame.searchingBar:HighlightText();
end

function MB:SearchBarResetAndClear()
	self.Frame.searchingBarText:Show();
	self.Frame.searchingBar:ClearFocus();
	self.Frame.searchingBar:SetText("");
end

---- Sorting ----

function MB:BuildSortOrder()
	self.AhSortIndex = {}
	--local c = 0;
	for i, iType in ipairs({GetAuctionItemClasses()}) do
		self.AhSortIndex[iType] = i
		-- for ii, isType in ipairs({GetAuctionItemSubClasses(i)}) do
			-- c = c + 1;
			-- self.AhSortIndex[isType] = c;
		-- end
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
	if method == "no-sorting" then
		local itemIdxTb = {[1]={mailIndex = mailIndex,attachIndex = attachIndex}}
		tinsert(subIdxTb[subIdx], itemIdxTb)
		return
	elseif method == "money" then
		if keyword then
			tinsert(subIdxTb[subIdx], mailIndex)
		end
		return
	end
	if not attachIndex then return end
	local itemID = tonumber(match(G_DB[selectChar][mailIndex][attachIndex].itemLink, "item:(%d+)"))
	local itemIdxTb = {mailIndex = mailIndex,attachIndex = attachIndex}
	if getn(subIdxTb[subIdx]) == 0 then --no items in this type yet..
		subIdxTb[subIdx][1] = {itemID = itemID}--,["count"] = 1}
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
					if G_DB[selectChar][v.mailIndex][v.attachIndex].count >  G_DB[selectChar][mailIndex][attachIndex].count then --can insert before this count
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
	["No sorting"] = function(self, mailIndex, attachIndex)
		local keyword = L["No sorting"]
		self:InsertToIndexTable(keyword, mailIndex, attachIndex, "no-sorting")	
	end,
	["AH"] = function(self, mailIndex, attachIndex)
		if not self.AhSortIndex then self:BuildSortOrder() end
		local itemID = tonumber(match(G_DB[selectChar][mailIndex][attachIndex].itemLink, "item:(%d+)"))
		local _, _, itemRarity, _, _, itemType, _, _, _, _, _ = GetItemInfo(itemID)
		self:InsertToIndexTable(itemType, mailIndex, attachIndex, "AH")
	end,
	["quality"] = function(self, mailIndex, attachIndex)
		local _, _, quality, _, _, _, _, _, _, _ = GetItemInfo(G_DB[selectChar][mailIndex][attachIndex].itemLink)
		self:InsertToIndexTable(quality, mailIndex, attachIndex, "quality")
	end,
	["sender"] = function(self, mailIndex, attachIndex)
		local sender = G_DB[selectChar][mailIndex].sender
		self:InsertToIndexTable(sender, mailIndex, attachIndex)	
	end,--mailbox only
	["left day"] = function(self, mailIndex, attachIndex)
		local leftday = self:CalcLeftDay(selectChar, mailIndex)
		self:InsertToIndexTable(leftday, mailIndex, attachIndex, "left day")
	end,--mailbox only
	["C.O.D."] = function(self, mailIndex, attachIndex)
		local isCOD
		if G_DB[selectChar][mailIndex].CODAmount then
			isCOD = L["is C.O.D."]
		else
			isCOD = L["not C.O.D."]
		end
		self:InsertToIndexTable(isCOD, mailIndex, attachIndex)
	end,--mailbox only
	["money"] = function(self, mailIndex)
		local hasMoney
		if G_DB[selectChar][mailIndex].money then
			hasMoney = L["has money"]
		end
		self:InsertToIndexTable(hasMoney, mailIndex, nil, "money")
	end,--mailbox only
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
	local _, _, quality, _, _, _, _, _, _, _ = GetItemInfo(G_DB[selectChar][mailIndex][attachIndex].itemLink)
	if not quality then return end
	if not sumQuality[quality] then sumQuality[quality] = 0 end
	local count = G_DB[selectChar][mailIndex][attachIndex].count
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
	return c
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
			slotDB[c] = subIdxTb[1][i]
		end
		return
	end
	if filter == "__all" then
		for i = 1, getn(subIdxTb) do
			c = self:SubFilter(i, c)
		end
	else
		i = revSubIdxTb[filter]
		c = self:SubFilter(i, c)
	end
end

function MB:SortDB()
	local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
	if not method then return end
	subIdxTb = {}
	--subIdxTb.method = method
	revSubIdxTb = {__count = 0}
	--if not G_DB[selectChar] then return end
	if selectTab == "mail" then
		if not G_DB[selectChar].itemCount then return end
		for mailIndex = 1, G_DB[selectChar].mailCount do
			if not G_DB[selectChar][mailIndex] then return end
			if method == "money" then
				if G_DB[selectChar][mailIndex].money then
					self.SelectSortMethod[method](self, mailIndex)
				end
			else
				for attachIndex, t in pairs(G_DB[selectChar][mailIndex]) do
					if type(t) == "table" then
						self.SelectSortMethod[method](self, mailIndex, attachIndex)
					end
				end
			end
		end
	elseif selectTab == "bank" then
		local BagIDs = {-1, 5, 6, 7, 8, 9, 10, 11}
		for i, bagIndex in ipairs(BagIDs) do
			if G_DB[selectChar][bagIndex] then
				for slotIndex = 1, G_DB[selectChar][bagIndex].slotMAX do
					if type(G_DB[selectChar][bagIndex][slotIndex]) == "table" then
						self.SelectSortMethod[method](self, bagIndex, slotIndex)
					end
				end
			end
		end
	else
		local BagIDs = {0, 1, 2, 3, 4}
		for i, bagIndex in ipairs(BagIDs) do
			if G_DB[selectChar][bagIndex] then
				for slotIndex = 1, G_DB[selectChar][bagIndex].slotMAX do
					if type(G_DB[selectChar][bagIndex][slotIndex]) == "table" then
						self.SelectSortMethod[method](self, bagIndex, slotIndex)
					end
				end
			end
		end
	end
	--if not subIdxTb then print("empty!!");return end
	UIDropDownMenu_Initialize(MailboxBankFrameFilterDropDown, function(self)
		MB:FilterMenuInitialize(self)
	end)
	self:Filter()
end

function MB:UpdateContainer()
	if not self.Frame or not self.Frame.Container then return end
	for i = 1, self.config_const.itemsSlotDisplay do
		if self.Frame.Container[i] then
			self.Frame.Container[i]:Hide()
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
	self.Frame.mailboxGoldText:SetText(L["Mailbox gold: "]..GetCoinTextureString(G_DB[selectChar].money).."\r\n"..sumQ)
	--self.mailboxTime:SetText(floor(difftime(time(),sorted_db[selectChar].checkMailTick)/60).." 分鐘前掃描" or "");

	local offset = FauxScrollFrame_GetOffset(self.Frame.scrollBar)
	
	local iconDisplayCount
	if (getn(slotDB) - offset * 8) > self.config_const.itemsSlotDisplay then
		iconDisplayCount = self.config_const.itemsSlotDisplay
	else
		iconDisplayCount = getn(slotDB) - offset * 8
	end
	
--[[
structure of slotDB:
case1&2: isStack = not stack
slotDB{		[1]		{	[1].mailIndex .attachIndex
			[2]			[2].mailIndex .attachIndex
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
		local slot = self.Frame.Container[i]
		
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
			--slot = self:InsertToSlot(slot, slotDB[itemIndex], true, true)
			local money = G_DB[selectChar][mailIndex].money
			slot.tex:SetTexture(GetCoinIcon(money))
			slot.count:SetText(money/10000)
		else
			slot.mailIndex = {}
			slot.attachIndex = {}
			for j = 1, getn(slotDB[itemIndex]) do
				tinsert(slot.mailIndex, slotDB[itemIndex][j].mailIndex)
				tinsert(slot.attachIndex, slotDB[itemIndex][j].attachIndex)
			end
			--local mailIndex, attachIndex = slotDB[itemIndex].mailIndex, slotDB[itemIndex].attachIndex--!!!!
			--slot.data = slotDB[itemIndex]
			--slot.tex:SetTexture(GetCoinIcon(money))
			slot.link = G_DB[selectChar][slot.mailIndex[1]][slot.attachIndex[1]].itemLink
			if slot.link then
				slot.name, _, slot.rarity, _, _, _, _, _, _, slot.texture = GetItemInfo(slot.link);
				if slot.rarity and slot.rarity > 1 then
					local r, g, b = GetItemQualityColor(slot.rarity);
					slot:SetBackdropBorderColor(r, g, b);
				else
					slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
				end
				slot.tex:SetTexture(slot.texture)
			else
				slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
			end
			
			local countnum = 0
			for j = 1 , getn(slot.mailIndex) do
				countnum = countnum + G_DB[selectChar][slot.mailIndex[j]][slot.attachIndex[j]].count
				if G_DB[selectChar][slot.mailIndex[j]].CODAmount then
				slot.tex:SetDesaturated(1)
				slot.cod:Show()
				end
			end
			slot.count:SetText(countnum > 1 and countnum or '');
			
			if self.Frame.searchingBar:HasFocus() then
				if not slot.name then break end
				local searchingStr = self.Frame.searchingBar:GetText();
				if not find(slot.name, searchingStr) then
					slot.tex:SetVertexColor(0.25, 0.25, 0.25)
					slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
					slot.count:SetTextColor(0.3, 0.3, 0.3)
				end
			end
			
		end
		
		slot:Show()
	end
	FauxScrollFrame_Update(self.Frame.scrollBar, ceil(getn(slotDB) / self.config_const.numItemsPerRow) , self.config_const.numItemsRows, self.config_const.buttonSize + self.config_const.buttonSpacing );
end

function MB:Update(method)
	if not MB.Frame:IsVisible() then return end
	if not self.SortDB then return end
	--if not selectChar then return end
	if method == "sort" then
		self:SortDB()
	elseif method == "filter" then
		self:Filter()
	end
	self:UpdateContainer()
end

---- GUI ----

function MB:Filter_OnClick(self)
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameFilterDropDown, self.value);
	MB:Update("filter")
end

function MB:FilterMenuInitialize(self)
	if not revSubIdxTb then return end
	local info = UIDropDownMenu_CreateInfo();
	info = UIDropDownMenu_CreateInfo()
	info.text = ALL
	info.value = "__all"
	info.func = function(self)
		MB:Filter_OnClick(self)
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
			MB:Filter_OnClick(self)
		end;
		UIDropDownMenu_AddButton(info, level)
	end
	if UIDropDownMenu_GetSelectedValue(MailboxBankFrameFilterDropDown) == nil or selectSortChanged == true then
		UIDropDownMenu_SetSelectedValue(MailboxBankFrameFilterDropDown, "__all");
		selectSortChanged = nil
	end
end

function MB:SortMethod_OnClick(self)
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameSortDropDown, self.value);
	selectSortChanged = true
	MB:Update("sort")
	--local text = MailboxBankFrameSortDropDownText;
	--local width = text:GetStringWidth();
	--UIDropDownMenu_SetWidth(MailboxBankFrameSortDropDown, width+40);
	--MailboxBankFrameSortDropDown:SetWidth(width+60)	
end

function MB:SortMenuInitialize(self)
--TODO: split out Methods from bags
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(MB.SelectSortMethod) do
			info = UIDropDownMenu_CreateInfo()
			info.text = L[k]
			info.value = k
			info.func = function(self)
				MB:SortMethod_OnClick(self)
			end;
			UIDropDownMenu_AddButton(info, level)
	end
	if UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown) == nil then
		UIDropDownMenu_SetSelectedValue(MailboxBankFrameSortDropDown, "No sorting");
	end
	--local text = MailboxBankFrameSortDropDownText;
	--local width = text:GetStringWidth();
	--UIDropDownMenu_SetWidth(MailboxBankFrameSortDropDown, width+40);
	--MailboxBankFrameSortDropDown:SetWidth(width+60)
end

function MB:ChooseChar_OnClick(self) ---!!!
	selectChar = self.value
	UIDropDownMenu_SetSelectedValue(MB.Frame.chooseChar, self.value);
	MB:SearchBarResetAndClear()
	MB:Update("sort")
	
	local text = MailboxBankFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(MB.Frame.chooseChar, width+40);
	MB.Frame.chooseChar:SetWidth(width+60)	
end

function MB:ChooseCharMenuInitialize(self)
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			local info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = function(self)
				MB.Frame:ChooseChar_OnClick(self)
			end;
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(MB.Frame.chooseChar, selectChar);
	local text = MailboxBankFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(MB.Frame.chooseChar, width+40);
	MB.Frame.chooseChar:SetWidth(width+60)
end

function MB:SetActiveTab(typeStr)
	if typeStr == 'mail' then
		G_DB = MB_DB
	else
		G_DB = BB_DB
	end
	--重新初始化各下拉选项框
	--根据新的DB刷新SLOT
	selectTab = typeStr
	MB:Update("sort")
	MB:FrameShow()
end
	
function MB:CreateMailboxBankFrame()
	----Create mailbox bank frame
	local f = CreateFrame("Frame", nil , UIParent)
	MB.Frame = f
	
	if ElvUI then
		f:SetTemplate(ElvUI[1].db.bags.transparent and "notrans" or "Transparent")
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
	if ElvUI then
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
		MB:SearchBarResetAndClear()
		collectgarbage("collect")
	end)
	
	----Search
	if ElvUI then
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
	if ElvUI then
		f.searchingBar:FontTemplate()
	else
		f.searchingBar:SetFont(STANDARD_TEXT_FONT, 12);
	end

	f.searchingBarText = f:CreateFontString(nil, "ARTWORK");
	if ElvUI then
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
			MB:OpenEditbox();
		else
			if f.searchingBar:IsShown() then
				MB:SearchBarResetAndClear()
			else
				MB:OpenEditbox();
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
		MB:Update("filter")
	end)

	----Create sort dropdown menu
	tinsert(UISpecialFrames, f)
	f.sortmethod = CreateFrame('Frame', name..'SortDropDown', f, 'UIDropDownMenuTemplate')
	f.sortmethod:SetPoint("BOTTOMLEFT", f.searchingBar, 0, -36)
	
	----Create filter dropdown menu
	f.filter = CreateFrame('Frame', name..'FilterDropDown', f, 'UIDropDownMenuTemplate')
	f.filter:SetPoint("LEFT", f.sortmethod, 150, 0)
	--UIDropDownMenu_Initialize(f.filter, f:FilterMenuInitialize);
	
	----Create mailbox gold text
	f.mailboxGoldText = f:CreateFontString(nil, 'OVERLAY');
	if ElvUI then
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
		MB:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		MB:Update()
	end)
	
	if ElvUI then
		local S = ElvUI[1]:GetModule("Skins")
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
		if ElvUI then
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
		if ElvUI then
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
		--slot.tex:SetTexture("Interface\\AddOns\\MailboxBank\\Textures\\bag.tga")
		slot:SetScript("OnEnter", function(self)
			MB:TooltipShow(self)----???
		end)
		slot:HookScript("OnClick", function(self,button)
			MB:SlotClick(self,button)----???
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
		MB:SearchBarResetAndClear()
		MB:Update()
	end);
	f.searchingBar:SetScript("OnEnterPressed", function()
		MB:SearchBarResetAndClear()
		MB:Update()
	end);
	f.searchingBar:SetScript("OnEditFocusLost", f.searchingBar.Hide);
	f.searchingBar:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
		MB:UpdateSearch()
	end);
	f.searchingBar:SetScript("OnTextChanged", function()
		MB:UpdateSearch()
	end);
	f.searchingBar:SetScript('OnChar', function()
		MB:UpdateSearch()
	end);
	
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, MB.config_const.buttonSize + MB.config_const.buttonSpacing);
		MB:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		MB:Update()
	end)
	
	UIDropDownMenu_Initialize(f.chooseChar, function(self)
		MB:ChooseCharMenuInitialize(self)
	end)
	
	UIDropDownMenu_Initialize(f.sortmethod, function(self)
		MB:SortMenuInitialize(self)
	end)
	
	--tab button
	local tabIndex = 1
	for k , v in pairs(Textures) do
		local tab = CreateFrame("CheckButton", name..k..'Tab', f, "SpellBookSkillLineTabTemplate SecureActionButtonTemplate")
		tab:ClearAllPoints()
		local texture
		if ElvUI then
			--local S = ElvUI[1]:GetModule("Skins")
			tab:SetPoint("TOPLEFT", f, "TOPRIGHT", 2, (-44 * tabIndex) + 34)
			tabIndex = tabIndex + 1
			tab:DisableDrawLayer("BACKGROUND")
			tab:SetNormalTexture(v)
			tab:GetNormalTexture():ClearAllPoints()
			tab:GetNormalTexture():Point("TOPLEFT", 2, -2)
			tab:GetNormalTexture():Point("BOTTOMRIGHT", -2, 2)
			tab:GetNormalTexture():SetTexCoord(0.1, 0.9, 0.1, 0.9)

			tab:CreateBackdrop("Default")
			tab.backdrop:SetAllPoints()
			tab:StyleButton()
		else
			tab:SetPoint("TOPLEFT", object, "TOPRIGHT", 0, (-44 * tabIndex) + 18)
			tab:SetNormalTexture(v)
		end	
		tab:SetAttribute("type", "spell")
		tab:SetAttribute("spell", name)
		tab.typeStr = k
		tab:SetScript("OnClick", function(self)
			MB:SetActiveTab(self.typeStr)
		end)
		
		tab.name = name
		tab.tooltip = TabTooltip[k]
		tab:Show()
	end
end

function MB:CreatePopupFrame()
	self.PopupFrame = CreateFrame("Frame", nil , UIParent)
	local f = self.PopupFrame

	if ElvUI then
		f:SetTemplate(ElvUI[1].db.bags.transparent and "notrans" or "Transparent")
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
function MB:GetLeftTimeText(mailIndex)
	local lefttext = L["+ Left time: "]
	local dayLeftTick = difftime(floor(MB_DB[selectChar][mailIndex].daysLeft * 86400) + MB_DB[selectChar].checkMailTick,time())
	local leftday = floor(dayLeftTick / 86400)
	if leftday > 0 then
		lefttext = lefttext..format("> %d "..DAYS,leftday)
	else
		local lefthour = floor((dayLeftTick-leftday*86400) / 3600) 
		local leftminute = floor((dayLeftTick-leftday*86400-lefthour*3600) / 60)
		lefttext = lefttext..format( lefthour > 0 and "%d"..HOURS or "" ,lefthour)..format( leftminute > 0 and "%d"..MINUTES or "",leftminute)
	end
	return lefttext, leftday
end

function MB:TooltipShow(self)--self=slot
	local f = self:GetParent():GetParent()
	local mIdx, aIdx = self.mailIndex, self.attachIndex
	local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
	--local sender, wasReturned
	if method =="money" then
					local x = self:GetRight();
			if ( x >= ( GetScreenWidth() / 2 ) ) then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			else
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			end
		local money = MB_DB[selectChar][mIdx].money
		local lefttext = L["Sender: "] ..MB_DB[selectChar][mIdx].sender
		local rL, gL, bL = 1, 1, 1
		GameTooltip:AddDoubleLine(lefttext, GetCoinTextureString(money),rL, gL, bL)
		local lefttext = f:GetLeftTimeText(mIdx)
		GameTooltip:AddDoubleLine(lefttext, "", rL, gL, bL)
		GameTooltip:Show()
		return
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
		
		local lefttext, leftday = f:GetLeftTimeText(mIdx[i])
		-- local lefttext = L["+ Left time: "]
		-- local dayLeftTick = difftime(floor(MB_DB[selectChar][mIdx[i]].daysLeft * 86400) + MB_DB[selectChar].checkMailTick,time())
		-- local leftday = floor(dayLeftTick / 86400)
		-- if leftday > 0 then
			-- lefttext = lefttext..format("> %d "..DAYS,leftday)
		-- else
			-- local lefthour = floor((dayLeftTick-leftday*86400) / 3600) 
			-- local leftminute = floor((dayLeftTick-leftday*86400-lefthour*3600) / 60)
			-- lefttext = lefttext..format( lefthour > 0 and "%d"..HOURS or "" ,lefthour)..format( leftminute > 0 and "%d"..MINUTES or "",leftminute)--tostring(lefthour)..HOURS..tostring(leftminute)..MINUTES
		-- end
		
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
			
			if MB_DB[selectChar][mIdx[i]].CODAmount then
				row = {}
				row.lefttext = "└-"..COD.." "..ITEMS
				row.righttext = L["pay for: "]..GetCoinTextureString(MB_DB[selectChar][mIdx[i]].CODAmount)
				row.cod = true
				tinsert(formatList[MB_DB[selectChar][mIdx[i]].sender], row)
				--GameTooltip:AddDoubleLine(COD.." "..ITEMS, L["pay for: "]..GetCoinTextureString(self.CODAmount), 1, 0, 0.5)
			end
			
			if MB_DB[selectChar][mIdx[i]].wasReturned then
				row = {}
				row.lefttext = "└-"..L["was returned"]
				row.righttext = ""
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
					rL, gL, bL = 1, 1, 1
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
		if MB_DB[selectChar][self.mailIndex[1]].CODAmount then
			if MB_DB[selectChar][self.mailIndex[1]].CODAmount > GetMoney() then
				SetMoneyFrameColor("GameTooltipMoneyFrame1", "red");
				StaticPopup_Show("COD_ALERT");
			else
				codMoney, codMailIndex, codAttachmentIndex = MB_DB[selectChar][self.mailIndex[1]].CODAmount, self.mailIndex[1], self.attachIndex[1]
				SetMoneyFrameColor("GameTooltipMoneyFrame1", "white");
				StaticPopup_Show("MAILBOXBANK_ACCEPT_COD_MAIL")
			end
		else
			if self.mailIndex[1] and self.attachIndex[1] then
				--for i = getn(self.mailIndex), 1, -1 do
					TakeInboxItem(self.mailIndex[1], self.attachIndex[1])
				--end
				MB:Update("sort")
			end
		end
	end
end

function MB:AlertDeadlineMails()
	local DeadlineList = {__count = 0}
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
				--else--because of cod items' deadline is 3 days !!
					--break
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
						--self:AddItemMail(itemLink, count, mailIndex, attachIndex, sender, daysLeft, money, CODAmount, wasReturned, recipient, firstItem)
						self:AddItemMail(itemLink, count, 1, i, GetUnitName("player"), 31, Sendmoney, Codmoney, nil, k, firstItem)
						firstItem = nil
					end
				end
				if self.Frame:IsVisible() and selectChar == k then
					self:Update("sort")
				end
				return
			end
		end
	end
end

function MB:BagUpdateDelayed()
	self:CheckBags()
end

function MB:FrameShow()
	self:UpdateContainer()
	self.Frame:Show()
end

function MB:FrameHide()
	self.Frame:Hide()
	self:SearchBarResetAndClear()
	collectgarbage("collect")
end

local MailboxBankPopMenu = {
	{text = L['Offline MailBox'],
	func = function() PlaySound("igMainMenuOpen"); MB:SetActiveTab('mail') end},
	{text = L['Offline Bag'],
	func = function() PlaySound("igMainMenuOpen"); MB:SetActiveTab('bag') end},
	{text = L['Offline Bank'], 
	func = function() PlaySound("igMainMenuOpen"); MB:SetActiveTab('bank') end},
}

local function DropDown(list, frame, xOffset, yOffset)
	if not frame.buttons then
		frame.buttons = {}
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		tinsert(UISpecialFrames, frame:GetName())
		frame:Hide()
	end

	xOffset = xOffset or 0
	yOffset = yOffset or 0

	for i=1, #frame.buttons do
		frame.buttons[i]:Hide()
	end

	for i=1, #list do 
		if not frame.buttons[i] then
			frame.buttons[i] = CreateFrame("Button", nil, frame)
			
			frame.buttons[i].hoverTex = frame.buttons[i]:CreateTexture(nil, 'OVERLAY')
			frame.buttons[i].hoverTex:SetAllPoints()
			frame.buttons[i].hoverTex:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
			frame.buttons[i].hoverTex:SetBlendMode("ADD")
			frame.buttons[i].hoverTex:Hide()

			frame.buttons[i].text = frame.buttons[i]:CreateFontString(nil, 'BORDER')
			frame.buttons[i].text:SetAllPoints()
			frame.buttons[i].text:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
			frame.buttons[i].text:SetJustifyH("LEFT")

			frame.buttons[i]:SetScript("OnEnter", function(btn)
				btn.hoverTex:Show()
			end)
			frame.buttons[i]:SetScript("OnLeave", function(btn)
				btn.hoverTex:Hide()
			end)
		end

		frame.buttons[i]:Show()
		frame.buttons[i]:SetHeight(16)
		frame.buttons[i]:SetWidth(135)
		frame.buttons[i].text:SetText(list[i].text)
		frame.buttons[i].func = list[i].func
		frame.buttons[i]:SetScript("OnClick", function(btn)
			btn.func()
			btn:GetParent():Hide()
		end)

		if i == 1 then
			frame.buttons[i]:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
		else
			frame.buttons[i]:SetPoint("TOPLEFT", frame.buttons[i-1], "BOTTOMLEFT")
		end
	end

	frame:SetHeight((#list * 16) + 10 * 2)
	frame:SetWidth(135 + 10 * 2)

	local UIScale = UIParent:GetScale();
	local x, y = GetCursorPosition();
	x = x/UIScale
	y = y/UIScale
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + xOffset, y + yOffset)	

	ToggleFrame(frame)
end

local menuFrame = CreateFrame("Frame", "MailboxBankClickMenu", UIParent)

function MB:CreateToggleButton(f, x, y)
	if not f then return; end
	
	if _G[f:GetName().."OfflineToogleButton"] then
		return _G[f:GetName().."OfflineToogleButton"]
	end		
	
	local frame = CreateFrame("Button", f:GetName().."OfflineToogleButton", f)
	if ElvUI then
		frame:StyleButton()
		frame:SetTemplate("Transparent")
	end	
	frame:RegisterForClicks('AnyUp', 'AnyDown')
	frame:SetScript("OnClick", function(self)
		DropDown(MailboxBankPopMenu, menuFrame)
	end)
	frame:SetSize(18, 18)
	frame:SetNormalTexture("Interface\\AddOns\\MailboxBank\\textures\\button.tga")
	frame:SetPushedTexture("Interface\\AddOns\\MailboxBank\\textures\\button.tga")
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine('Offline Frame')
		GameTooltip:SetClampedToScreen(true)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame:SetClampedToScreen(true)
	frame:SetPoint("TOPLEFT", x or 20, y or -10)
	
	return frame
end

---- Event ----

function MB:MAIL_INBOX_UPDATE()
		self:CheckMail()
		if selectChar == playername then
			self:Update("sort")
		end
end

function MB:BAG_UPDATE_DELAYED()
		self:CancelAllTimers()
		self:ScheduleTimer(function() self:BagUpdateDelayed() end, 2)
end

function MB:BANKFRAME_OPENED()
		self.isBankOpened = true
		self:CreateToggleButton(ElvUI_BankContainerFrame, 30, -20)
		self:CheckBags()
end

function MB:BANKFRAME_CLOSED()
		self.isBankOpened = nil
end

function MB:MAIL_SHOW()
		if not self.Frame:IsVisible() then 
			self:FrameShow();
		end
end

function MB:MAIL_CLOSED()
	self:FrameHide()
end

function MB:OnInitialize()
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
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
	if not BB_DB then BB_DB = {} end
	self:CreateMailboxBankFrame()
	self:SetActiveTab('mail')
	
	self:CreateToggleButton(ElvUI_BankContainerFrame, 30, -20)
	self:CreateToggleButton(ElvUI_ContainerFrame, 30, -20)
	self:CreateToggleButton(ContainerFrame1, 2, -2)
	self:CreateToggleButton(BankFrame, 2, -2)
	
	self:AlertDeadlineMails()
	hooksecurefunc("SendMail", function() self:HookSendMail() end)
	self.isBankOpened = nil
end
---- Slash command ----

SLASH_MAILBOXBANK1 = "/mb";
SLASH_MAILBOXBANK2 = "/mailbox";
SlashCmdList["MAILBOXBANK"] = function()
	if MB.Frame:IsVisible() then
		MB:FrameHide()
	else
		MB:Update("sort")
		MB:FrameShow()
	end
end;