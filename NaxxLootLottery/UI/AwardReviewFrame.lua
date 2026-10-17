-- Naxxramas Loot Ledger v0.1.0.25
-- The real transfer button is opt-in and requires review, arm and confirm.
local NLL = NaxxLootLottery
local UI = NLL.UI

function UI:CreateAwardReview()
    if self.awardReviewFrame then return end
    local frame = CreateFrame('Frame',nil,self.mainFrame)
    frame:SetSize(635,278)
    frame:SetPoint('CENTER',self.mainFrame,'CENTER',0,0)
    frame:SetFrameStrata('DIALOG')
    frame:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+30)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile='Interface\\Buttons\\WHITE8X8',
        edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}
    })
    frame:SetBackdropColor(.055,.065,.085,.99)
    frame:SetBackdropBorderColor(.96,.72,.25,1)

    local title=frame:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    title:SetPoint('TOP',frame,'TOP',0,-25)
    title:SetText('AWARD WINNER - VERIFY MASTER LOOT')
    local subject=frame:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    subject:SetPoint('TOP',title,'BOTTOM',0,-19)
    subject:SetWidth(570)
    subject:SetJustifyH('CENTER')
    local status=frame:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    status:SetPoint('TOP',subject,'BOTTOM',0,-18)
    status:SetWidth(555)
    status:SetJustifyH('CENTER')
    local warning=frame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    warning:SetPoint('BOTTOM',frame,'BOTTOM',0,84)
    warning:SetWidth(550)
    warning:SetJustifyH('CENTER')

    -- The first step never calls GiveMasterLoot. WoW Master Loot must be
    -- open on THIS exact slot, then Check Master Loot validates the winner.
    -- Lua 5.1 forward locals: the recheck callback refers to both controls.
    local manual,direct
    local check=self:CreateTextButton(frame,'Check Master Loot',169)
    check:SetPoint('BOTTOM',frame,'BOTTOM',0,120)
    check:SetScript('OnClick',function()
        local entry=NLL.AwardWorkflow:GetReviewedDrop()
        local outcome=entry and NLL.AwardWorkflow:GetOutcome(entry)
        if not entry or entry.dropUID~=UI.awardReviewDropUID or
            not outcome or outcome.winner~=UI.awardReviewWinner then
            NLL.AwardWorkflow:Cancel()
            manual:Disable()
            direct:Disable()
            status:SetText('|cffff7777Selection changed. Close and reopen Award Winner.|r')
            NLL:Print('Award review stopped: selected item or winner changed.')
            return
        end
        local ok,message=NLL.AwardWorkflow:Review(entry)
        status:SetText((ok and '|cff66ff99' or '|cffffaa55')..
            tostring(message)..'|r')
        direct.label:SetText('Arm Direct Award')
        if ok then
            manual:Enable()
            if entry and not entry.simulationOnly and
                NLL.AwardWorkflow:IsDirectEnabled() then
                direct:Enable()
            else
                direct:Disable()
            end
        else
            manual:Disable()
            direct:Disable()
        end
        NLL:Print(message)
    end)

    -- The original manual confirmation remains available.
    manual=self:CreateTextButton(frame,'I Awarded It in WoW',173)
    manual:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',22,25)
    manual:SetScript('OnClick',function()
        local entry=NLL.AwardWorkflow:GetReviewedDrop()
        if not entry or entry.dropUID~=UI.awardReviewDropUID then
            NLL.AwardWorkflow:Cancel()
            NLL:Print('Award review stopped: item selection changed.')
            manual:Disable()
            direct:Disable()
            return
        end
        local ok,msg=NLL.AwardWorkflow:Confirm()
        NLL:Print(msg)
        if ok then frame:Hide() end
        if UI.RefreshCurrentLootPanel then UI:RefreshCurrentLootPanel() end
        if UI.RefreshOverview then UI:RefreshOverview() end
    end)

    -- The first click ARMS; the second click immediately re-verifies live
    -- Master Loot state and sends the real request. Never used by simulation.
    direct=self:CreateTextButton(frame,'Arm Direct Award',192)
    direct:SetPoint('LEFT',manual,'RIGHT',12,0)
    direct:SetScript('OnClick',function()
        local entry=NLL.AwardWorkflow:GetReviewedDrop()
        local outcome=entry and NLL.AwardWorkflow:GetOutcome(entry)
        if not entry or entry.dropUID~=UI.awardReviewDropUID or
            not outcome or outcome.winner~=UI.awardReviewWinner then
            NLL.AwardWorkflow:Cancel()
            NLL:Print('Award review stopped: item or winner changed.')
            direct:Disable()
            manual:Disable()
            return
        end
        local verified=NLL.AwardWorkflow.verification
        local ok,msg
        if verified and verified.armedAt then
            ok,msg=NLL.AwardWorkflow:CommitDirectAward(entry)
        else
            ok,msg=NLL.AwardWorkflow:ArmDirectAward(entry)
        end
        NLL:Print(msg)
        if ok and NLL.AwardWorkflow.verification and
           NLL.AwardWorkflow.verification.armedAt then
            direct.label:SetText('CONFIRM GIVE ITEM')
            status:SetText('|cffffaa55'..msg..'|r')
        elseif ok then
            frame:Hide()
        else
            direct.label:SetText('Arm Direct Award')
            status:SetText('|cffff7777'..tostring(msg)..'|r')
        end
        if UI.RefreshCurrentLootPanel then UI:RefreshCurrentLootPanel() end
        if UI.RefreshOverview then UI:RefreshOverview() end
    end)

    local close=self:CreateTextButton(frame,'Back / Cancel',133)
    close:SetPoint('LEFT',direct,'RIGHT',12,0)
    close:SetScript('OnClick',function()
        frame:Hide()
        NLL.AwardWorkflow:Cancel()
    end)

    self.awardReviewCheck=check
    self.awardReviewFrame=frame
    self.awardReviewSubject=subject
    self.awardReviewStatus=status
    self.awardReviewWarning=warning
    self.awardReviewConfirm=manual
    self.awardReviewDirect=direct
    self.awardReviewCancel=close
    frame:Hide()
