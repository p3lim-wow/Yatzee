--[[
 
Copyright (c) 2009, Adrian L Lange
All rights reserved.
 
You're allowed to use this addon, free of monetary charge,
but you are not allowed to modify, alter, or redistribute
this addon without express, written permission of the author.
 
--]]

local active = false
local configuring = false
local frames = {}

local function Update(self, elapsed)
	if(not configuring) then
		self:SetValue(GetLootRollTimeLeft(self.id))
	else
		self.dummyTime = self.dummyTime - elapsed
		self:SetValue(self.dummyTime)
	end
end

local function IconClick(self)
	HandleModifiedItemClick(GetLootRollItemLink(self:GetParent().id))
end

local function IconUpdate(self)
	if(GameTooltip:IsOwned(self)) then
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetLootRollItem(self:GetParent().id)
	end

	CursorOnUpdate(self)
end

local function IconTooltip(self)
	GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
	GameTooltip:SetLootRollItem(self:GetParent().id)

	if(self.reason) then
		GameTooltip:AddLine(self.reason, 1, 0, 0)
		GameTooltip:Show()
	end
end

local function ButtonClick(self, button)
	if(self.type == 0 and button ~= 'RightButton') then return end
	RollOnLoot(self.id or self:GetParent().id, self.type)
end

local function ButtonTooltip(self)
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	GameTooltip:SetText(self.type == 1 and NEED or self.type == 2 and GREED or ROLL_DISENCHANT)
end

local function MODIFIER_STATE_CHANGED(self)
	local button = self.greed
	if(IsShiftKeyDown() or not self.nukable) then
		button:SetNormalTexture([=[Interface\Buttons\UI-GroupLoot-Coin-Up]=])
		button:SetPushedTexture([=[Interface\Buttons\UI-GroupLoot-Coin-Down]=])
		button:SetHighlightTexture([=[Interface\Buttons\UI-GroupLoot-Coin-Highlight]=])
		button.type = 2
	else
		button:SetNormalTexture([=[Interface\Buttons\UI-GroupLoot-DE-Up]=])
		button:SetPushedTexture([=[Interface\Buttons\UI-GroupLoot-DE-Down]=])
		button:SetHighlightTexture([=[Interface\Buttons\UI-GroupLoot-DE-Highlight]=])
		button.type = 3
	end
end

local function OnShow(self)
	local texture, name, _, _, bop, needable, _, nukable, reason = GetLootRollItemInfo(self.id)
	self.icon:SetNormalTexture(texture)
	self.icon:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92)

	self.name:SetFormattedText('|cffff0000%s|r%s', bop and '!' or '', name)
	self:SetWidth(self.name:GetWidth() + 100)

	self.nukable = nukable
	MODIFIER_STATE_CHANGED(self)

	if(needable) then
		GroupLootFrame_EnableLootButton(self.need)
		self.need.reason = nil
	else
		GroupLootFrame_DisableLootButton(self.need)
		self.need.reason = _G['LOOT_ROLL_INELIGIBLE_REASON'..reason]
	end

	self:SetMinMaxValues(0, self.time)
	self:SetValue(self.time)

	self:SetMovable(false)
	self.icon:EnableMouse(true)
	self.need:EnableMouse(true)
	self.greed:EnableMouse(true)
end

local function OnEvent(self, event, id)
	if(event == 'CANCEL_LOOT_ROLL') then
		if(id == self.id) then
			self:Hide()
		end

		for index, frame in pairs(frames) do
			if(frame:IsShown()) then
				active = true
				return
			else
				active = false
			end
		end
	else
		MODIFIER_STATE_CHANGED(self)
	end
end

