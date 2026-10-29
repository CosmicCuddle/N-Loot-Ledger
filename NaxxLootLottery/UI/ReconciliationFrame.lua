-- NLL non-awarding investigation window for uncertain physical loot.
-- Every click only selects, arms, or records NO RETRY. No Master Loot APIs.
local NLL=NaxxLootLottery
local UI=NLL.UI
local PER_PAGE=5
local function Identity(a,b)
    return a and b and a.kind==b.kind and a.id==b.id
end
local function Name(row)
    return tostring(row.kind).." "..tostring(row.id)..
        "  |  Item "..tostring(row.itemID or "?")..
        "  |  "..tostring(row.recipient or "Unknown")
end
local function State(row)
    if row.reviewed then
        return "REVIEW CLOSED - NO RETRY; receipt remains separate"
    end
    if row.receipt=="OBTAINED" then
        return "Recipient receipt OBTAINED - no NO-RETRY action needed"
    end
    return tostring(row.status or "UNKNOWN").." - recipient receipt unverified"
end

function UI:CreateReconciliationDialog()
    if self.reconciliationDialog then return end
    local f=CreateFrame("Frame",nil,self.mainFrame)
    f:SetSize(715,438)
    f:SetPoint("CENTER",self.mainFrame,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+45)
    f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}})
    f:SetBackdropColor(.055,.065,.085,.99)
    f:SetBackdropBorderColor(.96,.72,.25,1)

    local heading=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    heading:SetPoint("TOP",f,"TOP",0,-21)
    heading:SetText("DELIVERY INVESTIGATIONS - NO RE-ISSUE")
    local explanation=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    explanation:SetPoint("TOP",heading,"BOTTOM",0,-9)
    explanation:SetWidth(670)
    explanation:SetJustifyH("CENTER")
    explanation:SetText("Select an old request. Closing review NEVER proves delivery, awards loot or unlocks the original item.")
    local status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOP",explanation,"BOTTOM",0,-10)
    status:SetWidth(665)
    status:SetJustifyH("CENTER")
    status:SetText("No investigation selected.")
    self.reconciliationStatus=status
    self.reconciliationRows={}
    for i=1,PER_PAGE do
        local line=CreateFrame("Frame",nil,f)
        line:SetPoint("TOPLEFT",f,"TOPLEFT",20,-103-(i-1)*47)
        line:SetWidth(675)
        line:SetHeight(43)
        self:RegisterSkinnedFrame(line,i%2==0 and "rowAlt" or "row")
        local item=line:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        item:SetPoint("TOPLEFT",line,"TOPLEFT",10,-5)
        item:SetWidth(525)
        item:SetJustifyH("LEFT")
        local detail=line:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        detail:SetPoint("BOTTOMLEFT",line,"BOTTOMLEFT",10,5)
        detail:SetWidth(525)
        detail:SetJustifyH("LEFT")
        local pick=self:CreateTextButton(line,"Select",111)
        pick:SetPoint("RIGHT",line,"RIGHT",-7,0)
        pick:SetScript("OnClick",function(button)
            local chosen=button.record
            if not chosen then return end
            if NLL.LootReconciliation then NLL.LootReconciliation:Cancel() end
            UI.reconciliationSelected={kind=chosen.kind,id=chosen.id}
            UI.reconciliationNotice="Selected "..Name(chosen)..
                ". Review the recipient and history; ARM is not a receipt."
            UI:RefreshReconciliationDialog()
        end)
        self.reconciliationRows[i]={panel=line,name=item,detail=detail,pick=pick}
    end
    local prev=self:CreateTextButton(f,"Previous",100)
    prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",21,64)
    prev:SetScript("OnClick",function()
        NLL.LootReconciliation:Cancel()
        UI.reconciliationPage=math.max(1,(UI.reconciliationPage or 1)-1)
        UI.reconciliationSelected=nil
        UI.reconciliationNotice=nil
        UI:RefreshReconciliationDialog()
    end)
    local nextB=self:CreateTextButton(f,"Next",79)
    nextB:SetPoint("LEFT",prev,"RIGHT",8,0)
    nextB:SetScript("OnClick",function()
        NLL.LootReconciliation:Cancel()
        UI.reconciliationPage=(UI.reconciliationPage or 1)+1
        UI.reconciliationSelected=nil
        UI.reconciliationNotice=nil
        UI:RefreshReconciliationDialog()
    end)
    local page=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    page:SetPoint("LEFT",nextB,"RIGHT",12,0)
    page:SetWidth(116)
    self.reconciliationPageLabel=page
    self.reconciliationPrev=prev
    self.reconciliationNext=nextB

    local arm=self:CreateTextButton(f,"ARM NO RETRY",172)
    arm:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",21,22)
    arm:SetScript("OnClick",function()
        local choice=UI.reconciliationSelected
        if not choice then return end
        local ok,msg=NLL.LootReconciliation:Arm(choice.kind,choice.id)
        UI.reconciliationNotice=msg
        if NLL.Print then NLL:Print(msg) end
        UI:RefreshReconciliationDialog()
    end)
    local confirm=self:CreateTextButton(f,"CONFIRM CLOSE REVIEW",211)
    confirm:SetPoint("LEFT",arm,"RIGHT",9,0)
    confirm:SetScript("OnClick",function()
        local choice=UI.reconciliationSelected
        local armed=NLL.LootReconciliation and NLL.LootReconciliation.armed
        if not Identity(choice,armed) then
            UI.reconciliationNotice="Review selection changed. ARM this record again."
            NLL.LootReconciliation:Cancel()
            UI:RefreshReconciliationDialog()
            return
        end
        local ok,msg=NLL.LootReconciliation:ConfirmNoRetry()
        UI.reconciliationNotice=msg
        if NLL.Print then NLL:Print(msg) end
        UI:RefreshReconciliationDialog()
    end)
    self.reconciliationArm=arm
    self.reconciliationConfirm=confirm

    -- Only guild rows may open a SEPARATE self-inventory attestation.
    -- NO RETRY and recipient bag evidence must never share a confirm click.
    local bags=self:CreateTextButton(f,"My Bag Receipt",114)
    bags:SetPoint("LEFT",confirm,"RIGHT",6,0)
    bags:SetScript("OnClick",function()
        local selected=UI.reconciliationSelected
        if not selected or selected.kind~="GUILD" or
           not NLL.GuildRecipientReceipt or
           not UI.OpenGuildRecipientReceiptDialog then return end
        -- An old guild receipt belongs to its EXACT recipient. A
        -- different character may inspect NO RETRY, but must never
        -- be invited into the recipient's own-bag confirmation flow.
        local permitted=NLL.GuildRecipientReceipt:CanAttest(selected.id)
        if not permitted then return end
        NLL.LootReconciliation:Cancel()
        UI.reconciliationSelected=nil
        f:Hide()
        UI:OpenGuildRecipientReceiptDialog(selected.id)
    end)
    self.reconciliationBagReceipt=bags

    local close=self:CreateTextButton(f,"Close / Cancel",155)
    close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-21,22)
    close:SetScript("OnClick",function()
        if NLL.LootReconciliation then NLL.LootReconciliation:Cancel() end
        UI.reconciliationSelected=nil
        UI.reconciliationNotice=nil
        f:Hide()
    end)
    self.reconciliationClose=close
    self.reconciliationDialog=f
    f:Hide()
