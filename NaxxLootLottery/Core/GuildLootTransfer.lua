-- Naxxramas Loot Ledger: opt-in, TWO-CLICK guild loot transfer.
-- DRAFT: never invoked by a timer, an addon message, or a loot scan.
-- Requires an owner click to review, arm, and confirm a real Master
-- Looter request. Successful GiveMasterLoot is NOT recipient proof.
local NLL=NaxxLootLottery
NLL.GuildLootTransfer=NLL.GuildLootTransfer or {}
local T=NLL.GuildLootTransfer
T.review=nil
T.liveRequests=T.liveRequests or {}
local ARM_SECONDS=15
-- A missing or invalid client clock must NEVER leave an armed award
-- permanently confirmable. Zero itself is a valid early uptime value.
local function Now()
    if type(GetTime)~="function" then return nil end
    local value=GetTime()
    if type(value)~="number" or value~=value or value<0 then
        return nil
    end
    return value
end
local function Key(s) return string.lower((tostring(s or ""):match("^([^%-]+)") or "")) end
local function ItemID(link)
    return type(link)=="string" and tonumber(link:match("item:(%d+)")) or nil
end

function T:IsEnabled()
    return NLL.db and NLL.db.settings and
        NLL.db.settings.directMasterLootEnabled==true and
        NLL.db.settings.guildLootTransfersEnabled==true
end

function T:SetEnabled(enabled)
    if not NLL.db or not NLL.db.settings or
       (NLL.DebugSimulator and NLL.DebugSimulator:IsActive()) then return false end
    NLL.db.settings.guildLootTransfersEnabled=enabled==true
    self:Cancel()
    return true
end

function T:Cancel() self.review=nil end

function T:IsUnresolved()
    local audit=NLL.db and NLL.db.guildLootTransferAudit or {}
    -- Never retry silently after an uncertain outcome, even after /reload.
    for _,row in ipairs(audit) do
        if row.reconciliationStatus~="CLOSED_NO_RETRY" and
           (row.status=="AWARD_REQUESTED" or
            row.status=="AWARD_OUTCOME_UNKNOWN" or
            row.status=="LOOT_SLOT_CLEARED") then
            return true
        end
    end
    -- Also include persisted winner-award attempts, not just live
    -- references that vanish at /reload. Missing receipts fail closed.
    for _,row in ipairs(NLL.db and NLL.db.lootAwardHistory or {}) do
        local receipt=NLL.LootReceiptTracker and
            NLL.LootReceiptTracker:Get(row.dropUID)
        -- Independent HUMAN-confirmed receipt resolves the global unknown
        -- gate, but NEVER removes the original drop UID's no-retry lock.
        local confirmed=receipt and receipt.status=="OBTAINED" and
            tonumber(receipt.itemID)==tonumber(row.itemID) and
            Key(receipt.character)==Key(row.winner)
        if not confirmed and row.reconciliationStatus~="CLOSED_NO_RETRY" and
           (row.status=="AWARD_REQUESTED" or
            row.status=="AWARD_OUTCOME_UNKNOWN" or
            row.status=="LOOT_SLOT_CLEARED") then
            return true
        end
    end
    if NLL.AwardWorkflow then
        for _,v in pairs(NLL.AwardWorkflow.liveRequests or {}) do
            if v.history and v.history.status=="AWARD_REQUESTED" and
               v.history.reconciliationStatus~="CLOSED_NO_RETRY" then
                return true
            end
        end
    end
    return false
end

function T:WasAttempted(itemID,slot)
    -- WoW 3.3.5a cannot prove the original corpse identity for guild
    -- materials. Slot numbers can change on re-open and two corpses may
    -- drop identical items. A matching ITEM ID is therefore an enduring
    -- NO-RETRY guard, even if the later slot number is different and
    -- even after an investigation was CLOSED_NO_RETRY. Until a trusted
    -- per-corpse identity is available, never mistake a changed slot
    -- for proof of a new physical copy.
    for _,row in ipairs(NLL.db and NLL.db.guildLootTransferAudit or {}) do
        if tonumber(row.itemID)==tonumber(itemID) then
            return true
        end
    end
    return false
end

