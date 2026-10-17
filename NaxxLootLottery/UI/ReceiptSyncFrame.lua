-- NLL remote player receipt inbox. Human confirmation ONLY.
-- The button can never award an item or edit a different account's data.
local NLL=NaxxLootLottery
local UI=NLL.UI
function UI:CreateReceiptSyncDialog()
    if self.receiptSyncFrame then return end
    local f=CreateFrame("Frame",nil,self.mainFrame)
    f:SetSize(635,268)
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
    local heading=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    heading:SetPoint("TOP",f,"TOP",0,-22)
    heading:SetText("MY RECEIPT INBOX - CHECK YOUR BAG")
    local detail=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    detail:SetPoint("TOP",heading,"BOTTOM",0,-24)
    detail:SetWidth(580)
    detail:SetJustifyH("CENTER")
    local warning=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    warning:SetPoint("TOP",detail,"BOTTOM",0,-24)
    warning:SetWidth(570)
    warning:SetJustifyH("CENTER")
    local page=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    page:SetPoint("BOTTOM",f,"BOTTOM",0,94)
    local prev=self:CreateTextButton(f,"Previous",86)
    prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",25,84)
    prev:SetScript("OnClick",function()
        UI.receiptSyncIndex=math.max(1,(UI.receiptSyncIndex or 1)-1)
        UI:RefreshReceiptSyncDialog()
    end)
    local nextB=self:CreateTextButton(f,"Next",70)
    nextB:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-25,84)
    nextB:SetScript("OnClick",function()
        UI.receiptSyncIndex=(UI.receiptSyncIndex or 1)+1
        UI:RefreshReceiptSyncDialog()
    end)
    local verify=self:CreateTextButton(f,"I Have the Item",174)
    verify:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,25)
    verify:SetScript("OnClick",function()
        local key=UI.receiptSyncKey
        local ok,record=NLL.ReceiptSync:CanAccept(key)
        UI.receiptSyncArmedAt=nil
        UI.receiptSyncConfirm:Disable()
        if ok then
            UI.receiptSyncArmedAt=GetTime and GetTime() or 0
            UI.receiptSyncConfirm:Enable()
            warning:SetText("Now click MARK OBTAINED within 15 seconds.")
        else warning:SetText(tostring(record)) end
    end)
    local confirm=self:CreateTextButton(f,"MARK OBTAINED",168)
    confirm:SetPoint("LEFT",verify,"RIGHT",12,0)
    confirm:SetScript("OnClick",function()
        if not UI.receiptSyncArmedAt or
            (GetTime and GetTime() or 0)-UI.receiptSyncArmedAt>15 then
            UI.receiptSyncArmedAt=nil
            confirm:Disable()
            warning:SetText("Confirmation expired. Check the item again.")
            return
        end
        UI.receiptSyncArmedAt=nil
        confirm:Disable()
        local ok,message=NLL.ReceiptSync:Accept(UI.receiptSyncKey)
        NLL:Print(message)
        if ok then UI:RefreshReceiptSyncDialog()
        else warning:SetText(tostring(message)) end
    end)
    local close=self:CreateTextButton(f,"Close",112)
    close:SetPoint("LEFT",confirm,"RIGHT",12,0)
    close:SetScript("OnClick",function()
        UI.receiptSyncArmedAt=nil
        f:Hide()
    end)
    self.receiptSyncFrame=f
    self.receiptSyncDetail=detail
    self.receiptSyncWarning=warning
    self.receiptSyncPageText=page
    self.receiptSyncPrev=prev
    self.receiptSyncNext=nextB
    self.receiptSyncVerify=verify
    self.receiptSyncConfirm=confirm
    self.receiptSyncClose=close
    f:Hide()
end

function UI:RefreshReceiptSyncDialog()
    if not self.receiptSyncFrame or not NLL.ReceiptSync then return end
    local pending=NLL.ReceiptSync:GetPendingForLocal()
    self.receiptSyncIndex=math.min(math.max(1,self.receiptSyncIndex or 1),
        math.max(1,#pending))
    self.receiptSyncArmedAt=nil
    self.receiptSyncConfirm:Disable()
    self.receiptSyncPageText:SetText(
        "Receipt "..(pending[1] and self.receiptSyncIndex or 0)..
        " / "..#pending)
    if self.receiptSyncIndex<=1 then self.receiptSyncPrev:Disable()
    else self.receiptSyncPrev:Enable() end
    if self.receiptSyncIndex>=#pending then self.receiptSyncNext:Disable()
    else self.receiptSyncNext:Enable() end
    local row=pending[self.receiptSyncIndex]
    self.receiptSyncKey=row and row.key or nil
    if not row then
        self.receiptSyncDetail:SetText("No outstanding receipt messages.")
        self.receiptSyncWarning:SetText("No changes to your wishlist.")
        self.receiptSyncVerify:Disable()
        return
    end
    local item=NLL.Data and NLL.Data.MoltenCore and
        NLL.Data.MoltenCore:GetItem(row.itemID)
    self.receiptSyncDetail:SetText(
        tostring(item and item.name or ("Item "..row.itemID))..
        " - reported by "..tostring(row.leader))
    self.receiptSyncWarning:SetText(
        "Did YOU physically receive this item? Check inventory first."..
        " If not, close; your NEED/GREED stays unchanged.")
    self.receiptSyncVerify:Enable()
end

function UI:OpenReceiptSyncReview()
    self:CreateReceiptSyncDialog()
    self.receiptSyncIndex=1
    self:RefreshReceiptSyncDialog()
    self.receiptSyncFrame:Show()
end
