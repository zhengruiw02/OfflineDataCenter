--@@ TODO: solve COD item, maybe displaying COD amount above the slot icon or using tool-tip
	--UC..don't know how to layout in tool-tip..
--@@ TODO: change frame's layout!
	--holy shit..
--@@ TODO: should stacked attachments can be collect??
	--UC.. new window to produce? or pop-up ?
--@@ TODO: should attachments be alerted to player to collect when almost in deadline?
	--UC.. should make new function to calculate deadline time?
--local E, L, V, P, G, _ = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
--local MB = LibStub("AceAddon-3.0"):NewAddon("MailboxBank")
local L = LibStub("AceLocale-3.0"):GetLocale("MailboxBank")
local getn, tinsert = table.getn, table.insert
local floor = math.floor
local len, sub, find, format, match = string.len, string.sub, string.find, string.format, string.match
local playername = GetUnitName("player")..'-'..GetRealmName()
local selectValue = playername
local slotDB, subIdxTb, revSubIdxTb

local MB = CreateFrame("Frame", nil , UIParent)

MB.config_init = {
	daysLeftYellow = 7,
	daysLeftRed = 3,
	buttonSize = 36,
	buttonSpacing = 4,
	numItemsPerRow = 8,
	numItemsRows = 10,
	itemsSlotDisplay = 80,
	frameWidth = 350,
	frameHeight = 500,
	rowcount = 8,
	maxrow = 10,
	px = 0,
	py = 0,
	isStacked = false,
}	

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

function MB:AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, CODAmount, wasReturned, recipient)
	local item = {}
	item["sender"] = sender
	item["count"] = count
	item["itemLink"] = itemLink
	item["daysLeft"] = daysLeft
	item["mailIndex"] = mailIndex
	item["attachIndex"] = attachIndex
	if CODAmount > 0 then item["CODAmount"] = CODAmount end
	if wasReturned then item["wasReturned"] = wasReturned end
	if recipient then
		tinsert(MB_DB[recipient], 1, item)
		MB_DB[recipient].itemCount = MB_DB[recipient].itemCount + 1
	else
		tinsert(MB_DB[playername], item)
		MB_DB[playername].itemCount = MB_DB[playername].itemCount + 1
	end
end

function MB:CheckMail(isCollectMoney)
	if isCollectMoney and MB_DB[playername].money == 0 then return end
	MB_DB[playername] = {itemCount = 0, money = 0}
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
			--@@ TODO: solve COD item, maybe can display COD amount in the slot icon or tooltip
				if sender == nil then
					sender = L["UNKNOWN SENDER"]
				end
				for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
					local itemLink = GetInboxItemLink(mailIndex, attachIndex)
					if itemLink then
						local _, _, count, _, _ = GetInboxItem(mailIndex, attachIndex)
						self:AddItem(sender, itemLink, count, daysLeft, mailIndex, attachIndex, CODAmount, wasReturned)
					end
				end
			end
		end
	end
	MB_DB[playername].checkMailTick = time()
	--return true
end

function MB:CalcLeftDay(player, itemIndex)
	return floor(difftime(floor(MB_DB[player][itemIndex].daysLeft * 86400) + MB_DB[player].checkMailTick,time()) / 86400)
end

function MB:SearchReset()
	self:UpdateContainer()
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
			return;
		end
	end
	self:UpdateContainer();
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
	self:UpdateContainer()
end

function MB:CollectMoney()
	self:CheckMail(true)
end

function MB:UpdateRevIndexTable(keyword, method) --keyword as [sender], "uncommom"
	local insertIndex
	if revSubIdxTb["__count"] == 0 then --table is nil
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