for index = 1, 4 do
	local bar = CreateFrame('StatusBar', 'Yatzee'..index, UIParent)
	bar:SetSize(300, 10)
	bar:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = {top = -1, bottom = -1, left = -1, right = -1}})
	bar:SetBackdropColor(0, 0, 0)
	bar:SetStatusBarTexture([=[Interface\AddOns\Yatzee\minimalist]=])
	bar:SetStatusBarColor(1/4, 1/4, 2/5)
	bar:SetScript('OnUpdate', Update)
	bar:SetScript('OnMouseUp', ButtonClick)
	bar:SetScript('OnEvent', OnEvent)
	bar:EnableMouse(true)
	bar:RegisterEvent('CANCEL_LOOT_ROLL')
	bar:RegisterEvent('MODIFIER_STATE_CHANGED')
	bar.type = 0
	bar:Hide()

	bar:SetMovable(true)
	bar:SetUserPlaced(true)
	bar:SetClampedToScreen(true)
	bar:CreateTitleRegion():SetAllPoints()

	local background = bar:CreateTexture('$parentBG', 'BORDER')
	background:SetAllPoints()
	background:SetTexture(1/3, 1/3, 1/3)

	local icon = CreateFrame('Button', nil, bar)
	icon:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMLEFT', -5, 0)
	icon:SetSize(26, 26)
	icon:SetBackdrop(bar:GetBackdrop())
	icon:SetBackdropColor(0, 0, 0)
	icon:SetScript('OnClick', IconClick)
	icon:SetScript('OnUpdate', IconUpdate)
	icon:SetScript('OnEnter', IconTooltip)
	icon:SetScript('OnLeave', GameTooltip_HideResetCursor)
	bar.icon = icon

	local name = icon:CreateFontString('$parentName', 'ARTWORK')
	name:SetPoint('LEFT', bar, 2, 0)
	name:SetFont([=[Interface\AddOns\oUF_P3lim\media\semplice.ttf]=], 8, 'OUTLINE')
	name:SetJustifyH('LEFT')
	bar.name = name

	local greed = CreateFrame('Button', nil, bar)
	greed:SetPoint('BOTTOMRIGHT', bar, 'RIGHT', 0, 0)
	greed:SetSize(24, 24)
	greed:SetMotionScriptsWhileDisabled(true)
	greed:SetScript('OnClick', ButtonClick)
	greed:SetScript('OnEnter', ButtonTooltip)
	greed:SetScript('OnLeave', GameTooltip_Hide)
	bar.greed = greed

	local need = CreateFrame('Button', nil, bar)
	need:SetPoint('RIGHT', greed, 'LEFT', -4, 0)
	need:SetSize(24, 24)
	need:SetNormalTexture([=[Interface\Buttons\UI-GroupLoot-Dice-Up]=])
	need:SetPushedTexture([=[Interface\Buttons\UI-GroupLoot-Dice-Down]=])
	need:SetHighlightTexture([=[Interface\Buttons\UI-GroupLoot-Dice-Highlight]=])
	need:SetMotionScriptsWhileDisabled(true)
	need:SetScript('OnClick', ButtonClick)
	need:SetScript('OnEnter', ButtonTooltip)
	need:SetScript('OnLeave', GameTooltip_Hide)
	need.type = 1
	bar.need = need

	if(index == 1) then
		bar:SetPoint('CENTER', 300, 100)
	else
		bar:SetPoint('BOTTOMLEFT', frames[index - 1], 'TOPLEFT', 0, 26)
	end

	frames[index] = bar
end

local function SlashCommand(str)
	if(InCombatLockdown() or active) then
		return print('|cffff8080Yatzee:|r Cannot alter the frames right now, try again later')
	elseif(str == 'reset') then
		for index, frame in pairs(frames) do
			frame:ClearAllPoints()
			if(index == 1) then
				frame:SetPoint('CENTER', 300, 100)
			else
				frame:SetPoint('BOTTOMLEFT', frames[index - 1], 'TOPLEFT', 0, 26)
			end
		end
	else
		for index, frame in pairs(frames) do
			if(not frame:IsShown()) then
				frame.icon:SetNormalTexture([=[Interface\Icons\INV_Misc_CandySkull]=])
				frame.icon:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92)

				frame.name:SetFormattedText('Yatzee Frame #%s', index)
				frame:SetWidth(frame.name:GetWidth() + 100)

				frame.nukable = true
				MODIFIER_STATE_CHANGED(frame)

				GroupLootFrame_EnableLootButton(frame.need)
				frame.need.reason = nil

				frame.dummyTime = 100
				frame:SetMinMaxValues(0, 100)
				frame:SetValue(100)

				frame:SetMovable(true)
				frame.icon:EnableMouse(false)
				frame.need:EnableMouse(false)
				frame.greed:EnableMouse(false)
				frame:Show()

				configuring = true
			else
				frame:SetMovable(false)
				frame.icon:EnableMouse(true)
				frame.need:EnableMouse(true)
				frame.greed:EnableMouse(true)
				frame:Hide()

				configuring = false
			end
		end
	end
end

local Yatzee = CreateFrame('Frame')
Yatzee:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)
Yatzee:RegisterEvent('VARIABLES_LOADED')

function Yatzee:START_LOOT_ROLL(id, time)
	if(configuring) then
		for index, frame in pairs(frames) do
			frame:Hide()
		end
	end

	for index, frame in pairs(frames) do
		if(not frame:IsShown()) then
			active = true

			frame.id = id
			frame.time = time
			frame:Show()
			frame:SetMovable(false)
			return OnShow(frame)
		end
	end
end

function Yatzee:PLAYER_REGEN_DISABLED()
	if(configuring) then
		for index, frame in pairs(frames) do
			frame:Hide()
		end

		print('|cffff8080Yatzee:|r Entering combat, locking down frames.')
		configuring = false
	end
end
	

function Yatzee:CONFIRM_LOOT_ROLL(id, type)
	for index = 1, STATICPOPUP_NUMDIALOGS do
		local popup = _G['StaticPopup'..index]
		if(popup.which == 'CONFIRM_LOOT_ROLL' and popup.data == id and popup.data2 == type and popup:IsVisible()) then
			StaticPopup_OnClick(popup, 1)
		end
	end
end

function Yatzee:VARIABLES_LOADED()
	SlashCmdList.Yatzee = SlashCommand
	SLASH_Yatzee1 = '/yatzee'

	self:UnregisterEvent('VARIABLES_LOADED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('START_LOOT_ROLL')

	self:RegisterEvent('CONFIRM_LOOT_ROLL')
	self:RegisterEvent('CONFIRM_DISENCHANT_ROLL')
	self.CONFIRM_DISENCHANT_ROLL = CONFIRM_LOOT_ROLL

	UIParent:UnregisterEvent('START_LOOT_ROLL')
	UIParent:UnregisterEvent('CANCEL_LOOT_ROLL')
end