end

function UI:OpenAwardReview()
    self:CreateAwardReview()
    local loot=NLL.LootDetection:GetCurrentLoot() or {}
    local entry=loot[self.currentLootSelected or 1]
    local result=entry and NLL.AwardWorkflow:GetOutcome(entry)
    if not result or not result.winner then
        NLL:Print('Finish a real lottery before reviewing its winner.')
        return false
    end
    -- An already-requested award has an unknown receipt; never offer a
    -- second request against that same physical drop.
    if result.awardStatus then
        NLL:Print(NLL.AwardWorkflow:GetStatus(entry)..
            '. Check award history before any new action.')
        return false
    end
    self.awardReviewDropUID=entry.dropUID
    self.awardReviewWinner=result.winner
    local ok,msg=NLL.AwardWorkflow:Review(entry)
    self.awardReviewSubject:SetText(tostring(entry.itemName)..
        '  ->  '..tostring(result.winner))
    self.awardReviewStatus:SetText(
        (ok and '|cff66ff99' or '|cffffaa55')..tostring(msg)..'|r')
    self.awardReviewDirect.label:SetText('Arm Direct Award')
    if ok then self.awardReviewConfirm:Enable()
    else self.awardReviewConfirm:Disable() end
    if entry.simulationOnly then
        self.awardReviewConfirm.label:SetText('Confirm Fake Award')
        self.awardReviewWarning:SetText(
            '|cffffbb66SIMULATION ONLY: no server roll or real award.|r')
        self.awardReviewCheck:Disable()
        self.awardReviewDirect:Hide()
    else
        self.awardReviewCheck:Enable()
        self.awardReviewConfirm.label:SetText('I Awarded It in WoW')
        self.awardReviewDirect:Show()
        if NLL.AwardWorkflow:IsDirectEnabled() then
            if ok then self.awardReviewDirect:Enable()
            else self.awardReviewDirect:Disable() end
            self.awardReviewWarning:SetText(
                'Double-confirm REAL transfer. No delivery receipt is guaranteed.')
        else
            self.awardReviewDirect:Disable()
            self.awardReviewWarning:SetText(
                'Direct awards OFF. To use in-addon transfer, opt in '..
                'at Settings > Loot Awards, then re-check this item.')
        end
    end
    self.awardReviewFrame:Show()
    -- Opening the modal NEVER requires an unsafe guessed slot or awards
    -- an item; a live missing/closed context can be reviewed diagnostically.
    return true
end