end

function UI:RefreshReconciliationDialog()
    if not self.reconciliationDialog or not NLL.LootReconciliation then return end
    local ledger=NLL.LootReconciliation
    local rows=ledger:List()
    local pages=math.max(1,math.ceil(#rows/PER_PAGE))
    self.reconciliationPage=math.max(1,math.min(pages,self.reconciliationPage or 1))
    local page=self.reconciliationPage
    self.reconciliationPageLabel:SetText(
        "Page "..page.."/"..pages.." ("..#rows..")")
    if page<=1 then self.reconciliationPrev:Disable()
    else self.reconciliationPrev:Enable() end
    if page>=pages then self.reconciliationNext:Disable()
    else self.reconciliationNext:Enable() end
    local active
    for i=1,PER_PAGE do
        local line=self.reconciliationRows[i]
        local item=rows[(page-1)*PER_PAGE+i]
        if item then
            line.name:SetText(Name(item))
            line.detail:SetText(State(item))
            line.pick.record={kind=item.kind,id=item.id}
            line.pick.label:SetText(
                Identity(item,self.reconciliationSelected) and "Selected" or "Select")
            if Identity(item,self.reconciliationSelected) then active=item end
            line.panel:Show()
        else
            line.pick.record=nil
            line.panel:Hide()
        end
    end
    -- Never use a stale page selection or a previously armed different row.
    if not active then
        self.reconciliationSelected=nil
        ledger:Cancel()
    end
    if self.reconciliationBagReceipt then
        local permitted=active and active.kind=="GUILD" and
            NLL.GuildRecipientReceipt and
            NLL.GuildRecipientReceipt.CanAttest and
            self.OpenGuildRecipientReceiptDialog and
            NLL.GuildRecipientReceipt:CanAttest(active.id)
        if permitted then self.reconciliationBagReceipt:Enable()
        else self.reconciliationBagReceipt:Disable() end
    end
    local armed=ledger.armed
    local matching=active and not active.reviewed and
        active.receipt~="OBTAINED"
    if matching and not armed then self.reconciliationArm:Enable()
    else self.reconciliationArm:Disable() end
    local fresh=matching and Identity(active,armed) and
        type(armed.at)=="number" and
        (GetTime and GetTime() or 0)-armed.at<=15
    if fresh then self.reconciliationConfirm:Enable()
    else self.reconciliationConfirm:Disable() end
    -- A completed roll is not necessarily a physical award attempt.
    -- Empty reconciliation is expected when no uncertain attempts exist.
    -- Explain the difference rather than presenting an apparently dead UI.
    if #rows==0 then
        self.reconciliationStatus:SetText(
            "No delivery investigations found. Close this window; "..
            "use Award History > Info to review a saved winner receipt.")
    else
        self.reconciliationStatus:SetText(tostring(self.reconciliationNotice or
            (not active and "Select a request. No status or item is changed." or
             (active.reviewed and "This original attempt remains permanently locked." or
              active.receipt=="OBTAINED" and
              "Recipient receipt already confirmed. Do not close as unknown." or
              "Selected request. Click ARM NO RETRY, then CONFIRM within 15 seconds."))))
    end
end

function UI:OpenReconciliationDialog(kind,identifier)
    self:CreateReconciliationDialog()
    NLL.LootReconciliation:Cancel()
    self.reconciliationPage=1
    self.reconciliationSelected=nil
    self.reconciliationNotice=nil
    if kind and identifier then
        local rows=NLL.LootReconciliation:List()
        for index,row in ipairs(rows) do
            if row.kind==kind and row.id==identifier then
                self.reconciliationPage=math.ceil(index/PER_PAGE)
                self.reconciliationSelected={kind=kind,id=identifier}
                break
            end
        end
    end
    self:RefreshReconciliationDialog()
    self.reconciliationDialog:Show()
end