function MB:InsertToIndexTable(keyword, itemIndexCount, method)
	if not keyword or not itemIndexCount then return end
	local itemID = tonumber(match(MB_DB[selectValue][itemIndexCount].itemLink, "item:(%d+)"))
	if not revSubIdxTb[keyword] then
		 self:UpdateRevIndexTable(keyword, method)
	end
	local subIdx = revSubIdxTb[keyword]
	local c = 0
	if getn(subIdxTb[subIdx]) == 0 then --no items in this type yet..
		subIdxTb[subIdx][1] = {["itemID"] = itemID}--,["count"] = 1}
		subIdxTb[subIdx][1][1] = itemIndexCount
		subIdxTb[subIdx].itemslotCount = 1
		for i = 1, subIdx do
			c = c + subIdxTb[i].itemslotCount
		end
		return c
	else
		for i, v in ipairs(subIdxTb[subIdx]) do
			if subIdxTb[subIdx][i].itemID > itemID then --can insert before end of table
				local t = {[1] = itemIndexCount, ["itemID"] = itemID}
				tinsert(subIdxTb[subIdx], i, t)
				subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
				for ii = 1, subIdx - 1 do
					c = c + subIdxTb[ii].itemslotCount
				end
				for ii = 1, i do
					c = c + getn(subIdxTb[subIdx][ii])
				end
				return c
			elseif subIdxTb[subIdx][i].itemID == itemID then
				for ii, v in ipairs(subIdxTb[subIdx][i]) do
					if MB_DB[selectValue][v].count >  MB_DB[selectValue][itemIndexCount].count then
						tinsert(subIdxTb[subIdx][i], ii, itemIndexCount)
						subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
						for iii = 1, subIdx - 1 do
							c = c + subIdxTb[iii].itemslotCount
						end
						for iii = 1, i - 1 do
							c = c + getn(subIdxTb[subIdx][iii])
						end
						c = c + ii
						return c
					elseif ii == getn(subIdxTb[subIdx][i]) then
						tinsert(subIdxTb[subIdx][i], itemIndexCount)
						subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
						for iii = 1, subIdx - 1 do
							c = c + subIdxTb[iii].itemslotCount
						end
						for iii = 1, i do
							c = c + getn(subIdxTb[subIdx][iii])
						end
						return c
					end
				end
			elseif i == getn(subIdxTb[subIdx]) then  --insert to end of table
				local t = {[1] = itemIndexCount, ["itemID"] = itemID}
				tinsert(subIdxTb[subIdx], t)
				subIdxTb[subIdx].itemslotCount = subIdxTb[subIdx].itemslotCount + 1
				for ii = 1, subIdx do
					c = c + subIdxTb[ii].itemslotCount
				end
				return c
			end
		end
	end
end

