local unlocked

local greedNormal = [=[Interface\Buttons\UI-GroupLoot-Coin-Up]=]
local greedPushed = [=[Interface\Buttons\UI-GroupLoot-Coin-Down]=] 
local greedHighlight = [=[Interface\Buttons\UI-GroupLoot-Coin-Highlight]=]

local nukeNormal = [=[Interface\Buttons\UI-GroupLoot-DE-Up]=]
local nukePushed = [=[Interface\Buttons\UI-GroupLoot-DE-Down]=]
local nukeHighlight = [=[Interface\Buttons\UI-GroupLoot-DE-Highlight]=]

local frames = {}
local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	edgeFile = [=[Interface\Tooltips\UI-Tooltip-Border]=], edgeSize = 12,
	insets = {left = 3, right = 3, top = 3, bottom = 3},
}

local defaults = {
	position = 'CENTER#CENTER#-100#-100',
	orientation = 'down',
}

local function savePosition(self)
	local point1, _, point2, x, y = self:GetPoint()
	YatzeeDB.position = string.format('%s#%s#%s#%s', point1, point2, x, y)
end

local function createLootTooltip(self)
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	GameTooltip:SetText(unlocked and 'Lock' or self.tooltip and self.tooltip or (IsShiftKeyDown() or not self:GetParent().nukable) and GREED or ROLL_DISENCHANT)
	GameTooltip:Show()
end

local function createItemTooltip(self)
	if(not self.link) then return end

	GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
	GameTooltip:SetHyperlink(self.link)

	if(IsShiftKeyDown()) then
		GameTooltip_ShowCompareItem()
	end

	if(IsModifiedClick('DRESSUP')) then
		ShowInspectCursor()
	else
		ResetCursor()
	end
end

local function onItemUpdate(self)
	if(IsShiftKeyDown()) then
		GameTooltip_ShowCompareItem()
	end

	CursorOnUpdate(self)
end

local function onLootClick(self)
	if(unlocked) then
		unlocked = not unlocked

		for k, v in pairs(frames) do
			v.id = nil
			v:Hide()
		end
	else
		RollOnLoot(self:GetParent().id, self.type and self.type or (IsShiftKeyDown() or not self:GetParent().nukable) and 2 or 3)
	end
end

local function onItemClick(self)
	if(IsControlKeyDown()) then
		DressUpItemLink(self.link)
	elseif(IsShiftKeyDown()) then
		ChatEdit_InsertLink(self.link)
	end
end

local function onBarUpdate(self)
	self:SetValue(GetLootRollTimeLeft(self.id))
end

local cancelled = {}
local function CANCEL_LOOT_ROLL(self, event, id)
	cancelled[id] = true

	if(self.id == id) then
		self.id = nil
		self:Hide()
	end
end

