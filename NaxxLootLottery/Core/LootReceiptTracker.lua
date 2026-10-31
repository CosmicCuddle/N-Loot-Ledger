-- Naxxramas Loot Ledger - pending roll winners / manually verified receipt.
-- A lottery winner is NEVER proof of actual item delivery.
-- This module does not call GiveMasterLoot, move items, or overwrite bot plans.
local NLL=NaxxLootLottery
NLL.LootReceiptTracker=NLL.LootReceiptTracker or {}
local R=NLL.LootReceiptTracker

local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function ExactName(a,b)
    -- A short-name match is not evidence of the same physical recipient.
    -- The persistent drop/award ledger must preserve the full identity
    -- (including a realm suffix if one is present).
    return type(a)=="string" and type(b)=="string" and
        a~="" and b~="" and string.lower(a)==string.lower(b)
end
local function Now()
    return date and date("%Y-%m-%d %H:%M:%S") or "unknown"
end
local function GetBook()
    local db=NLL.db
    if not db or type(db.lootReceiptTracker)~="table" then return nil end
    return db.lootReceiptTracker
end

function R:Get(dropUID)
    local book=GetBook()
    return book and type(dropUID)=="string" and book[dropUID] or nil
end

function R:ObserveWinner(result)
    if not result or result.test or result.simulationOnly or
        result.status~="COMPLETE" or not result.winner or
        not result.dropUID or not tonumber(result.itemID) then
        return false,"Only a completed REAL ticket roll can create a pending receipt."
    end
    local book=GetBook()
    if not book then return false,"Saved receipt ledger unavailable." end
    local old=book[result.dropUID]
    if old then
        if ExactName(old.character,result.winner) and
            old.itemID==tonumber(result.itemID) then return true,old end
        return false,"This physical loot opportunity is locked to another winner."
    end
    -- Snapshot only the original active reservations. Every source (bot,
    -- leader manual, player submitted) remains untouched until receipt.
    local keys={}
    for key,need in pairs(NLL.db.gearNeeds or {}) do
        if type(need)=="table" and
            ExactName(need.character,result.winner) and
            tonumber(need.itemID)==tonumber(result.itemID) and
            need.raidKey==(result.raidKey or "MOLTEN_CORE") and
            (need.status=="NEEDED" or need.status=="GREED") then
            keys[#keys+1]={key=key,from=need.status}
        end
    end
    table.sort(keys,function(a,b)return a.key<b.key end)
    local row={
        dropUID=result.dropUID,
        itemID=tonumber(result.itemID),
        itemName=result.itemName,
        raidKey=result.raidKey or "MOLTEN_CORE",
        character=result.winner,
        selectionType=result.selectionType or "NEED",
        status="WON_AWAITING_ITEM",
        savedAt=Now(),confirmedAt=nil,
        observedBy=UnitName and UnitName("player") or "Unknown",
        needs=keys,
        confirmedNeedCount=0,
    }
    book[result.dropUID]=row
    return true,row
end

-- A previously attested bot item is already OBTAINED in the local Gear
-- Plan. Later human receipt review must be able to complete the original
-- pending drop without treating the manual edit as a fabricated receipt.
-- Require the exact persisted attestation audit, not merely a status flag.
local function MatchesManualAttestation(need,snapshot,receipt)
    if type(need)~="table" or type(snapshot)~="table" or
       type(receipt)~="table" or
       need.status~="OBTAINED" or need.obtainedDropUID~=nil or
       need.source~="BOT_GEAR_PLAN" or
       need.characterType~="PLAYERBOT" or
       need.manualObtainedEvidence~="LEADER_ATTESTED_BOT_HAS_ITEM" or
       type(need.manualObtainedBy)~="string" or
       (snapshot.from~="NEEDED" and snapshot.from~="GREED") then
        return false
    end
    if not ExactName(need.character,receipt.character) or
       tonumber(need.itemID)~=receipt.itemID or
       need.raidKey~=receipt.raidKey then
        return false
    end
    for _,audit in ipairs(NLL.db.manualObtainedEvidence or {}) do
        if type(audit)=="table" and
           audit.kind=="LEADER_ATTESTED_BOT_HAS_ITEM" and
           audit.gearKey==snapshot.key and
           ExactName(audit.character,receipt.character) and
           tonumber(audit.itemID)==receipt.itemID and
           audit.oldStatus==snapshot.from and
           audit.newStatus=="OBTAINED" and
           audit.by==need.manualObtainedBy and
           audit.receiptVerified==false then
            return true
        end
    end
    return false
end

function R:CanConfirm(dropUID)
    local row=self:Get(dropUID)
    if not row then return false,"This win has no tracked receipt; do not guess." end
    if row.status=="OBTAINED" then
        return false,"Receipt was already confirmed. Do not mark it twice."
    end
    if row.status~="WON_AWAITING_ITEM" then
        return false,"Receipt status is not eligible for confirmation."
    end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Fake raids cannot update real Gear Plans."
    end
    -- User must be acting as the leader who recorded the win, or have
    -- current raid authority. No third-party addon message can confirm.
    local actor=UnitName and UnitName("player")
    local allowed=ExactName(actor,row.observedBy) or
        (NLL.TicketLottery and
         NLL.TicketLottery:AuthorityAllowed(false))
    if not allowed then
        return false,"Original raid leader or active raid authority required."
    end
    -- NLL must contain an award report for THIS exact drop/winner.
    -- A server roll or merely a GiveMasterLoot request is insufficient.
    local awarded=false
    for _,a in ipairs(NLL.db.lootAwardHistory or {}) do
        if a.dropUID==dropUID and
           tonumber(a.itemID)==row.itemID and
           ExactName(a.winner,row.character) and
           (a.status=="LEADER_REPORTED" or
            a.status=="LOOT_SLOT_CLEARED") then
            awarded=true
            break
        end
    end
    if not awarded then
        return false,"First record the award or observed loot-slot clear, "..
            "then independently CHECK the recipient inventory."
    end
    if type(NLL.db.gearNeeds)~="table" then
        return false,"Gear Plans unavailable; no statuses changed."
    end
    for _,snapshot in ipairs(row.needs or {}) do
        local need=NLL.db.gearNeeds[snapshot.key]
        if need and (not ExactName(need.character,row.character) or
            tonumber(need.itemID)~=row.itemID or
            need.raidKey~=row.raidKey or
            (need.status~=snapshot.from and
             not (need.status=="OBTAINED" and
                  need.obtainedDropUID==dropUID) and
             not MatchesManualAttestation(need,snapshot,row))) then
            return false,"A Gear Plan has changed since the roll. Review "..
                "the plan before confirming receipt."
        end
    end
    return true,row
end

-- Called ONLY from the leader's second explicit 'verified inventory'
-- UI click; the call deliberately trusts a HUMAN confirmation, never
-- an inexact loot-slot-cleared or server /roll event.
function R:ConfirmReceipt(dropUID)
    local ok,row=self:CanConfirm(dropUID)
    if not ok then return false,row end
    local changed=0
    local linked=0
    for _,snapshot in ipairs(row.needs or {}) do
        local need=NLL.db.gearNeeds[snapshot.key]
        if need and (need.status=="NEEDED" or need.status=="GREED") then
            need.status="OBTAINED"
            need.obtainedDropUID=dropUID
            changed=changed+1
        elseif MatchesManualAttestation(need,snapshot,row) then
            -- Independent confirmation links this previously attested
            -- local plan to the reviewed drop; preserve the original
            -- manual-attestation audit as historical evidence.
            need.obtainedDropUID=dropUID
            linked=linked+1
        end
    end
    -- Only the local character's SavedVariables are writable. A remote
    -- player's local wishlist must be synchronized separately; do NOT
    -- pretend the raid leader edited another client's WTF folder.
    if NLL.Database and NLL.Database.MarkLocalObtained and
       UnitName and ExactName(UnitName("player"),row.character) then
        NLL.Database:MarkLocalObtained(row.character,row.raidKey,row.itemID)
    end
    row.status="OBTAINED"
    row.confirmedAt=Now()
    row.confirmedBy=UnitName and UnitName("player") or "Unknown"
    row.evidence="LEADER_CONFIRMED_RECIPIENT_INVENTORY"
    row.confirmedNeedCount=changed
    -- Offer a notification ONLY to a human recipient after leader's
    -- explicit confirmed receipt. Another client's wishlist is never edited.
    if NLL.ReceiptSync and NLL.ReceiptSync.OnLeaderConfirmed then
        NLL.ReceiptSync:OnLeaderConfirmed(row)
    end
    if NLL.UI then
        if NLL.UI.RefreshGearPlans and NLL.UI.gearPlansContent then
            NLL.UI:RefreshGearPlans()
        end
        if NLL.UI.RefreshWishlistPanel then NLL.UI:RefreshWishlistPanel() end
        if NLL.UI.RefreshCurrentLootPanel then
            NLL.UI:RefreshCurrentLootPanel()
        end
    end
    return true,"Recipient receipt CONFIRMED for "..row.character..
        " / "..tostring(row.itemName or row.itemID)..
        ". "..changed.." active Gear Plan(s) -> OBTAINED; "..
        linked.." earlier manual attestation(s) linked to this receipt."
end
