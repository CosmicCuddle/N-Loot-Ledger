-- Real leader/client addon whisper receipt handshake. NEVER GiveMasterLoot.
-- Every client has different SavedVariables; a report is not auto-obtained.
local checks=0
local function ok(v,why)assert(v,why);checks=checks+1 end
local actor="Leader"
local members={"Leader","Pikeotter","Other"}
local ambiguous=false
UnitName=function()return actor end
GetNumRaidMembers=function()return #members end
GetRaidRosterInfo=function(i)
    local v=members[i]
    if not v then return nil end
    return v,(i==1 or (i==2 and ambiguous)) and 2 or 0
end
GetTime=function()return 150 end
date=function()return "2026-10-17" end
time=function()return 1800000000 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local whispers,awards,notes={},0,{}
SendAddonMessage=function(prefix,msg,channel,target)
    whispers[#whispers+1]={from=actor,to=target,prefix=prefix,
        channel=channel,message=msg}
end
GiveMasterLoot=function()awards=awards+1;error("Never physically award")end
local Naxx=NaxxLootLottery
NaxxLootLottery={
    databaseVersion=1,
    Print=function(_,msg) notes[#notes+1]=msg end,
    Debug=function()end,
    IsValidRole=function()return true end,
    TicketLottery={AuthorityAllowed=function()return actor=="Leader" end},
    DebugSimulator={IsActive=function()return false end},
    UI={RefreshWishlistPanel=function()end,
        RefreshCurrentLootPanel=function()end},
    Data={MoltenCore={GetItem=function(_,id)
        if id==18821 or id==16800 then
            return {itemID=id,name="Fixture "..id}
        end
    end}},
}
local N=NaxxLootLottery
local function load(path) assert(loadfile("NaxxLootLottery/"..path))() end
load("Storage/Database.lua")
N.Database:Initialize()
local leaderDB=N.db
load("Core/Communication.lua")
load("Core/LootReceiptTracker.lua")
load("Core/ReceiptSync.lua")
local C,R,S=N.Communication,N.LootReceiptTracker,N.ReceiptSync
local key="pikeotter|MOLTEN_CORE|18821|PLAYER_SUBMITTED"
leaderDB.gearNeeds[key]={key=key,character="Pikeotter",itemID=18821,
    status="GREED",source="PLAYER_SUBMITTED",characterType="PLAYER",
    raidKey="MOLTEN_CORE"}
local fake={dropUID="L1:1:18821",status="COMPLETE",
    itemID=18821,itemName="Quick Strike Ring",
    winner="Pikeotter",raidKey="MOLTEN_CORE",selectionType="GREED"}
ok(R:ObserveWinner(fake),"real leader lottery winner tracked")
ok(leaderDB.gearNeeds[key].status=="GREED" and #whispers==0,
    "win does not notify or mark item obtained")
leaderDB.lootAwardHistory[1]={status="AWARD_REQUESTED",
    itemID=18821,dropUID=fake.dropUID,winner="Pikeotter"}
ok(not R:ConfirmReceipt(fake.dropUID) and #whispers==0,
    "award request alone cannot sync or update status")
leaderDB.lootAwardHistory[1].status="LEADER_REPORTED"
local success,msg=R:ConfirmReceipt(fake.dropUID)
ok(success and leaderDB.gearNeeds[key].status=="OBTAINED",
    "leader confirms actual item separately before notification")
ok(#whispers==1 and whispers[1].from=="Leader" and
    whispers[1].to=="Pikeotter" and
    whispers[1].message=="R1|OBTAINED|L1:1:18821|18821|MOLTEN_CORE|Pikeotter",
    "correct dedicated R1 whisper sent ONLY for confirmed human winner")
local leaderRow=R:Get(fake.dropUID)
ok(leaderRow.remoteSyncStatus=="AWAITING_PLAYER",
    "leader status awaits recipient acknowledgement")
local savedLeader=leaderDB.gearNeeds[key]
-- Separate client with a distinct WTF SavedVariables table.
NaxxLootLotteryDB={}
actor="Pikeotter"
N.Database:Initialize()
local playerDB=N.db
ok(N.Database:SetLocalReservation("Pikeotter","MOLTEN_CORE",18821,true),
    "player has matching local wishlist")
ok(N.Database:SetLocalInterest("Pikeotter","MOLTEN_CORE",18821,"GREED"),
    "player's interest remains GREED")
local oldWishlist=playerDB.localWishlists.Pikeotter.MOLTEN_CORE
local oldGreed=playerDB.localWishlistGreed.Pikeotter.MOLTEN_CORE
local raw=whispers[1]
local function receive(from,message,channel)
    C:HandleAddonMessage("NLL",message,channel or "WHISPER",from)
end
receive("Impostor",raw.message)
ok(#S:GetPendingForLocal()==0 and
    N.Database:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)=="GREED",
    "fake nonleader sender cannot even add a pending confirmation")
receive("Leader",raw.message,"RAID")
ok(#S:GetPendingForLocal()==0,
    "R1 raid broadcast is not valid; receipt requires private WHISPER")
