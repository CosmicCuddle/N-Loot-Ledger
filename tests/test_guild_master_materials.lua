-- Lua 5.1: a Guild material targets the actual GUILD MASTER, never
-- the distinct RAID LEADER. All API actions are intercepted in this mock.
local count=0
local given={}
local clock=50
GetTime=function()return clock end
date=function()return "2026-10-30" end
UnitName=function()return "MasterLooter" end
local raid={"RaidLeader","MasterLooter","GuildBoss"}
GetNumRaidMembers=function()return #raid end
GetRaidRosterInfo=function(i)
    return raid[i],i==1 and 2 or 0
end
local online=true
GetNumGuildMembers=function()return 3 end
GetGuildRosterInfo=function(i)
    if i==1 then
        return "GuildBoss","Guild Master",0,nil,nil,nil,nil,nil,online
    elseif i==2 then
        return "RaidLeader","Officer",1,nil,nil,nil,nil,nil,true
    end
    return "MasterLooter","Member",2,nil,nil,nil,nil,nil,true
end
local candidates={"GuildBoss","RaidLeader"}
GetMasterLootCandidate=function(i) return candidates[i] end
GetLootMethod=function()return "master",nil,2 end
local selected=1
LootFrame={IsShown=function()return true end,selectedSlot=1}
local slots={17011,7075,18563}
GetNumLootItems=function()return #slots end
GetLootSlotLink=function(i)
    local id=slots[i]
    return id and ("|Hitem:"..id..":0|h[Item "..id.."]|h") or nil
end
GetLootSlotInfo=function()return nil,nil,1,2,false end
GetItemInfo=function(id)
    return "Item "..id,nil,id==18563 and 5 or 2,nil,nil,"Trade Goods"
end
local threshold=1
GetLootThreshold=function() return threshold end
GiveMasterLoot=function(slot,idx)
    count=count+1;given[#given+1]={slot=slot,idx=idx}
end
local N={
    db={gearNeeds={},localWishlists={},localWishlistObtained={},
        lootReceiptTracker={},submissionInbox={},lootAwardHistory={},
        guildLootTransferAudit={},
        settings={guildLootTransfersEnabled=true,directMasterLootEnabled=true}},
    DebugSimulator={IsActive=function()return false end},
    TicketLottery={liveLootObserved=true,AuthorityAllowed=function()return true end},
    LootDetection={lootOpen=true},
    Data={MoltenCore={GetItem=function(_,id)
        if id==18563 then return {legendary=true,manualOnly=true} end
        if id==17011 then return {manualOnly=true,manualReason="Crafting material"} end
        return nil
    end,IsRecipeItem=function()return false end}},
    AwardWorkflow={liveRequests={}}
}
NaxxLootLottery=N
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
local G=N.GuildLootReview
local T=N.GuildLootTransfer
assert(G:GetLeader()=="RaidLeader" and
    G:GetGuildMaster()=="GuildBoss","raid and guild masters differ")
local rows=G:Scan()
assert(rows[1].status=="GUILD_REVIEW" and
    rows[1].guildMaterial and rows[1].guildMaster=="GuildBoss")
assert(rows[2].status=="GUILD_REVIEW" and
    rows[2].guildMaterial,"Core of Earth (7075) can be reviewed")
assert(rows[3].status=="SPECIAL_HOLD","Windseeker never guild-routed")
threshold=3
local blocked=G:Scan()
assert(blocked[1].status=="BELOW_THRESHOLD" and
    blocked[2].status=="BELOW_THRESHOLD",
    "ordinary materials below Master Loot threshold cannot be assigned")
threshold=1
local target={slotIndex=1,itemID=17011,quantity=1,
    itemLink=rows[1].itemLink}
assert(T:Review(target))
assert(T.review.context.recipientKind=="GUILD_MASTER" and
    T.review.context.leader=="GuildBoss")
assert(count==0,"review has no physical action")
online=false
assert(not T:Arm() and count==0,"offline guild master blocks transfer")
online=true
candidates={"RaidLeader","MasterLooter"}
assert(not T:Review(target),"raid leader is never an allowed fallback")
candidates={"GuildBoss","RaidLeader"}
assert(T:Review(target) and T:Arm())
raid[3]="SomeoneElse"
assert(not T:Commit() and count==0,
    "guild master leaving raid blocks previously armed transfer")
raid[3]="GuildBoss"
assert(T:Review(target) and T:Arm())
candidates={"RaidLeader","GuildBoss"}
assert(not T:Commit() and count==0,
    "Master Loot candidate order changed; restart exact confirmation")
candidates={"GuildBoss","RaidLeader"}
assert(T:Review(target) and T:Arm())
assert(T:Commit() and count==1 and given[1].slot==1 and given[1].idx==1)
assert(N.db.guildLootTransferAudit[1].recipient=="GuildBoss" and
    N.db.guildLootTransferAudit[1].recipientKind=="GUILD_MASTER" and
    N.db.guildLootTransferAudit[1].status=="AWARD_REQUESTED")
assert(not T:Commit() and count==1)
assert(not T:Review(target) and count==1,
    "same material cannot auto retry after a physical request")
print("PASS: guild master distinct from raid leader, exact no-retry material routing")