--revSubIdxTb, subIdxTb
--[[ subIdxTb structure
			subType		itemsID			sameID items	slot?
subIdxTb{	[1]		{ 	[1]			{	[1]		=		itemIndexCount(.itemCount)
			[2]			[2]				[2]
			...			...				...
			[n]			[n]				[n]
						.keyword		.itemID
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
--[[	build filter menu base on subType!
if sort as normal, it can be COD, gold?
]]
MB.SelectSortMethod = {
	["AH"] = function(self, itemIndexCount)
		if not self.AhSortIndex then self:BuildSortOrder() end
		local itemID = tonumber(match(MB_DB[selectValue][itemIndexCount].itemLink, "item:(%d+)"))
		local _, _, itemRarity, _, _, _, itemSubType, _, _, _, _ = GetItemInfo(itemID)
		return self:InsertToIndexTable(itemSubType, itemIndexCount, "AH")	
	end,
	["sender"] = function(self, itemIndexCount)
		local sender = MB_DB[selectValue][itemIndexCount].sender
		return self:InsertToIndexTable(sender, itemIndexCount)	
	end,
	["quality"] = function(self, itemIndexCount)
		local _, _, quality, _, _, _, _, _, _, _ = GetItemInfo(MB_DB[selectValue][itemIndexCount].itemLink)
		return self:InsertToIndexTable(quality, itemIndexCount, "quality")
	end,
	["left day"] = function(self, itemIndexCount)
		local leftday = self:CalcLeftDay(selectValue, itemIndexCount)
		return self:InsertToIndexTable(leftday, itemIndexCount, "left day")
	end,
	["C.O.D."] = function(self, itemIndexCount)
		local isCOD
		if MB_DB[selectValue][itemIndexCount].CODAmount then
			isCOD = "is C.O.D."
		else
			isCOD = "not C.O.D."
		end
		return self:InsertToIndexTable(isCOD, itemIndexCount)
	end,
}

function MB:InsertToSlot(slot, itemIndexCount, isInit)
	if isInit then
		slot.link = MB_DB[selectValue][itemIndexCount].itemLink
		slot.checkMailTick = MB_DB[selectValue].checkMailTick
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
			slot.wasReturned = MB_DB[selectValue][itemIndexCount].wasReturned
			slot.CODAmount = MB_DB[selectValue][itemIndexCount].CODAmount
		end
	end
	if selectValue == playername then
		if not slot.mailIndex then slot.mailIndex = {} end
		if not slot.attachIndex then slot.attachIndex = {} end
		tinsert(slot.mailIndex , MB_DB[selectValue][itemIndexCount].mailIndex)
		tinsert(slot.attachIndex , MB_DB[selectValue][itemIndexCount].attachIndex)
	end
	tinsert(slot.sender , MB_DB[selectValue][itemIndexCount].sender)
	tinsert(slot.dayLeft , MB_DB[selectValue][itemIndexCount].daysLeft)
	tinsert(slot.countNum , MB_DB[selectValue][itemIndexCount].count)
	-- local index = getn(slot.dayLeft)
	-- tinsert(slot.wasReturned, index, MB_DB[selectValue][itemIndexCount].wasReturned)
	-- tinsert(slot.CODAmount, index, MB_DB[selectValue][itemIndexCount].CODAmount)
	return slot
end

function MB:Filter_OnClick(self, info)
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameFilterDropDown, info.value);
	self:Update("filter")
end

function MB:BuildFilter()
	if not revSubIdxTb then return end
	local info = UIDropDownMenu_CreateInfo();
	info = UIDropDownMenu_CreateInfo()
	info.text = L["All"]
	info.value = "__all"
	info.func = self:Filter_OnClick(self, info);
	UIDropDownMenu_AddButton(info, level)

	for k, v in pairs(revSubIdxTb) do
		if k ~= "__count" then
			info = UIDropDownMenu_CreateInfo()
			local t
			local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
			if method == "quality" then
				t = _G["ITEM_QUALITY"..k.."_DESC"]
			elseif method == "left day" then
				t = k .. L[" days"]
			else
				t = k
			end
			info.text = t
			info.value = k
			info.func = self:Filter_OnClick(self, info);
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameFilterDropDown, "__all");
end

function MB:Filter()
	if not subIdxTb then return end
	slotDB = {}
	local filter = UIDropDownMenu_GetSelectedValue(MailboxBankFrameFilterDropDown)
	if not filter then filter = "__all" end
	local c = 0
	if filter == "__all" then
		for i = 1, getn(subIdxTb) do
			for j = 1, getn(subIdxTb[i]) do
				if not MB_config.isStacked then
					for k = 1, getn(subIdxTb[i][j]) do
						c = c + 1
						slotDB[c] = subIdxTb[i][j][k]
					end
				else
					c = c + 1
					slotDB[c] = subIdxTb[i][j]
				end
			end
		end
	else
		i = revSubIdxTb[filter]
		for j = 1, getn(subIdxTb[i]) do
			if not MB_config.isStacked then
				for k = 1, getn(subIdxTb[i][j]) do
					c = c + 1
					slotDB[c] = subIdxTb[i][j][k]
				end
			else
				c = c + 1
				slotDB[c] = subIdxTb[i][j]
			end
		end
	end
end

function MB:SortDB()
	local method = UIDropDownMenu_GetSelectedValue(MailboxBankFrameSortDropDown)
	subIdxTb = {}
	revSubIdxTb = {["__count"] = 0}
	for itemIndexCount = 1, MB_DB[selectValue].itemCount do
		self.SelectSortMethod[method](self, itemIndexCount)
	end
	UIDropDownMenu_Initialize(MailboxBankFrameFilterDropDown, self:BuildFilter());
	self:Filter()
end

---- GUI ----
function MB:SortMethod_OnClick(self, info)
	UIDropDownMenu_SetSelectedValue(MailboxBankFrameSortDropDown, info.value);
	
	self:Update("sort")
	--local text = MailboxBankFrameSortDropDownText;
	--local width = text:GetStringWidth();
	--UIDropDownMenu_SetWidth(MailboxBankFrameSortDropDown, width+40);
	--MailboxBankFrameSortDropDown:SetWidth(width+60)	
end

function MB:SortMenuInitialize()
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(self.SelectSortMethod) do
			info = UIDropDownMenu_CreateInfo()
			info.text = L[k]
			info.value = k
			info.func = self:SortMethod_OnClick(self, info);
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
function MB:ChooseChar_OnClick(self, value) ---!!!
	selectValue = value
	UIDropDownMenu_SetSelectedValue(self.chooseChar, value);
	self:SearchBarResetAndClear()
	self:Update(true)
	
	local text = MailboxBankFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(self.chooseChar, width+40);
	self.chooseChar:SetWidth(width+60)	
end

function MB:DropDownMenuInitialize()
	local info = UIDropDownMenu_CreateInfo();
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			local info = UIDropDownMenu_CreateInfo()
			info.text = k
			info.value = k
			info.func = self:ChooseChar_OnClick(self, info.value); ---???
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_SetSelectedValue(self.chooseChar, selectValue);
	local text = MailboxBankFrameChooseCharDropDownText;
	local width = text:GetStringWidth();
	UIDropDownMenu_SetWidth(self.chooseChar, width+40);
	self.chooseChar:SetWidth(width+60)
end

function MB:CreatMailboxBankFrame()
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
	f:SetWidth(MB_config.frameWidth)
	f:SetHeight(MB_config.frameHeight)
	--f:SetPoint("CENTER", 0, 0)
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
	
	----Create close button
	f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton");
	f.closeButton:SetPoint("TOPRIGHT", -2, -2);
	f.closeButton:HookScript("OnClick", function()
		f:SearchBarResetAndClear()
		collectgarbage("collect")
	end)
	
	----Create stack up button
	f.stackUpCheckButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	f.stackUpCheckButton:SetPoint("TOPLEFT", 2, -2)
	f.stackUpCheckButton.text:SetText(L["Stack items"])
	f.stackUpCheckButton:SetChecked(MB_config.isStacked)
	f.stackUpCheckButton:SetScript("OnClick", function(self)
		MB_config.isStacked = self:GetChecked()
		f:Update("filter")
	end)

	----Create sort dropdown menu
	local name = "MailboxBankFrame"
	tinsert(UISpecialFrames, f)
	f.sortmethod = CreateFrame('Frame', name..'SortDropDown', f, 'UIDropDownMenuTemplate')
	f.sortmethod:SetPoint("TOPLEFT", f, 80, -36)
	

	----Create filter dropdown menu
	f.filter = CreateFrame('Frame', name..'FilterDropDown', f, 'UIDropDownMenuTemplate')
	f.filter:SetPoint("TOPLEFT", f, 200, -36)
	--UIDropDownMenu_Initialize(f.filter, f:FilterMenuInitialize);
	
	----Create choose char dropdown menu
	f.chooseChar = CreateFrame('Frame', name..'ChooseCharDropDown', f, 'UIDropDownMenuTemplate')
	f.chooseChar:SetPoint("TOPLEFT", f, 80, -6)
	--UIDropDownMenu_Initialize(f.chooseChar, self:DropDownMenuInitialize());
	--UIDropDownMenu_SetWidth(MailboxBankFrameDropDown, 200);
	
	----Search
	if E then
		f.searchingBar = CreateFrame('EditBox', nil, f);
		f.searchingBar:CreateBackdrop('Default', true);
	else
		f.searchingBar = CreateFrame('EditBox', nil, f, "BagSearchBoxTemplate");
	end
	f.searchingBar:SetFrameLevel(f:GetFrameLevel() + 2);
	f.searchingBar:SetHeight(15);
	f.searchingBar:SetWidth(80);
	f.searchingBar:Hide();
	f.searchingBar:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -40);
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
	
	----Create collect mailbox gold button
	f.CollectGoldButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate");
	f.CollectGoldButton:SetWidth(100)
	f.CollectGoldButton:SetHeight(30)
	f.CollectGoldButton:SetPoint("BOTTOMLEFT", 10, 5);
	f.CollectGoldButton:SetText(L["Collect gold"])
	
	----Create mailbox gold text
	f.mailboxGoldText = f:CreateFontString(nil, 'OVERLAY');
	if E then
		f.mailboxGoldText:FontTemplate()
	else
		f.mailboxGoldText:SetFont(STANDARD_TEXT_FONT, 12);
	end
	f.mailboxGoldText:SetPoint("LEFT", f.CollectGoldButton, "RIGHT", 20, 0);
	
	----Create check time text
	-- f.checktime = f:CreateFontString(nil, 'OVERLAY');
	-- f.checktime:FontTemplate()
	-- f.checktime:SetPoint("BOTTOMLEFT", 20, 5);
	
	----Create scroll frame
	f.scrollBar = CreateFrame("ScrollFrame", name.."ScrollBar", f, "FauxScrollFrameTemplate")
	f.scrollBar:SetPoint("TOPLEFT", 0, -64)
	f.scrollBar:SetPoint("BOTTOMRIGHT", -28, 40)
	f.scrollBar:SetHeight( MB_config.numItemsRows * MB_config.buttonSize + (MB_config.numItemsRows - 1) * MB_config.buttonSpacing)
	f.scrollBar:Hide()
	--f.scrollBar:EnableMouseWheel(true)
	f.scrollBar:SetScript("OnVerticalScroll",  function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, MB_config.buttonSize + MB_config.buttonSpacing);
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
			S:HandleDropDownBox(f.chooseChar, 180)
			S:HandleButton(f.CollectGoldButton)
			S:HandleScrollBar(f.scrollBar);
		end
	end
	
	----Create Container
	f.Container = CreateFrame('Frame', nil, f);
	f.Container:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -64);
	f.Container:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 8);
	f.Container:Show()
	
	local numContainerRows = 0;
	local lastButton;
	local lastRowButton;
	for i = 1, MB_config.itemsSlotDisplay do
		local slot
		if E then
			slot = CreateFrame('Button', nil, f.Container);
			slot:SetTemplate('Default');
			slot:StyleButton();
			slot:Size(MB_config.buttonSize);
		else
			slot = CreateFrame('Button', nil, f.Container, "ItemButtonTemplate");
			slot:SetSize(MB_config.buttonSize, MB_config.buttonSize);
		end
		slot:Hide()
		
		slot.count = slot:CreateFontString(nil, 'OVERLAY');
		if E then
			slot.count:FontTemplate()
		else
			slot.count:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE');
		end
		--slot.count:SetFont(STANDARD_TEXT_FONT, 14)
		slot.count:SetPoint('BOTTOMRIGHT', 0, 2);
		
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
			if (i - 1) % MB_config.numItemsPerRow == 0 then
				slot:SetPoint('TOP', lastRowButton, 'BOTTOM', 0, -MB_config.buttonSpacing);
				lastRowButton = f.Container[i];
				numContainerRows = numContainerRows + 1;
			else
				slot:SetPoint('LEFT', lastButton, 'RIGHT', MB_config.buttonSpacing, 0);
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
	end);
	f.searchingBar:SetScript("OnEnterPressed", function()
		f:SearchBarResetAndClear()
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
		FauxScrollFrame_OnVerticalScroll(self, offset, MB_config.buttonSize + MB_config.buttonSpacing);
		f:Update()
	end)
	f.scrollBar:SetScript("OnShow", function()
		f:Update()
	end)
	
	f.CollectGoldButton:SetScript("OnClick", function()
		f:CollectMoney()
	end)
	UIDropDownMenu_Initialize(f.chooseChar, self:DropDownMenuInitialize());
	UIDropDownMenu_Initialize(f.sortmethod, self:SortMenuInitialize());
