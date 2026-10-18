-- Recipient-only BAG SELF-ATTESTATION window, independent of NO RETRY.
-- Human evidence is NOT an item grant, WoW-delivery receipt or release gate.
local NLL=NaxxLootLottery
local UI=NLL.UI
local PER_PAGE=5
function UI:CreateGuildRecipientReceiptDialog()
    if self.guildRecipientReceiptDialog then return end
    local f=CreateFrame("Frame",nil,self.mainFrame)
    f:SetSize(712,430)
    f:SetPoint("CENTER",self.mainFrame,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+48)
    f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}})
    f:SetBackdropColor(.055,.065,.085,.99)
    f:SetBackdropBorderColor(.96,.72,.25,1)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",f,"TOP",0,-20)
    title:SetText("MY BAGS - GUILD RECEIPT ATTESTATION")
    local warning=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    warning:SetPoint("TOP",title,"BOTTOM",0,-9)
    warning:SetWidth(672)
    warning:SetJustifyH("CENTER")
    warning:SetText("ONLY the intended recipient checks their own bags. Bag count is NOT proof of source or delivery.")
    local note=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    note:SetPoint("TOP",warning,"BOTTOM",0,-12)
    note:SetWidth(672)
    note:SetJustifyH("CENTER")
    self.guildReceiptNotice=note
    self.guildReceiptRows={}
    for i=1,PER_PAGE do
        local row=CreateFrame("Frame",nil,f)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",20,-102-(i-1)*46)
        row:SetSize(672,42)
        self:RegisterSkinnedFrame(row,i%2==0 and "rowAlt" or "row")
        local name=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        name:SetPoint("TOPLEFT",row,"TOPLEFT",8,-5)
        name:SetWidth(526)
        name:SetJustifyH("LEFT")
        local desc=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        desc:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",8,5)
        desc:SetWidth(526)
        desc:SetJustifyH("LEFT")
        local select=self:CreateTextButton(row,"Select",104)
        select:SetPoint("RIGHT",row,"RIGHT",-6,0)
        select:SetScript("OnClick",function(button)
            NLL.GuildRecipientReceipt:Cancel()
            UI.guildReceiptSelected=button.auditIndex
            UI.guildReceiptMessage=nil
            UI:RefreshGuildRecipientReceiptDialog()
        end)
        self.guildReceiptRows[i]={frame=row,name=name,desc=desc,select=select}
    end
    local prev=self:CreateTextButton(f,"Previous",101)
    prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",20,62)
    prev:SetScript("OnClick",function()
        NLL.GuildRecipientReceipt:Cancel()
        UI.guildReceiptPage=math.max(1,(UI.guildReceiptPage or 1)-1)
        UI.guildReceiptSelected=nil
        UI.guildReceiptMessage=nil
        UI:RefreshGuildRecipientReceiptDialog()
    end)
    local nextButton=self:CreateTextButton(f,"Next",81)
    nextButton:SetPoint("LEFT",prev,"RIGHT",8,0)
    nextButton:SetScript("OnClick",function()
        NLL.GuildRecipientReceipt:Cancel()
        UI.guildReceiptPage=(UI.guildReceiptPage or 1)+1
        UI.guildReceiptSelected=nil
        UI.guildReceiptMessage=nil
        UI:RefreshGuildRecipientReceiptDialog()
    end)
    local pagination=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    pagination:SetPoint("LEFT",nextButton,"RIGHT",12,0)
    pagination:SetWidth(130)
    self.guildReceiptPages=pagination
    self.guildReceiptPrev=prev
    self.guildReceiptNext=nextButton
    local arm=self:CreateTextButton(f,"I CHECKED MY BAGS",186)
    arm:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",20,18)
    arm:SetScript("OnClick",function()
        local id=UI.guildReceiptSelected
        if not id then return end
        local ok,message=NLL.GuildRecipientReceipt:Arm(id)
        UI.guildReceiptMessage=message
        UI:RefreshGuildRecipientReceiptDialog()
        if NLL.Print then NLL:Print(message) end
    end)
    local confirm=self:CreateTextButton(f,"CONFIRM SELF-ATTESTATION",233)
    confirm:SetPoint("LEFT",arm,"RIGHT",10,0)
    confirm:SetScript("OnClick",function()
        local selected=UI.guildReceiptSelected
        local current=NLL.GuildRecipientReceipt.armed
        if not selected or not current or current.index~=selected then
            NLL.GuildRecipientReceipt:Cancel()
            UI.guildReceiptMessage="Selection changed. Arm again."
        else
            local ok,message=NLL.GuildRecipientReceipt:Confirm()
            UI.guildReceiptMessage=message
        end
        UI:RefreshGuildRecipientReceiptDialog()
        if NLL.Print then NLL:Print(UI.guildReceiptMessage) end
    end)
    local close=self:CreateTextButton(f,"Close / Cancel",147)
    close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-20,18)
    close:SetScript("OnClick",function()
        NLL.GuildRecipientReceipt:Cancel()
        UI.guildReceiptSelected=nil
        UI.guildReceiptMessage=nil
        f:Hide()
    end)
    self.guildReceiptArm=arm
    self.guildReceiptConfirm=confirm
    self.guildReceiptClose=close
    self.guildRecipientReceiptDialog=f
    f:Hide()
