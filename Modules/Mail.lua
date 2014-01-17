local ODC = LibStub("AceAddon-3.0"):GetAddon("OfflineDataCenter")
local ODC_SF = ODC:GetModule("SortFilter")
if not ODC_SF then return end
local ODC_Mail = ODC:NewModule("OfflineMail", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("OfflineDataCenter")
ODC_Mail.description = L["Offline MailBox"]
ODC_Mail.type = "tab"
ODC_Mail.name = "OfflineMail"
ODC_Mail.tabs = {
	["mail"] = {
		["Textures"] = "Interface\\MailFrame\\Mail-Icon.blp",
		["Tooltip"] = L['Offline MailBox'],
		["CallTabFunc"] = function()
			ODC_SF:CreateOrShowSubFrame("mail")
			ODC_SF:Update("sort")
		end,
		["CharChangedFunc"] = function()
			ODC_SF:Update("sort")
		end,
	}
}

local playername, selectChar, selectTab = ODC.playername, ODC.selectChar, ODC.selectTab

local Config = {
	daysLeftWarning = 5,
}

local function AddItemMail(itemLink, count, mailIndex, attachIndex, sender, daysLeft, money, CODAmount, wasReturned, recipient, firstItem)
	if recipient and firstItem then
		local t ={}
		tinsert(ODC_DB[recipient]["mail"], 1, t)
	elseif not recipient then
		recipient = playername
	end
	
	if not ODC_DB[recipient]["mail"][mailIndex] or firstItem then
		ODC_DB[recipient]["mail"][mailIndex] = {
			sender = sender,
			daysLeft = daysLeft,
			wasReturned = wasReturned,
			money = (money > 0) and money or nil,
			CODAmount = (CODAmount > 0) and CODAmount or nil,}
		--ODC_DB[recipient]["mail"].mailCount = ODC_DB[recipient]["mail"].mailCount + 1
	end
	
	if not itemLink then return end --for money only
	ODC_DB[recipient]["mail"][mailIndex][attachIndex] = {
		count = count,
		itemLink = itemLink,}
	--ODC_DB[recipient]["mail"].itemCount = ODC_DB[recipient]["mail"].itemCount + 1
end
--[[
new structure:
[charName]		mailIndex		attachIndex
["mail"] = {	[1]				[1]			{	.count
				[n]				.sender			.itemLink
				.checkMailTick	.daysLeft
								.wasReturned
								.CODAmount?
								.money?
enum:
for i = 1, getn(mailIndex) do
	curr.sender, curr.daysLeft, curr.wasReturned, curr.CODAmount
	for j = 1, ATTACHMENTS_MAX_RECEIVE do
		if ODC_DB[charName]["mail"].i.j then
			
		end
	end
end
]]
function ODC_Mail:CheckMail()
	ODC_DB[playername]["mail"] = {mailCount = 0, itemCount = 0, money = 0}
	local numItems, totalItems = GetInboxNumItems()
	if numItems and numItems > 0 then
		for mailIndex = 1, numItems do
			--local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(mailIndex);
			local _, _, sender, _, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, _, _, _ = GetInboxHeaderInfo(mailIndex);
			--if isGM ~= nil then print("GM@"..sender) end
			if money > 0 then
				ODC_DB[playername]["mail"].money = ODC_DB[playername]["mail"].money + money
			end
			AddItemMail(nil, nil, mailIndex, nil, sender, daysLeft, money, CODAmount, wasReturned)
			if hasItem then
				if sender == nil then
					sender = L["UNKNOWN SENDER"]
				end
				for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
					local itemLink = GetInboxItemLink(mailIndex, attachIndex)
					if itemLink then
						local _, _, count, _, _ = GetInboxItem(mailIndex, attachIndex)
						AddItemMail(itemLink, count, mailIndex, attachIndex)
					end
				end
			end
		end
	end
	ODC_DB[playername]["mail"].checkMailTick = time()
	
	if ODC.Frame:IsVisible() and selectChar == playername and selectTab == "mail" then
		ODC_SF:Update("sort")
	end
end

function ODC_Mail:HookSendMail(recipient, subject, body)
	if not recipient then recipient = _G["SendMailNameEditBox"]:GetText() end
	if not recipient then return end
	recipient = string.upper(string.sub(recipient, 1, 1))..string.sub(recipient, 2, -1)
	if not string.find(recipient, "%-") then
		recipient = recipient..'-'..GetRealmName()
	end
	if ODC_DB[recipient]["mail"] then
		local Getmoney = GetSendMailMoney()
		local Sendmoney, Codmoney = 0, 0
		if Getmoney then
			if _G["SendMailSendMoneyButton"]:GetChecked() then
				Sendmoney = Getmoney
				ODC_DB[recipient]["mail"].money = ODC_DB[recipient]["mail"].money + Sendmoney
			else
				Codmoney = Getmoney
			end
		end
		local firstItem = true
		for i = ATTACHMENTS_MAX_RECEIVE, 1, -1 do
			local Name, _, count, _ = GetSendMailItem(i)
			if Name then
				local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(Name or "")
				AddItemMail(itemLink, count, 1, i, GetUnitName("player"), 31, Sendmoney, Codmoney, nil, k, firstItem)
				firstItem = nil
			end
		end
		if ODC.Frame:IsVisible() and selectChar == recipient then
			ODC_SF:Update("sort")
		end
	end
end

local function CalcLeftDay(player, mailIndex)
	return floor(difftime(floor(ODC_DB[player]["mail"][mailIndex].daysLeft * 86400) + ODC_DB[player]["mail"].checkMailTick,time()) / 86400)
end
----------------TODO
local function AlertDeadlineMails()
	local DeadlineList = {__count = 0}
	for charName, v in pairs(ODC_DB) do
		if ODC_DB[charName]["mail"] then
			for mailIndex, mail in pairs(ODC_DB[charName]["mail"]) do
				if type(mail) == "table" then
					local dayLeft = CalcLeftDay(charName, mailIndex)
					if dayLeft < Config.daysLeftWarning then
						if not DeadlineList[charName] then 
							DeadlineList[charName] = {}
							DeadlineList.__count = DeadlineList.__count +1
						end
						for attachIndex, attach in pairs(mail) do
							if type(attach) == "table" then
								tinsert(DeadlineList[charName], attach.itemLink)
							end
						end
					end
				end
			end
		end
	end
	if DeadlineList.__count > 0 then
		local alertText = L["Offline Data Center"] .. L[": |cff00aabbYou have mails soon expire: |r"]
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

function ODC_Mail:MAIL_INBOX_UPDATE()
	self:CheckMail()
end

function ODC_Mail:OnInitialize()
	if ODC_Config.toggle.mail == nil then ODC_Config.toggle.mail = true end
	ODC:AddAvaliableTab("mail", self)
	if ODC_Config.toggle.mail then
		AlertDeadlineMails()
	end
end

ODC_Mail.selectTabCallbackFunc = function(selectedTab)
	selectTab = selectedTab
end

ODC_Mail.selectCharCallbackFunc = function(selectedChar)
	selectChar = selectedChar
end

function ODC_Mail:OnEnable()
	if not ODC_Config.toggle.mail then return end
	if not ODC_DB[playername]["mail"] then ODC_DB[playername]["mail"] = {money = 0} end
	ODC:AddModule(self)
	ODC:AddTab("mail", self.tabs["mail"])
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:SecureHook('SendMail', 'HookSendMail');
end

function ODC_Mail:OnDisable()
	--ODC_Config.toggle.mail = false
	ODC:RemoveModule(self)
	ODC:RemoveTab("mail")
	self:UnhookAll()
	-- self:UnregisterEvent("MAIL_INBOX_UPDATE")
end