end

function MB:TooltipShow(self)--self=slot
	if self and self.link then
		local x = self:GetRight();
		if ( x >= ( GetScreenWidth() / 2 ) ) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		end
		GameTooltip:SetHyperlink(self.link)
		
		local formatList = {}
		for i = 1 , getn(self.countNum) do
			if formatList[self.sender[i]] == nil then
				formatList[self.sender[i]] = {}
				local row = {}
				row.lefttext = L["Sender: "] ..self.sender[i]
				row.righttext = 0
				tinsert(formatList[self.sender[i]], row)
			end
			
			local lefttext = L["+ Left time: "]
			local dayLeftTick = difftime(floor(self.dayLeft[i] * 86400) + self.checkMailTick,time())
			local leftday = floor(dayLeftTick / 86400)
			if leftday > 0 then
				lefttext = lefttext..L["more than "]..tostring(leftday)..L[" days"]
			else
				local lefthour = floor((dayLeftTick-leftday*86400) / 3600) 
				local leftminute = floor((dayLeftTick-leftday*86400-lefthour*3600) / 60)
				lefttext = lefttext..tostring(lefthour)..L[" hours"]..tostring(leftminute)..L[" minutes"]
			end
			
			local foundSameLefttime = false
			for j = 1, getn(formatList[self.sender[i]]) do
				if formatList[self.sender[i]][j].lefttext == lefttext then
					formatList[self.sender[i]][j].righttext = formatList[self.sender[i]][j].righttext + self.countNum[i]
					formatList[self.sender[i]][1].righttext = formatList[self.sender[i]][1].righttext + self.countNum[i]
					foundSameLefttime = true
				end
			end
			
			if foundSameLefttime == false then
				local row = {}
				row.lefttext = lefttext
				row.righttext = self.countNum[i]
				row.leftday = leftday
				formatList[self.sender[i]][1].righttext = formatList[self.sender[i]][1].righttext + self.countNum[i]
				tinsert(formatList[self.sender[i]], row)
			end
		end

		for k in pairs(formatList) do
			for i = 1, getn(formatList[k]) do
				local rL, gL, bL = 1, 1, 1
				if i > 1 then
					local leftday = formatList[k][i].leftday
					if leftday < MB_config.daysLeftRed then
						rL, gL, bL = 1, 0, 0
					elseif leftday < MB_config.daysLeftYellow then
						rL, gL, bL = 1, 1, 0
					else
						rL, gL, bL = 0, 1, 0
					end
				end
				GameTooltip:AddDoubleLine(formatList[k][i].lefttext, formatList[k][i].righttext, rL, gL, bL)
			end
		end
		
		if self.CODAmount then
			GameTooltip:AddDoubleLine(L["C.O.D. item"], L["pay for: "]..GetCoinTextureString(self.CODAmount), 1, 0, 0.5)
		end
		if self.wasReturned == 1 then
			GameTooltip:AddLine(L["was returned"])
		end

		GameTooltip:Show()
	end
