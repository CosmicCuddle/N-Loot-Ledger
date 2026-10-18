-- NLL explicit Playerbot Gear Plan review dialog: NO immediate status/X saves.
local NLL=NaxxLootLottery
local UI=NLL.UI
function UI:CreateGearPlanReviewDialog()
    if self.gearPlanReviewDialog then return end
    local parent=UIParent or self.mainFrame
    local f=CreateFrame("Frame",nil,parent)
    f:SetSize(580,220)
    f:SetPoint("CENTER",parent,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 0)+48)
    f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}})
    f:SetBackdropColor(.055,.065,.085,.99)
    f:SetBackdropBorderColor(.96,.72,.25,1)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",f,"TOP",0,-22)
    title:SetText("REVIEW EXISTING PLAYERBOT GEAR PLAN")
    local detail=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    detail:SetPoint("TOP",title,"BOTTOM",0,-18)
    detail:SetWidth(535)
    detail:SetJustifyH("CENTER")
    detail:SetText("Review the exact character/item before saving.")
    local caution=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    caution:SetPoint("TOP",detail,"BOTTOM",0,-15)
    caution:SetWidth(535)
    caution:SetJustifyH("CENTER")
    caution:SetText("OBTAINED requires a receipt. Original winner and inventory records are never edited.")
    local confirm=self:CreateTextButton(f,"CONFIRM THIS CHANGE",205)
    confirm:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",28,24)
    confirm:SetScript("OnClick",function()
        local ok,message=NLL.GearPlanReview:Confirm()
        if NLL.Print then NLL:Print(message) end
        f:Hide()
        UI:RefreshGearPlans()
    end)
    local cancel=self:CreateTextButton(f,"Cancel (Keep Plan)",173)
    cancel:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-28,24)
    cancel:SetScript("OnClick",function()
        NLL.GearPlanReview:Cancel()
        f:Hide()
    end)
    self.gearPlanReviewDetail=detail
    self.gearPlanReviewConfirm=confirm
    self.gearPlanReviewCancel=cancel
    self.gearPlanReviewDialog=f
    f:Hide()
end

function UI:ReviewBotPlan(key,action,status)
    if not NLL.GearPlanReview then return end
    local ok,message=NLL.GearPlanReview:Arm(key,action,status)
    if not ok then
        if NLL.Print then NLL:Print(message) end
        return
    end
    self:CreateGearPlanReviewDialog()
    self.gearPlanReviewDetail:SetText(message)
    self.gearPlanReviewDialog:Show()
end
