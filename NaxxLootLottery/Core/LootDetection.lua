-- ============================================================
-- Naxxramas Loot Ledger
-- Core/LootDetection.lua
--
-- Phase 6: read the Wrath-era loot window and build a current
-- supported-raid loot queue. No item is awarded here.
-- ============================================================

local NLL = NaxxLootLottery
NLL.LootDetection = NLL.LootDetection or {}
local Loot = NLL.LootDetection

Loot.initialized = false
Loot.recentBossName = nil
Loot.recentBossTime = 0

Loot.moltenCoreBosses = {
    ["Lucifron"] = true,
    ["Magmadar"] = true,
    ["Gehennas"] = true,
    ["Garr"] = true,
    ["Shazzrah"] = true,
    ["Baron Geddon"] = true,
    ["Golemagg the Incinerator"] = true,
    ["Sulfuron Harbinger"] = true,
    ["Majordomo Executus"] = true,
    ["Ragnaros"] = true
}

local function ItemIDFromLink(link)
    if type(link) ~= "string" then
        return nil
    end

    return tonumber(
        string.match(
            link,
            "item:(%d+)"
        )
    )
end

local function BossListContains(item, bossName)
    if not item or not bossName then
        return false
    end

    for i = 1, #(item.bosses or {}) do
        if item.bosses[i] == bossName then
            return true
        end
    end

    return false
end

function Loot:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true
end

function Loot:GetCurrentLoot()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return NLL.DebugSimulator:GetLoot()
    end
    if not NLL.db
        or not NLL.db.raidSession
        or type(
            NLL.db.raidSession.currentLoot
        ) ~= "table" then

        return {}
    end

    return NLL.db.raidSession.currentLoot
end

function Loot:SetCurrentLoot(entries)
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false -- never persist a loot queue during fake raid mode
    end
    if not NLL.db
        or not NLL.db.raidSession then

        return
    end

    local session = NLL.db.raidSession
    session.lootGeneration = (tonumber(session.lootGeneration) or 0) + 1
    for i, entry in ipairs(entries or {}) do
        entry.dropUID = tostring(session.lootGeneration) .. ":" ..
            tostring(i) .. ":" .. tostring(entry.itemID)
    end
    -- Refreshing/clearing the loot window invalidates every uncommitted draw.
    -- Completed results remain in history, but no stale tickets carry forward.
    if NLL.TicketLottery and NLL.TicketLottery.Invalidate then
        NLL.TicketLottery:Invalidate("Loot window changed")
    end
    if NLL.CandidateReview and NLL.CandidateReview.OnLootChanged then
        NLL.CandidateReview:OnLootChanged()
    end
    NLL.db.raidSession.currentLoot = entries or {}

    NLL.db.raidSession.currentLootUpdated =
        GetTime and GetTime() or 0

    if NLL.UI
        and NLL.UI.RefreshCurrentLootPanel then

        NLL.UI:RefreshCurrentLootPanel()
    end
end

function Loot:ClearCurrentLoot()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return NLL.DebugSimulator:Cancel()
    end
    self:SetCurrentLoot({})
end

function Loot:ResolveBoss(item)
    if self.recentBossName
        and GetTime
        and (GetTime() - self.recentBossTime) <= 180
        and BossListContains(
            item,
            self.recentBossName
        ) then

        return self.recentBossName
    end

    if item
        and item.bosses
        and #item.bosses == 1 then

        return item.bosses[1]
    end

    if NLL.Data
        and NLL.Data.MoltenCore
        and NLL.Data.MoltenCore.GetBossText then

        return
            NLL.Data.MoltenCore:GetBossText(
                item
            )
    end

    return "Unknown source"
end

function Loot:BuildEntry(
    item,
    itemLink,
    slotIndex,
    quantity
)
    return {
        itemID = item.itemID,
        itemName = item.name,
        itemLink = itemLink,
        raidKey = "MOLTEN_CORE",
        raid = "Molten Core",
        boss = self:ResolveBoss(item),
        slotIndex = slotIndex,
        quantity = quantity or 1,
        manualOnly =
            item.manualOnly == true,
        legendary =
            item.legendary == true,
        state = "DETECTED"
    }