end

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
	elseif button == 'LeftButton' then
		if self.mailIndex and self.attachIndex then
			for i = getn(self[mailIndex]), 1, -1 do
				TakeInboxItem(self[mailIndex][i], self[attachIndex][i])
			end
			MB:Update("sort")
		end
	end

end

function MB:UpdateContainer()
	if not self or not self.Container then return end
	for i = 1, MB_config.itemsSlotDisplay do
		if self.Container[i] then
			self.Container[i]:Hide()
		end
	end
	if not slotDB then return end
	
	self.mailboxGoldText:SetText(L["Mailbox gold: "]..GetCoinTextureString(MB_DB[selectValue].money))
	--self.mailboxTime:SetText(floor(difftime(time(),sorted_db[selectValue].checkMailTick)/60).." 分鐘前掃描" or "");

	local offset = FauxScrollFrame_GetOffset(self.scrollBar)
	
	local iconDisplayCount
	if (getn(slotDB) - offset * 8) > MB_config.itemsSlotDisplay then
		iconDisplayCount = MB_config.itemsSlotDisplay
	else
		iconDisplayCount = getn(slotDB) - offset * 8
	end
	
	for i = 1, iconDisplayCount do
		local itemIndex = i + offset * 8
		local slot = self.Container[i]
		
		if not MB_config.isStacked then
			slot = self:InsertToSlot(slot, slotDB[itemIndex], true)		
		else
			slot = self:InsertToSlot(slot, slotDB[itemIndex][1], true)
			if getn(slotDB[itemIndex]) > 1 then
				for i = 2, getn(slotDB[itemIndex]) do
					slot = self:InsertToSlot(slot, slotDB[itemIndex][i])
				end
			end
		end

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
		for i = 1 , getn(slot.countNum) do
			countnum = countnum + slot.countNum[i]
		end
		slot.count:SetText(countnum > 1 and countnum or '');
		
		slot.tex:SetVertexColor(1, 1, 1)
		slot.count:SetTextColor(1, 1, 1)
		slot.tex:SetDesaturated(0)
		if slot.CODAmount then
			slot.tex:SetDesaturated(1)
		end
		if self.searchingBar:HasFocus() then
			if not slot.name then break end
			local searchingStr = self.searchingBar:GetText();
			if not find(slot.name, searchingStr) then
				slot.tex:SetVertexColor(0.25, 0.25, 0.25)
				slot:SetBackdropBorderColor(0.3, 0.3, 0.3)
				slot.count:SetTextColor(0.3, 0.3, 0.3)
			end
		end

		slot:Show()
	end
	FauxScrollFrame_Update(self.scrollBar, ceil(getn(slotDB) / MB_config.numItemsPerRow) , MB_config.numItemsRows, MB_config.buttonSize + MB_config.buttonSpacing );
