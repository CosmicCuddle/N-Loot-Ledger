-- Naxxramas Loot Ledger v0.1.0.26: conservative 3.3.5 loot identity.
-- Wrath does not expose a trustworthy loot-source GUID via GetLootSourceInfo.
-- Treat overlapping loot scans as the SAME opportunity until a leader explicitly
-- confirms a new corpse. Never infer a new opportunity from a reopen or /reload.
local NLL = NaxxLootLottery
NLL.LootIdentity = NLL.LootIdentity or {}
local I = NLL.LootIdentity
I.confirmation = nil -- transient: never allow a reload to arm a reset
I.scanNumber = 0
local function Now() return GetTime and GetTime() or 0 end
local function Wall() return time and time() or 0 end
local function Name() return UnitName and UnitName('player') or 'Unknown' end
local function Log(action, message, oldID, newID)
    if not NLL.db then return end
    local history = NLL.db.lootIdentityAudit
    if type(history) ~= 'table' then history={}; NLL.db.lootIdentityAudit=history end
    history[#history+1]={action=action,note=message,oldID=oldID,newID=newID,
        actor=Name(),when=date and date('%Y-%m-%d %H:%M:%S') or 'unknown'}
    while #history>100 do table.remove(history,1) end
end
function I:Initialize()
    if self.initialized then return end
    local session = NLL.db and NLL.db.raidSession
    if not session then return end
    if type(session.lootIdentity) ~= 'table' then session.lootIdentity={} end
    local group=session.lootIdentity
    if type(group.rows) ~= 'table' then group.rows={} end
    if type(group.serial) ~= 'number' then group.serial=0 end
    if type(NLL.db.lootIdentityAudit) ~= 'table' then NLL.db.lootIdentityAudit={} end
    -- v0.1.0.25's former currentLoot entries cannot safely be used to prove
    -- same-corpse identity. Clear the on-screen stale queue on upgrade only.
    if group.schema ~= 2 then
        session.currentLoot={}
        group.schema=2
        group.rows={}
        group.id=nil
        group.serial=0
    else
        -- A client reload cannot prove an award window stayed open.
        -- Restored winners are view-only for real direct awarding.
        for _,row in ipairs(group.rows) do
            if row.processed then row.awardContextClosed=true end
        end
    end
    self.initialized=true
end
function I:GetGroup()
    return NLL.db and NLL.db.raidSession and NLL.db.raidSession.lootIdentity
end
function I:GetRow(uid)
    if not uid then return nil end
    local group=self:GetGroup()
    for _,row in ipairs(group and group.rows or {}) do
        if row.uid==uid then return row end
    end
    return nil
end
function I:NewGroup(group,reason)
    local old=group.id
    local session=NLL.db.raidSession
    session.lootGeneration=(tonumber(session.lootGeneration) or 0)+1
    group.id='L'..tostring(session.lootGeneration)
    group.rows={}
    group.serial=0
    group.startedAt=Wall()
    group.schema=2
    Log('NEW_OPPORTUNITY',reason or 'Nonoverlapping loot items',old,group.id)
end
local function Count(rows)
    local counts={}
    for _,r in ipairs(rows or {}) do
        counts[r.itemID]=(counts[r.itemID] or 0)+1
    end
    return counts
