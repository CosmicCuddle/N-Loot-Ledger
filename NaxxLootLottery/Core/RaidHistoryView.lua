-- WoW 3.3.5a Lua 5.1: read-only combined lottery-winner / award-attempt view.
-- A lottery WINNER is never inventory RECEIVED or an actual item grant.
-- Starting a new run changes only the VISIBLE cutoff, never the audit rows.
local N=NaxxLootLottery
N.RaidHistoryView=N.RaidHistoryView or {}
local H=N.RaidHistoryView
local function Timestamp()
    return type(date)=="function" and date("%Y-%m-%d %H:%M:%S") or nil
end
local function Actor()
    return type(UnitName)=="function" and UnitName("player") or nil
end
local function Now()
    return type(GetTime)=="function" and GetTime() or nil
end
local function SafeRows(t)
    return type(t)=="table" and t or {}
end
local function Sort(a,b)
    if a.when~=b.when then return a.when>b.when end
    return a.seq>b.seq
end
function H:Build(showAll)
    local db=N.db or {}
    local cutoff=not showAll and type(db.raidHistoryView)=="table"
        and db.raidHistoryView.startedAfter or nil
    local result={}
    local byDrop={}
    for i,a in ipairs(SafeRows(db.lootAwardHistory)) do
        if type(a)=="table" and a.test~=true and
            (not cutoff or
             (type(a.when)=="string" and a.when>cutoff)) then
            local r={
                itemID=a.itemID,itemName=a.itemName or "Unknown item",
                winner=a.winner or a.recipient or "Unknown",
                when=a.when or "Unknown",status=a.status or "UNKNOWN",
                dropUID=a.dropUID, selectionType=a.selectionType,
                priorityTier=a.priorityTier,
                note=a.note, source="PHYSICAL_ATTEMPT",original=a,
                deliveryVerified=false,receiptUnknown=true,
                seq=i+100000,
            }
            result[#result+1]=r
            if type(a.dropUID)=="string" and a.dropUID~="" then
                byDrop[a.dropUID]=true
            end
        end
    end
    for i,a in ipairs(SafeRows(db.lotteryHistory)) do
        if type(a)=="table" and a.test~=true and
           a.status=="COMPLETE" and type(a.winner)=="string"
           and a.winner~="" and
           (not cutoff or
            (type(a.when)=="string" and a.when>cutoff)) and
           (type(a.dropUID)~="string" or not byDrop[a.dropUID]) then
            result[#result+1]={
                itemID=a.itemID,itemName=a.itemName or "Unknown item",
                winner=a.winner,when=a.when or "Unknown",
                status="ROLL_WINNER_ONLY",dropUID=a.dropUID,
                selectionType=a.selectionType,
                priorityTier=a.tier,note=a.note,
                source="LOTTERY",original=a,
                deliveryVerified=false,receiptUnknown=true,seq=i,
            }
        end
    end
    table.sort(result,Sort)
    return result
end
function H:Cancel()self.pending=nil end
function H:ArmNewRun()
    self:Cancel()
    if not N.db then return false,"Saved database unavailable." end
    if N.DebugSimulator and N.DebugSimulator.IsActive and
       N.DebugSimulator:IsActive() then
        return false,"Close the Debug Lab before starting a new view."
    end
    if N.LootDetection and N.LootDetection.lootOpen then
        return false,"Close the loot window before starting a new view."
    end
    if N.TicketLottery and N.TicketLottery.active and
       N.TicketLottery.active.status~="COMPLETE" then
        return false,"Finish/cancel the pending lottery first."
    end
    local stamp,actor,seconds=Timestamp(),Actor(),Now()
    if not stamp or not actor or actor=="" or type(seconds)~="number" then
        return false,"Clock or acting character unavailable."
    end
    self.pending={at=seconds,when=stamp,actor=actor,
        lottery=N.db.lotteryHistory,awards=N.db.lootAwardHistory,
        lotteryCount=#SafeRows(N.db.lotteryHistory),
        awardCount=#SafeRows(N.db.lootAwardHistory)}
    return true,"CONFIRM New Run View within 15 seconds. Old winner and "..
        "award histories will remain intact. No loot actions."
end
function H:ConfirmNewRun()
    local p=self.pending
    self:Cancel()
    if not p or type(Now())~="number" or
       Now()<p.at or Now()-p.at>15 or Actor()~=p.actor or
       not N.db or N.db.lotteryHistory~=p.lottery or
       N.db.lootAwardHistory~=p.awards or
       #SafeRows(N.db.lotteryHistory)~=p.lotteryCount or
       #SafeRows(N.db.lootAwardHistory)~=p.awardCount or
       (N.DebugSimulator and N.DebugSimulator.IsActive and
        N.DebugSimulator:IsActive()) or
       (N.LootDetection and N.LootDetection.lootOpen) or
       (N.TicketLottery and N.TicketLottery.active and
        N.TicketLottery.active.status~="COMPLETE") then
        return false,"New Run View expired or raid context changed. No changes."
    end
    -- The strict > cutoff avoids displaying old events created
    -- in the exact second the operator clicked Confirm.
    N.db.raidHistoryView={startedAfter=Timestamp() or p.when,
        startedBy=p.actor}
    return true,"New Run View started. ALL prior winners and physical "..
        "attempt histories are still preserved. Select All History to review."
end
