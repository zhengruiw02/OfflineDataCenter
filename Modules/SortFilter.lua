local ODC = LibStub("AceAddon-3.0"):GetAddon("OfflineDataCenter")
local ODC_SortFilter = ODC:NewModule("SortFilter", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
--ODC_SortFilter.description = L["Offline Bag"]
ODC_SortFilter.type = "subFrame"
ODC_SortFilter.name = "SortFilter"

local len, sub, find, format, match = string.len, string.sub, string.find, string.format, string.match
local playername, selectChar, selectTab = ODC.playername, ODC.selectChar, ODC.selectTab
local G_DB, slotDB, subIdxTb, revSubIdxTb, sumQuality
local selectSortChanged, isStacked
local codMoney, codMailIndex, codAttachmentIndex
local FRAMENAME = "ODCFrameSortFilterSubFrame"

local AhSortIndex

--ODC.config_const
local Config = {
	daysLeftYellow = 7,
	daysLeftRed = 3,
	buttonSize = 36,
	buttonSpacing = 4,
	numItemsPerRow = 8,
	numItemsRows = 11,
	itemsSlotDisplay = 88,
	-- frameWidth = 360,
	-- frameHeight = 580,
}

local function BuildSortOrder()
	AhSortIndex = {__count = 0}
	--local c = 0;
	for i, iType in ipairs({GetAuctionItemClasses()}) do
		AhSortIndex[iType] = i
		AhSortIndex.__count = AhSortIndex.__count + 1
		-- for ii, isType in ipairs({GetAuctionItemSubClasses(i)}) do
			-- c = c + 1;
			-- AhSortIndex[isType] = c;
		-- end
	end
end

local function CalcLeftDay(player, mailIndex)
	return floor(difftime(floor(ODC_DB[player]["mail"][mailIndex].daysLeft * 86400) + ODC_DB[player]["mail"].checkMailTick,time()) / 86400)
end

local function GetItemID(itemLink)
	return tonumber(match(itemLink, "item:(%d+)"))
end

local function UpdateRevIndexTable(keyword, method) --keyword as [sender], "uncommom"
	local insertIndex
	if revSubIdxTb.__count == 0 then --table is nil(money can add only once)
		revSubIdxTb.__count = revSubIdxTb.__count + 1
		insertIndex = revSubIdxTb.__count
	elseif not method then --add to last
		revSubIdxTb.__count = revSubIdxTb.__count + 1
		insertIndex = revSubIdxTb.__count
	elseif method == "AH" then--table is not empty
		local AhIndex = AhSortIndex[keyword]
		if not AhIndex then
			AhSortIndex.__count = AhSortIndex.__count + 1
			AhSortIndex[keyword] = AhSortIndex.__count
			AhIndex = AhSortIndex.__count
			
		end
		for i, v in ipairs(subIdxTb) do --table is not empty
			
			if AhSortIndex[subIdxTb[i].keyword] > AhIndex then --can insert before end of table
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

local function InsertToIndexTable(keyword, mailIndex, attachIndex, method)
	if not keyword or not mailIndex then return end
	if not revSubIdxTb[keyword] then
		 UpdateRevIndexTable(keyword, method)
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
	local itemID = GetItemID(G_DB[mailIndex][attachIndex].itemLink)
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
					if G_DB[v.mailIndex][v.attachIndex].count >  G_DB[mailIndex][attachIndex].count then --can insert before this count
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

local SelectSortMethod = {
	["No sorting"] = function(mailIndex, attachIndex)
		local keyword = L["No sorting"]
		InsertToIndexTable(keyword, mailIndex, attachIndex, "no-sorting")	
	end,
	["AH"] = function(mailIndex, attachIndex)
		if not AhSortIndex then BuildSortOrder() end
		local itemID = GetItemID(G_DB[mailIndex][attachIndex].itemLink)
		local _, _, itemRarity, _, _, itemType, _, _, _, _, _ = GetItemInfo(itemID)
		InsertToIndexTable(itemType, mailIndex, attachIndex, "AH")
	end,
	["quality"] = function(mailIndex, attachIndex)
		local _, _, quality, _, _, _, _, _, _, _ = GetItemInfo(G_DB[mailIndex][attachIndex].itemLink)
		InsertToIndexTable(quality, mailIndex, attachIndex, "quality")
	end,
	["sender"] = function(mailIndex, attachIndex)
		local sender = G_DB[mailIndex].sender
		InsertToIndexTable(sender, mailIndex, attachIndex)	
	end,--mailbox only
	["left day"] = function(mailIndex, attachIndex)
		local leftday = CalcLeftDay(selectChar, mailIndex)
		InsertToIndexTable(leftday, mailIndex, attachIndex, "left day")
	end,--mailbox only
	["C.O.D."] = function(mailIndex, attachIndex)
		local isCOD
		if G_DB[mailIndex].CODAmount then
			isCOD = L["is C.O.D."]
		else
			isCOD = L["not C.O.D."]
		end
		InsertToIndexTable(isCOD, mailIndex, attachIndex)
	end,--mailbox only
	["money"] = function(mailIndex)
		local hasMoney
		if G_DB[mailIndex].money then
			hasMoney = L["has money"]
		end
		InsertToIndexTable(hasMoney, mailIndex, nil, "money")
	end,--mailbox only
}

local function Filter_OnClick(self)
	UIDropDownMenu_SetSelectedValue(ODCFrameSortFilterSubFrameFilterDropDown, self.value);
	ODC_SortFilter:Update("filter")
end

local function FilterMenuInitialize(self, level)
	--if not revSubIdxTb then return end
	local info = UIDropDownMenu_CreateInfo();
	info.text = ALL
	info.value = "__all"
	info.func = Filter_OnClick;
	UIDropDownMenu_AddButton(info, level)

	for k, v in ipairs(subIdxTb) do
		info = UIDropDownMenu_CreateInfo()
		local t
		local method = UIDropDownMenu_GetSelectedValue(ODCFrameSortFilterSubFrameSortDropDown)
		if method == "quality" then
			t = _G["ITEM_QUALITY"..v.keyword.."_DESC"]
		elseif method == "left day" then
			t = format("%d "..DAYS, v.keyword)
		else
			t = v.keyword
		end
		info.text = t
		info.value = v.keyword
		info.func = Filter_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end
	
	if UIDropDownMenu_GetSelectedValue(ODCFrameSortFilterSubFrameFilterDropDown) == nil or selectSortChanged == true then
		UIDropDownMenu_SetSelectedValue(ODCFrameSortFilterSubFrameFilterDropDown, "__all");
		selectSortChanged = nil
	end
end

local function SortMethod_OnClick(self)
	UIDropDownMenu_SetSelectedValue(ODCFrameSortFilterSubFrameSortDropDown, self.value);
	selectSortChanged = true
	ODC_SortFilter:Update("sort")
	--local text = OfflineDataCenterFrameSortDropDownText;
	--local width = text:GetStringWidth();
	--UIDropDownMenu_SetWidth(OfflineDataCenterFrameSortDropDown, width+40);
	--OfflineDataCenterFrameSortDropDown:SetWidth(width+60)	
end

local function SortMenuInitialize(self, level)
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(SelectSortMethod) do
		if selectTab == "mail" and (k == "sender" or k == "left day" or k == "C.O.D." or k == "money") or (k == "No sorting" or k == "AH" or k == "quality") then
			info = UIDropDownMenu_CreateInfo()
			info.text = L[k]
			info.value = k
			info.func = SortMethod_OnClick
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(ODCFrameSortFilterSubFrameSortDropDown, "No sorting");
	--local text = OfflineDataCenterFrameSortDropDownText;
	--local width = text:GetStringWidth();
	--UIDropDownMenu_SetWidth(OfflineDataCenterFrameSortDropDown, width+40);
	--OfflineDataCenterFrameSortDropDown:SetWidth(width+60)
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

local function SlotClick(slot,button)
	local msg = slot.link
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
	elseif button == 'LeftButton' and not isStacked then
		if selectTab == "mail" then
			if ODC_DB[selectChar]["mail"][slot.mailIndex[1]].CODAmount then
				if ODC_DB[selectChar]["mail"][slot.mailIndex[1]].CODAmount > GetMoney() then
					SetMoneyFrameColor("GameTooltipMoneyFrame1", "red");
					StaticPopup_Show("COD_ALERT");
				else
					codMoney, codMailIndex, codAttachmentIndex = ODC_DB[selectChar]["mail"][slot.mailIndex[1]].CODAmount, slot.mailIndex[1], slot.attachIndex[1]
					SetMoneyFrameColor("GameTooltipMoneyFrame1", "white");
					StaticPopup_Show("MAILBOXBANK_ACCEPT_COD_MAIL")
				end
			else
				if slot.mailIndex[1] and slot.attachIndex[1] then
					--for i = getn(slot.mailIndex), 1, -1 do
						TakeInboxItem(slot.mailIndex[1], slot.attachIndex[1])
					--end
					ODC_SortFilter:Update("sort")
				end
			end
		else
			
		end
	end
end

local function GetLeftTimeText(mailIndex)
	local lefttext = L["+ Left time: "]
	local dayLeftTick = difftime(floor(ODC_DB[selectChar]["mail"][mailIndex].daysLeft * 86400) + ODC_DB[selectChar]["mail"].checkMailTick,time())
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

local function TooltipShow(slot)
	if selectTab ~= "mail" then 
		if slot and slot.link then
			local x = slot:GetRight();
			if ( x >= ( GetScreenWidth() / 2 ) ) then
				GameTooltip:SetOwner(slot, "ANCHOR_LEFT");
			else
				GameTooltip:SetOwner(slot, "ANCHOR_RIGHT");
			end
			GameTooltip:SetHyperlink(slot.link)
		end
		return
	end
	local mIdx, aIdx = slot.mailIndex, slot.attachIndex
	local method = UIDropDownMenu_GetSelectedValue(ODCFrameSortFilterSubFrameSortDropDown)
	--local sender, wasReturned
	if method =="money" then
			local x = slot:GetRight();
			if ( x >= ( GetScreenWidth() / 2 ) ) then
				GameTooltip:SetOwner(slot, "ANCHOR_LEFT");
			else
				GameTooltip:SetOwner(slot, "ANCHOR_RIGHT");
			end
		local money = ODC_DB[selectChar]["mail"][mIdx].money
		local lefttext = L["Sender: "] ..ODC_DB[selectChar]["mail"][mIdx].sender
		local rL, gL, bL = 1, 1, 1
		GameTooltip:AddDoubleLine(lefttext, GetCoinTextureString(money),rL, gL, bL)
		local lefttext = GetLeftTimeText(mIdx)
		GameTooltip:AddDoubleLine(lefttext, "", rL, gL, bL)
		GameTooltip:Show()
		return
	else
		if slot and slot.link then
			local x = slot:GetRight();
			if ( x >= ( GetScreenWidth() / 2 ) ) then
				GameTooltip:SetOwner(slot, "ANCHOR_LEFT");
			else
				GameTooltip:SetOwner(slot, "ANCHOR_RIGHT");
			end
			GameTooltip:SetHyperlink(slot.link)
		end
	end
	
	local formatList = {}
	for i = 1 , getn(mIdx) do
		if formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender] == nil then
			formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender] = {}
			local row = {}
			row.lefttext = L["Sender: "] ..ODC_DB[selectChar]["mail"][mIdx[i]].sender
			row.righttext = 0 ---summary count
			tinsert(formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender], row)
		end
		
		local lefttext, leftday = GetLeftTimeText(mIdx[i])
		
		local foundSameLefttime = false
		for j = 1, getn(formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender]) do
			if formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender][j].lefttext == lefttext and not ODC_DB[selectChar]["mail"][mIdx[i]][aIdx[i]].CODAmount and not ODC_DB[selectChar]["mail"][mIdx[i]][aIdx[i]].wasReturned then----!!should add cod and was returned
				formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender][j].righttext = formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender][j].righttext + ODC_DB[selectChar]["mail"][mIdx[i]][aIdx[i]].count
				formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender][1].righttext = formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender][1].righttext + ODC_DB[selectChar]["mail"][mIdx[i]][aIdx[i]].count
				foundSameLefttime = true
			end
		end
		
		if foundSameLefttime == false then
			local row = {}
			row.lefttext = lefttext
			row.righttext = ODC_DB[selectChar]["mail"][mIdx[i]][aIdx[i]].count
			row.leftday = leftday
			formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender][1].righttext = formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender][1].righttext + ODC_DB[selectChar]["mail"][mIdx[i]][aIdx[i]].count
			tinsert(formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender], row)
			
			if ODC_DB[selectChar]["mail"][mIdx[i]].CODAmount then
				row = {}
				row.lefttext = "└-"..COD.." "..ITEMS
				row.righttext = L["pay for: "]..GetCoinTextureString(ODC_DB[selectChar]["mail"][mIdx[i]].CODAmount)
				row.cod = true
				tinsert(formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender], row)
			end
			
			if ODC_DB[selectChar]["mail"][mIdx[i]].wasReturned then
				row = {}
				row.lefttext = "└-"..L["was returned"]
				row.righttext = ""
				row.wasreturned = true
				tinsert(formatList[ODC_DB[selectChar]["mail"][mIdx[i]].sender], row)
			end
		end
		
	end
	
	for k in pairs(formatList) do
		for i = 1, getn(formatList[k]) do
			local rL, gL, bL = 1, 1, 1
			if i > 1 then
				if formatList[k][i].leftday then
					local leftday = formatList[k][i].leftday
					if leftday < Config.daysLeftRed then
						rL, gL, bL = 1, 0, 0
					elseif leftday < Config.daysLeftYellow then
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

