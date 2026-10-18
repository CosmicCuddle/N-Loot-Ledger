-- Dry-run automatic guild policy preview deliberately never awards ANYTHING.
local checks=0
local function ok(v,msg)assert(v,msg);checks=checks+1 end
local attempts=0
GiveMasterLoot=function()attempts=attempts+1;error("never request")end
local live=true
local unresolved=false
local previous=true
local actual={
 {itemID=17010,itemName="Fiery Core",itemLink="|Hitem:17010|h[Fiery Core]|h",
    status="GUILD_REVIEW",slotIndex=1,quantity=1,category="Trade Goods",leader="Leader"},
 {itemID=16800,itemName="Arcanist Boots",itemLink="|Hitem:16800|h[Boots]|h",
    status="RESERVED",slotIndex=2,quantity=1,category="Armor",leader="Leader"},
 {itemID=18259,itemName="Recipe",itemLink="|Hitem:18259|h[Recipe]|h",
    status="UNRESOLVED",slotIndex=3,quantity=1,category="Recipe",leader="Leader"},
 {itemID=17011,itemName="Lava Core",itemLink="|Hitem:17011|h[Lava Core]|h",
    status="GUILD_REVIEW",slotIndex=4,quantity=2,category="Trade Goods",leader="Leader"},
 {itemID=17204,itemName="Eye of Sulfuras",itemLink="|Hitem:17204|h[Eye]|h",
    status="SPECIAL_HOLD",slotIndex=5,quantity=1,category="Quest",leader="Leader"},
}
NaxxLootLottery={
    db={gearNeeds={{status="NEEDED",itemID=16800}},lootAwardHistory={}},
    GuildLootReview={Scan=function()
        if not live then return {},"CORPSE CLOSED" end
        return actual,"Real loot still open"
    end},
    GuildLootTransfer={
        IsUnresolved=function()return unresolved end,
        WasAttempted=function(_,id,slot)
            return previous and id==17011 and slot==4
        end
    }
}
assert(loadfile("NaxxLootLottery/Core/GuildLootAutoPreview.lua"))()
local P=NaxxLootLottery.GuildLootAutoPreview
local result=P:Build()
ok(result.automaticTransfers==0 and #result.rows==5,
    "all live gear, mats and special appear but never transfer")
ok(result.counts.candidates==1 and result.counts.reserved==1 and
   result.counts.held==2 and result.counts.blocked==1,
   "catalogue respected: one candidate, known need, two holds, old attempt")
ok(result.rows[1].status=="CANDIDATE_ONLY" and
   not result.rows[1].automaticTransferAuthorized,
   "unreserved crafting material is review candidate, NOT automatic award")
ok(result.rows[2].status=="RESERVATION_BLOCKED",
   "known NEED may never auto-route")
ok(result.rows[3].status=="MANUAL_HOLD" and
   result.rows[5].status=="MANUAL_HOLD",
   "pending recipe, quest, legendary and unknown classes remain held")
ok(result.rows[4].status=="PRIOR_ATTEMPT_BLOCKED",
    "separate previous item/slot remains locked after prior attempt")
unresolved=true
result=P:Build()
ok(result.counts.candidates==0 and result.counts.blocked==2,
    "unknown prior delivery blocks ALL guild candidates")
unresolved=false
previous=false
result=P:Build()
ok(result.counts.candidates==2 and result.automaticTransfers==0,
    "even with no known holds, two potential mats have NO transfer authorization")
live=false
result=P:Build()
ok(#result.rows==0 and result.message=="CORPSE CLOSED" and
   result.automaticTransfers==0,
    "old stale corpse records cannot generate auto-award candidates")
ok(attempts==0 and NaxxLootLottery.db.gearNeeds[1].status=="NEEDED",
    "preview never calls GiveMasterLoot or mutates Gear Plans")
print("PASS: "..checks.." preview-only unreserved gear/materials/quest safeguards")
