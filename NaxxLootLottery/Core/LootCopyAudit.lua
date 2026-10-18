-- NLL / AzerothCore WoW 3.3.5a: grouped physical-copy risk AUDIT ONLY.
-- Visible slots, stack amounts, target hints, and player acknowledgement
-- cannot prove a new corpse, item instance, verified delivery or safe retry.
-- This module never unlocks historical Master Loot attempts.
local NLL=NaxxLootLottery
NLL.LootCopyAudit=NLL.LootCopyAudit or {}
local A=NLL.LootCopyAudit

local function IsPositiveInteger(number)
    return type(number)=="number" and number>0 and number%1==0
end

function A:Inspect()
    local audit={
        mode="READ_ONLY",client="WRATH_335A",items={},distinctItemIDs=0,
        visibleSlots=0,visibleUnits=0,heldItemIDs=0,
        perSourceVerified=false,physicalCopyVerified=false,
        receiptVerified=false,uniqueEquippedVerified=false,
        multiCopyPlanSupported=false,
        canUnlock=false,canReroll=false,canRetry=false,
        canAward=false,autoTransferAuthorized=false,
        message="No authenticated corpse/item-copy identity available.",
    }
    if not NLL.LootSourceDiagnostics or
       type(NLL.LootSourceDiagnostics.Inspect)~="function" then
        audit.message="Loot-source diagnostics unavailable. No copy audit."
        return audit
    end
    local source=NLL.LootSourceDiagnostics:Inspect()
    if type(source)~="table" or
       source.sourceVerified~=false or source.canUnlock~=false or
       source.autoTransferAuthorized~=false or
       type(source.items)~="table" then
        audit.message="Unsafe or invalid source data refused; no copy identity."
        return audit
    end
    if #source.items==0 then
        -- Do not display previous loot as currently present. Historical
        -- attempt flags remain untouched in their original saved audits.
        audit.message="No independently observed live loot items. "..
            "No source proof and no authorization to retry."
        return audit
    end
    local groups={}
    for _,entry in ipairs(source.items) do
        if type(entry)=="table" and IsPositiveInteger(entry.itemID)
           and IsPositiveInteger(entry.slotIndex) and
           entry.sourceVerified==false and
           entry.canUnlock==false and
           entry.transferAuthorized==false then
            local id=entry.itemID
            local row=groups[id]
            if not row then
                row={
                    itemID=id,visibleSlots=0,visibleStackUnits=0,
                    maxStackInOneSlot=0,
                    priorGuildAttempt=false,priorWinnerAttempt=false,
                    status="UNVERIFIED_SOURCE",
                    sourceVerified=false,uniqueEquippedVerified=false,
                    physicalCopyVerified=false,recipientReceiptVerified=false,
                    separateCorpseVerified=false,
                    canUnlock=false,canRetry=false,
                    canAward=false,autoTransferAuthorized=false,
                    allowedAdditionalWishCopies=0,
                }
                groups[id]=row
            end
            local quantity=entry.quantity
            if not IsPositiveInteger(quantity) then quantity=1 end
            -- Report a displayed stack count, not verified physical
            -- copies. Stack quantity is never a number of safe awards.
            row.visibleSlots=row.visibleSlots+1
            row.visibleStackUnits=row.visibleStackUnits+quantity
            row.maxStackInOneSlot=math.max(
                row.maxStackInOneSlot,quantity)
            row.priorGuildAttempt=row.priorGuildAttempt or
                entry.priorGuildAttempt==true
            row.priorWinnerAttempt=row.priorWinnerAttempt or
                entry.priorWinnerAttempt==true
            audit.visibleSlots=audit.visibleSlots+1
            audit.visibleUnits=audit.visibleUnits+quantity
        end
    end
    for _,row in pairs(groups) do
        row.hasPreviousAttempt=row.priorGuildAttempt or
            row.priorWinnerAttempt
        row.multiSlot=(row.visibleSlots>1)
        row.stacked=(row.maxStackInOneSlot>1)
        if row.hasPreviousAttempt then
            row.status="PRIOR_ATTEMPT_HELD"
            audit.heldItemIDs=audit.heldItemIDs+1
        elseif row.multiSlot then
            row.status="MULTIPLE_SLOTS_UNVERIFIED"
        elseif row.stacked then
            row.status="STACK_QUANTITY_UNVERIFIED"
        end
        audit.items[#audit.items+1]=row
    end
    table.sort(audit.items,function(x,y)return x.itemID<y.itemID end)
    audit.distinctItemIDs=#audit.items
    audit.message="Copy audit READ ONLY: "..audit.distinctItemIDs..
        " item ID(s), "..audit.visibleSlots.." visible slot(s), "..
        audit.visibleUnits.." displayed stack unit(s), "..
        audit.heldItemIDs.." prior item-ID hold(s). "..
        "Stacks/slots are NOT independently verified copies. "..
        "NO RETRY and all old awards stay locked."
    return audit
end

function A:Report()
    local result=self:Inspect()
    local out={result.message}
    local count=0
    for _,entry in ipairs(result.items) do
        if entry.hasPreviousAttempt or entry.multiSlot or entry.stacked then
            out[#out+1]="Item "..entry.itemID..": slots "..
                entry.visibleSlots..", displayed units "..
                entry.visibleStackUnits..", "..
                (entry.hasPreviousAttempt and "PRIOR ATTEMPT HELD; " or
                 entry.multiSlot and "REPEATED ID UNVERIFIED; " or
                 "STACK ONLY UNVERIFIED; ")..
                "NO VERIFIED NEW COPY; NO RETRY."
            count=count+1
            if count>=6 then
                out[#out+1]="Additional item IDs omitted; "..
                    "NO attempts are released."
                break
            end
        end
    end
    if count==0 then
        out[#out+1]="No duplicated/held item ID shown; this is still "..
            "NOT a verified loot source or recipient receipt."
    end
    out[#out+1]="Multiple wishlist copies remain unsupported. "..
        "Use /nll lootsource for target-hint context (never proof)."
    return out
end