local function SummingForQuality(slotdb)
	local mailIndex, attachIndex = slotdb.mailIndex, slotdb.attachIndex
	if not mailIndex or not attachIndex or not selectChar then return end
	local _, _, quality, _, _, _, _, _, _, _ = GetItemInfo(G_DB[mailIndex][attachIndex].itemLink)
	if not quality then return end
	if not sumQuality[quality] then sumQuality[quality] = 0 end
	local count = G_DB[mailIndex][attachIndex].count
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

local function SubFilter(i, c)
	for j = 1, getn(subIdxTb[i]) do
		if not isStacked then --ODC_Config.UI.isStacked
			for k = 1, getn(subIdxTb[i][j]) do
				c = c + 1
				slotDB[c] = {}
				slotDB[c][1] = subIdxTb[i][j][k]--??
				SummingForQuality(slotDB[c][1])
			end
		else
			c = c + 1
			slotDB[c] = subIdxTb[i][j]
			for k = 1, getn(subIdxTb[i][j]) do
				SummingForQuality(subIdxTb[i][j][k])
			end
		end
	end
	return c
end

local function Filter()
	if not subIdxTb then return end
	slotDB = {}
	sumQuality = {}
	local filter = UIDropDownMenu_GetSelectedValue(ODCFrameSortFilterSubFrameFilterDropDown)
	if not filter then filter = "__all" end
	local c = 0
	
	local method = UIDropDownMenu_GetSelectedValue(ODCFrameSortFilterSubFrameSortDropDown)
	if method == "money" then
		for i = 1, getn(subIdxTb[1]) do
			c = c + 1
			slotDB[c] = subIdxTb[1][i]
		end
		return
	end
	if filter == "__all" then
		for i = 1, getn(subIdxTb) do
			c = SubFilter(i, c)
		end
	else
		i = revSubIdxTb[filter]
		c = SubFilter(i, c)
	end
