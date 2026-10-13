-- Offline Lua 5.1 regression: dark-only UI and SavedVariables continuity.
-- Run from repository root: lua5.1 tests/test_dark_skin.lua
local count = 0
local function check(value, message)
    assert(value, message or "assertion failed")
    count = count + 1
end

NaxxLootLottery = { databaseVersion = 3, UI = {} }
local NLL = NaxxLootLottery
local savedNeeds = { test = { itemID = 18814, character = "Raider", status = "NEEDED" } }
local savedWishes = { Raider = { MOLTEN_CORE = { [18814] = true } } }
local savedRules = { MOLTEN_CORE = { [18814] = { rolePriority = { MAGE = 1 } } } }
local savedAwards = { { itemID = 18814, winner = "Raider", status = "LEADER_REPORTED" } }
local savedWinners = { { itemID = 18814, winner = "Raider" } }
local savedIdentity = { schema = 3, rows = { { uid = "L1:1:18814", processed = true } } }
NaxxLootLotteryDB = {
    settings = { skin = "VANILLA", debug = true,
        priorityPresetsEnabled = true, directMasterLootEnabled = true },
    gearNeeds = savedNeeds,
    localWishlists = savedWishes,
    priorityRules = savedRules,
    lootAwardHistory = savedAwards,
    lotteryHistory = savedWinners,
    raidSession = { lootIdentity = savedIdentity }
}
local initialDB = NaxxLootLotteryDB
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
NLL.Database:Initialize()
check(NLL.db == initialDB, "must preserve the SavedVariables table")
check(NLL.db.settings.skin == "DARK", "old VANILLA setting becomes DARK")
check(NLL.db.settings.directMasterLootEnabled == false, "real awarding must reset OFF")
check(NLL.db.settings.debug == true, "unrelated settings preserved")
check(NLL.db.settings.priorityPresetsEnabled == true, "guild preset choice preserved")
check(NLL.db.gearNeeds == savedNeeds, "gear plans preserved")
check(NLL.db.localWishlists == savedWishes, "wishlists preserved")
check(NLL.db.priorityRules == savedRules, "custom priorities preserved")
check(NLL.db.lootAwardHistory == savedAwards, "award history preserved")
check(NLL.db.lotteryHistory == savedWinners, "winners preserved")
check(NLL.db.raidSession.lootIdentity == savedIdentity, "identity schema preserved")
for _, legacy in ipairs({ "CLASSIC", "VANILLA", "DARK" }) do
    NLL.db.settings.skin = legacy
    NLL.Database:Initialize()
    check(NLL.db.settings.skin == "DARK", "skin normalization: " .. legacy)
end

assert(loadfile("NaxxLootLottery/UI/SkinManager.lua"))()
local UI = NLL.UI
check(UI:GetSkinID() == "DARK", "dark is the only active skin")
check(UI:GetSkin() == UI.skins.DARK, "dark palette selected")
check(UI.skins.VANILLA == nil, "Vanilla skin definition removed")
check(UI:SetSkin("VANILLA") == false, "old skin cannot be re-enabled")
check(NLL.db.settings.skin == "DARK", "old skin request changes nothing")

