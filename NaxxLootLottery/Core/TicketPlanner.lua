-- NLL Phase 9 preparation: POST-DROP CANDIDATE PREVIEW ONLY.
-- This module never rolls, transmits tickets, chooses a winner or awards loot.
local NLL = NaxxLootLottery
NLL.TicketPlanner = NLL.TicketPlanner or {}
local Planner = NLL.TicketPlanner

local function ByName(a, b)
    return string.lower(a.character or "") < string.lower(b.character or "")
end

function Planner:BuildPreview(entry, matches, options)
    options = options or {}
    -- Simulated entries are accepted ONLY by the explicit sandbox caller.
    -- They cannot pass the real DETECTED-drop checks in TicketLottery.
    local sandbox = options.simulation == true and
        type(entry) == "table" and entry.simulationOnly == true
    local result = {
        ready = false,
        message = "",
        itemID = entry and entry.itemID or nil,
        chosenTier = nil, selectionType = nil,
        current = {}, waiting = {}, excluded = {}, unresolved = {},
        greedUnresolved = {}, needCount = 0, greedCount = 0,
        -- no pre-drop or post-drop lottery ticket objects created
        previewOnly = true,
        debug = entry and entry.slotIndex == 0 or false
    }
    if type(entry) ~= "table" or
        (not sandbox and entry.state ~= "DETECTED") or
        (sandbox and entry.state ~= "SIMULATED_DROP") or
        (entry.simulationOnly and not sandbox) then
        result.message = "No real detected drop. Simulation requires the Debug Lab."
        return result
    end
    local raidKey = entry.raidKey or "MOLTEN_CORE"
    if raidKey ~= "MOLTEN_CORE" or not NLL.Data.MoltenCore:GetItem(entry.itemID) then
        result.message = "Unsupported drop; no ticket preview."
        return result
    end
    local item = NLL.Data.MoltenCore:GetItem(entry.itemID)
    if entry.manualOnly or item.manualOnly or
        (not sandbox and NLL.PriorityEngine:GetState(raidKey, entry.itemID) ==
        NLL.PriorityEngine.STATUS.MANUAL_ONLY) then
        result.message = "Guild/manual item: no normal lottery."
        return result
    end
    if sandbox then
        local rule = options.rule
        if type(rule) ~= "table" or
            NLL.PriorityEngine:GetUnsetRoleCount(rule) > 0 then
            result.message = "Simulation needs a complete priority rule or suggestion."
            return result
        end
    elseif NLL.PriorityEngine:GetState(raidKey, entry.itemID) ~=
        NLL.PriorityEngine.STATUS.CONFIGURED then
        result.message = "Priority rule must be fully configured first."
        return result
    end
    if sandbox and type(matches) ~= "table" then
        result.message = "Simulation requires an explicit fake candidate roster."
        return result
    end
    matches = matches or NLL.NeedMatcher:GetMatchesForItem(entry.itemID)
    if not sandbox and NLL.CandidateReview then
        matches = NLL.CandidateReview:MergeMatches(entry,matches)
    end
    -- NEED and GREED are different stages. GREED is NOT Tier 4.
    -- Explicit leader additions are NEED candidates only when the player
    -- does not already have a saved GREED reservation (checked in review).
    -- Primary entries always come first to avoid duplicate character tickets.
    local candidates = {}
    for _, match in ipairs(matches) do
        candidates[#candidates+1] = match
    end
    if not sandbox then
        for _, match in ipairs(NLL.NeedMatcher:GetMatchesForItem(
            entry.itemID, "GREED")) do
            candidates[#candidates+1] = match
        end
    end
    local needPools = {{}, {}, {}}
    local greedPool = {}
    local seen = {}
    for _, m in ipairs(candidates) do
        local isGreed = m.interestStatus == "GREED"
        local key = string.lower((m.character or ""):match("^([^%-]+)") or "")
        if key ~= "" and not seen[key] then
            seen[key] = true
            local unresolved = isGreed and result.greedUnresolved or result.unresolved
            if sandbox and options.excluded and options.excluded[key] then
                table.insert(result.excluded, {match=m, reason="Simulated leader exclusion"})
            elseif not sandbox and NLL.CandidateReview and
                NLL.CandidateReview:IsExcluded(entry,m.character) then
                table.insert(result.excluded, {match=m, reason="Leader exclusion: " ..
                    tostring(NLL.CandidateReview:IsExcluded(entry,m.character))})
            elseif not m.inRaid or not m.online or m.eligiblePresence == false then
                table.insert(result.excluded, {match=m, reason="Not present/online"})
            elseif not m.classFile or not NLL:IsValidClass(m.classFile) then
                table.insert(unresolved, {match=m, reason="Class unknown"})
            elseif not m.role or not NLL.roleLabels[m.role] then
                table.insert(unresolved, {match=m, reason="Role unassigned"})
            else
                local tier, explanation
                if sandbox then
                    if not NLL.PriorityEngine:IsClassEligible(
                        raidKey, entry.itemID, m.classFile, options.rule) then
                        tier = NLL.PriorityEngine.EXCLUDE
                        explanation = "Wrong class"
                    else
                        tier = options.rule.rolePriority[m.role]
                        explanation = tier == NLL.PriorityEngine.EXCLUDE and
                            "Not eligible" or "Unconfigured role"
                    end
                else
                    tier, explanation = NLL.PriorityEngine:GetCandidatePriority(
                        raidKey, entry.itemID, m)
                end
                if tier == 1 or tier == 2 or tier == 3 then
                    if isGreed then
                        greedPool[#greedPool+1] = m
                    else
                        needPools[tier][#needPools[tier]+1] = m
                    end
                elseif tier == NLL.PriorityEngine.EXCLUDE then
                    table.insert(result.excluded, {match=m, reason=explanation or "Excluded"})
                else
                    table.insert(unresolved, {match=m, reason=explanation or "Unresolved"})
                end
            end
        end
    end
    for tier = 1, 3 do
        table.sort(needPools[tier], ByName)
        result.needCount = result.needCount + #needPools[tier]
    end
    table.sort(greedPool, ByName)
    result.greedCount = #greedPool
    for tier = 1, 3 do
        if #needPools[tier] > 0 and not result.chosenTier then
            result.chosenTier = tier
        end
    end
    if result.chosenTier then
        result.selectionType = "NEED"
        for tier = 1, 3 do
            for _, m in ipairs(needPools[tier]) do
                if tier == result.chosenTier then
                    result.current[#result.current+1] = m
                else
                    result.waiting[#result.waiting+1] = {
                        match=m, selectionType="NEED", tier=tier}
                end
            end
        end
        for _, m in ipairs(greedPool) do
            result.waiting[#result.waiting+1] = {
                match=m, selectionType="GREED"}
        end
    elseif #greedPool > 0 then
        result.selectionType = "GREED"
        for _, m in ipairs(greedPool) do
            result.current[#result.current+1] = m
        end
    end
    if #result.unresolved > 0 then
        result.message = #result.unresolved ..
            " present NEED character(s) have unresolved class/role/policy. " ..
            "No roll or award until reviewed."
        return result
    end
    if not result.chosenTier and #result.greedUnresolved > 0 then
        result.message = #result.greedUnresolved ..
            " present GREED character(s) have unresolved class/role/policy. " ..
            "No Greed roll or award until reviewed."
        return result
    end
    if not result.selectionType then
        result.message = "No eligible NEED or GREED candidates. " ..
            "Leave the item for manual distribution; no roll or award."
        return result
    end
    result.ready = true
    if result.selectionType == "GREED" then
        result.message = "GREED lottery: " .. #result.current ..
            " equal-interest candidate(s), after all NEED tiers are empty. " ..
            #result.excluded .. " excluded. Preview only: no roll or award."
    else
        result.message = "NEED - Tier " .. result.chosenTier .. ": " ..
            #result.current .. " candidate(s), " .. #result.waiting ..
            " waiting (including Greed); " .. #result.excluded ..
            " excluded. Preview only: no roll or award."
    end
    return result
end

function Planner:PreviewSelectedLoot()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return NLL.DebugSimulator:Preview()
    end
    local UI = NLL.UI
    local loot = NLL.LootDetection:GetCurrentLoot() or {}
    local index = UI.currentLootSelected or 1
    local entry = loot[index]
    local matches = entry and NLL.NeedMatcher:GetMatchesForItem(entry.itemID) or {}
    return self:BuildPreview(entry, matches)
end