end

local function SortDB()
	local method = UIDropDownMenu_GetSelectedValue(ODCFrameSortFilterSubFrameSortDropDown)
	if not method then return end
	subIdxTb = {}
	--subIdxTb.method = method
	revSubIdxTb = {__count = 0}
	if not G_DB then return end --by eui.cc

	for firstIndex ,t1 in pairs(G_DB) do
		if type(t1) == "table" then
			--if not G_DB[firstIndex] then return end
			if method == "money" then
				if G_DB[firstIndex].money then
					SelectSortMethod[method](firstIndex)
				end
			else
				for secondIndex, t in pairs(G_DB[firstIndex]) do
					if type(t) == "table" then
						SelectSortMethod[method](firstIndex, secondIndex)
					end
				end
			end
		end
	end
	
	if revSubIdxTb.__count == 0 then slotDB = nil; return end
	UIDropDownMenu_Initialize(ODCFrameSortFilterSubFrameFilterDropDown, FilterMenuInitialize)
	Filter()
end

local function UpdateContainer()
	if not ODC.Frame or not ODC_SortFilter.Frame then return end
	ODC_SortFilter.Frame.mailboxGoldText:SetText("")
	
	for i = 1, Config.itemsSlotDisplay do
		if ODC_SortFilter.Frame.Container[i] then
			ODC_SortFilter.Frame.Container[i]:Hide()
		end
	end
	if not slotDB then return end
	
	local sumQ = ""
	for i = 1, 7 do
		if sumQuality[i] then
			local _,_,_,colorCode = GetItemQualityColor(i)
			if sumQ ~= "" then sumQ = sumQ.." / " end
			sumQ = sumQ.."|c"..colorCode..sumQuality[i].."|r "
		end
	end
	if sumQ ~= "" then
		sumQ = "\r\n"..L["Quality summary: "]..sumQ
	end
	local former = ""
	if G_DB.money then
		if selectTab == "mail" then
			former = L["Mailbox gold: "]
		elseif selectTab == "bag" or selectTab == "bank" then
			former = L["Character gold: "]
		end
		former = former .. GetCoinTextureString(G_DB.money)
	end
	ODC_SortFilter.Frame.mailboxGoldText:SetText(former..sumQ)
	--ODC.mailboxTime:SetText(floor(difftime(time(),sorted_db[selectChar].checkMailTick)/60).." 分鐘前掃描" or "");

	local offset = FauxScrollFrame_GetOffset(ODC_SortFilter.Frame.scrollBar)
	
	local iconDisplayCount
	if (getn(slotDB) - offset * 8) > Config.itemsSlotDisplay then
		iconDisplayCount = Config.itemsSlotDisplay
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
		local slot = ODC_SortFilter.Frame.Container[i]
		
		local method = UIDropDownMenu_GetSelectedValue(ODCFrameSortFilterSubFrameSortDropDown)
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

			local money = G_DB[mailIndex].money
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
			slot.link = G_DB[slot.mailIndex[1]][slot.attachIndex[1]].itemLink
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
				countnum = countnum + G_DB[slot.mailIndex[j]][slot.attachIndex[j]].count
				if G_DB[slot.mailIndex[j]].CODAmount then
				slot.tex:SetDesaturated(1)
				slot.cod:Show()
				end
			end
			slot.count:SetText(countnum > 1 and countnum or '');
			
			if ODC_SortFilter.Frame.searchingBar:HasFocus() then
				if not slot.name then break end
				local searchingStr = ODC_SortFilter.Frame.searchingBar:GetText();
				if not find(slot.name, searchingStr) then
					slot.tex:SetVertexColor(0.25, 0.25, 0.25)
					slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
					slot.count:SetTextColor(0.3, 0.3, 0.3)
				end
			end
			
		end
		
		slot:Show()
	end
	FauxScrollFrame_Update(ODC_SortFilter.Frame.scrollBar, ceil(getn(slotDB) / Config.numItemsPerRow) , Config.numItemsRows, Config.buttonSize + Config.buttonSpacing );
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


