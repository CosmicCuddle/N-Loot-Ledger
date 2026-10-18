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

-- Separate role picker is a choice screen only, not a save. It uses the
-- exact saved row key; ONLY the next explicit Confirm may change role.
-- Unlike the global role setup, this is per ITEM, per PLAYERBOT.
function UI:CreateGearPlanRolePicker()
    if self.gearPlanRolePicker then return end
    local parent=UIParent or self.mainFrame
    local f=CreateFrame("Frame",nil,parent)
    f:SetSize(484,367)
    f:SetPoint("CENTER",parent,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 0)+47)
    f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}})
    f:SetBackdropColor(.055,.065,.085,.99)
    f:SetBackdropBorderColor(.96,.72,.25,1)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",f,"TOP",0,-23)
    title:SetText("CHOOSE ROLE FOR ONE BOT ITEM")
    local note=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    note:SetPoint("TOP",title,"BOTTOM",0,-13)
    note:SetWidth(448)
    note:SetJustifyH("CENTER")
    note:SetText("Choose a new item role. No changes until Confirm.")
    local buttons={}
    for i,role in ipairs(NLL.roles or {}) do
        local choose=self:CreateTextButton(f,role.label,302)
        choose:SetPoint("TOP",f,"TOP",0,-90-(i-1)*34)
        choose:SetScript("OnClick",function()
            local key=UI.gearPlanRoleKey
            UI.gearPlanRoleKey=nil
            f:Hide()
            if key then UI:ReviewBotPlan(key,"ROLE",role.id) end
        end)
        buttons[i]=choose
    end
    local cancel=self:CreateTextButton(f,"Cancel (Keep Role)",180)
    cancel:SetPoint("BOTTOM",f,"BOTTOM",0,17)
    cancel:SetScript("OnClick",function()
        UI:CancelGearPlanRolePicker()
    end)
    self.gearPlanRoleButtons=buttons
    self.gearPlanRolePicker=f
    self.gearPlanRoleCancel=cancel
    f:Hide()
end

function UI:CancelGearPlanRolePicker()
    self.gearPlanRoleKey=nil
    if NLL.GearPlanReview then NLL.GearPlanReview:Cancel() end
    if self.gearPlanRolePicker then self.gearPlanRolePicker:Hide() end
end

function UI:OpenGearPlanRolePicker(key)
    self:CancelGearPlanRolePicker()
    if not NLL.GearPlanReview then return end
    -- Check the same full safety guards before exposing any role option.
    -- The second ROLE review will check them again, including the role ID.
    local row=NLL.db and NLL.db.gearNeeds and NLL.db.gearNeeds[key]
    if not row or row.status=="OBTAINED" then return end
    local eligible=false
    for _,role in ipairs(NLL.roles or {}) do
        if NLL.GearPlanReview:CanEdit(key,"ROLE",role.id) then
            eligible=true
            break
        end
    end
    if not eligible then
        if NLL.Print then
            NLL:Print("Bot item role is unchanged or blocked by an outstanding receipt.")
        end
        return
    end
    self:CreateGearPlanRolePicker()
    self.gearPlanRoleKey=key
    self.gearPlanRolePicker:Show()
end
