-- Source hints on WoW 3.3.5a MUST NEVER grant physical identity.
-- Lua 5.1 fixture with isolated fake WoW loot APIs and SavedVariables.
local checks=0
local function ok(v,msg) assert(v,msg);checks=checks+1 end
local fake=false
local opened=true
local guid="0xF13000AB00002345"
local links={
    "|Hitem:17010:0|h[Fiery Core]|h",
    "|Hitem:17010:0|h[Fiery Core]|h",
    "|Hitem:16800:0|h[Arcanist Boots]|h",
    "|Hitem:17011:0|h[Lava Core]|h",
    nil,
}
GetNumLootItems=function() return 5 end
GetLootSlotLink=function(slot) return links[slot] end
GetLootSlotInfo=function(slot) return nil,nil,slot==1 and 3 or 1,4,false end
local targetCalls=0
UnitGUID=function(unit)
    ok(unit=="target","diagnostic only samples current target")
    targetCalls=targetCalls+1
    return guid
end
-- Explicitly forbid a post-Wrath function; the addon must not call it
-- even if a private emulator installed such a global.
GetLootSourceInfo=function() error("5.0.4+ API must never be used") end
local actualGrants=0
GiveMasterLoot=function() actualGrants=actualGrants+1;error("NO GIVE") end
RandomRoll=function() actualGrants=actualGrants+1;error("NO ROLL") end
local guild={
    {itemID=17010,slotIndex=1,status="LOOT_SLOT_CLEARED",
        reconciliationStatus="CLOSED_NO_RETRY",recipient="Leader"},
}
local awards={{
    itemID=16800,slotIndex=4,status="AWARD_OUTCOME_UNKNOWN",
    reconciliationStatus="CLOSED_NO_RETRY",dropUID="L10:1:16800",
}}
local preservedGear={Gorak={character="Gorak",itemID=16800,status="NEEDED"}}
local preservedReceipt={["L10:1:16800"]={
    itemID=16800,status="WON_AWAITING_ITEM"}}
local original={
    guildLootTransferAudit=guild,lootAwardHistory=awards,
    lootReceiptTracker=preservedReceipt,gearNeeds=preservedGear,
    awardAttemptLocks={["L10:1:16800"]={status="AWARD_REQUESTED"}},
    lootReconciliationAudit={{action="CLOSED_NO_RETRY",identifier=1}},
    localWishlists={Gorak={MOLTEN_CORE={[16800]=true}}},
    settings={guildAutoPreviewEnabled=false,
        directMasterLootEnabled=false,guildLootTransfersEnabled=false},
}
NaxxLootLottery={
    db=original,
    DebugSimulator={IsActive=function()return fake end},
    LootDetection={lootOpen=true},
    TicketLottery={liveLootObserved=true},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/LootSourceDiagnostics.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
local D=N.LootSourceDiagnostics
local T=N.GuildLootTransfer
local first=D:Inspect()
ok(first.mode=="READ_ONLY" and
   not first.sourceVerified and not first.canUnlock and
   not first.autoTransferAuthorized,
   "current target GUID is NEVER approved corpse proof")
ok(first.targetGUIDHint==guid and targetCalls==1,
   "target GUID is merely informational and not persisted")
ok(first.itemSlots==4 and #first.items==4 and
   first.priorAttemptHolds==3 and first.repeatedSlots==2,
   "repeated material and old guild/winner attempts conservatively counted")
ok(first.items[1].priorGuildAttempt and first.items[2].priorGuildAttempt and
   first.items[1].repeatedInWindow and first.items[2].repeatedInWindow,
   "multiple copies remain unresolved even on an open window")
ok(first.items[3].priorWinnerAttempt and
   not first.items[4].priorWinnerAttempt and
   not first.items[4].priorGuildAttempt,
   "prior winner hold and unrelated item are kept distinct")
for _,r in ipairs(first.items) do
    ok(not r.sourceVerified and not r.canUnlock and
       not r.transferAuthorized,"no live item row can unlock old lock")
end
local msgs=D:Report()
ok(#msgs>=4 and msgs[1]:find("source UNVERIFIED",1,true) and
   msgs[2]:find("NOT a loot-source GUID",1,true),
   "user-facing command clearly explains limits, never hints permission")
ok(msgs[3]:find("GUILD ATTEMPT LOCK",1,true) and
   msgs[3]:find("NO RETRY",1,true),
   "prior physical guild request remains explicitly labelled")
-- Changed target can NEVER prove different loot-source identity.
guid="0xF13000AB00007890"
links[1]="|Hitem:17011:0|h[Lava Core]|h"
links[2]="|Hitem:17010:0|h[Fiery Core]|h"
links[3]="|Hitem:17010:0|h[Fiery Core]|h"
local other=D:Inspect()
ok(other.targetGUIDHint~=first.targetGUIDHint and
   other.priorAttemptHolds>=2 and
   not other.canUnlock and T:WasAttempted(17010,30),
   "different target and moved slot CANNOT override item-ID attempt lock")
ok(guild[1].reconciliationStatus=="CLOSED_NO_RETRY" and
   original.awardAttemptLocks["L10:1:16800"].status=="AWARD_REQUESTED",
   "previously investigated and write-ahead item locks remain intact")
guid=nil
local noTarget=D:Inspect()
ok(noTarget.targetGUIDHint==nil and
   not noTarget.sourceVerified and not noTarget.canUnlock,
   "no target cannot invent a source identity")
N.LootDetection.lootOpen=false
local closed=D:Inspect()
ok(closed.itemSlots==0 and not closed.targetGUIDHint and
   closed.message:find("closed",1,true),
   "closed window cannot reuse stale target as proof")
N.LootDetection.lootOpen=true
N.TicketLottery.liveLootObserved=false
local unverified=D:Inspect()
ok(unverified.itemSlots==0 and not unverified.targetGUIDHint,
   "saved/fake observed loot without real ticket context is not live proof")
N.TicketLottery.liveLootObserved=true
fake=true
local simulated=D:Inspect()
ok(simulated.itemSlots==0 and not simulated.targetGUIDHint and
   simulated.message:find("Fake raid",1,true),
   "simulator never samples or endorses physical corpse source")
fake=false
local previousSlot=GetLootSlotLink
GetLootSlotLink=nil
local apiMissing=D:Inspect()
ok(apiMissing.itemSlots==0 and apiMissing.message:find("unavailable",1,true),
   "missing old Wrath API fails safely without access or transfer")
GetLootSlotLink=previousSlot
ok(original.guildLootTransferAudit==guild and
   original.lootAwardHistory==awards and original.gearNeeds==preservedGear and
   original.lootReceiptTracker==preservedReceipt and
   #original.guildLootTransferAudit==1 and #original.lootAwardHistory==1 and
   #original.lootReconciliationAudit==1 and
   original.settings.guildAutoPreviewEnabled==false and
   original.settings.directMasterLootEnabled==false and
   original.settings.guildLootTransfersEnabled==false and actualGrants==0,
   "all saved structures and physical consent remain unchanged; zero grants")
print("PASS: "..checks.." 3.3.5a loot-source diagnostics and permanent NO RETRY")
