-- WoW 3.3.5a / Lua 5.1: grouped visible-copy audit is evidence only.
local checks=0
local function ok(v,message) assert(v,message); checks=checks+1 end
local fake=false
local guid="CURRENT_TARGET_A"
local opened=true
local links={
    "|Hitem:17010:0|h[Fiery Core]|h",
    "|Hitem:17010:0|h[Fiery Core]|h",
    "|Hitem:17011:0|h[Lava Core]|h",
    "|Hitem:16800:0|h[Arcanist Boots]|h",
    "|Hitem:19147:0|h[Ring of Spell Power]|h",
    nil
}
GetNumLootItems=function()return #links end
GetLootSlotLink=function(i)return links[i] end
GetLootSlotInfo=function(i)
    return nil,nil,i==1 and 5 or i==3 and 20 or 1,4,false
end
UnitGUID=function(name)
    ok(name=="target","target is a hint, NOT source evidence")
    return guid
end
-- Patch 5.0.4+ API must not be invoked in this addon on 3.3.5a.
GetLootSourceInfo=function()error("No 5.0.4 source API permitted")end
local awards=0
GiveMasterLoot=function()awards=awards+1;error("NO PHYSICAL GRANT")end
RandomRoll=function()awards=awards+1;error("NO ROLL")end
SendAddonMessage=function()awards=awards+1;error("NO MESSAGES")end
local guild={{itemID=17010,slotIndex=1,status="LOOT_SLOT_CLEARED",
    reconciliationStatus="CLOSED_NO_RETRY"}}
local winners={{itemID=16800,slotIndex=4,status="AWARD_OUTCOME_UNKNOWN",
    reconciliationStatus="CLOSED_NO_RETRY"}}
local locks={historic={itemID=16800,status="AWARD_REQUESTED"}}
local gear={}
for i=1,604 do
    local key="Bot"..i
    gear[key]={character=key,itemID=19147,raidKey="MOLTEN_CORE",
        status=i<=469 and "NEEDED" or "GREED",source="BOT_GEAR_PLAN"}
end
local db={
    guildLootTransferAudit=guild,lootAwardHistory=winners,
    awardAttemptLocks=locks,gearNeeds=gear,
    localWishlists={Leader={MOLTEN_CORE={[19147]=true}}},
    lootReceiptTracker={old={status="WON_AWAITING_ITEM"}},
    lotteryHistory={{winner="Someone"}},
    raidSession={lootIdentity={oldProcessed={["17010"]=true}}},
    settings={directMasterLootEnabled=false,
        guildLootTransfersEnabled=false,guildAutoPreviewEnabled=false},
}
local refs={guild=db.guildLootTransferAudit,
    winners=db.lootAwardHistory,locks=db.awardAttemptLocks,
    gear=db.gearNeeds,wish=db.localWishlists,
    receipt=db.lootReceiptTracker,lottery=db.lotteryHistory,
    identity=db.raidSession.lootIdentity,
    settings=db.settings}