function ODC_SortFilter:GameTooltip_OnTooltipCleared(TT)
	if ( not TT ) then
		TT = GameTooltip;
	end
	TT.ItemCleared = nil
end

local function AddItemTooltip(characterName, count, FoundDB)
	if not FoundDB[characterName] then
		FoundDB[characterName] = 0
	end
	FoundDB[characterName] = FoundDB[characterName] + count
end

local function LookupSameItem(itemID)
	local FoundDB = {}
	local BagIDs = {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
	local dbs = {"bag", "bank", "mail", "inventory"}
	for charName, db in pairs(ODC_DB) do
		for k, tabName in pairs(dbs) do
			if ODC_DB[charName][tabName] then
				for i, box in pairs(ODC_DB[charName][tabName]) do
					if type(box) == "table" then
						for j, item in pairs(box) do
							if item and type(item) == "table" then
								if GetItemID(item.itemLink) == itemID then
									AddItemTooltip(charName, item.count, FoundDB)
								end
							end
						end
					end
				end
			end
		end
	end
	return FoundDB
end

function ODC_SortFilter:GameTooltip_OnTooltipSetItem(TT)
	if ( not TT ) then
		TT = GameTooltip;
	end
	if not TT.ItemCleared then
		TT:AddLine(" ")
		local item, link = TT:GetItem()
		if IsAltKeyDown() and link ~= nil then
			local itemID = GetItemID(link)
			local FoundDB = LookupSameItem(itemID)
			for k, v in pairs(FoundDB) do
				TT:AddDoubleLine('|cFFCA3C3C'..k..'|r', v)
			end
		else
			TT:AddDoubleLine('|cFFCA3C3C'..L['Hold down the ALT key']..'|r', L['Show the number of items for all Character'])
		end		
		
		TT.ItemCleared = true;
	end		
end

local function UpdateSearch()
	local MIN_REPEAT_CHARACTERS = 3;
	local searchString = ODC_SortFilter.Frame.searchingBar:GetText();
	if (len(searchString) > MIN_REPEAT_CHARACTERS) then
		local repeatChar = true;
		for i=1, MIN_REPEAT_CHARACTERS, 1 do 
			if ( sub(searchString,(0-i), (0-i)) ~= sub(searchString,(-1-i),(-1-i)) ) then
				repeatChar = false;
				break;
			end
		end
		if ( repeatChar ) then
			SearchBarResetAndClear();
			ODC_SortFilter:Update();
			return;
		end
	end
	ODC_SortFilter:Update();
end

local function OpenEditbox()
	ODC_SortFilter.Frame.searchingBarText:Hide();
	ODC_SortFilter.Frame.searchingBar:Show();
	ODC_SortFilter.Frame.searchingBar:SetText(SEARCH);
	ODC_SortFilter.Frame.searchingBar:HighlightText();
end

local function SearchBarResetAndClear()
	ODC_SortFilter.Frame.searchingBarText:Show();
	ODC_SortFilter.Frame.searchingBar:ClearFocus();
	ODC_SortFilter.Frame.searchingBar:SetText("");
end

local function CreateSubFrame()
	local p = ODC.Frame
	local f = CreateFrame('Frame',FRAMENAME, p);
	f:SetPoint('TOPLEFT', 0, -40);
	f:SetPoint('BOTTOMRIGHT', 0, 0);
	ODC_SortFilter.Frame = f
	
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
	f.searchingBar:SetPoint('TOPLEFT', f, 'TOPLEFT', 12, 0);
	if ElvUI then
		f.searchingBar:FontTemplate(nil, 12, 'OUTLINE')
	else
		f.searchingBar:SetFont(STANDARD_TEXT_FONT, 12);
	end

	f.searchingBarText = f:CreateFontString(nil, "ARTWORK");
	if ElvUI then
		f.searchingBarText:FontTemplate(nil, 12, 'OUTLINE')
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
			OpenEditbox();
		else
			if f.searchingBar:IsShown() then
				SearchBarResetAndClear()
			else
				OpenEditbox();
			end
		end
	end)
	
	----Create stack up button
	f.stackUpCheckButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.stackUpCheckButton:SetPoint("LEFT",f.searchingBar, 200, 0)
	f.stackUpCheckButton.text:SetText(L["Stack items"])
	f.stackUpCheckButton:SetChecked(false)--ODC_Config.UI.isStacked or false)
	f.stackUpCheckButton:SetScript("OnClick", function(self)
		--ODC_Config.UI.isStacked = self:GetChecked()
		isStacked = self:GetChecked()
		ODC_SortFilter:Update("filter")
	end)

	----Create sort dropdown menu
	tinsert(UISpecialFrames, f)
	f.sortmethod = CreateFrame('Frame', FRAMENAME..'SortDropDown', f, 'UIDropDownMenuTemplate')
	f.sortmethod:SetPoint("BOTTOMLEFT", f.searchingBar, 0, -36)
	
	----Create filter dropdown menu
	f.filter = CreateFrame('Frame', FRAMENAME..'FilterDropDown', f, 'UIDropDownMenuTemplate')
	f.filter:SetPoint("LEFT", f.sortmethod, 150, 0)
	
	----Create mailbox gold text
	f.mailboxGoldText = f:CreateFontString(nil, 'OVERLAY');
	if ElvUI then
		f.mailboxGoldText:FontTemplate(nil, 14, 'OUTLINE')
	else
		f.mailboxGoldText:SetFont(STANDARD_TEXT_FONT, 14);
	end
	f.mailboxGoldText:SetPoint("BOTTOMLEFT", 10, 5);
	f.mailboxGoldText:SetJustifyH("LEFT");
	
	----Create check time text
	-- f.checktime = f:CreateFontString(nil, 'OVERLAY');
	-- f.checktime:FontTemplate()
	-- f.checktime:SetPoint("BOTTOMLEFT", 20, 5);
	
	----Create scroll frame
	f.scrollBar = CreateFrame("ScrollFrame", FRAMENAME.."ScrollBar", f, "FauxScrollFrameTemplate")
	f.scrollBar:SetPoint("TOPLEFT", 0, -64)
	f.scrollBar:SetPoint("BOTTOMRIGHT", -28, 40)
	f.scrollBar:SetHeight( Config.numItemsRows * Config.buttonSize + (Config.numItemsRows - 1) * Config.buttonSpacing)
	f.scrollBar:Hide()
	--f.scrollBar:EnableMouseWheel(true)
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, Config.buttonSize + Config.buttonSpacing);
		ODC_SortFilter:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		ODC_SortFilter:Update()
	end)
	
	if ElvUI then
		local S = ElvUI[1]:GetModule("Skins")
		if S then
			S:HandleCheckBox(f.stackUpCheckButton);
			S:HandleDropDownBox(f.sortmethod)
			S:HandleDropDownBox(f.filter)
			S:HandleScrollBar(_G[FRAMENAME.."ScrollBarScrollBar"])
		end
	end
	
	----Create Container
	f.Container = CreateFrame('Frame', nil, f);
	f.Container:SetPoint('TOPLEFT', f, 'TOPLEFT', 12, -50);-- -90);
	f.Container:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 8);
	f.Container:Show()
	
	local numContainerRows = 0;
	local lastButton;
	local lastRowButton;
	for i = 1, Config.itemsSlotDisplay do
		local slot
		if ElvUI then
			slot = CreateFrame('Button', nil, f.Container);
			slot:SetTemplate('Default');
			slot:StyleButton();
			slot:Size(Config.buttonSize);
		else
			slot = CreateFrame('Button', nil, f.Container, "ItemButtonTemplate");
			slot:SetSize(Config.buttonSize, Config.buttonSize);
		end
		slot:Hide()
		
		slot.count = slot:CreateFontString(nil, 'OVERLAY');
		slot.cod = slot:CreateFontString(nil, 'OVERLAY');
		if ElvUI then
			slot.count:FontTemplate(nil, 12, 'OUTLINE')
			slot.cod:FontTemplate(nil, 12, 'OUTLINE')
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
		slot:SetScript("OnEnter", TooltipShow)
		slot:HookScript("OnClick", SlotClick)
		slot:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		f.Container[i] = slot
		
		if lastButton then
			if (i - 1) % Config.numItemsPerRow == 0 then
				slot:SetPoint('TOP', lastRowButton, 'BOTTOM', 0, -Config.buttonSpacing);
				lastRowButton = f.Container[i];
				numContainerRows = numContainerRows + 1;
			else
				slot:SetPoint('LEFT', lastButton, 'RIGHT', Config.buttonSpacing, 0);
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
		SearchBarResetAndClear()
		ODC_SortFilter:Update()
	end);
	f.searchingBar:SetScript("OnEnterPressed", function()
		ODC_SortFilter:SearchBarResetAndClear()
		ODC_SortFilter:Update()
	end);
	f.searchingBar:SetScript("OnEditFocusLost", f.searchingBar.Hide);
	f.searchingBar:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
		UpdateSearch()
	end);
	f.searchingBar:SetScript("OnTextChanged", function()
		UpdateSearch()
	end);
	f.searchingBar:SetScript('OnChar', function()
		UpdateSearch()
	end);
	
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, Config.buttonSize + Config.buttonSpacing);
		ODC_SortFilter:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		ODC_SortFilter:Update()
	end)
	--UIDropDownMenu_Initialize(f.sortmethod, SortMenuInitialize)