function T:Validate(target)
    if not self:IsEnabled() then
        return false,"Guild transfer and Direct Master Loot must BOTH be enabled separately."
    end
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,"Fake raid active; physical loot transfers disabled."
    end
    if type(target)~="table" or
       type(target.slotIndex)~="number" or target.slotIndex<1 or
       type(target.itemID)~="number" or target.itemID<1 or
       type(target.itemLink)~="string" or
       ItemID(target.itemLink)~=target.itemID then
        return false,"Select a real guild-loot item slot first."
    end
    -- Owner's newer allocation policy supersedes the old Guild Master
    -- destination for the five guild materials. Physical requests must go
    -- through the leader-only ticket winner and the normal Award workflow.
    if NLL.GuildLootReview and
       NLL.GuildLootReview:IsGuildMaterial(target.itemID) then
        return false,"Guild material now uses leader-only Prepare Tickets / Start Roll / Award Winner."
    end
    if not NLL.TicketLottery or
       not NLL.TicketLottery:AuthorityAllowed(false) then
        return false,"Only a raid leader/officer can request guild transfers."
    end
    if not NLL.GuildLootReview then
        return false,"Guild Loot review module unavailable."
    end
    local current=NLL.GuildLootReview:Scan()
    local row
    for _,v in ipairs(current) do
        if v.slotIndex==target.slotIndex then row=v break end
    end
    if not row or row.status~="GUILD_REVIEW" or
       row.itemID~=target.itemID or row.itemLink~=target.itemLink or
       row.quantity~=target.quantity then
        return false,"Live loot or reservation changed; review the item again."
    end
    if self:IsUnresolved() then
        return false,"An earlier item transfer is unresolved; review its receipt first."
    end
    local active=NLL.TicketLottery and NLL.TicketLottery.active
    if active and active.status~="COMPLETE" and
       active.status~="CANCELLED" and active.status~="INVALIDATED" then
        return false,"A ticket lottery is still active. Finish or cancel it first."
    end
    local winnerReview=NLL.AwardWorkflow and NLL.AwardWorkflow.verification
    if winnerReview and not winnerReview.simulated then
        return false,"Another Master Loot winner review is pending. Close it first."
    end
    if self:WasAttempted(row.itemID,row.slotIndex) then
        return false,"This item ID has a previous request, possibly from another slot/corpse. No automatic duplicate attempt is allowed."
    end
    if type(GetLootMethod)~="function" or
       type(GetRaidRosterInfo)~="function" or
       type(GetNumLootItems)~="function" or
       type(GetLootSlotLink)~="function" or
       type(GetMasterLootCandidate)~="function" or
       type(UnitName)~="function" then
        return false,"Required Wrath Master Loot APIs unavailable."
    end
    local method,_,masterIndex=GetLootMethod()
    if method~="master" or type(masterIndex)~="number" or masterIndex<1 then
        return false,"Must use WoW Master Loot with a verified designated Master Looter."
    end
    local master=GetRaidRosterInfo(masterIndex)
    if Key(master)=="" or Key(master)~=Key(UnitName("player")) then
        return false,"You are not the designated WoW Master Looter."
    end
    if not LootFrame or not LootFrame.IsShown or not LootFrame:IsShown() or
       LootFrame.selectedSlot~=row.slotIndex then
        return false,"Select THIS exact item in WoW's Master Loot dropdown."
    end
    if row.slotIndex>(GetNumLootItems() or 0) or
       GetLootSlotLink(row.slotIndex)~=row.itemLink then
        return false,"The exact item/loot slot changed in WoW."
    end
    local recipientKind=row.guildMaterial and "GUILD_MASTER" or "RAID_LEADER"
    local leader=row.guildMaterial and
        NLL.GuildLootReview:GetGuildMaster() or
        NLL.GuildLootReview:GetLeader()
    if not leader or
       (row.guildMaterial and Key(leader)~=Key(row.guildMaster)) or
       (not row.guildMaterial and Key(leader)~=Key(row.leader)) then
        return false,row.guildMaterial and
            "Guild master unavailable, offline or absent from this raid. "..
            "Open the WoW Guild roster to refresh, then review again." or
            "Raid leader changed or could not be uniquely verified."
    end
    local match,count=nil,0
    for i=1,40 do
        local name=GetMasterLootCandidate(i)
        if name and Key(name)==Key(leader) then
            match=i
            count=count+1
        end
    end
    if count~=1 then
        return false,"Chosen guild/raid leader must occur exactly once in the current Master Loot candidates."
    end
    return true,{
        slot=row.slotIndex,itemID=row.itemID,link=row.itemLink,
        quantity=row.quantity,leader=leader,
        recipientKind=recipientKind,candidate=match,
        startedAt=Now(),
    }