NaxxLootLottery={db=db,
    DebugSimulator={IsActive=function()return fake end},
    LootDetection={lootOpen=true},
    TicketLottery={liveLootObserved=true},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/LootSourceDiagnostics.lua"))()
assert(loadfile("NaxxLootLottery/Core/LootCopyAudit.lua"))()
local A=N.LootCopyAudit
local result=A:Inspect()
ok(result.mode=="READ_ONLY" and result.client=="WRATH_335A" and
   #result.items==4 and result.visibleSlots==5 and
   result.visibleUnits==28 and result.heldItemIDs==2,
   "5 slot copies/grouped into 4 IDs, visible stack units not item IDs")
ok(not result.canUnlock and not result.canReroll and
   not result.canRetry and not result.canAward and
   not result.autoTransferAuthorized and
   not result.perSourceVerified and not result.physicalCopyVerified and
   not result.receiptVerified and not result.multiCopyPlanSupported and
   not result.uniqueEquippedVerified,
   "no condition can authorize retry, ticket, extra wishlist copy or award")
local core=result.items[3]
ok(core.itemID==17010 and core.visibleSlots==2 and
   core.visibleStackUnits==6 and core.maxStackInOneSlot==5 and
   core.hasPreviousAttempt and core.priorGuildAttempt and
   core.status=="PRIOR_ATTEMPT_HELD",
   "two moved material slots and stack quantity preserve old guild hold")
local lava=result.items[4]
ok(lava.itemID==17011 and lava.visibleSlots==1 and
   lava.visibleStackUnits==20 and lava.status=="STACK_QUANTITY_UNVERIFIED" and
   not lava.priorGuildAttempt and not lava.canAward,
   "single 20-unit stack is NOT 20 uniquely grantable new copies")
local ring=result.items[2]
ok(ring.itemID==19147 and not ring.uniqueEquippedVerified and
   ring.allowedAdditionalWishCopies==0 and
   not ring.physicalCopyVerified,
   "ring has NO second-copy equip or award proof from two ring slots")
local armor=result.items[1]
ok(armor.itemID==16800 and armor.priorWinnerAttempt and
   armor.status=="PRIOR_ATTEMPT_HELD",
   "uncertain old winner award always held even when slot changed")
local lines=A:Report()
ok(#lines>=4 and lines[1]:find("NO RETRY",1,true) and
   table.concat(lines,"\n"):find("PRIOR ATTEMPT HELD",1,true),
   "chat report clearly states duplicated item safety and old hold")
guid="CURRENT_TARGET_B"
links[1],links[2]=links[2],links[1]
local retarget=A:Inspect()
ok(retarget.heldItemIDs==2 and retarget.items[3].canRetry==false,
   "moving slots/changing current target NEVER changes old item ID locks")
links={"|Hitem:17010:0|h[Fiery Core]|h"}
GetNumLootItems=function()return 1 end
local one=A:Inspect()
ok(one.items[1].status=="PRIOR_ATTEMPT_HELD" and
   one.items[1].visibleSlots==1 and one.items[1].visibleStackUnits==5,
   "old held item remains held even when only one loot slot appears")
-- Force non-source proof despite malicious or future-looking data.
local originalInspect=N.LootSourceDiagnostics.Inspect
N.LootSourceDiagnostics.Inspect=function()
    return {sourceVerified=true,canUnlock=true,
        autoTransferAuthorized=true,items={{itemID=17010,
        slotIndex=1,quantity=1,canUnlock=true,sourceVerified=true,
        transferAuthorized=true}}}
end
local hostile=A:Inspect()
ok(#hostile.items==0 and hostile.visibleSlots==0 and
   not hostile.canUnlock and not hostile.canAward and
   hostile.message:find("refused",1,true),
   "future/malicious claimed source authority fails closed")
N.LootSourceDiagnostics.Inspect=originalInspect
N.LootDetection.lootOpen=false
ok(#A:Inspect().items==0 and A:Inspect().visibleSlots==0,
   "closed real loot shows no fabricated CURRENT slot data")
N.LootDetection.lootOpen=true
N.TicketLottery.liveLootObserved=false
ok(#A:Inspect().items==0,"not verified by real loot observer")
N.TicketLottery.liveLootObserved=true
fake=true
ok(#A:Inspect().items==0,"Debug Simulator never creates live award evidence")
fake=false
local realLink=GetLootSlotLink
GetLootSlotLink=nil
ok(#A:Inspect().items==0,"missing 3.3.5a API fails safely")
GetLootSlotLink=realLink
N.LootSourceDiagnostics=nil
ok(#A:Inspect().items==0,"missing lower-level diagnostic fails safely")
ok(db.guildLootTransferAudit==refs.guild and
   db.lootAwardHistory==refs.winners and
   db.awardAttemptLocks==refs.locks and
   db.gearNeeds==refs.gear and
   db.localWishlists==refs.wish and
   db.lootReceiptTracker==refs.receipt and
   db.lotteryHistory==refs.lottery and
   db.raidSession.lootIdentity==refs.identity and
   db.settings==refs.settings and
   db.settings.directMasterLootEnabled==false and
   db.settings.guildLootTransfersEnabled==false and
   db.settings.guildAutoPreviewEnabled==false and
   awards==0,
   "all audit, winner, role/wishlist, receipt, consent states preserved")
local planCount=0
for _,plan in pairs(gear) do
    planCount=planCount+1
    ok(plan.status=="NEEDED" or plan.status=="GREED",
       "604 saved original Gear Plan statuses never mutate")
end
ok(planCount==604,"original 604 reservations never become extra copies")
print("PASS: "..checks.." duplicate-copy audit and immutable no-retry proofs")