end
function I:Assign(entries, forceNew)
    self:Initialize()
    local group=self:GetGroup()
    if not group then return entries end
    entries=entries or {}
    if #entries==0 then return entries end -- no new opportunity for an empty window
    local hadGroup=group.id~=nil and #group.rows>0
    local overlap=false
    local known=Count(group.rows)
    for _,entry in ipairs(entries) do
        if known[entry.itemID] then overlap=true break end
    end
    if forceNew or not hadGroup or not overlap then
        self:NewGroup(group,forceNew and 'Leader confirmed a different corpse' or
            'New non-overlapping loot signature')
    end
    self.scanNumber=self.scanNumber+1
    local used={}
    local currentCounts=Count(entries)
    for _,entry in ipairs(entries) do
        local matches={}
        for _,row in ipairs(group.rows) do
            if row.itemID==entry.itemID and not used[row.uid] then
                matches[#matches+1]=row
            end
        end
        local match=nil
        for _,row in ipairs(matches) do
            if row.lastSlot==entry.slotIndex then match=row break end
        end
        if not match then match=matches[1] end
        if not match then
            group.serial=group.serial+1
            match={uid=group.id..':'..tostring(group.serial)..':'..tostring(entry.itemID),
                itemID=entry.itemID,firstSlot=entry.slotIndex}
            group.rows[#group.rows+1]=match
        end
        used[match.uid]=true
        match.lastSlot=entry.slotIndex
        match.lastSeen=Wall()
        entry.dropUID=match.uid
        -- If duplicate copies have different disposition, a partial scan
        -- cannot prove which physical copy remains. Block instead of guessing.
        local total=0
        for _,row in ipairs(group.rows) do
            if row.itemID==entry.itemID then total=total+1 end
        end
        -- Even two already completed identical copies cannot be safely
        -- mapped to a remaining single copy once one slot disappears.
        entry.identityUncertain=(total>1 and currentCounts[entry.itemID]<total) or false
    end
    group.lastSeenAt=Wall()
    return entries
end
function I:MarkCompleted(uid,winner,ticket,method)
    local row=self:GetRow(uid)
    if not row then return end -- standalone debug testdrop is separate
    row.processed=true
    row.winner=winner
    row.winningTicket=ticket
    row.method=method
    row.processedAt=Wall()
    row.awardContextClosed=false
end
function I:OnLootClosed()
    local group=self:GetGroup()
    for _,row in ipairs(group and group.rows or {}) do
        if row.processed then row.awardContextClosed=true end
    end
end
function I:MarkAward(uid,status)
    local row=self:GetRow(uid)
    if row then row.awardStatus=status end
end
function I:IsProcessed(uid)
    local row=self:GetRow(uid)
    return row and row.processed==true or false
end
function I:RestoreOutcome(entry)
    local row=entry and self:GetRow(entry.dropUID)
    if not row or not row.processed then return nil end
    if not row.winner then
        return {dropUID=entry.dropUID,status='COMPLETE',winner=nil,restored=true}
    end
    return {dropUID=entry.dropUID,itemID=entry.itemID,itemName=entry.itemName,
        raidKey=entry.raidKey,boss=entry.boss,status='COMPLETE',
        winner=row.winner,winningTicket=row.winningTicket,
        method=row.method or 'RECOVERED',awardStatus=row.awardStatus,
        test=false,restored=true}
end
function I:PrepareReset()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return false,'Stop the fake raid before starting a real loot opportunity.'
    end
    if not NLL.LootDetection or not NLL.LootDetection.lootOpen or
        not NLL.TicketLottery.liveLootObserved or
        not NLL.TicketLottery:AuthorityAllowed(false) then
        return false,'Open REAL raid loot as leader/officer before using /nll newloot.'
    end
    local a=NLL.TicketLottery.active
    if a and (a.status=='WAITING_FOR_ROLL' or a.status=='ROLL_UNCONFIRMED') then
        return false,'Resolve or cancel the pending server roll first.'
    end
    local aw=NLL.AwardWorkflow
    for _,r in pairs(aw and aw.liveRequests or {}) do
        if r and r.history and r.history.status=='AWARD_REQUESTED' then
            return false,'An award request is unresolved; investigate before resetting loot identity.'
        end
    end
    local previous=self:GetGroup()
    self.confirmation={at=Now(),previous=previous and previous.id}
    return true,'Only use for a DIFFERENT corpse. To start a new opportunity type /nll newloot confirm within 20 seconds. Do not use this to re-roll the same drop.'
end
function I:ConfirmReset()
    local c=self.confirmation
    self.confirmation=nil
    if not c or Now()-c.at>20 then
        return false,'Confirmation expired. Start with /nll newloot again.'
    end
    if not NLL.LootDetection.lootOpen or
        not NLL.TicketLottery.liveLootObserved or
        not NLL.TicketLottery:AuthorityAllowed(false) or
        (NLL.DebugSimulator and NLL.DebugSimulator:IsActive()) then
        return false,'Real loot window/authority is no longer valid.'
    end
    if (self:GetGroup() or {}).id~=c.previous then
        return false,'Loot opportunity changed; begin a new confirmation.'
    end
    local a=NLL.TicketLottery.active
    if a and (a.status=='WAITING_FOR_ROLL' or a.status=='ROLL_UNCONFIRMED') then
        return false,'Cannot reset while a server roll is unresolved.'
    end
    local success=NLL.LootDetection:ScanLootWindow(true)
    if not success then return false,'No supported real loot found; opportunity unchanged.' end
    return true,'New loot opportunity started. Previous winners remain in history; confirm the corpse really was different.'
end
