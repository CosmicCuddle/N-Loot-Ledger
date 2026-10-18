-- A winning roll is not physical receipt; no guild proposal may bypass
-- a deleted/obsolete reservation while a receipt or human ACK is pending.
-- Lua 5.1; zero Master Loot calls and ZERO SavedVariables changes.
local n=0
local function ok(v,msg) assert(v,msg);n=n+1 end
local loot={17010,17011,17012,17013}
local awardCalls=0
GiveMasterLoot=function()awardCalls=awardCalls+1;error("No awards from preview")end
RandomRoll=function()error("No rolls from preview")end
GetNumLootItems=function()return #loot end
GetLootSlotLink=function(slot)
    return "|Hitem:"..loot[slot]..":0|h[Material "..loot[slot].."]|h"
end
GetLootSlotInfo=function()return nil,nil,1,2,false end
GetItemInfo=function(id)
    return "Material "..id,nil,2,nil,nil,"Trade Goods"
end
GetNumRaidMembers=function()return 2 end
GetRaidRosterInfo=function(i)
    if i==1 then return "Leader",2 end
    return "Pikeotter",0
end
GetLootMethod=function()return "master",nil,1 end
UnitName=function()return "Leader" end
local receiptPending={dropUID="L1:1:17010",itemID=17010,
    character="Throgar",status="WON_AWAITING_ITEM"}
local remotePending={dropUID="L1:2:17011",itemID=17011,
    character="Pikeotter",status="OBTAINED",
    remoteSyncStatus="AWAITING_PLAYER"}
local confirmed={dropUID="L1:3:17012",itemID=17012,
    character="Pikeotter",status="OBTAINED",
    remoteSyncStatus="ACKNOWLEDGED"}
local old={dropUID="L1:4:17013",itemID=17013,
    character="Throgar",status="OBTAINED"}
local tracking={[receiptPending.dropUID]=receiptPending,
    [remotePending.dropUID]=remotePending,
    [confirmed.dropUID]=confirmed,
    [old.dropUID]=old}
local gearNeeds={
    oldBot={itemID=17010,raidKey="MOLTEN_CORE",status="OBTAINED",
        character="Throgar",source="BOT_GEAR_PLAN"},
    oldPlayer={itemID=17011,raidKey="MOLTEN_CORE",status="OBTAINED",
        character="Pikeotter",source="PLAYER_SUBMITTED"},
}
local wishlist={}
local inbox={}
local settings={directMasterLootEnabled=true,guildLootTransfersEnabled=true}
NaxxLootLottery={
    db={settings=settings,gearNeeds=gearNeeds,localWishlists=wishlist,
        submissionInbox=inbox,lootReceiptTracker=tracking,
        guildLootTransferAudit={},lootAwardHistory={}},
    LootDetection={lootOpen=true},
    TicketLottery={liveLootObserved=true,active=nil,
        AuthorityAllowed=function()return true end},
    DebugSimulator={IsActive=function()return false end},
    Data={MoltenCore={GetItem=function()end}},
    Database={GetLocalInterest=function()return "NEEDED" end},
    AwardWorkflow={verification=nil,liveRequests={}},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildAutoPreview.lua"))()
local G=N.GuildLootReview
local P=N.GuildAutoPreview
local rows=G:Scan()
ok(rows[1].status=="UNRESOLVED" and rows[1].receiptPending==1,
    "orphaned winner without active Need still held for receipt")
ok(rows[2].status=="UNRESOLVED" and rows[2].receiptPending==1,
    "leader-obtained human item is held until PLAYER acknowledges")
ok(rows[3].status=="GUILD_REVIEW" and rows[4].status=="GUILD_REVIEW",
    "fully acknowledged or complete bot historical copies do not block unrelated new proposals")
local dry=P:Plan()
ok(#dry.items==4 and dry.proposed==2,
    "auto preview proposes only fully cleared historical statuses")
ok(dry.items[1].decision=="HOLD_UNCERTAIN" and
   dry.items[2].decision=="HOLD_UNCERTAIN" and
   dry.items[3].decision=="PROPOSED_ONLY",
   "auto-routing summary inherits receipt holds from conservative guild review")
local sample={slotIndex=1,itemID=rows[1].itemID,
    itemLink=rows[1].itemLink,quantity=1}
local allowed,notice=N.GuildLootTransfer:Validate(sample)
ok(not allowed and notice:find("Live loot or reservation changed",1,true),
    "manual guild transfers also block orphaned winners")
sample={slotIndex=2,itemID=rows[2].itemID,
    itemLink=rows[2].itemLink,quantity=1}
allowed=N.GuildLootTransfer:Validate(sample)
ok(not allowed,"manual transfer also blocks pending player acknowledgement")
remotePending.remoteSyncStatus="WAITING_FOR_PLAYER"
dry=P:Plan()
ok(dry.items[2].decision=="HOLD_UNCERTAIN",
    "offline pending human ACK remains held")
remotePending.remoteSyncStatus="SEND_FAILED"
dry=P:Plan()
ok(dry.items[2].decision=="HOLD_UNCERTAIN",
    "failed player notification cannot clear a remote reservation")
remotePending.remoteSyncStatus="ACKNOWLEDGED"
dry=P:Plan()
ok(dry.items[2].decision=="PROPOSED_ONLY",
    "matching exact receipt ACK safely lifts this additional preview hold")
receiptPending.status="OBTAINED"
dry=P:Plan()
ok(dry.items[1].decision=="PROPOSED_ONLY",
    "independently completed bot receipt lifts pending receipt hold")
ok(N.db.gearNeeds==gearNeeds and
   N.db.lootReceiptTracker==tracking and
   receiptPending.status=="OBTAINED" and
   N.db.localWishlists==wishlist and
   #N.db.guildLootTransferAudit==0,
   "preview never overwrites plans or appends audit history")
N.LootDetection.lootOpen=false
dry=P:Plan()
ok(#dry.items==0 and dry.realTransfers==0,
    "despawned corpse never produces new proposals")
ok(awardCalls==0,"neither manual validation nor automation preview requests loot")
print("PASS: "..n.." pending winner/remote ACK manual-and-auto guild hold assertions")