end

function UI:RefreshGuildRecipientReceiptDialog()
    if not self.guildRecipientReceiptDialog or not NLL.GuildRecipientReceipt then
        return
    end
    local r=NLL.GuildRecipientReceipt
    local list=r:List()
    local pages=math.max(1,math.ceil(#list/PER_PAGE))
    self.guildReceiptPage=math.min(pages,math.max(1,self.guildReceiptPage or 1))
    local page=self.guildReceiptPage
    self.guildReceiptPages:SetText("Page "..page.."/"..pages.." ("..#list..")")
    if page<=1 then self.guildReceiptPrev:Disable()
    else self.guildReceiptPrev:Enable() end
    if page>=pages then self.guildReceiptNext:Disable()
    else self.guildReceiptNext:Enable() end
    local selected
    for i=1,PER_PAGE do
        local row=self.guildReceiptRows[i]
        local data=list[(page-1)*PER_PAGE+i]
        if data then
            row.name:SetText("AUDIT "..data.auditIndex.."  "..tostring(data.itemID)..
                " x"..tostring(data.quantity or "?").."  -> "..
                tostring(data.recipient or "?"))
            row.desc:SetText(data.selfAttested and "SELF-ATTESTED (source unverified; item still locked)" or
                (data.noRetry and "NO RETRY reviewed; recipient proof remains separate" or
                 tostring(data.status).." - own bag check ONLY"))
            row.select.auditIndex=data.auditIndex
            row.select.label:SetText(
                data.auditIndex==self.guildReceiptSelected and "Selected" or "Select")
            row.frame:Show()
            if data.auditIndex==self.guildReceiptSelected then selected=data end
        else
            row.select.auditIndex=nil
            row.frame:Hide()
        end
    end
    if not selected then
        self.guildReceiptSelected=nil
        r:Cancel()
    end
    local can=selected and r:CanAttest(selected.auditIndex)
    local armed=r.armed
    local now=GetTime and GetTime() or 0
    local fresh=can and armed and selected and
        armed.index==selected.auditIndex and
        now>=armed.startedAt and now-armed.startedAt<=15
    if can and not armed then self.guildReceiptArm:Enable()
    else self.guildReceiptArm:Disable() end
    if fresh then self.guildReceiptConfirm:Enable()
    else self.guildReceiptConfirm:Disable() end
    -- Never leave both first-click and final confirmation available.
    -- A failed / expired bag check must visually disable both actions,
    -- not just be rejected by the backend on click.
    self.guildReceiptNotice:SetText(tostring(self.guildReceiptMessage or
        (selected and "Select YOUR prior request. Review bags; two clicks to attest only." or
         "Select a historical GUILD request. NO item will be awarded.")))
end

function UI:OpenGuildRecipientReceiptDialog(auditIndex)
    if NLL.LootReconciliation then NLL.LootReconciliation:Cancel() end
    self:CreateGuildRecipientReceiptDialog()
    NLL.GuildRecipientReceipt:Cancel()
    self.guildReceiptPage=1
    self.guildReceiptSelected=nil
    self.guildReceiptMessage=nil
    if type(auditIndex)=="number" then
        for i,row in ipairs(NLL.GuildRecipientReceipt:List()) do
            if row.auditIndex==auditIndex then
                self.guildReceiptPage=math.ceil(i/PER_PAGE)
                self.guildReceiptSelected=auditIndex
                break
            end
        end
    end
    self:RefreshGuildRecipientReceiptDialog()
    self.guildRecipientReceiptDialog:Show()
end