local function mockFrame()
    local frame = {}
    function frame:SetAllPoints() end
    function frame:SetPoint(...)
        self.points = self.points or {}
        self.points[#self.points + 1] = { ... }
    end
    function frame:ClearAllPoints() self.points = {} end
    function frame:SetJustifyH() end
    function frame:SetAutoFocus() end
    function frame:CreateTexture() return mockFrame() end
    function frame:SetWidth(width) self.width = width end
    function frame:SetHeight(height) self.height = height end
    function frame:SetText(text) self.text = text end
    function frame:SetBackdrop(backdrop) self.backdrop = backdrop end
    function frame:SetBackdropColor(...) self.color = { ... } end
    function frame:SetBackdropBorderColor(...) self.borderColor = { ... } end
    function frame:SetNormalTexture(texture) self.normalTexture = texture end
    function frame:SetPushedTexture(texture) self.pushedTexture = texture end
    function frame:SetHighlightTexture(texture) self.highlightTexture = texture end
    function frame:SetScript(event, handler)
        self.scripts = self.scripts or {}
        self.scripts[event] = handler
    end
    function frame:CreateFontString() return mockFrame() end
    function frame:Show() self.visible = true end
    function frame:Hide() self.visible = false end
    return frame
end
local content = mockFrame()
UI:RegisterSkinnedFrame(content, "content")
check(content.backdrop == UI.skins.DARK.contentBackdrop, "dark content backdrop")
check(content.color[4] == UI.skins.DARK.content[4], "dark content opacity")
local button = mockFrame()
button.nllBaseWidth, button.nllBaseHeight = 104, 23
UI:RegisterSkinnedFrame(button, "button")
check(button.width == 104 and button.height == 23, "dark button dimensions retained")
check(button.normalTexture == nil, "no Vanilla button artwork")
UI:SetButtonState(button, "active")
check(button.color[1] == UI.skins.DARK.buttonActive[1], "dark active state retained")
button.nllHover = true
UI:ApplySkinToFrame(button)
check(button.color[1] == UI.skins.DARK.buttonHover[1], "dark hover state retained")
UI:SetSkin("DARK")
check(NLL.db.settings.skin == "DARK", "dark-only compatibility setter remains safe")

CreateFrame = function() return mockFrame() end
UI.CreateTextButton = function(self, parent, label)
    local frame = mockFrame()
    frame.label = label
    return frame
end
UI.CreateAwardSettingsContent = function() end
UI.CreateAwardHistoryContent = function() end
UI.CreateDebugLabContent = function() end
UI.CreatePrioritySettingsContent = function() end
UI.SetButtonState = function(self, frame, state) frame.nllButtonState = state end
UI.RefreshPrioritySetup = function(self) self.lastRefresh = "priority" end
UI.RefreshDebugLab = function(self) self.lastRefresh = "debug" end
UI.RefreshAwardSettingsContent = function(self) self.lastRefresh = "awards" end
UI.RefreshAwardHistory = function(self) self.lastRefresh = "history" end
assert(loadfile("NaxxLootLottery/UI/SettingsFrame.lua"))()
UI:CreateSettingsPanel(mockFrame())
check(UI.settingsAppearanceButton == nil and UI.settingsAppearancePage == nil,
    "appearance choice removed from Settings")
check(UI.settingsPriorityButton ~= nil and UI.settingsMode == "priority",
    "Priority Setup is default Settings tab")
for _, mode in ipairs({ "priority", "debug", "awards", "history" }) do
    UI.settingsMode = mode
    UI:RefreshSettingsPanel()
    check(UI.lastRefresh == mode, "Settings still works: " .. mode)
end
-- Priority Setup footer layout regression: no destructive preset changes.
-- These checks inspect WoW anchor choices with lightweight frame mocks.
NLL.classes, NLL.roles = {}, {}
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_SetText = function() end
UIDropDownMenu_Initialize = function() end
assert(loadfile("NaxxLootLottery/UI/PriorityFrame.lua"))()
local fullRefresh = UI.RefreshPrioritySetup
UI.RefreshPrioritySetup = function() end -- layout-only; do not touch saved presets
UI:CreatePrioritySettingsContent(mockFrame())
UI.RefreshPrioritySetup = fullRefresh
local footer = UI.priorityPresetToggleButton
local footerAnchor = footer.points and footer.points[1]
check(footerAnchor and footerAnchor[1] == "BOTTOMLEFT"
    and footerAnchor[3] == "BOTTOMLEFT" and footerAnchor[4] == 8
    and footerAnchor[5] == 10, "preset button anchored 10 pixels from panel bottom")
check(footerAnchor[2] == UI.priorityBrowsePage,
    "preset footer anchored to its browse panel")
local explain = UI.priorityPresetExplanation
local explainAnchor = explain.points and explain.points[1]
check(explainAnchor and explainAnchor[1] == "LEFT"
    and explainAnchor[2] == footer and explainAnchor[3] == "RIGHT"
    and explainAnchor[4] == 12 and explainAnchor[5] == 0,
    "preset explanation follows its button and stays vertically centered")
local summaryAnchor = UI.priorityBrowseSummary.points[1]
check(summaryAnchor[5] == -351, "priority summary moved above footer")
check(UI.priorityPreviousButton ~= nil and UI.priorityNextButton ~= nil,
    "priority pagination retained")
check(NLL.db.settings.priorityPresetsEnabled == true,
    "layout check has not changed saved presets")

print("PASS: " .. count .. " dark-only UI, priority footer, and SavedVariables assertions")