end

function MB:Update(isSortDB)
	if not self.SortDB then return end
	if isSortDB == "sort" then
		self:SortDB()
	elseif isSortDB == "filter" then
		self:Filter()
	end
	self:UpdateContainer()
end

function MB:AlertDeadlineMails()
	local DeadlineList = {}
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			for i = MB_DB[k].itemCount , 1, -1 do
				local dayLeft = self:CalcLeftDay(k, i)
				if dayLeft < 3 then
					if not DeadlineList.k then DeadlineList.k = {} end
					tinsert(DeadlineList.k, MB_DB[k][i].itemLink)
				else
					break
				end
			end
		end
	end
	if getn(DeadlineList) > 0 then
		local alertText = L["MailboxBank: |cffaa0000: |r"]
		for k, t in pairs(DeadlineList) do
			alertText = alertText .. "[" .. k .. "]: "
			for i, v in pairs(t) do
				alertText = alertText .. v
			end
		end
		alertText = alertText .. L["|cffaa0000Please remember to check it!|r"]
		print(alertText)
	end
end

function MB:HookSendMail(recipient, subject, body)
	if not recipient then return end
	for k, v in pairs(MB_DB) do
		if type(k) == 'string' and type(v) == 'table' then
			if recipient..'-'..GetRealmName() == k then
				local Sendmoney = GetSendMailMoney()
				for i = ATTACHMENTS_MAX_RECEIVE, 1, -1 do
					local Name, _, count, _ = GetSendMailItem(i)
					if Name then
						local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(Name or "")
						self:AddItem(GetUnitName("player"), itemLink, count, 31, 1, i, 0, nil, k)
					end
				end
				if Sendmoney then
					MB_DB[recipient..'-'..GetRealmName()].money = MB_DB[recipient..'-'..GetRealmName()].money + Sendmoney
				end
				if self:IsVisible() and selectValue == k then
					self:Update("sort")
				end
				return
			end
		end
	end
end

function MB:FrameShow()
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
		if selectValue == playername then
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
		if MB_config == nil then
			MB_config = {}
			for k ,v in pairs(self.config_init) do
				MB_config[k] = v;
			end
		end
		if not MB_DB then MB_DB = {} end
		self:CreatMailboxBankFrame()
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
	if MB.MB_Frame:IsVisible() then
		MB:FrameHide()
	else
		MB:Update("sort")
		MB:FrameShow()
	end
end;