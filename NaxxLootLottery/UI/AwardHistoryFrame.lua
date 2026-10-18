-- Naxxramas Loot Ledger v0.1.0.25 - readable, audited real award events.
-- Simulation never writes this table.
local NLL = NaxxLootLottery
local UI = NLL.UI
local PAGE_ROWS = 6
local function Label(row)
    local receipt=NLL.LootReceiptTracker and
        NLL.LootReceiptTracker:Get(row.dropUID)
    if row.status=="ROLL_WINNER_ONLY" then
        return "Won roll - unverified"
    end
    if receipt and receipt.status=="OBTAINED" then
        if receipt.remoteSyncStatus=="ACKNOWLEDGED" then
            return "Obtained + player ACK"
        end
        if receipt.remoteSyncStatus=="AWAITING_PLAYER" or
           receipt.remoteSyncStatus=="WAITING_FOR_PLAYER" then
            return "Obtained (ACK pending)"
        end
        return "OBTAINED"
    end
    local s = row.status or 'UNKNOWN'
    if s == 'LOOT_SLOT_CLEARED' then return 'Slot cleared' end
    if s == 'LEADER_REPORTED' then return 'Leader reported' end
    if s == 'AWARD_REQUESTED' then return 'Request sent' end
    if s == 'AWARD_OUTCOME_UNKNOWN' then return 'Outcome unknown' end
    return s
end
function UI:CreateAwardHistoryContent(parent)
    local panel=CreateFrame('Frame',nil,parent)
    panel:SetAllPoints(parent)
    local heading=panel:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    heading:SetPoint('TOPLEFT',panel,'TOPLEFT',8,-9)
    heading:SetText('Roll Winners & Loot Award History')
    local caution=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    caution:SetPoint('TOPLEFT',heading,'BOTTOMLEFT',0,-12)
    caution:SetWidth(680)
    caution:SetJustifyH('LEFT')
    caution:SetText('Winning a roll is NOT delivery. Physical awards and recipient receipts are separate; test draws hidden.')
    -- Neither button changes a ticket, award, receipt, or physical attempt.
    local newRun=self:CreateTextButton(panel,'New Run View',133)
    newRun:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-4,-6)
    local all=self:CreateTextButton(panel,'All History',105)
    all:SetPoint('RIGHT',newRun,'LEFT',-7,0)
    newRun:SetScript('OnClick',function()
        if not NLL.RaidHistoryView then return end
        local ok,message
        if NLL.RaidHistoryView.pending then
            ok,message=NLL.RaidHistoryView:ConfirmNewRun()
            newRun.label:SetText('New Run View')
            if ok then UI.awardHistoryShowAll=false end
        else
            ok,message=NLL.RaidHistoryView:ArmNewRun()
            if ok then newRun.label:SetText('CONFIRM NEW VIEW') end
        end
        if NLL.Print then NLL:Print(message) end
        UI.awardHistoryPage=1
        UI:RefreshAwardHistory()
    end)
    all:SetScript('OnClick',function()
        if NLL.RaidHistoryView then NLL.RaidHistoryView:Cancel() end
        newRun.label:SetText('New Run View')
        UI.awardHistoryShowAll=not UI.awardHistoryShowAll
        UI.awardHistoryPage=1
        UI:RefreshAwardHistory()
    end)
    self.awardHistoryNewRun=newRun
    self.awardHistoryAll=all
    local header=CreateFrame('Frame',nil,panel)
    header:SetPoint('TOPLEFT',panel,'TOPLEFT',4,-68)
    header:SetPoint('TOPRIGHT',panel,'TOPRIGHT',-4,-68)
    header:SetHeight(24)
    self:RegisterSkinnedFrame(header,'header')
    local function Caption(text,offset,width)
        local f=header:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
        f:SetPoint('LEFT',header,'LEFT',offset,0)
        f:SetWidth(width)
        f:SetJustifyH('LEFT')
        f:SetText(text)
    end
    Caption('Item / ID',12,206)
    Caption('Winner',220,116)
    Caption('State',345,156)
    Caption('Time',508,110)
    self.awardHistoryRows={}
    for i=1,PAGE_ROWS do
        local line=CreateFrame('Frame',nil,panel)
        line:SetPoint('TOPLEFT',header,'BOTTOMLEFT',0,-(i-1)*34)
        line:SetPoint('TOPRIGHT',header,'BOTTOMRIGHT',0,-(i-1)*34)
        line:SetHeight(32)
        self:RegisterSkinnedFrame(line,i%2==0 and 'rowAlt' or 'row')
        local function Field(x,width)
            local f=line:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
            f:SetPoint('LEFT',line,'LEFT',x,0)
            f:SetWidth(width)
            f:SetJustifyH('LEFT')
            return f
        end
        local item=Field(12,200)
        local winner=Field(220,116)
        local state=Field(345,156)
        local when=Field(508,110)
        local details=self:CreateTextButton(line,'Info',53)
        details:SetPoint('RIGHT',line,'RIGHT',-5,0)
        details:SetScript('OnClick',function()
            if line.record then
                UI.awardHistoryDetail:SetText(
                    tostring(line.record.itemName)..' -> '..tostring(line.record.winner)..
                    ' | '..(line.record.selectionType=='GREED' and 'GREED' or
                        ('NEED'..(line.record.priorityTier and
                         (' Tier '..tostring(line.record.priorityTier)) or '')))..
                    ' | '..Label(line.record)..' | '..tostring(line.record.note or 'No note'))
                local pending=NLL.LootReceiptTracker and
                    NLL.LootReceiptTracker:Get(line.record.dropUID)
                if pending and pending.remoteSyncStatus then
                    UI.awardHistoryDetail:SetText(
                        UI.awardHistoryDetail:GetText()..
                        ' | Player-side receipt: '..pending.remoteSyncStatus)
                end
                if pending and pending.status=="WON_AWAITING_ITEM" and
                    UI.OpenReceiptReview then
                    UI:OpenReceiptReview(pending.dropUID)
                end
            end
        end)
        self.awardHistoryRows[i]={panel=line,item=item,winner=winner,state=state,
            when=when,details=details}
    end
    local prev=self:CreateTextButton(panel,'Previous',90)
    prev:SetPoint('TOPLEFT',header,'BOTTOMLEFT',5,-218)
    prev:SetScript('OnClick',function()
        UI.awardHistoryPage=math.max(1,(UI.awardHistoryPage or 1)-1)
        UI:RefreshAwardHistory()
    end)
    local nextButton=self:CreateTextButton(panel,'Next',70)
    nextButton:SetPoint('LEFT',prev,'RIGHT',8,0)
    nextButton:SetScript('OnClick',function()
        UI.awardHistoryPage=(UI.awardHistoryPage or 1)+1
        UI:RefreshAwardHistory()
    end)
    local investigate=self:CreateTextButton(panel,'Investigate Transfers',176)
    investigate:SetPoint('LEFT',nextButton,'RIGHT',12,0)
    investigate:SetScript('OnClick',function()
        if UI.OpenReconciliationDialog then UI:OpenReconciliationDialog() end
    end)
    self.awardHistoryInvestigate=investigate
    local pages=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    pages:SetPoint('LEFT',investigate,'RIGHT',10,0)
    pages:SetWidth(235)
    pages:SetJustifyH('LEFT')
    self.awardHistoryPrevious=prev
    self.awardHistoryNext=nextButton
    self.awardHistoryPageLabel=pages
    local detail=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    detail:SetPoint('TOPLEFT',prev,'BOTTOMLEFT',0,-18)
    detail:SetWidth(680)
    detail:SetJustifyH('LEFT')
    detail:SetText('A winner is not a receipt. New Run View hides earlier rows; All History restores them without deleting anything.')
    self.awardHistoryDetail=detail
    self.awardHistoryPage=1
    self.awardHistoryShowAll=false
    self.awardHistoryContent=panel
    self:RefreshAwardHistory()