local function createFrame()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetWidth(300)
	frame:SetHeight(24)
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
	frame:SetBackdropBorderColor(0.7, 0.7, 0.7)
	frame:RegisterEvent('CANCEL_LOOT_ROLL')
	frame:Hide()

	local item = CreateFrame('Button', nil, frame)
	item:SetPoint('CENTER', frame, 'LEFT')
	item:SetWidth(26)
	item:SetHeight(26)
	item:SetNormalTexture([=[Interface\InventoryItems\WoWUnknownItem01]=])
	item:SetHighlightTexture([=[Interface\Calendar\CurrentDay]=])
	item:GetHighlightTexture():SetTexCoord(0.58, 0.96, 0.13, 0.49)
	item:SetScript('OnEnter', createItemTooltip)
	item:SetScript('OnLeave', GameTooltip_HideResetCursor)
	item:SetScript('OnUpdate', onItemUpdate)
	item:SetScript('OnClick', onItemClick)
	frame.item = item

	local name = item:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	name:SetPoint('LEFT', item, 'RIGHT', 30, 1)
	name:SetPoint('RIGHT', frame, -5, 1)
	name:SetJustifyH('LEFT')
	name:SetTextColor(1, 1, 1)
	frame.name = name

	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetPoint('TOPLEFT', -6.5, 6.5)
	border:SetPoint('BOTTOMRIGHT', 6.5, -6.5)
	border:SetTexCoord(0.0078125, 0.57421875, 0.0390625, 0.5859375)
	border:SetTexture([=[Interface\Calendar\CurrentDay]=])
	frame.border = border

	local bar = CreateFrame('StatusBar', nil, frame)
	bar:SetPoint('LEFT', item, 'RIGHT')
	bar:SetPoint('TOPRIGHT', -3.5, -3.5)
	bar:SetPoint('BOTTOMRIGHT', -3.5, 3.5)
	bar:SetStatusBarTexture([=[Interface\AddOns\Yatzee\Armory]=])
	bar:SetStatusBarColor(0.8, 0.8, 0.8)
	bar:SetFrameLevel(bar:GetFrameLevel() - 1)
	bar:SetScript('OnUpdate', onBarUpdate)
	bar.id = 1
	frame.bar = bar

	local close = CreateFrame('Button', nil, frame)
	close:SetPoint('TOPRIGHT', -1, -1)
	close:SetHeight(12)
	close:SetWidth(12)
	close:SetNormalTexture([=[Interface\Buttons\UI-Panel-MinimizeButton-Disabled]=])
	close:SetHighlightTexture([=[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]=])
	close:SetMotionScriptsWhileDisabled(true)
	close:SetScript('OnEnter', createLootTooltip)
	close:SetScript('OnLeave', GameTooltip_Hide)
	close:SetScript('OnClick', onLootClick)
	close.tooltip = PASS
	close.type = 0

	local need = CreateFrame('Button', nil, frame)
	need:SetPoint('LEFT', item, 'TOPRIGHT', 4, -3)
	need:SetWidth(24)
	need:SetHeight(24)
	need:SetFrameStrata('HIGH')
	need:SetNormalTexture([=[Interface\Buttons\UI-GroupLoot-Dice-Up]=])
	need:SetPushedTexture([=[Interface\Buttons\UI-GroupLoot-Dice-Down]=])
	need:SetHighlightTexture([=[Interface\Buttons\UI-GroupLoot-Dice-Highlight]=])
	need:SetMotionScriptsWhileDisabled(true)
	need:SetScript('OnEnter', createLootTooltip)
	need:SetScript('OnLeave', GameTooltip_Hide)
	need:SetScript('OnClick', onLootClick)
	need.tooltip = NEED
	need.type = 1
	frame.need = need

	local greed = CreateFrame('Button', nil, frame)
	greed:SetPoint('LEFT', item, 'BOTTOMRIGHT', 3, 2)
	greed:SetWidth(24)
	greed:SetHeight(24)
	greed:SetFrameStrata('HIGH')
	greed:SetNormalTexture(greedNormal)
	greed:SetPushedTexture(greedPushed)
	greed:SetHighlightTexture(greedHighlight)
	greed:SetMotionScriptsWhileDisabled(true)
	greed:SetScript('OnEnter', createLootTooltip)
	greed:SetScript('OnLeave', GameTooltip_Hide)
	greed:SetScript('OnClick', onLootClick)
	frame.greed = greed

	return frame
end

local anchor = createFrame()
anchor:SetScript('OnDragStart', function(self) if(unlocked) then self:StartMoving() end end)
anchor:SetScript('OnDragStop', function(self) 
	self:StopMovingOrSizing()
	savePosition(self)
end)

anchor:SetMovable(true)
anchor:EnableMouse(true)
anchor:RegisterForDrag('LeftButton')
table.insert(frames, anchor)