end

function Loot:ScanLootWindow()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return -- real LOOT_OPENED events must not alter fake raid or saved loot
    end
    if NLL.TicketLottery then NLL.TicketLottery.liveLootObserved=true end
    if not GetNumLootItems
        or not GetLootSlotLink then

        return
    end

    if NLL.Roster then
        NLL.Roster:Refresh()
    end

    local entries = {}
    local slotCount =
        GetNumLootItems() or 0

    for slotIndex = 1, slotCount do
        local link =
            GetLootSlotLink(slotIndex)

        local itemID =
            ItemIDFromLink(link)

        if itemID then
            local item =
                NLL.Data.MoltenCore:GetItem(
                    itemID
                )

            if item then
                local quantity = 1

                if GetLootSlotInfo then
                    local _, _, count =
                        GetLootSlotInfo(
                            slotIndex
                        )

                    quantity =
                        tonumber(count)
                        or 1
                end

                table.insert(
                    entries,
                    self:BuildEntry(
                        item,
                        link,
                        slotIndex,
                        quantity
                    )
                )
            end
        end
    end

    self:SetCurrentLoot(entries)

    if #entries > 0 then
        NLL:Print(
            "Detected " ..
            tostring(#entries) ..
            " supported raid loot item(s)."
        )
    else
        NLL:Debug(
            "Loot window contained no supported Molten Core items."
        )
    end
end

function Loot:RememberBossDeath(
    eventType,
    destName
)
    if eventType ~= "UNIT_DIED"
        or not destName
        or not self.moltenCoreBosses[destName] then

        return
    end

    self.recentBossName = destName
    self.recentBossTime =
        GetTime and GetTime() or 0

    NLL:Debug(
        "Recent Molten Core boss: " ..
        destName
    )
end

function Loot:InjectTestDrop(itemID)
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        NLL:Print("Stop the integrated fake raid before using testdrop.")
        return false
    end
    itemID = tonumber(itemID)
    if NLL.TicketLottery then NLL.TicketLottery.liveLootObserved=true end

    local item =
        NLL.Data.MoltenCore:GetItem(
            itemID
        )

    if not item then
        return false,
            "That Item ID is not in the Molten Core database."
    end

    if NLL.Roster then
        NLL.Roster:Refresh()
    end

    local link =
        "|Hitem:" ..
        tostring(itemID) ..
        ":0:0:0:0:0:0:0|h[" ..
        item.name ..
        "]|h"

    local entry =
        self:BuildEntry(
            item,
            link,
            0,
            1
        )

    self:SetCurrentLoot({
        entry
    })

    return true, entry
end

local eventFrame =
    CreateFrame("Frame")

Loot.eventFrame = eventFrame

eventFrame:RegisterEvent(
    "LOOT_OPENED"
)
eventFrame:RegisterEvent(
    "COMBAT_LOG_EVENT_UNFILTERED"
)
eventFrame:RegisterEvent("LOOT_SLOT_CLEARED")
eventFrame:RegisterEvent("LOOT_CLOSED")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if not NLL.initialized then
            return
        end

        if event == "LOOT_OPENED" then
            Loot:ScanLootWindow()
            return
        end
        if event == "LOOT_SLOT_CLEARED" then
            if NLL.AwardWorkflow then
                NLL.AwardWorkflow:OnLootSlotCleared(...)
            end
            return
        end
        if event == "LOOT_CLOSED" then
            if NLL.AwardWorkflow then
                NLL.AwardWorkflow:OnLootClosed()
            end
            if NLL.TicketLottery then
                NLL.TicketLottery.liveLootObserved = false
            end
            return
        end

        if event ==
            "COMBAT_LOG_EVENT_UNFILTERED" then

            local eventType =
                select(2, ...)

            local destName =
                select(7, ...)

            Loot:RememberBossDeath(
                eventType,
                destName
            )
        end
    end
)
