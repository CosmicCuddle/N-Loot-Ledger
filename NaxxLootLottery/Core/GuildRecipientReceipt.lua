-- Guild recipient-self inventory attestation: additive, human-evidence-only ledger.
-- Does NOT resolve NO RETRY, change transfer history, mark OBTAINED, grant,
-- or unblock any physical or automatic award. Bag count is NOT source proof.
local NLL=NaxxLootLottery
NLL.GuildRecipientReceipt=NLL.GuildRecipientReceipt or {}
local R=NLL.GuildRecipientReceipt
R.armed=nil
local MAX_ARM=15
local function Now()
    return GetTime and GetTime() or nil
end
local function Actor()
    return UnitName and UnitName("player") or nil
end
local function Same(a,b)
    -- Require the exact client character name, not a guessed realm-stripped
    -- alias. An ambiguity MUST NOT authorize someone else's bag assertion.
    return type(a)=="string" and type(b)=="string" and a~="" and
        string.lower(a)==string.lower(b)
end
local function Attempt(s)
    return s=="AWARD_REQUESTED" or s=="AWARD_OUTCOME_UNKNOWN" or
        s=="LOOT_SLOT_CLEARED"
end
local function Book()
    return NLL.db and NLL.db.guildRecipientReceiptAudit
end
function R:IsRecorded(index)
    for _,record in ipairs(Book() or {}) do
        if type(record)=="table" and record.auditIndex==index and
           record.action=="RECIPIENT_SELF_ATTESTED_BAGS" then
            return true,record
        end
    end
    return false,nil
end
function R:List()
    local list={}
    for index,row in ipairs(NLL.db and NLL.db.guildLootTransferAudit or {}) do
        if type(row)=="table" then
            local confirmed=self:IsRecorded(index)
            list[#list+1]={
                auditIndex=index,itemID=row.itemID,itemLink=row.itemLink,
                quantity=row.quantity,recipient=row.recipient,
                status=row.status,slotIndex=row.slotIndex,
                selfAttested=confirmed,
                noRetry=row.reconciliationStatus=="CLOSED_NO_RETRY",
            }
        end
    end
    return list
end
function R:Cancel()
    self.armed=nil
end
function R:CanAttest(index)
    if type(index)~="number" or index<1 or index%1~=0 or
       index>1000000 or not NLL.db or
       type(NLL.db.guildLootTransferAudit)~="table" or
       type(NLL.db.guildRecipientReceiptAudit)~="table" then
        return false,"Select a recorded guild transfer from your own client."
    end
    local row=NLL.db.guildLootTransferAudit[index]
    if type(row)~="table" or not Attempt(row.status) then
        return false,"Only previous unverified physical attempts may be checked."
    end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Fake raids cannot attest real inventory."
    end
    if not Same(Actor(),row.recipient) then
        return false,"Only the EXACT intended recipient may check their own bags."
    end
    if self:IsRecorded(index) then
        return false,"This guild attempt already has a recipient self-attestation."
    end
    local id=tonumber(row.itemID)
    local qty=tonumber(row.quantity)
    if not id or id<1 or id%1~=0 or not qty or qty<1 or
       qty%1~=0 or qty>100000 or
       type(row.itemLink)~="string" or
       tonumber(row.itemLink:match("item:(%d+)"))~=id or
       type(row.slotIndex)~="number" or row.slotIndex<1 or
       row.slotIndex%1~=0 then
        return false,"Old attempt lacks consistent item, quantity or slot evidence."
    end
    local now=Now()
    if type(now)~="number" or type(GetItemCount)~="function" then
        return false,"Read-only bag count is unavailable; do not guess receipt."
    end
    local ok,inventory=pcall(GetItemCount,id,false,false)
    if not ok or type(inventory)~="number" or inventory<qty then
        return false,"Your own bags do not currently show this quantity; do not attest."
    end
    return true,row,inventory
end
function R:Arm(index)
    self:Cancel()
    local ok,row,bags=self:CanAttest(index)
    if not ok then return false,row end
    local now=Now()
    self.armed={
        index=index,row=row,itemID=row.itemID,itemLink=row.itemLink,
        quantity=row.quantity,slotIndex=row.slotIndex,
        status=row.status,recipient=row.recipient,
        noRetry=row.reconciliationStatus,operator=row.operator,
        when=row.when,actor=Actor(),startedAt=now,
    }
    return true,"ARMED: Your bags currently contain "..tostring(bags)..
        " of "..row.itemLink..". Only if YOU checked this item, "..
        "CONFIRM within 15 seconds. This is a HUMAN assertion, "..
        "not proof of which corpse supplied it; NO item can be retried."
end
function R:Confirm()
    local armed=self.armed
    self:Cancel()
    local now=Now()
    if not armed or type(now)~="number" or
       now<armed.startedAt or now-armed.startedAt>MAX_ARM then
        return false,"No active recipient confirmation (or expired); nothing changed."
    end
    if not Same(Actor(),armed.actor) then
        return false,"The acting client changed; confirmation cancelled."
    end
    local ok,row,bags=self:CanAttest(armed.index)
    if not ok then return false,row end
    if row~=armed.row or row.itemID~=armed.itemID or
       row.itemLink~=armed.itemLink or row.quantity~=armed.quantity or
       row.slotIndex~=armed.slotIndex or row.status~=armed.status or
       row.recipient~=armed.recipient or
       row.reconciliationStatus~=armed.noRetry or
       row.operator~=armed.operator or row.when~=armed.when then
        return false,"Historical attempt changed while armed; no receipt was recorded."
    end
    if self:IsRecorded(armed.index) then
        return false,"This request was already self-attested; no duplicates."
    end
    local entry={
        auditIndex=armed.index,action="RECIPIENT_SELF_ATTESTED_BAGS",
        itemID=row.itemID,itemLink=row.itemLink,quantity=row.quantity,
        slotIndex=row.slotIndex,recipient=row.recipient,actor=Actor(),
        originalStatus=row.status,
        originalNoRetry=row.reconciliationStatus=="CLOSED_NO_RETRY",
        observedBagCount=bags,
        evidence="SELF_CHECKED_BAGS_PLUS_NON_UNIQUE_ITEM_COUNT",
        sourceVerified=false,deliveryServerVerified=false,
        grantsAuthorized=false,
        at=date and date("%Y-%m-%d %H:%M:%S") or "unknown",
        note="Manual statement only. Bag contents may predate the attempt; "..
            "original history, uncertainty and no-retry lock stay unchanged.",
    }
    table.insert(NLL.db.guildRecipientReceiptAudit,entry)
    -- Deliberately no write to guildLootTransferAudit, LootReceiptTracker,
    -- lootReconciliationAudit, Gear Plans, localWishlists or attempt locks.
    return true,"Recipient self-attestation RECORDED separately. "..
        "Original item is still locked; delivery origin remains unverified."
end