end

local function Same(a,b)
    return a and b and a.slot==b.slot and a.itemID==b.itemID and
        a.link==b.link and a.quantity==b.quantity and
        Key(a.leader)==Key(b.leader) and a.candidate==b.candidate and
        a.recipientKind==b.recipientKind
end

function T:Review(target)
    self:Cancel()
    local ok,data=self:Validate(target)
    if not ok then return false,data end
    self.review={target={
        slotIndex=data.slot,itemID=data.itemID,
        itemLink=data.link,quantity=data.quantity,
    },context=data}
    return true,"Verified "..data.link.." x"..data.quantity..
        " for "..(data.recipientKind=="GUILD_MASTER" and
        "guild master " or "raid leader ")..data.leader..
        ". ARM requires another click."
end

function T:Arm()
    local review=self.review
    if not review or not review.context then
        return false,"Choose Review for a guild-loot item first."
    end
    local ok,fresh=self:Validate(review.target)
    if not ok then self:Cancel();return false,fresh end
    if not Same(review.context,fresh) then
        self:Cancel()
        return false,"Recipient or loot slot changed; start review again."
    end
    local armedAt=Now()
    if armedAt==nil then
        self:Cancel()
        return false,"WoW clock unavailable; cannot arm a physical loot request."
    end
    review.armedAt=armedAt
    return true,"ARMED for "..fresh.leader.." / "..fresh.link..
        ". Confirm GIVE ITEM within 15 seconds, otherwise cancel."
end

function T:Commit()
    local review=self.review
    if not review or not review.armedAt then
        return false,"Guild item transfer has not been armed."
    end
    local now=Now()
    if type(review.armedAt)~="number" or now==nil or
       now<review.armedAt or now-review.armedAt>ARM_SECONDS then
        self:Cancel()
        return false,"Confirmation expired or WoW clock changed; review and arm again."
    end
    local ok,fresh=self:Validate(review.target)
    if not ok then self:Cancel();return false,fresh end
    if not Same(review.context,fresh) then
        self:Cancel()
        return false,"Item or raid leader candidate changed; transfer stopped."
    end
    if type(GiveMasterLoot)~="function" then
        self:Cancel()
        return false,"WoW GiveMasterLoot is unavailable."
    end
    self:Cancel() -- no UI retry window after sending the request
    -- Persist an ATTEMPT before invoking WoW. This survives /reload and
    -- blocks retry if the request throws, silently fails or clears the slot.
    local row={
        itemID=fresh.itemID,itemLink=fresh.link,quantity=fresh.quantity,
        slotIndex=fresh.slot,recipient=fresh.leader,
        recipientKind=fresh.recipientKind,
        operator=UnitName and UnitName("player") or nil,
        candidateIndex=fresh.candidate,
        status="AWARD_OUTCOME_UNKNOWN",
        note="Request attempt; no recipient receipt verified",
        when=date and date("%Y-%m-%d %H:%M:%S") or "unknown",
    }
    local audit=NLL.db.guildLootTransferAudit
    table.insert(audit,row)
    local success,err=pcall(GiveMasterLoot,fresh.slot,fresh.candidate)
    if not success then
        row.note="WoW GiveMasterLoot raised an error: "..tostring(err)..
            "; do not automatically retry"
        return false,"WoW Master Loot reported an error; outcome UNKNOWN. Do not retry."
    end
    row.status="AWARD_REQUESTED"
    row.note="GiveMasterLoot invoked; delivery NOT verified"
    self.liveRequests[fresh.slot]={row=row,itemID=fresh.itemID,link=fresh.link}
    return true,"Requested guild loot to "..fresh.leader..
        ". DELIVERY UNVERIFIED. Never retry this physical item."
end

function T:OnLootSlotCleared(slot)
    local a=self.liveRequests[slot]
    if a and a.row and a.row.status=="AWARD_REQUESTED" then
        a.row.status="LOOT_SLOT_CLEARED"
        a.row.note="Loot slot cleared; actual recipient receipt NOT verified"
        self.liveRequests[slot]=nil
    end
end

function T:OnLootClosed()
    self:Cancel()
    for slot,request in pairs(self.liveRequests) do
        if request.row and request.row.status=="AWARD_REQUESTED" then
            request.row.status="AWARD_OUTCOME_UNKNOWN"
            request.row.note="Loot closed without clear observation; receipt UNKNOWN"
        end
        self.liveRequests[slot]=nil
    end
end
