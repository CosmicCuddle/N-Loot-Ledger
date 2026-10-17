-- Historical guild transfer reconciliation UI. No GiveMasterLoot calls.
-- A "receipt" here means the operator explicitly checked, never that
-- the 3.3.5 client independently proved item delivery.
local NLL=NaxxLootLottery
local UI=NLL.UI
function UI:CreateGuildReconciliation()
    if self.guildReconciliationFrame then return end
    local f=CreateFrame("Frame",nil,self.mainFrame)
    f:SetSize(730,460)
    f:SetPoint("CENTER",self.mainFrame,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+36)
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
    title:SetPoint("TOP",f,"TOP",0,-21)
    title:SetText("GUILD ITEM TRANSFER HISTORY - NO REGRANTS")
    local message=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    message:SetPoint("TOP",title,"BOTTOM",0,-14)
    message:SetWidth(675)
    message:SetJustifyH("CENTER")
    self.guildReconciliationStatus=message
    self.guildReconciliationRows={}
    for i=1,5 do
        local row=CreateFrame("Frame",nil,f)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",24,-86-49*(i-1))
        row:SetWidth(677)
        row:SetHeight(44)
        self:RegisterSkinnedFrame(row,i%2==0 and "rowAlt" or "row")
        local name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        name:SetPoint("TOPLEFT",row,"TOPLEFT",9,-4)
        name:SetWidth(533)
        name:SetJustifyH("LEFT")
        local detail=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        detail:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",9,5)
        detail:SetWidth(533)
        detail:SetJustifyH("LEFT")
        local inspect=self:CreateTextButton(row,"Inspect",100)
        inspect:SetPoint("RIGHT",row,"RIGHT",-7,0)
        inspect:SetScript("OnClick",function(button)
            if not button.auditIndex then return end
            local ok,notice=NLL.GuildLootReconcile:Review(button.auditIndex)
            UI.guildReconciliationLast=tostring(notice)
            NLL:Print(notice)
            UI:RefreshGuildReconciliation()
        end)
        row.nameText=name
        row.detailText=detail
        row.inspect=inspect
        self.guildReconciliationRows[i]=row
    end
    local prev=self:CreateTextButton(f,"Previous",88)
    prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,92)
    prev:SetScript("OnClick",function()
        NLL.GuildLootReconcile:Cancel()
        UI.guildReconciliationPage=math.max(1,(UI.guildReconciliationPage or 1)-1)
        UI:RefreshGuildReconciliation()
    end)
    local nextB=self:CreateTextButton(f,"Next",75)
    nextB:SetPoint("LEFT",prev,"RIGHT",8,0)
    nextB:SetScript("OnClick",function()
        NLL.GuildLootReconcile:Cancel()
        UI.guildReconciliationPage=(UI.guildReconciliationPage or 1)+1
        UI:RefreshGuildReconciliation()
    end)
    local page=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    page:SetPoint("LEFT",nextB,"RIGHT",13,0)
    page:SetWidth(140)
    self.guildReconciliationPageText=page
    local receive=self:CreateTextButton(f,"Verified Received",154)
    receive:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,47)
    receive:SetScript("OnClick",function()
        local ok,msg=NLL.GuildLootReconcile:Arm("RECEIVED")
        UI.guildReconciliationLast=tostring(msg)
        NLL:Print(msg)
        UI:RefreshGuildReconciliation()
    end)
    local hold=self:CreateTextButton(f,"Keep On Hold",145)
    hold:SetPoint("LEFT",receive,"RIGHT",8,0)
    hold:SetScript("OnClick",function()
        local ok,msg=NLL.GuildLootReconcile:Arm("UNVERIFIED")
        UI.guildReconciliationLast=tostring(msg)
        NLL:Print(msg)
        UI:RefreshGuildReconciliation()
    end)
    local commit=self:CreateTextButton(f,"CONFIRM RESULT",155)
    commit:SetPoint("LEFT",hold,"RIGHT",8,0)
    commit:SetScript("OnClick",function()
        local ok,msg=NLL.GuildLootReconcile:Commit()
        UI.guildReconciliationLast=tostring(msg)
        NLL:Print(msg)
        UI:RefreshGuildReconciliation()
    end)
    local close=self:CreateTextButton(f,"Close",105)
    close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-24,22)
    close:SetScript("OnClick",function()
        NLL.GuildLootReconcile:Cancel()
        f:Hide()
    end)
    self.guildReconciliationPrev=prev
    self.guildReconciliationNext=nextB
    self.guildReconciliationReceived=receive
    self.guildReconciliationHold=hold
    self.guildReconciliationCommit=commit
    self.guildReconciliationClose=close
    self.guildReconciliationFrame=f
    f:Hide()
end
function UI:RefreshGuildReconciliation()
    if not self.guildReconciliationFrame then return end
    local entries=NLL.GuildLootReconcile:GetRows()
    local pages=math.max(1,math.ceil(#entries/5))
    self.guildReconciliationPage=
        math.max(1,math.min(self.guildReconciliationPage or 1,pages))
    self.guildReconciliationPageText:SetText(
        "Page "..self.guildReconciliationPage.." / "..pages)
    if self.guildReconciliationPage<=1 then
        self.guildReconciliationPrev:Disable()
    else self.guildReconciliationPrev:Enable() end
    if self.guildReconciliationPage>=pages then
        self.guildReconciliationNext:Disable()
    else self.guildReconciliationNext:Enable() end
    local state=NLL.GuildLootReconcile.review
    if state and state.armedAt then
        self.guildReconciliationReceived:Disable()
        self.guildReconciliationHold:Disable()
        self.guildReconciliationCommit:Enable()
    elseif state then
        self.guildReconciliationReceived:Enable()
        self.guildReconciliationHold:Enable()
        self.guildReconciliationCommit:Disable()
    else
        self.guildReconciliationReceived:Disable()
        self.guildReconciliationHold:Disable()
        self.guildReconciliationCommit:Disable()
    end
    self.guildReconciliationStatus:SetText(tostring(
        self.guildReconciliationLast or
        "Inspect the exact saved request. Check recipient inventory before "..
        "Verified Received. Holding NEVER authorizes retry."))
    for i=1,5 do
        local row=self.guildReconciliationRows[i]
        local e=entries[(self.guildReconciliationPage-1)*5+i]
        if e then
            row.nameText:SetText(
                "#"..e.index.." "..tostring(e.itemLink or e.itemID)..
                " -> "..tostring(e.recipient).." ["..tostring(e.status).."]")
            row.detailText:SetText(
                "Slot "..tostring(e.slotIndex).." x"..tostring(e.quantity)..
                " | Original operator: "..tostring(e.actor or "UNRECORDED"))
            row.inspect.auditIndex=e.index
            if e.status=="AWARD_REQUESTED" or
               e.status=="AWARD_OUTCOME_UNKNOWN" or
               e.status=="LOOT_SLOT_CLEARED" or
               e.status=="INVESTIGATION_HOLD" then
                row.inspect:Enable()
            else row.inspect:Disable() end
            row:Show()
        else
            row.inspect.auditIndex=nil
            row:Hide()
        end
    end
end
function UI:OpenGuildReconciliation()
    self:CreateGuildReconciliation()
    NLL.GuildLootReconcile:Cancel()
    self.guildReconciliationPage=1
    self.guildReconciliationLast=nil
    self:RefreshGuildReconciliation()
    self.guildReconciliationFrame:Show()
end
