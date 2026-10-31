-- v0.1.0.25 - explicit opt-in for dangerous real Master Loot transfers.
local NLL = NaxxLootLottery
local UI = NLL.UI
function UI:CreateAwardSettingsContent(parent)
    local page = CreateFrame('Frame', nil, parent)
    page:SetAllPoints(parent)
    local heading = page:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    heading:SetPoint('TOPLEFT',page,'TOPLEFT',14,-14)
    heading:SetText('Live Loot Awards (Experimental)')
    local detail = page:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    detail:SetPoint('TOPLEFT',heading,'BOTTOMLEFT',0,-22)
    detail:SetWidth(680)
    detail:SetJustifyH('LEFT')
    detail:SetText('Your lottery can keep reporting awards manually. You may also opt in to sending a real Master Loot request from NLL.')
    local warning = page:CreateFontString(nil,'OVERLAY','GameFontNormal')
    warning:SetPoint('TOPLEFT',detail,'BOTTOMLEFT',0,-32)
    warning:SetWidth(680)
    warning:SetJustifyH('LEFT')
    warning:SetText('|cffff9955IMPORTANT: A Master Loot request can transfer real items and cannot be undone by NLL.|r')
    local procedure = page:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    procedure:SetPoint('TOPLEFT',warning,'BOTTOMLEFT',0,-26)
    procedure:SetWidth(670)
    procedure:SetJustifyH('LEFT')
    procedure:SetText('Direct mode requires a verified winner and open Blizzard loot slot. Normal awards use Arm + Confirm. Separate one-click winner awards can be opted into for this login only.')
    local status = page:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    status:SetPoint('TOPLEFT',procedure,'BOTTOMLEFT',0,-32)
    status:SetWidth(650)
    status:SetJustifyH('LEFT')
    local toggle = UI:CreateTextButton(page,'Enable Direct Awards',210)
    toggle:SetPoint('TOPLEFT',status,'BOTTOMLEFT',0,-18)
    toggle:SetScript('OnClick',function()
        local enable = not NLL.AwardWorkflow:IsDirectEnabled()
        local changed = NLL.AwardWorkflow:SetDirectEnabled(enable)
        if changed then
            NLL:Print(enable and 'Direct Master Loot ENABLED: always confirm recipient and item.' or
                'Direct Master Loot DISABLED. Manual award reporting is available.')
        else
            NLL:Print('Stop the fake raid before changing live-award settings.')
        end
        UI:RefreshAwardSettingsContent()
    end)
    local quick=UI:CreateTextButton(page,'Enable 1-Click Award',228)
    quick:SetPoint('LEFT',toggle,'RIGHT',16,0)
    quick:SetScript('OnClick',function()
        local A=NLL.AwardWorkflow
        if not A or not A.SetQuickEnabled then return end
        local enable=not A:IsQuickEnabled()
        local ok,msg=A:SetQuickEnabled(enable)
        if ok then
            NLL:Print(enable and 'ONE-CLICK physical award ENABLED for this login. AWARD ITEM on a winner popup sends real Master Loot immediately after live checks.' or
                'ONE-CLICK winner awards DISABLED.')
        else NLL:Print(msg or 'Cannot change one-click award consent.') end
        UI:RefreshAwardSettingsContent()
    end)
    self.awardSettingsQuickToggle=quick
    local foot = page:CreateFontString(nil,'OVERLAY','GameFontDisableSmall')
    foot:SetPoint('TOPLEFT',toggle,'BOTTOMLEFT',0,-26)
    foot:SetWidth(670)
    foot:SetJustifyH('LEFT')
    foot:SetText('No awards happen automatically after a roll. ONE-CLICK AWARD transfers REAL loot when pressed if both toggles are ON. Delivery remains UNVERIFIED until human receipt.')
    local guildStatus=page:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    guildStatus:SetPoint('TOPLEFT',foot,'BOTTOMLEFT',0,-26)
    guildStatus:SetWidth(650)
    guildStatus:SetJustifyH('LEFT')
    local guildToggle=UI:CreateTextButton(page,'Enable Guild Transfers',224)
    guildToggle:SetPoint('TOPLEFT',guildStatus,'BOTTOMLEFT',0,-12)
    guildToggle:SetScript('OnClick',function()
        local T=NLL.GuildLootTransfer
        if not T then return end
        local change=T:SetEnabled(not (NLL.db.settings.guildLootTransfersEnabled==true))
        if change then
            NLL:Print(NLL.db.settings.guildLootTransfersEnabled and
                'MANUAL guild-loot transfers enabled. Direct Master Loot ALSO required; each item needs Review, Arm and Confirm.' or
                'Manual guild-loot transfers disabled.')
        end
        UI:RefreshAwardSettingsContent()
    end)
    self.awardSettingsGuildStatus=guildStatus
    self.awardSettingsGuildToggle=guildToggle
    self.awardSettingsPage = page
    self.awardSettingsStatus = status
    self.awardSettingsToggle = toggle
end
function UI:RefreshAwardSettingsContent()
    if not self.awardSettingsPage then return end
    local enabled = NLL.AwardWorkflow:IsDirectEnabled()
    self.awardSettingsStatus:SetText(enabled and
        '|cffffaa55Direct Master Loot: ENABLED (use carefully)|r' or
        '|cff66ff99Direct Master Loot: OFF (recommended until live testing)|r')
    self.awardSettingsToggle.label:SetText(enabled and
        'Disable Direct Awards' or 'Enable Direct Awards')
    local fake=NLL.DebugSimulator and NLL.DebugSimulator:IsActive()
    if fake then self.awardSettingsToggle:Disable()
    else self.awardSettingsToggle:Enable() end
    local A=NLL.AwardWorkflow
    if self.awardSettingsQuickToggle then
        local quick=A and A.IsQuickEnabled and A:IsQuickEnabled()
        self.awardSettingsQuickToggle.label:SetText(quick and
            'Disable 1-Click Award' or 'Enable 1-Click Award')
        if fake or not enabled or not A or not A.SetQuickEnabled then
            self.awardSettingsQuickToggle:Disable()
        else self.awardSettingsQuickToggle:Enable() end
    end
    local T=NLL.GuildLootTransfer
    if self.awardSettingsGuildStatus then
        local consent=NLL.db and NLL.db.settings and
            NLL.db.settings.guildLootTransfersEnabled==true
        self.awardSettingsGuildStatus:SetText(consent and
            '|cffffaa55Guild transfers: ON, but EACH item requires review + ARM + CONFIRM|r' or
            '|cff66ff99Guild transfers: OFF (resets each login/reload)|r')
        self.awardSettingsGuildToggle.label:SetText(consent and
            'Disable Guild Transfers' or 'Enable Guild Transfers')
        if fake or not T then self.awardSettingsGuildToggle:Disable()
        else self.awardSettingsGuildToggle:Enable() end
    end
end
