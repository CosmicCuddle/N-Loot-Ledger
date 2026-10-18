-- Guild Loot Reconciliation: confirmation of actual recipient inventory.
-- This file CANNOT issue GiveMasterLoot or cancel a historical audit attempt.
-- The exact itemID+slot remains non-retryable even after reconciliation:
-- Wrath 3.3.5a has no trustworthy physical corpse source GUID.
local NLL=NaxxLootLottery
NLL.GuildLootReconciliation=NLL.GuildLootReconciliation or {}
local R=NLL.GuildLootReconciliation
R.armed=nil
local function Now()return GetTime and GetTime() or 0 end
local function Identity(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function History()
    return NLL.db and NLL.db.guildLootTransferAudit
end
local function Pending(status)
    return status=="AWARD_REQUESTED" or
        status=="AWARD_OUTCOME_UNKNOWN" or
        status=="LOOT_SLOT_CLEARED"
end
function R:List()
    local list={}
    for index,row in ipairs(History() or {}) do
        if type(row)=="table" then
            list[#list+1]={
                index=index,itemID=row.itemID,
                recipient=row.recipient,status=row.status,
                itemLink=row.itemLink,quantity=row.quantity,
                slotIndex=row.slotIndex,
                when=row.when
            }
        end
    end
    return list
end
function R:CanVerify(index)
    local history=History()
    if type(index)~="number" or index%1~=0 or index<1 or
       not history or type(history[index])~="table" then
        return false,"Select a recorded guild loot request."
    end
    local row=history[index]
    if row.status=="RECIPIENT_CONFIRMED" then
        return false,"This recipient already confirmed the item. No duplicate."
    end
    if not Pending(row.status) then
        return false,"Only unverified/cleared requests may be reconciled."
    end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Fake mode cannot verify a real physical item."
    end
    local actor=UnitName and UnitName("player")
    -- The intended recipient is the real raid leader, who can personally
    -- inspect THEIR OWN bags even after leaving a raid. Not an officer
    -- attesting another player's bags, and not a remote addon whisper.
    if Identity(actor)=="" or Identity(actor)~=Identity(row.recipient) then
        return false,"Only the intended raid leader recipient may confirm their own inventory."
    end
    if not row.itemID or not row.itemLink or
       type(row.slotIndex)~="number" or not row.quantity or
       type(row.recipient)~="string" then
        return false,"Recorded transfer fields are incomplete; manual investigation only."
    end
    return true,row
end
function R:Arm(index)
    self.armed=nil
    local ok,row=self:CanVerify(index)
    if not ok then return false,row end
    self.armed={index=index,itemID=row.itemID,link=row.itemLink,
        recipient=row.recipient,quantity=row.quantity,
        originalStatus=row.status,startedAt=Now()}
    return true,"Check your OWN bags for "..row.itemLink..
        " x"..row.quantity..", then CONFIRM RECEIVED within 15 seconds."
end
function R:Confirm(index)
    local a=self.armed
    self.armed=nil
    if not a or a.index~=index or Now()-a.startedAt>15 then
        return false,"Confirmation missing/expired; no award state changed."
    end
    local ok,row=self:CanVerify(index)
    if not ok then return false,row end
    if row.itemID~=a.itemID or row.itemLink~=a.link or
       row.quantity~=a.quantity or
       Identity(row.recipient)~=Identity(a.recipient) or
       row.status~=a.originalStatus then
        return false,"Audit record changed; receipt verification was cancelled."
    end
    row.priorStatus=row.status
    row.status="RECIPIENT_CONFIRMED"
    row.confirmedBy=UnitName("player")
    row.confirmedAt=date and date("%Y-%m-%d %H:%M:%S") or "unknown"
    row.evidence="RECIPIENT_CHECKED_OWN_INVENTORY"
    row.note="Intended guild recipient manually confirmed their inventory; "..
        "no server receipt proved. Original item+slot retry remains blocked."
    if NLL.GuildLootTransfer then
        for slot,request in pairs(NLL.GuildLootTransfer.liveRequests or {}) do
            if request.row==row then
                NLL.GuildLootTransfer.liveRequests[slot]=nil
            end
        end
    end
    return true,"Guild recipient confirmed this item in their own bags. "..
        "No further transfer was attempted; duplicate protection remains."
end
function R:Cancel()
    self.armed=nil
end