receive("Leader","R1|OBTAINED|L1:1:18821|16800|MOLTEN_CORE|Pikeotter")
receive("Leader","R1|OBTAINED|L1:1:18821|18821|MOLTEN_CORE|Other")
receive("Leader","R1|OBTAINED|BADUID|18821|MOLTEN_CORE|Pikeotter")
ok(#S:GetPendingForLocal()==0,"mismatched IDs, recipient and malformed UID ignored")
ambiguous=true
receive("Leader",raw.message)
ok(#S:GetPendingForLocal()==0,"ambiguous raid leader blocks receipt offer")
ambiguous=false
receive("Leader",raw.message)
ok(#S:GetPendingForLocal()==1,"valid leader offer saved as PENDING on player client")
local pending=S:GetPendingForLocal()[1]
ok(pending.itemID==18821 and pending.interestAtOffer=="GREED",
    "offer records exact reserved item and original status")
receive("Leader",raw.message)
ok(#S:GetPendingForLocal()==1 and
   N.Database:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)=="GREED",
    "duplicate leader messages do not auto-obtain or create more records")
members[1]="NewLeader"
local allowed,reason=S:CanAccept(pending.key)
ok(not allowed and reason:find("leader"),"leader change blocks stale offer")
members[1]="Leader"
ok(S:CanAccept(pending.key),"original leader and player's own wishlist rechecked")
local playerPlan=playerDB.localWishlists.Pikeotter.MOLTEN_CORE
ok(playerPlan==oldWishlist and oldGreed[18821] and #whispers==1,
    "no remote client writes or ACK before explicit player confirmation")
success,msg=S:Accept(pending.key)
ok(success and N.Database:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)=="OBTAINED",
    "only player's explicit receipt confirmation changes their OWN wishlist")
ok(playerDB.localWishlists.Pikeotter.MOLTEN_CORE==oldWishlist and
    oldGreed[18821] and
    playerDB.localWishlistObtained.Pikeotter.MOLTEN_CORE[18821],
    "original wish boolean and Greed flag preserved in player's WTF")
ok(#S:GetPendingForLocal()==0 and
    #whispers==2 and whispers[2].message=="R1|ACK|L1:1:18821|18821|MOLTEN_CORE",
    "player sends exact audit acknowledgement and consumes pending offer")
ok(not S:Accept(pending.key),"duplicate receipt acceptance cannot re-mark item")
local originalAck=whispers[2]
receive("Leader",raw.message)
ok(#whispers==3 and
    whispers[3].message==originalAck.message and
    N.Database:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)=="OBTAINED",
    "lost ACK recovered by re-sending identical ACK, never another wishlist edit")
N.db=nil
N.Database:Initialize()
ok(N.db==playerDB and
    N.Database:GetLocalInterest("Pikeotter","MOLTEN_CORE",18821)=="OBTAINED",
    "player obtained status, ACK and inbox survive reload")
-- Leader sees R1 ACK only from the matching recipient.
actor="Leader"
N.db=leaderDB
receive("Impostor",whispers[2].message)
ok(leaderRow.remoteSyncStatus=="AWAITING_PLAYER",
    "unrelated raid member cannot acknowledge someone else's item")
receive("Pikeotter","R1|ACK|L1:1:18821|16800|MOLTEN_CORE")
ok(leaderRow.remoteSyncStatus=="AWAITING_PLAYER",
    "wrong item cannot acknowledge receipt")
receive("Pikeotter",whispers[2].message)
ok(leaderRow.remoteSyncStatus=="ACKNOWLEDGED",
    "leader records independent recipient-side confirmation")
local before=#whispers
ok(not S:RetryFor(fake.dropUID) and #whispers==before,
    "acknowledged award cannot be resent as a new receipt")
ok(leaderDB.gearNeeds[key]==savedLeader and
    leaderDB.gearNeeds[key].status=="OBTAINED" and
    #leaderDB.lootAwardHistory==1,
    "leader's historic plans/award history preserved")
-- Playerbot wins must NEVER be sent a human-client receipt.
local botkey="throgar|MOLTEN_CORE|16800|BOT_GEAR_PLAN"
leaderDB.gearNeeds[botkey]={character="Throgar",itemID=16800,
    status="GREED",source="BOT_GEAR_PLAN",characterType="PLAYERBOT",
    raidKey="MOLTEN_CORE"}
local bot={dropUID="L1:2:16800",itemID=16800,status="COMPLETE",
    itemName="Test",winner="Throgar",raidKey="MOLTEN_CORE"}
ok(R:ObserveWinner(bot),"bot real winner can still be recorded")
leaderDB.lootAwardHistory[#leaderDB.lootAwardHistory+1]={
    dropUID=bot.dropUID,winner="Throgar",itemID=16800,
    status="LEADER_REPORTED"
}
ok(R:ConfirmReceipt(bot.dropUID),"bot leader-side obtained still functions")
ok(#whispers==before and leaderDB.gearNeeds[botkey].status=="OBTAINED",
    "bot obtained without external player notification or extra messages")
ok(awards==0,"no Master Loot API used by receipt messaging")
print("PASS: "..checks.." two-client receipt offer/ack, trusted leader, replay, bot/plan safety assertions")