end
function UI:RefreshAwardHistory()
    if not self.awardHistoryContent then return end
    local rows=NLL.RaidHistoryView and
        NLL.RaidHistoryView:Build(self.awardHistoryShowAll) or
        ((NLL.db and NLL.db.lootAwardHistory) or {})
    -- Preserve the original 3.3.5a Award History caller contract if a
    -- partial addon load or isolated historical test omits the new module.
    local totalPages=math.max(1,math.ceil(#rows/PAGE_ROWS))
    local page=math.min(math.max(1,self.awardHistoryPage or 1),totalPages)
    self.awardHistoryPage=page
    for i=1,PAGE_ROWS do
        local row=self.awardHistoryRows[i]
        local index=#rows-((page-1)*PAGE_ROWS+i-1)
        local data=rows[index]
        if data then
            row.panel.record=data
            row.item:SetText(tostring(data.itemName)..' ('..tostring(data.itemID)..')')
            row.winner:SetText(tostring(data.winner or 'Unknown'))
            row.state:SetText(Label(data))
            row.when:SetText(tostring(data.when or 'Unknown'))
            row.panel:Show()
        else
            row.panel.record=nil
            row.panel:Hide()
        end
    end
    local mode=self.awardHistoryShowAll and 'ALL' or 'THIS RUN'
    self.awardHistoryPageLabel:SetText(mode..' '..page..'/'..totalPages..
        ' ('..#rows..' event(s))')
    if self.awardHistoryAll and self.awardHistoryAll.label then
        self.awardHistoryAll.label:SetText(
            self.awardHistoryShowAll and 'This Run' or 'All History')
    end
    if page<=1 then self.awardHistoryPrevious:Disable() else self.awardHistoryPrevious:Enable() end
    if page>=totalPages then self.awardHistoryNext:Disable() else self.awardHistoryNext:Enable() end
end
