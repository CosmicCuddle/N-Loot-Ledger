-- Guild Master Loot request audit reconciliation. This is a HUMAN
-- attestation ONLY. Even a cleared slot does NOT prove recipient receipt.
-- Never sends an item, creates a retry token, or resets WasAttempted.
local NLL=NaxxLootLottery
NLL.GuildLootReconcile=NLL.GuildLootReconcile or {}
local R=NLL.GuildLootReconcile
R.review=nil
local ARM_SECONDS=15
local function Key(s)
    return string.lower((tostring(s or ""):match("^([^%-]+)") or ""))
end
local function Now()return GetTime and GetTime() or 0 end
local function Wall()
    return date and date("%Y-%m-%d %H:%M:%S") or "unknown"
end
local unresolved={
    AWARD_REQUESTED=true,AWARD_OUTCOME_UNKNOWN=true,
    LOOT_SLOT_CLEARED=true,INVESTIGATION_HOLD=true,
}
function R:GetRows()
    local list=NLL.db and NLL.db.guildLootTransferAudit
    local output={}
    for index,row in ipairs(type(list)=="table" and list or {}) do
        if type(row)=="table" then
            output[#output+1]={
                index=index,itemID=row.itemID,itemLink=row.itemLink,
                status=row.status,recipient=row.recipient,
                actor=row.actor,when=row.when,
                slotIndex=row.slotIndex,quantity=row.quantity,
            }
        end
    end
    return output
end
function R:Cancel()self.review=nil end
function R:CanReview(index)
    if type(index)~="number" or index<1 or index%1~=0 then
        return false,"Choose an exact historical transfer record."
    end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Fake raid active. Real transfer history is read-only."
    end
    local db=NLL.db
    local row=db and db.guildLootTransferAudit and
        db.guildLootTransferAudit[index]
    if type(row)~="table" then
        return false,"No saved guild transfer request exists at this index."
    end
    if not unresolved[row.status] then
        return false,"This request is already reconciled or not eligible."
    end
    local actor=UnitName and UnitName("player")
    if not actor or Key(actor)=="" or
       not row.actor or Key(row.actor)~=Key(actor) then
        return false,"Only the original recorded Master Looter can "..
            "reconcile this attempt. Older unowned records need audit review."
    end
    if type(row.itemID)~="number" or type(row.slotIndex)~="number" or
       not row.recipient or Key(row.recipient)=="" or
       type(row.itemLink)~="string" then
        return false,"Original transfer identity is incomplete; leave on hold."
    end
    -- Reconciliation of old transfers is permitted after the raid, but
    -- never while a new transfer is armed or an unfinished lottery exists.
    if NLL.GuildLootTransfer and NLL.GuildLootTransfer.review then
        return false,"Cancel the active guild transfer before reconciliation."
    end
    local active=NLL.TicketLottery and NLL.TicketLottery.active
    if active and active.status~="COMPLETE" and
       active.status~="CANCELLED" and
       active.status~="INVALIDATED" then
        return false,"An active ticket lottery must finish first."
    end
    return true,row
end
function R:Review(index)
    self:Cancel()
    local ok,row=self:CanReview(index)
    if not ok then return false,row end
    self.review={index=index,row=row,status=row.status,
        itemID=row.itemID,itemLink=row.itemLink,
        slotIndex=row.slotIndex,recipient=row.recipient}
    return true,"Inspect recipient "..row.recipient.." / item "..
        row.itemID..". Check their inventory or server records "..
        "before choosing a reconciliation outcome."
end
function R:Arm(result)
    local v=self.review
    if not v or (result~="RECEIVED" and result~="UNVERIFIED") then
        return false,"Review a transfer first and choose the outcome."
    end
    local ok,row=self:CanReview(v.index)
    if not ok then self:Cancel();return false,row end
    if row~=v.row or row.status~=v.status or
       row.itemID~=v.itemID or row.itemLink~=v.itemLink or
       row.slotIndex~=v.slotIndex or
       row.recipient~=v.recipient then
        self:Cancel()
        return false,"Original record changed. Review again."
    end
    v.result=result
    v.armedAt=Now()
    if result=="RECEIVED" then
        return true,"ARMED: You independently verified "..
            v.recipient.." RECEIVED item "..v.itemID..
            ". CONFIRM RECEIPT within 15 seconds; "..
            "this will NOT reaward the item."
    end
    return true,"ARMED: Delivery could NOT be verified. "..
        "CONFIRM HOLD within 15 seconds; this leaves all "..
        "transfer blocks in place."
end
function R:Commit()
    local v=self.review
    if not v or not v.result or not v.armedAt then
        return false,"Reconciliation not armed."
    end
    if Now()-v.armedAt>ARM_SECONDS or Now()<v.armedAt then
        self:Cancel()
        return false,"Confirmation expired; review the transfer again."
    end
    local ok,row=self:CanReview(v.index)
    if not ok then self:Cancel();return false,row end
    if row~=v.row or row.status~=v.status or
       row.itemID~=v.itemID or row.itemLink~=v.itemLink or
       row.slotIndex~=v.slotIndex or
       row.recipient~=v.recipient then
        self:Cancel()
        return false,"Audit row changed; reconciliation cancelled."
    end
    local final=v.result=="RECEIVED" and
        "RECONCILED_RECEIVED" or "INVESTIGATION_HOLD"
    local actor=UnitName and UnitName("player") or "Unknown"
    local record={
        requestIndex=v.index,itemID=row.itemID,
        itemLink=row.itemLink,slotIndex=row.slotIndex,
        quantity=row.quantity,recipient=row.recipient,
        operator=actor,when=Wall(),initialStatus=v.status,
        finalStatus=final,evidence=v.result=="RECEIVED" and
            "OPERATOR_CHECKED_RECIPIENT_INVENTORY" or
            "OUTCOME_STILL_UNVERIFIED",
        noRegrant=true,
    }
    local audit=NLL.db.guildLootReconciliations
    if type(audit)~="table" then
        self:Cancel()
        return false,"Reconciliation ledger missing; no records changed."
    end
    audit[#audit+1]=record
    row.status=final
    row.reconciledBy=actor
    row.reconciledAt=record.when
    row.reconciliationEvidence=record.evidence
    row.note=v.result=="RECEIVED" and
        "Operator confirmed inventory. No automatic item or retry." or
        "Delivery still UNVERIFIED: hold/duplicate protections remain."
    self:Cancel()
    if NLL.UI and NLL.UI.RefreshGuildReconciliation then
        NLL.UI:RefreshGuildReconciliation()
    end
    return true,final=="RECONCILED_RECEIVED" and
        "Delivery RECORDED as operator-verified. "..
        "The original item/slot remains permanently protected." or
        "Investigation HOLD recorded. No new transfers or retries allowed."
end
