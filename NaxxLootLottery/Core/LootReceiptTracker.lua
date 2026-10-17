-- Naxxramas Loot Ledger - pending roll winners / manually verified receipt.
-- A lottery winner is NEVER proof of actual item delivery.
-- This module does not call GiveMasterLoot, move items, or overwrite bot plans.
local NLL=NaxxLootLottery
NLL.LootReceiptTracker=NLL.LootReceiptTracker or {}
local R=NLL.LootReceiptTracker

local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
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
        if Key(old.character)==Key(result.winner) and
            old.itemID==tonumber(result.itemID) then return true,old end
        return false,"This physical loot opportunity is locked to another winner."
    end
    -- Snapshot only the original active reservations. Every source (bot,
    -- leader manual, player submitted) remains untouched until receipt.
    local keys={}
    for key,need in pairs(NLL.db.gearNeeds or {}) do
        if type(need)=="table" and
            Key(need.character)==Key(result.winner) and
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
    local allowed=(actor and Key(actor)~="" and
        Key(actor)==Key(row.observedBy)) or
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
           Key(a.winner)==Key(row.character) and
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
        if need and (Key(need.character)~=Key(row.character) or
            tonumber(need.itemID)~=row.itemID or
            need.raidKey~=row.raidKey or
            (need.status~=snapshot.from and
             not (need.status=="OBTAINED" and
                  need.obtainedDropUID==dropUID))) then
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
    for _,snapshot in ipairs(row.needs or {}) do
        local need=NLL.db.gearNeeds[snapshot.key]
        if need and (need.status=="NEEDED" or need.status=="GREED") then
            need.status="OBTAINED"
            need.obtainedDropUID=dropUID
            changed=changed+1
        end
    end
    -- Only the local character's SavedVariables are writable. A remote
    -- player's local wishlist must be synchronized separately; do NOT
    -- pretend the raid leader edited another client's WTF folder.
    if NLL.Database and NLL.Database.MarkLocalObtained and
       UnitName and Key(UnitName("player"))==Key(row.character) then
        NLL.Database:MarkLocalObtained(row.character,row.raidKey,row.itemID)
    end
    row.status="OBTAINED"
    row.confirmedAt=Now()
    row.confirmedBy=UnitName and UnitName("player") or "Unknown"
    row.evidence="LEADER_CONFIRMED_RECIPIENT_INVENTORY"
    row.confirmedNeedCount=changed
    if NLL.UI then
        if NLL.UI.RefreshGearPlans then NLL.UI:RefreshGearPlans() end
        if NLL.UI.RefreshWishlistPanel then NLL.UI:RefreshWishlistPanel() end
        if NLL.UI.RefreshCurrentLootPanel then
            NLL.UI:RefreshCurrentLootPanel()
        end
    end
    return true,"Recipient receipt CONFIRMED for "..row.character..
        " / "..tostring(row.itemName or row.itemID)..
        ". "..changed.." active Gear Plan(s) -> OBTAINED."
end
