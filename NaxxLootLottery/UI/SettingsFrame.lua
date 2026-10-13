-- ============================================================
-- Naxxramas Loot Ledger
-- UI/SettingsFrame.lua
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

function UI:CreateSettingsPanel(parent)
    local panel =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    panel:SetAllPoints(parent)

    local heading =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalLarge"
        )

    heading:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        12,
        -10
    )

    heading:SetText("Settings")

    local priorityButton =
        self:CreateTextButton(
            panel,
            "Priority Setup",
            112
        )

    priorityButton:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -10)

    local debugButton = self:CreateTextButton(panel, "Debug Lab", 95)
    debugButton:SetPoint("LEFT", priorityButton, "RIGHT", 8, 0)

    local awardButton = self:CreateTextButton(panel, "Loot Awards", 110)
    awardButton:SetPoint("LEFT", debugButton, "RIGHT", 8, 0)

    local awardPage = CreateFrame("Frame", nil, panel)
    awardPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -72)
    awardPage:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

    local historyButton = self:CreateTextButton(panel, "Award History", 110)
    historyButton:SetPoint("LEFT", awardButton, "RIGHT", 8, 0)

    local historyPage = CreateFrame("Frame", nil, panel)
    historyPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -72)
    historyPage:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

    local debugPage = CreateFrame("Frame", nil, panel)
    debugPage:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -72)
    debugPage:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

    local priorityPage =
        CreateFrame(
            "Frame",
            nil,
            panel
        )

    priorityPage:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        10,
        -72
    )

    priorityPage:SetPoint(
        "BOTTOMRIGHT",
        panel,
        "BOTTOMRIGHT",
        -10,
        10
    )

    self:CreateAwardSettingsContent(awardPage)
    self:CreateAwardHistoryContent(historyPage)

    self:CreateDebugLabContent(debugPage)

    self:CreatePrioritySettingsContent(
        priorityPage
    )

    priorityButton:SetScript(
        "OnClick",
        function()
            UI.settingsMode =
                "priority"

            UI:RefreshSettingsPanel()
        end
    )

    debugButton:SetScript("OnClick", function()
        UI.settingsMode = "debug"
        UI:RefreshSettingsPanel()
    end)

    awardButton:SetScript("OnClick", function()
        UI.settingsMode = "awards"
        UI:RefreshSettingsPanel()
    end)

    historyButton:SetScript("OnClick", function()
        UI.settingsMode = "history"
        UI:RefreshSettingsPanel()
    end)
    self.settingsHistoryButton = historyButton
    self.settingsHistoryPage = historyPage
    self.settingsAwardButton = awardButton
    self.settingsAwardPage = awardPage
    self.settingsDebugButton = debugButton
    self.settingsDebugPage = debugPage
    self.settingsPriorityButton =
        priorityButton

    self.settingsPriorityPage =
        priorityPage

    self.settingsMode =
        self.settingsMode
        or "priority"

    self.settingsPanel = panel

    panel:Hide()
end

function UI:RefreshSettingsPanel()
    if not self.settingsPanel then
        return
    end

    local mode =
        self.settingsMode
        or "priority"

    self.settingsPriorityPage:Hide()
    self.settingsDebugPage:Hide()
    self.settingsAwardPage:Hide()
    self.settingsHistoryPage:Hide()

    self:SetButtonState(
        self.settingsPriorityButton,
        mode == "priority"
            and "active"
            or "normal"
    )

    self:SetButtonState(self.settingsDebugButton,
        mode == "debug" and "active" or "normal")

    self:SetButtonState(self.settingsAwardButton,
        mode == "awards" and "active" or "normal")

    self:SetButtonState(self.settingsHistoryButton,
        mode == "history" and "active" or "normal")

    if mode == "history" then
        self.settingsHistoryPage:Show()
        self:RefreshAwardHistory()
        return
    end

    if mode == "awards" then
        self.settingsAwardPage:Show()
        self:RefreshAwardSettingsContent()
        return
    end

    if mode == "debug" then
        self.settingsDebugPage:Show()
        self:RefreshDebugLab()
        return
    end

    if mode == "priority" then
        self.settingsPriorityPage:Show()
        self:RefreshPrioritySetup()
        return
    end

    self.settingsMode = "priority"
    self.settingsPriorityPage:Show()
    self:RefreshPrioritySetup()
end
