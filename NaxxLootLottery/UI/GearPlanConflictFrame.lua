-- NLL read-only 3.3.5a Gear Plan conflict comparison modal.
-- Never writes SavedVariables, resolves conflicts, or enables Confirm ADD.
local NLL=NaxxLootLottery
local UI=NLL.UI

function UI:CreateGearPlanConflictDialog()
    if self.gearPlanConflictDialog then return end
    local panel=CreateFrame("Frame","NaxxLootLotteryGearPlanConflictDialog",UIParent)
    panel:SetWidth(678)
    panel:SetHeight(368)
    panel:SetPoint("CENTER",UIParent,"CENTER",0,0)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    self:RegisterSkinnedFrame(panel,"main")

    local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-19)
    title:SetText("Gear Plan Import: SAVED vs PASTED")
    local warning=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    warning:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-11)
    warning:SetWidth(625)
    warning:SetJustifyH("LEFT")
    warning:SetText("READ-ONLY differences. Conflicting plans block the entire import.")
    local report=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    report:SetPoint("TOPLEFT",panel,"TOPLEFT",22,-85)
    report:SetWidth(626)
    report:SetHeight(226)
    report:SetJustifyH("LEFT")
    report:SetJustifyV("TOP")

    local previous=self:CreateTextButton(panel,"Previous Conflict",152)
    previous:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",20,17)
    local next=self:CreateTextButton(panel,"Next Conflict",140)
    next:SetPoint("LEFT",previous,"RIGHT",10,0)
    local close=self:CreateTextButton(panel,"Close (No Changes)",173)
    close:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-18,17)

    local function ShowIndex(index)
        -- Require unchanged original paste AND unchanged entire saved
        -- Gear Plans snapshot on each navigation; never show stale claims.
        local source=UI.gearTransferTextBox and UI.gearTransferTextBox:GetText()
        local text,count=NLL.GearPlanTransfer:FormatConflict(
            UI.gearConflictPreview,source,index)
        if not text then
            UI:CloseGearPlanConflictDialog()
            if NLL.Print then NLL:Print("Comparison cancelled: "..tostring(count)) end
            return
        end
        UI.gearConflictIndex=index
        report:SetText(text)
        if index>1 then previous:Enable() else previous:Disable() end
        if index<count then next:Enable() else next:Disable() end
    end
    previous:SetScript("OnClick",function()
        if not UI.gearConflictPreview or UI.gearConflictIndex<=1 then return end
        ShowIndex(UI.gearConflictIndex-1)
    end)
    next:SetScript("OnClick",function()
        if not UI.gearConflictPreview then return end
        local p=UI.gearConflictPreview
        if UI.gearConflictIndex>=#(p.conflicts or {}) then return end
        ShowIndex(UI.gearConflictIndex+1)
    end)
    close:SetScript("OnClick",function()UI:CloseGearPlanConflictDialog()end)
    self.gearPlanConflictDialog=panel
    self.gearPlanConflictReport=report
    self.gearPlanConflictPrev=previous
    self.gearPlanConflictNext=next
    self.gearPlanConflictClose=close
    self.gearPlanConflictShowIndex=ShowIndex
    panel:Hide()
end

function UI:CloseGearPlanConflictDialog()
    self.gearConflictPreview=nil
    self.gearConflictIndex=nil
    if self.gearPlanConflictDialog then self.gearPlanConflictDialog:Hide() end
end

function UI:ShowGearPlanConflictDialog(preview)
    if not preview or type(preview.conflicts)~="table" or
       #preview.conflicts==0 then
        return false,"No valid import conflicts to compare."
    end
    if not self.gearTransferTextBox then
        return false,"Original paste is unavailable."
    end
    local text,why=NLL.GearPlanTransfer:FormatConflict(
        preview,self.gearTransferTextBox:GetText(),1)
    if not text then return false,why end
    self:CreateGearPlanConflictDialog()
    self.gearConflictPreview=preview
    self.gearConflictIndex=1
    self.gearPlanConflictShowIndex(1)
    self.gearPlanConflictDialog:Show()
    return true,"Read-only conflict comparisons. Import remains BLOCKED."
end