local function getFrame()
	for k, v in pairs(frames) do
		if(not v.id) then
			return v
		end
	end

	local frame = createFrame()
	if(YatzeeDB.orientation == 'down') then
		frame:SetPoint('TOPLEFT', frames[#frames], 'BOTTOMLEFT', 0, -20)
	else
		frame:SetPoint('BOTTOMLEFT', frames[#frames], 'TOPLEFT', 0, 20)
	end

	frame:SetScript('OnEvent', CANCEL_LOOT_ROLL)
	table.insert(frames, frame)

	return frame
end

function anchor:START_LOOT_ROLL(id, duration)
	local frame = getFrame()
	frame.id = id
	frame.bar.id = id

	local texture, name, count, quality, bound, need, greed, nuke = GetLootRollItemInfo(id)
	frame.item:SetNormalTexture(texture)
	frame.item.link = GetLootRollItemLink(id)
	frame.name:SetText(name)
	frame:SetWidth(80 + frame.name:GetStringWidth())

	if(need) then
		frame.need:Enable()
	else
		frame.need:Disable()
	end
	SetDesaturation(frame.need:GetNormalTexture(), not need)

	frame.nukable = nuke
	anchor:MODIFIER_STATE_CHANGED()

	local color = ITEM_QUALITY_COLORS[quality]
	frame.bar:SetStatusBarColor(color.r, color.g, color.b, 0.6)

	frame.bar:SetMinMaxValues(0, duration)
	frame.bar:SetValue(duration)
	frame:Show()
end

function anchor:MODIFIER_STATE_CHANGED()
	for k, v in pairs(frames) do
		if(IsShiftKeyDown() or not v.nukable) then
			v.greed:SetNormalTexture(greedNormal)
			v.greed:SetPushedTexture(greedPushed)
			v.greed:SetHighlightTexture(greedHighlight)
		else
			v.greed:SetNormalTexture(nukeNormal)
			v.greed:SetPushedTexture(nukePushed)
			v.greed:SetHighlightTexture(nukeHighlight)
		end
	end
end

function anchor:VARIABLES_LOADED(name)
	self:UnregisterEvent(event)
	self.CONFIRM_DISENCHANT_ROLL = self.CONFIRM_LOOT_ROLL
	self:RegisterEvent('CONFIRM_DISENCHANT_ROLL')
	self:RegisterEvent('CONFIRM_LOOT_ROLL')
	self:RegisterEvent('START_LOOT_ROLL')
	self:RegisterEvent('MODIFIER_STATE_CHANGED')

	YatzeeDB = YatzeeDB or defaults
	local point1, point2, x, y = string.split('#', YatzeeDB.position)
	self:SetPoint(point1, UIParent, point2, x, y)

	UIParent:UnregisterEvent('START_LOOT_ROLL')
	UIParent:UnregisterEvent('CANCEL_LOOT_ROLL')
end

function anchor:CONFIRM_LOOT_ROLL(id, rolltype)
	for index = 1, STATICPOPUP_NUMDIALOGS do
		local popup = _G['StaticPopup'..index]
		if(popup.which == 'CONFIRM_LOOT_ROLL' and popup.data == id and popup.data2 == rolltype and popup:IsVisible()) then
			StaticPopup_OnClick(popup, 1)
		end
	end
end

anchor:RegisterEvent('VARIABLES_LOADED')
anchor:SetScript('OnEvent', function(self, event, ...)
	if(event == 'CANCEL_LOOT_ROLL') then
		CANCEL_LOOT_ROLL(self, event, ...)
	else
		self[event](self, ...)
	end
end)

SLASH_Yatzee1 = '/yatzee'
SlashCmdList.Yatzee = function(str)
	if(str == 'up' or str == 'down') then
		YatzeeDB.orientation = str
	elseif(str == 'reset') then
		YatzeeDB = defaults
	else
		unlocked = not unlocked

		if(anchor:IsVisible()) then
			for k, v in pairs(frames) do
				v.id = nil
				v:Hide()
			end
		else
			for index = 1, 4 do
				local frame = getFrame()
				frame.id = index
				frame.name:SetText('Movable '..index)
				frame:Show()
			end
		end
	end
end
