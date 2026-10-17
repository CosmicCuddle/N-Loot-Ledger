-- Noninteractive automated guild loot DRY-RUN panel, WoW 3.3.5a.
-- All generated rows are ephemeral, with ZERO real award controls.
local NLL=NaxxLootLottery
local UI=NLL.UI
function UI:CreateGuildAutoPreview()
    if self.guildAutoPreviewFrame then return end
    local f=CreateFrame("Frame",nil,self.mainFrame)
    f:SetSize(730,425)
    f:SetPoint("CENTER",self.mainFrame,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+34)
    f:EnableMouse(true)
    f:SetBackdrop({
        bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}
    })
    f:SetBackdropColor(.055,.065,.085,.99)
    f:SetBackdropBorderColor(.96,.72,.25,1)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",f,"TOP",0,-22)
    title:SetText("AUTOMATIC GUILD ROUTING - PREVIEW ONLY")
    local status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOP",title,"BOTTOM",0,-13)
    status:SetWidth(690)
    status:SetJustifyH("CENTER")
    self.guildAutoPreviewStatus=status
    self.guildAutoPreviewRows={}
    for i=1,6 do
        local row=CreateFrame("Frame",nil,f)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",24,-91-(i-1)*43)
        row:SetWidth(680)
        row:SetHeight(40)
        self:RegisterSkinnedFrame(row,i%2==0 and "rowAlt" or "row")
        local name=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        name:SetPoint("TOPLEFT",row,"TOPLEFT",8,-3)
        name:SetWidth(650)
        name:SetJustifyH("LEFT")
        local reason=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        reason:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",8,4)
        reason:SetWidth(650)
        reason:SetJustifyH("LEFT")
        row.nameText=name
        row.reasonText=reason
        self.guildAutoPreviewRows[i]=row
    end
    local previous=self:CreateTextButton(f,"Previous",100)
    previous:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,22)
    previous:SetScript("OnClick",function()
        UI.guildAutoPreviewPage=math.max(1,(UI.guildAutoPreviewPage or 1)-1)
        UI:RefreshGuildAutoPreview()
    end)
    local nextB=self:CreateTextButton(f,"Next",85)
    nextB:SetPoint("LEFT",previous,"RIGHT",8,0)
    nextB:SetScript("OnClick",function()
        UI.guildAutoPreviewPage=(UI.guildAutoPreviewPage or 1)+1
        UI:RefreshGuildAutoPreview()
    end)
    local page=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    page:SetPoint("LEFT",nextB,"RIGHT",13,0)
    page:SetWidth(175)
    self.guildAutoPreviewPageText=page
    local close=self:CreateTextButton(f,"Close Preview",145)
    close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-24,22)
    close:SetScript("OnClick",function()f:Hide()end)
    self.guildAutoPreviewPrevious=previous
    self.guildAutoPreviewNext=nextB
    self.guildAutoPreviewClose=close
    self.guildAutoPreviewFrame=f
    f:Hide()
end
function UI:RefreshGuildAutoPreview()
    if not self.guildAutoPreviewFrame then return end
    local plan=NLL.GuildAutoPreview:Plan()
    self.guildAutoPreviewLastPlan=plan -- display only, NOT a grant list
    self.guildAutoPreviewStatus:SetText(
        tostring(plan.notice or "Nothing to preview")..
        " All recipients UNVERIFIED. No automatic awards.")
    local pages=math.max(1,math.ceil(#plan.items/6))
    self.guildAutoPreviewPage=
        math.max(1,math.min(self.guildAutoPreviewPage or 1,pages))
    self.guildAutoPreviewPageText:SetText(
        "Page "..self.guildAutoPreviewPage.." / "..pages)
    if self.guildAutoPreviewPage<=1 then
        self.guildAutoPreviewPrevious:Disable()
    else self.guildAutoPreviewPrevious:Enable() end
    if self.guildAutoPreviewPage>=pages then
        self.guildAutoPreviewNext:Disable()
    else self.guildAutoPreviewNext:Enable() end
    for i=1,6 do
        local row=self.guildAutoPreviewRows[i]
        local item=plan.items[(self.guildAutoPreviewPage-1)*6+i]
        if item then
            row.nameText:SetText(
                "Slot "..item.slotIndex..": "..item.itemName.." x"..
                item.quantity.." ["..item.decision.."]")
            row.reasonText:SetText(item.reason..
                " | Intended leader: "..tostring(item.intendedRecipient))
            row:Show()
        else row:Hide() end
    end
end
function UI:OpenGuildAutoPreview()
    self:CreateGuildAutoPreview()
    self.guildAutoPreviewPage=1
    self:RefreshGuildAutoPreview()
    self.guildAutoPreviewFrame:Show()
end
