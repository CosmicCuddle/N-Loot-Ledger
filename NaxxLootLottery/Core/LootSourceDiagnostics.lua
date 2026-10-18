-- NLL WoW 3.3.5a corpse-source diagnostics (READ ONLY).
-- The 3.3.5a client lacks GetLootSourceInfo (added in 5.0.4).
-- UnitGUID("target") identifies only the CURRENTLY TARGETED UNIT:
-- it NEVER proves the loot source, physical item identity or a new corpse.
-- This module CANNOT unlock / retry an original item or call any loot API.
local NLL=NaxxLootLottery
NLL.LootSourceDiagnostics=NLL.LootSourceDiagnostics or {}
local D=NLL.LootSourceDiagnostics

local function ItemID(link)
    return type(link)=="string" and tonumber(link:match("item:(%d+)")) or nil
end

local function PriorGuild(id)
    for _,row in ipairs(NLL.db and NLL.db.guildLootTransferAudit or {}) do
        if type(row)=="table" and tonumber(row.itemID)==id then
            -- CLOSED_NO_RETRY retains the original attempt forever.
            return true
        end
    end
    return false
end

local function PriorWinner(id)
    for _,row in ipairs(NLL.db and NLL.db.lootAwardHistory or {}) do
        if type(row)=="table" and tonumber(row.itemID)==id and
           (row.status=="AWARD_REQUESTED" or
            row.status=="AWARD_OUTCOME_UNKNOWN" or
            row.status=="LOOT_SLOT_CLEARED") then
            return true
        end
    end
    return false
end

function D:Inspect()
    local result={
        mode="READ_ONLY",
        sourceVerified=false,canUnlock=false,autoTransferAuthorized=false,
        targetGUIDHint=nil,items={},itemSlots=0,priorAttemptHolds=0,
        repeatedSlots=0,
        message="No verified per-corpse identity is available on WoW 3.3.5a.",
    }
    if NLL.DebugSimulator and NLL.DebugSimulator.IsActive and
       NLL.DebugSimulator:IsActive() then
        result.message="Fake raid: no live loot-source evidence. NO RETRY remains."
        return result
    end
    if not NLL.LootDetection or not NLL.LootDetection.lootOpen or
       not NLL.TicketLottery or
       not NLL.TicketLottery.liveLootObserved then
        result.message="Real loot window closed or unverified. NO RETRY remains."
        return result
    end
    if type(GetNumLootItems)~="function" or
       type(GetLootSlotLink)~="function" then
        result.message="Wrath loot-slot APIs unavailable. No source verified."
        return result
    end
    -- This is NOT a loot-corpse GUID. The player may target a different
    -- creature, themselves, a live hostile, or nothing while looting.
    -- Never persist, compare as a lock key, or use to clear an attempt.
    if type(UnitGUID)=="function" then
        local ok,guid=pcall(UnitGUID,"target")
        if ok and type(guid)=="string" and guid~="" then
            result.targetGUIDHint=guid
        end
    end
    local counts={}
    local count=GetNumLootItems() or 0
    if type(count)~="number" or count<0 then count=0 end
    count=math.min(math.floor(count),200)
    for slot=1,count do
        local link=GetLootSlotLink(slot)
        local id=ItemID(link)
        if id then
            counts[id]=(counts[id] or 0)+1
            local oldGuild=PriorGuild(id)
            local oldWinner=PriorWinner(id)
            if oldGuild or oldWinner then
                result.priorAttemptHolds=result.priorAttemptHolds+1
            end
            local quantity=1
            if type(GetLootSlotInfo)=="function" then
                local _,_,qty=GetLootSlotInfo(slot)
                if type(qty)=="number" and qty>0 then
                    quantity=qty
                end
            end
            result.items[#result.items+1]={
                itemID=id,slotIndex=slot,quantity=quantity,
                repeatedInWindow=false,
                priorGuildAttempt=oldGuild,
                priorWinnerAttempt=oldWinner,
                -- The only permissible identity conclusion is UNKNOWN,
                -- even if a different target GUID or slot was observed.
                sourceVerified=false,canUnlock=false,
                transferAuthorized=false,
            }
        end
    end
    result.itemSlots=#result.items
    for _,item in ipairs(result.items) do
        item.repeatedInWindow=(counts[item.itemID] or 0)>1
        if item.repeatedInWindow then
            result.repeatedSlots=result.repeatedSlots+1
        end
    end
    result.message="Read-only: "..result.itemSlots.." live item slot(s), "..
        result.priorAttemptHolds.." prior item-ID hold(s), "..
        result.repeatedSlots.." repeated-copy slot(s). "..
        "Current TARGET GUID is only a hint; corpse source UNVERIFIED. "..
        "No NO-RETRY lock is cleared."
    return result
end

function D:Report()
    local inspected=self:Inspect()
    local messages={inspected.message}
    if inspected.targetGUIDHint then
        messages[#messages+1]="Current target hint: "..
            tostring(inspected.targetGUIDHint).." (NOT a loot-source GUID)."
    else
        messages[#messages+1]="Current target hint: none; corpse still UNVERIFIED."
    end
    local shown=0
    for _,item in ipairs(inspected.items) do
        if item.priorGuildAttempt or item.priorWinnerAttempt or
           item.repeatedInWindow then
            messages[#messages+1]="Slot "..tostring(item.slotIndex)..
                " item "..tostring(item.itemID)..
                " x"..tostring(item.quantity)..": "..
                (item.priorGuildAttempt and "GUILD ATTEMPT LOCK; " or "")..
                (item.priorWinnerAttempt and "WINNER ATTEMPT LOCK; " or "")..
                (item.repeatedInWindow and "MULTIPLE VISIBLE COPIES; " or "")..
                "NO SOURCE PROOF; NO RETRY."
            shown=shown+1
            if shown>=6 then
                messages[#messages+1]="Additional items omitted from chat; "..
                    "historical locks remain unchanged."
                break
            end
        end
    end
    return messages
end
