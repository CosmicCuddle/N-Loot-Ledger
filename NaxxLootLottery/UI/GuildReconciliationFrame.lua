-- Guild recipient's post-raid inventory reconciliation.
-- A human must click INSPECT then CONFIRM; no GiveMasterLoot calls.
local NLL=NaxxLootLottery
local UI=NLL.UI
function UI:CreateGuildReconciliationDialog()
    if self.guildReconcileFrame then return end
    local f=CreateFrame("Frame",nil,self.mainFrame)
    f:SetSize(690,386)
    f:SetPoint("CENTER",self.mainFrame,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+35)
    f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}})
    f:SetBackdropColor(.055,.065,.085,.99)
    f:SetBackdropBorderColor(.96,.72,.25,1)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",f,"TOP",0,-22)
    title:SetText("GUILD ITEM RECEIPTS - CHECK YOUR BAGS")
    local status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOP",title,"BOTTOM",0,-15)
    status:SetWidth(640)
    status:SetJustifyH("CENTER")
    self.guildReconcileStatus=status
    self.guildReconcileRows={}
    for i=1,5 do
        local line=CreateFrame("Frame",nil,f)
        line:SetPoint("TOPLEFT",f,"TOPLEFT",24,-87-37*(i-1))
        line:SetWidth(640)
        line:SetHeight(34)
        self:RegisterSkinnedFrame(line,i%2==0 and "rowAlt" or "row")
        local label=line:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("LEFT",line,"LEFT",8,0)
        label:SetWidth(532)
        label:SetJustifyH("LEFT")
        local choose=self:CreateTextButton(line,"Inspect",90)
        choose:SetPoint("RIGHT",line,"RIGHT",-5,0)
        choose:SetScript("OnClick",function(button)
            if not button.recordIndex then return end
            NLL.GuildLootReconciliation:Cancel()
            UI.guildReconcileIndex=button.recordIndex
            UI:RefreshGuildReconciliationDialog()
        end)
        line.statusText=label
        line.chooseButton=choose
        self.guildReconcileRows[i]=line
    end
    local prev=self:CreateTextButton(f,"Previous",88)
    prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,88)
    prev:SetScript("OnClick",function()
        UI.guildReconcilePage=math.max(1,(UI.guildReconcilePage or 1)-1)
        UI.guildReconcileIndex=nil
        NLL.GuildLootReconciliation:Cancel()
        UI:RefreshGuildReconciliationDialog()
    end)
    local nextB=self:CreateTextButton(f,"Next",70)
    nextB:SetPoint("LEFT",prev,"RIGHT",8,0)
    nextB:SetScript("OnClick",function()
        UI.guildReconcilePage=(UI.guildReconcilePage or 1)+1
        UI.guildReconcileIndex=nil
        NLL.GuildLootReconciliation:Cancel()
        UI:RefreshGuildReconciliationDialog()
    end)
    local page=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    page:SetPoint("LEFT",nextB,"RIGHT",12,0)
    self.guildReconcilePageText=page
    local inspect=self:CreateTextButton(f,"I Checked My Bags",180)
    inspect:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,27)
    inspect:SetScript("OnClick",function()
        local ok,msg=NLL.GuildLootReconciliation:Arm(UI.guildReconcileIndex)
        UI.guildReconcileMessage=msg
        UI:RefreshGuildReconciliationDialog()
        if ok then UI.guildReconcileConfirm:Enable() end
        NLL:Print(msg)
    end)
    local confirm=self:CreateTextButton(f,"CONFIRM RECEIVED",180)
    confirm:SetPoint("LEFT",inspect,"RIGHT",12,0)
    confirm:SetScript("OnClick",function()
        local ok,msg=NLL.GuildLootReconciliation:Confirm(
            UI.guildReconcileIndex)
        UI.guildReconcileMessage=msg
        NLL:Print(msg)
        UI:RefreshGuildReconciliationDialog()
    end)
    local close=self:CreateTextButton(f,"Close",112)
    close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-24,27)
    close:SetScript("OnClick",function()
        NLL.GuildLootReconciliation:Cancel()
        f:Hide()
    end)
    self.guildReconcileFrame=f
    self.guildReconcilePrev=prev
    self.guildReconcileNext=nextB
    self.guildReconcileInspect=inspect
    self.guildReconcileConfirm=confirm
    self.guildReconcileClose=close
    f:Hide()
end

function UI:RefreshGuildReconciliationDialog()
    if not self.guildReconcileFrame then return end
    local rows=NLL.GuildLootReconciliation:List()
    local pages=math.max(1,math.ceil(#rows/5))
    self.guildReconcilePage=math.min(pages,math.max(1,
        self.guildReconcilePage or 1))
    self.guildReconcilePageText:SetText("Page "..self.guildReconcilePage..
        "/"..pages.." ("..#rows.." requests)")
    if self.guildReconcilePage<=1 then self.guildReconcilePrev:Disable()
    else self.guildReconcilePrev:Enable() end
    if self.guildReconcilePage>=pages then self.guildReconcileNext:Disable()
    else self.guildReconcileNext:Enable() end
    local selected=self.guildReconcileIndex
    self.guildReconcileStatus:SetText(tostring(
        self.guildReconcileMessage or
        "This records YOUR inventory confirmation only. Never a new award."))
    for i=1,5 do
        local row=self.guildReconcileRows[i]
        local record=rows[(self.guildReconcilePage-1)*5+i]
        if record then
            row.chooseButton.recordIndex=record.index
            row.statusText:SetText(
                "#"..record.index..": "..tostring(record.itemID)..
                " x"..tostring(record.quantity).." -> "..
                tostring(record.recipient).." ["..tostring(record.status).."]")
            local ok=NLL.GuildLootReconciliation:CanVerify(record.index)
            if ok then row.chooseButton:Enable()
            else row.chooseButton:Disable() end
            row:Show()
        else
            row.chooseButton.recordIndex=nil
            row:Hide()
        end
    end
    local can=selected and NLL.GuildLootReconciliation:CanVerify(selected)
    if can then self.guildReconcileInspect:Enable()
    else self.guildReconcileInspect:Disable() end
    local a=NLL.GuildLootReconciliation.armed
    if can and a and a.index==selected then
        self.guildReconcileConfirm:Enable()
    else self.guildReconcileConfirm:Disable() end
end

function UI:OpenGuildReconciliationReview()
    self:CreateGuildReconciliationDialog()
    NLL.GuildLootReconciliation:Cancel()
    self.guildReconcileMessage=nil
    self.guildReconcileIndex=nil
    self.guildReconcilePage=1
    self:RefreshGuildReconciliationDialog()
    self.guildReconcileFrame:Show()
end
