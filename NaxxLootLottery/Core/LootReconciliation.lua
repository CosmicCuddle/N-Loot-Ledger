-- Naxxramas Loot Ledger: deliberate NO-RETRY reconciliation (non-awarding).
-- The client cannot verify physical delivery from GiveMasterLoot or a cleared slot.
-- Closing an investigation NEVER unlocks the original item, changes a winner,
-- confirms a recipient, edits Gear Plans or sends another Master Loot request.
local NLL=NaxxLootLottery
NLL.LootReconciliation=NLL.LootReconciliation or {}
local R=NLL.LootReconciliation
R.armed=nil
local ARM_SECONDS=15
local function Now() return GetTime and GetTime() or 0 end
local function Stamp() return date and date("%Y-%m-%d %H:%M:%S") or "unknown" end
local function Actor() return UnitName and UnitName("player") or nil end
local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function Allowed()
    return NLL.db and NLL.TicketLottery and
        NLL.TicketLottery.AuthorityAllowed and
        NLL.TicketLottery:AuthorityAllowed(false) and
        not (NLL.DebugSimulator and NLL.DebugSimulator:IsActive()) and
        Key(Actor())~=""
end
local function AttemptStatus(status)
    return status=="AWARD_REQUESTED" or status=="AWARD_OUTCOME_UNKNOWN" or
        status=="LOOT_SLOT_CLEARED"
end

function R:Get(kind,identifier)
    local db=NLL.db
    if not db then return nil end
    if kind=="WINNER" and type(identifier)=="string" and #identifier<=64 then
        -- Never guess an item from its ID alone. The immutable drop UID wins.
        local found
        for _,row in ipairs(db.lootAwardHistory or {}) do
            if row.dropUID==identifier and AttemptStatus(row.status) then
                if found then return nil end -- ambiguous historical references
                found=row
            end
        end
        return found
    elseif kind=="GUILD" and type(identifier)=="number" and
        identifier>0 and identifier%1==0 then
        local row=(db.guildLootTransferAudit or {})[identifier]
        if type(row)=="table" and AttemptStatus(row.status) then
            return row
        end
    end
    return nil
end

function R:List()
    local rows={}
    for _,row in ipairs(NLL.db and NLL.db.lootAwardHistory or {}) do
        if AttemptStatus(row.status) then
            rows[#rows+1]={kind="WINNER",id=row.dropUID,
                itemID=row.itemID,recipient=row.winner,
                status=row.status,reviewed=row.reconciliationStatus=="CLOSED_NO_RETRY",
                receipt=(NLL.LootReceiptTracker and
                    NLL.LootReceiptTracker:Get(row.dropUID) or {}).status}
        end
    end
    for index,row in ipairs(NLL.db and NLL.db.guildLootTransferAudit or {}) do
        if AttemptStatus(row.status) then
            rows[#rows+1]={kind="GUILD",id=index,
                itemID=row.itemID,recipient=row.recipient,
                status=row.status,reviewed=row.reconciliationStatus=="CLOSED_NO_RETRY",
                receipt=nil}
        end
    end
    return rows
end

function R:Cancel()
    self.armed=nil
end

-- First deliberate action: arm review. No state or item is changed.
function R:Arm(kind,identifier)
    self:Cancel()
    if not Allowed() then
        return false,"Real raid authority is required; fake raids are blocked."
    end
    local row=self:Get(kind,identifier)
    if not row or not tonumber(row.itemID) or tonumber(row.itemID)<1 then
        return false,"No unique, recorded uncertain award with that identifier."
    end
    if row.reconciliationStatus=="CLOSED_NO_RETRY" then
        return false,"Already reviewed. The original item remains permanently locked."
    end
    local receipt=kind=="WINNER" and NLL.LootReceiptTracker and
        NLL.LootReceiptTracker:Get(identifier)
    if receipt and receipt.status=="OBTAINED" then
        return false,"Recipient receipt already confirmed; no uncertainty to close."
    end
    self.armed={kind=kind,id=identifier,row=row,
        status=row.status,itemID=row.itemID,
        recipient=kind=="WINNER" and row.winner or row.recipient,
        at=Now(),actor=Actor()}
    return true,"REVIEW ARMED for "..kind.." "..tostring(identifier)..
        " (item "..tostring(row.itemID).."). Check records, then use "..
        "/nll reconcile confirm within 15 seconds. This ONLY closes review "..
        "as NO RETRY; it does NOT confirm delivery or permit a new award."
end

-- Second deliberate action: preserve immutable original status and append audit.
function R:ConfirmNoRetry()
    local armed=self.armed
    self:Cancel()
    if not armed or Now()-armed.at>ARM_SECONDS then
        return false,"Review absent or expired. Start again; nothing changed."
    end
    if not Allowed() or Key(Actor())~=Key(armed.actor) then
        return false,"Raid authority/actor changed; reconciliation cancelled."
    end
    local row=self:Get(armed.kind,armed.id)
    if not row or row~=armed.row or row.status~=armed.status or
        row.itemID~=armed.itemID or
        (armed.kind=="WINNER" and row.winner or row.recipient)~=armed.recipient or
        row.reconciliationStatus then
        return false,"Recorded attempt changed; reconciliation cancelled."
    end
    local receipt=armed.kind=="WINNER" and NLL.LootReceiptTracker and
        NLL.LootReceiptTracker:Get(armed.id)
    if receipt and receipt.status=="OBTAINED" then
        return false,"Receipt changed to OBTAINED; reconciliation cancelled."
    end
    if type(NLL.db.lootReconciliationAudit)~="table" then
        NLL.db.lootReconciliationAudit={}
    end
    local event={
        kind=armed.kind,identifier=armed.id,itemID=row.itemID,
        originalStatus=row.status,recipient=armed.recipient,
        actor=Actor(),when=Stamp(),action="CLOSED_NO_RETRY",
        note="Unverified outcome reviewed. Original award is never retryable. No receipt asserted.",
    }
    table.insert(NLL.db.lootReconciliationAudit,event)
    row.reconciliationStatus="CLOSED_NO_RETRY"
    row.reconciledBy=event.actor
    row.reconciledAt=event.when
    -- Critically retain status AWARD_OUTCOME_UNKNOWN / AWARD_REQUESTED /
    -- LOOT_SLOT_CLEARED: no change to receipt tracker, winner or award locks.
    return true,"Recorded NO RETRY review; original attempt remains locked. "..
        "Physical receipt is NOT confirmed and Gear Plans are unchanged."
end
