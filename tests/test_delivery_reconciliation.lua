-- Lua 5.1: write-ahead Master Loot attempts and non-awarding NO-RETRY review.
-- All Blizzard APIs are stubs. NEVER awards a real item or edits installed data.
local checks=0
local function ok(v,why)assert(v,why);checks=checks+1 end
local now=100
GetTime=function()return now end
date=function()return "2026-10-18" end
UnitName=function()return "Leader" end
GetLootMethod=function()return "master",nil,1 end
GetRaidRosterInfo=function(i)if i==1 then return "Leader",2 end end
GetNumLootItems=function()return 1 end
local link="|Hitem:16800:0|h[Arcanist Boots]|h"
GetLootSlotLink=function(i)if i==1 then return link end end
GetLootSlotInfo=function()return nil,nil,1,4,false end
GetMasterLootCandidate=function(i)if i==1 then return "Pikeotter" end end
LootFrame={selectedSlot=1,IsShown=function()return true end}
local authorized=true
local fake=false
local entry={dropUID="L1:1:16800",itemID=16800,
    itemName="Arcanist Boots",raidKey="MOLTEN_CORE",slotIndex=1}
local won={dropUID=entry.dropUID,itemID=16800,winner="Pikeotter",
    status="COMPLETE",test=false}
local sent=0
local beforeCall
local fail=true
GiveMasterLoot=function()
    sent=sent+1
    beforeCall=NaxxLootLottery.db.lootAwardHistory[1]
    ok(beforeCall and beforeCall.status=="AWARD_OUTCOME_UNKNOWN",
        "write-ahead saved audit must exist BEFORE API is called")
    ok(NaxxLootLottery.db.awardAttemptLocks[entry.dropUID]~=nil,
        "persistent immutable UID lock exists BEFORE API is called")
    if fail then error("API threw after attempting request") end
end
local plan={unchanged={character="Pikeotter",itemID=16800,status="NEEDED"}}
NaxxLootLottery={
    db={settings={directMasterLootEnabled=true,guildLootTransfersEnabled=true},
        gearNeeds=plan,lootAwardHistory={},guildLootTransferAudit={},
        lootReceiptTracker={},lootReconciliationAudit={},awardAttemptLocks={}},
    TicketLottery={liveLootObserved=true,
        AuthorityAllowed=function()return authorized end,
        GetActiveFor=function()return won end},
    LootDetection={lootOpen=true,GetCurrentLoot=function()return {entry} end},
    DebugSimulator={IsActive=function()return fake end},
    LootIdentity={GetRow=function()return nil end,
        MarkAward=function(_,uid,status)
            ok(uid==entry.dropUID and status~="OBTAINED",
               "award identity never asserts physical receipt")
        end},
}
local N=NaxxLootLottery
N.UI={currentLootSelected=1,RefreshCurrentLootPanel=function()end,
    RefreshOverview=function()end}
N.LootReceiptTracker={Get=function(_,uid)return N.db.lootReceiptTracker[uid] end}
assert(loadfile("NaxxLootLottery/Core/AwardWorkflow.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/LootReconciliation.lua"))()
local A=N.AwardWorkflow
local T=N.GuildLootTransfer
local R=N.LootReconciliation
ok(A:Review(entry),"live lottery review starts")
ok(A:ArmDirectAward(entry),"separate deliberate arm")
local done,msg=A:CommitDirectAward(entry)
ok(not done and msg:find("UNKNOWN") and sent==1,
    "thrown API call stays unknown, NEVER considered safe retry")
ok(won.awardStatus=="AWARD_OUTCOME_UNKNOWN" and
    N.db.lootAwardHistory[1].status=="AWARD_OUTCOME_UNKNOWN" and
    N.db.awardAttemptLocks[entry.dropUID].status=="AWARD_OUTCOME_UNKNOWN",
    "unknown survives in result, history and UID lock")
ok(not A:Review(entry) and sent==1,
    "duplicate direct award blocked after exception")
-- Even if another code path accidentally clears the displayed awardStatus
-- or old history is pruned, the permanent UID lock still prevents transfer.
won.awardStatus=nil
N.db.lootAwardHistory={}
ok(not A:Review(entry) and sent==1,
    "UID lock survives lost visible status/history")
-- Restore exact historical record to exercise the explicit investigation.
N.db.lootAwardHistory={beforeCall}
won.awardStatus="AWARD_OUTCOME_UNKNOWN"
local oldPlan=N.db.gearNeeds
local oldReceipt=N.db.lootReceiptTracker
local oldHistory=N.db.lootAwardHistory
local oldGuild=N.db.guildLootTransferAudit
local oldLock=N.db.awardAttemptLocks[entry.dropUID]
local oldRecord=N.db.lootAwardHistory[1]
ok(T:IsUnresolved(),"unknown winner attempt blocks guild transfers")
local items=R:List()
ok(#items==1 and items[1].kind=="WINNER" and not items[1].reviewed,
    "read-only list contains unresolved exact drop")