end

local function UpdateSortMenu()
	UIDropDownMenu_Initialize(ODC_SortFilter.Frame.sortmethod, SortMenuInitialize)
end

function ODC_SortFilter:CreateOrShowSubFrame(tabName)
	if not self.Frame then
		CreateSubFrame()
	end

	UpdateSortMenu()
	ODC:ShowSubFrame(tabName, ODC_SortFilter.Frame)
end

function ODC_SortFilter:Update(method)
	if not ODC.Frame:IsVisible() then return end
	if not selectChar then return end
	--selectTab = tabName
	G_DB = ODC_DB[selectChar][selectTab]
	if not G_DB then return end

	if method == "sort" then
		SearchBarResetAndClear()
		SortDB()
	elseif method == "filter" then
		Filter()
	end
	UpdateContainer()
end

ODC_SortFilter.selectTabCallbackFunc = function(selectedTab)
	selectTab = selectedTab
end

ODC_SortFilter.selectCharCallbackFunc = function(selectedChar)
	selectChar = selectedChar
end

-- function ODC_SortFilter:OnInitialize()
	-- CreateSubFrame()
-- end

function ODC_SortFilter:OnEnable()
	ODC:AddModule(self)
	self:HookScript(GameTooltip, 'OnTooltipSetItem', 'GameTooltip_OnTooltipSetItem')
	self:HookScript(GameTooltip, 'OnTooltipCleared', 'GameTooltip_OnTooltipCleared')
end

function ODC_SortFilter:OnDisable()
	-- self:UnhookAll()
	ODC:RemoveModule(self)
end