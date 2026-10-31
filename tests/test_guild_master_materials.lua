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
local stackCount=1
GetLootSlotInfo=function()return nil,nil,stackCount,2,false end
local specialType=false
local specialQuality=false
GetItemInfo=function(id)
    return "Item "..id,nil,
        (id==18563 or (id==17011 and specialQuality)) and 5 or 2,
        nil,nil,(id==17011 and specialType) and "Quest" or "Trade Goods"
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
threshold=nil
local unknown=G:Scan()
assert(unknown[1].status=="THRESHOLD_UNKNOWN" and
    unknown[2].status=="THRESHOLD_UNKNOWN",
    "unknown threshold must not expose guild master assignment")
threshold=1
specialType=true
local quest=G:Scan()
assert(quest[1].status=="SPECIAL_HOLD",
    "an ID reused by a custom server as a quest item remains held")
specialType=false
specialQuality=true
local legendary=G:Scan()
assert(legendary[1].status=="SPECIAL_HOLD",
    "an ID reused as a legendary/special item remains held")
specialQuality=false
local target={slotIndex=1,itemID=17011,quantity=1,
    itemLink=rows[1].itemLink,state="DETECTED",
    dropUID="LIVE-MATERIAL:1"}
-- Earlier Guild Master transfer behavior was superseded by CosmicCuddle's
-- 31 Oct owner decision. A guild-material item is NEVER physically sent
-- through the old Guild Transfer modal, even when both consents are ON.
local allowed,message=T:Review(target)
assert(not allowed and message:find("leader%-only") and count==0,
    "owner's raid-leader ticket policy disables superseded Guild Master physical route")
local leader,why=G:LeaderTicketRecipient(target)
assert(leader=="RaidLeader" and why:find("Leader%-only") and
    G:GetGuildMaster()=="GuildBoss",
    "leader-only ticket picks actual raid leader despite distinct Guild Master")
online=false
leader=G:LeaderTicketRecipient(target)
assert(leader=="RaidLeader",
    "guild master offline is no longer a prerequisite to raid leader tickets")
online=true
threshold=3
leader,why=G:LeaderTicketRecipient(target)
assert(not leader and why:find("Below WoW",1,true),
    "material below Master Loot threshold cannot start ticket route")
threshold=1
specialType=true
leader,why=G:LeaderTicketRecipient(target)
assert(not leader and why:find("special",1,true),
    "custom server quest material cannot enter leader ticket route")
specialType=false
stackCount=nil
leader,why=G:LeaderTicketRecipient(target)
assert(not leader and why:find("stack count",1,true),
    "unknown actual live stack prevents ticket preparation")
stackCount=1
N.db.guildLootTransferAudit={{itemID=17011,status="LOOT_SLOT_CLEARED",
    reconciliationStatus="CLOSED_NO_RETRY"}}
leader,why=G:LeaderTicketRecipient(target)
assert(not leader and why:find("NO RETRY",1,true),
    "historic Guild Master transfer attempt stays locked by material ID")
assert(count==0 and #given==0,
    "superseded Guild Master physical route makes ZERO GiveMasterLoot calls")
print("PASS: guild material owner routing superseded; guarded leader-only tickets") 