local u,notice=R:Arm("WINNER",entry.dropUID)
ok(u and notice:find("NO RETRY") and
    #N.db.lootReconciliationAudit==0,"first action arms without changing audit")
authorized=false
u,notice=R:ConfirmNoRetry()
ok(not u and #N.db.lootReconciliationAudit==0,
    "lost raid authority aborts armed review")
authorized=true
ok(R:Arm("WINNER",entry.dropUID),"rearm after authority recovery")
now=now+16
u=R:ConfirmNoRetry()
ok(not u and #N.db.lootReconciliationAudit==0,
    "15s timeout stops review without mutation")
now=now+1
ok(R:Arm("WINNER",entry.dropUID),"rearm for fresh confirmation")
u,notice=R:ConfirmNoRetry()
ok(u and notice:find("NOT confirmed") and
    oldRecord.reconciliationStatus=="CLOSED_NO_RETRY",
    "deliberate no-retry closure is audited WITHOUT claiming delivery")
ok(#N.db.lootReconciliationAudit==1 and
    N.db.lootReconciliationAudit[1].identifier==entry.dropUID and
    oldRecord.status=="AWARD_OUTCOME_UNKNOWN",
    "original unknown result and immutable UID retained")
ok(N.db.gearNeeds==oldPlan and plan.unchanged.status=="NEEDED" and
    N.db.lootReceiptTracker==oldReceipt and N.db.lootAwardHistory==oldHistory,
    "no Gear Plans or receipt/winner history replaced")
ok(N.db.awardAttemptLocks[entry.dropUID]==oldLock and
    not A:Review(entry),"closed review never unlocks this original award")
ok(not R:ConfirmNoRetry() and not R:Arm("WINNER",entry.dropUID),
    "no second review event or duplicate action")
ok(not T:IsUnresolved(),
    "explicit NO-RETRY review closes ONLY the global investigation gate")
local g={itemID=17010,slotIndex=2,status="AWARD_OUTCOME_UNKNOWN",
    recipient="Leader",note="old unknown guild request"}
N.db.guildLootTransferAudit[1]=g
ok(T:IsUnresolved() and T:WasAttempted(17010,2),
    "guild uncertainty blocks new requests before review")
fake=true
ok(not R:Arm("GUILD",1),"simulation cannot close real histories")
fake=false
ok(R:Arm("GUILD",1),"review old material request by stable audit index")
g.status="LOOT_SLOT_CLEARED"
u=R:ConfirmNoRetry()
ok(not u and not g.reconciliationStatus,
    "changed observation cannot be confirmed against stale review")
g.status="AWARD_OUTCOME_UNKNOWN"
ok(R:Arm("GUILD",1),"review refreshed exact guild material attempt")
ok(R:ConfirmNoRetry(),"material investigation closed after two deliberate commands")
ok(not T:IsUnresolved() and T:WasAttempted(17010,2),
    "global block can close but SAME PHYSICAL ITEM/SLOT stays locked")
ok(g.status=="AWARD_OUTCOME_UNKNOWN" and
    N.db.guildLootTransferAudit==oldGuild and
    #N.db.lootReconciliationAudit==2,
    "original guild audit kept, separate closure appended")
ok(sent==1,"reconciliation never calls GiveMasterLoot")
-- Confirmed receipts are not ambiguous. They cannot be overwritten by review.
local confirmed={dropUID="L3:1:16800",itemID=16800,winner="Pikeotter",
    status="AWARD_OUTCOME_UNKNOWN"}
N.db.lootAwardHistory[2]=confirmed
N.db.lootReceiptTracker[confirmed.dropUID]={
    status="OBTAINED",itemID=16800,character="Pikeotter"}
ok(not T:IsUnresolved(),
    "matching leader-confirmed receipt clears unrelated global block")
ok(not R:Arm("WINNER",confirmed.dropUID),
    "OBTAINED receipt cannot be relabelled as unknown")
N.db.lootReceiptTracker[confirmed.dropUID].character="Another"
ok(T:IsUnresolved(),
    "receipt for a different winner NEVER resolves unknown delivery")
N.db.lootReceiptTracker[confirmed.dropUID].character="Pikeotter"
ok(not T:IsUnresolved(),"restored exact match removes only global block")
-- No recreated module should reset original mutable histories.
ok(oldPlan==N.db.gearNeeds and
   N.db.lootAwardHistory[1]==oldRecord and #N.db.lootReconciliationAudit==2,
   "old data preserved across reconciliation")
print("PASS: "..checks.." write-ahead / unknown / no-retry / bot-plan safety assertions")
