-- WoW 3.3.5a / Lua 5.1: physical guild Master Loot requires three user clicks.
-- This fixture mocks GiveMasterLoot; NEVER run it against a live item.
local checks=0
local function ok(v,msg) assert(v,msg);checks=checks+1 end
local given={}
local auditAtCall
local t=100
GetTime=function()return t end
date=function()return "2026-10-17" end
local user="Leader"
UnitName=function()return user end
local roster={"Leader","Pikeotter","Other"}
GetNumRaidMembers=function()return #roster end
local dualLeader=false
GetRaidRosterInfo=function(i)
    return roster[i], (i==1 or (i==2 and dualLeader)) and 2 or 0
end
local master=1
GetLootMethod=function()return "master",nil,master end
local selectedSlot=1
LootFrame={IsShown=function()return true end,selectedSlot=selectedSlot}
local candidates={"Leader","Pikeotter"}
GetMasterLootCandidate=function(i)return candidates[i] end
local itemIDs={17010,17011,16800,18259,17204}
local names={"Fiery Core","Lava Core","Arcanist Boots","Enchant Formula","Eye of Sulfuras"}
local locked={}
local quantities={2,1,1,1,1}
GetNumLootItems=function()return #itemIDs end
GetLootSlotLink=function(slot)
    local id=itemIDs[slot]
    if id then return "|Hitem:"..id..":0:0:0|h["..names[slot].."]|h" end
end
GetLootSlotInfo=function(slot)
    return nil,nil,quantities[slot],4,locked[slot]==true
end
GetItemInfo=function(id)
    return "Item "..id,nil,(id==17204 and 5 or 2),nil,nil,
        (id==18259 and "Recipe" or "Trade Goods")
end
local N
GiveMasterLoot=function(slot,candidateIndex)
    auditAtCall=N.db.guildLootTransferAudit[#N.db.guildLootTransferAudit]
    given[#given+1]={slot=slot,candidate=candidateIndex}
end
local logs={}
NaxxLootLottery={
    databaseVersion=1,
    Debug=function()end,
    Print=function(_,msg)logs[#logs+1]=msg end,
    DebugSimulator={IsActive=function()return false end},
    TicketLottery={AuthorityAllowed=function()return true end,liveLootObserved=true},
    LootDetection={lootOpen=true},
    Data={MoltenCore={GetItem=function(_,id)
        if id==17204 then return {itemID=id,manualOnly=true,legendary=true} end
        if id==18259 then return {itemID=id,name="Enchant Formula"} end
    end,IsRecipeItem=function(_,entry)return entry and entry.itemID==18259 end}},
    AwardWorkflow={liveRequests={}},
}
N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
N.Database:Initialize()
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootReconciliation.lua"))()
local T=N.GuildLootTransfer
local R=N.GuildLootReconciliation
local guild=N.GuildLootReview
local reference=N.db
local oldGear=N.db.gearNeeds
N.db.gearNeeds={sentinel={itemID=16800,raidKey="MOLTEN_CORE",status="NEEDED",
    character="Gorak"}}
local plan=N.db.gearNeeds
N.db.localWishlists={Pikeotter={MOLTEN_CORE={[18259]=true}}}
local localPlans=N.db.localWishlists
N.db.submissionInbox={}
local rosterSnapshot=roster
ok(N.db.settings.guildLootTransfersEnabled==false and
   N.db.settings.directMasterLootEnabled==false,"both consents OFF by default")
local rows=guild:Scan()
ok(#rows==5 and rows[1].status=="GUILD_REVIEW" and
   rows[3].status=="RESERVED" and rows[4].status=="UNRESOLVED" and
   rows[5].status=="SPECIAL_HOLD",
   "only unreserved materials may reach manual guild review")
local target={slotIndex=rows[1].slotIndex,itemID=rows[1].itemID,
    itemLink=rows[1].itemLink,quantity=rows[1].quantity}
local reserved={slotIndex=rows[3].slotIndex,itemID=rows[3].itemID,
    itemLink=rows[3].itemLink,quantity=rows[3].quantity}
local wantReview,why=T:Review(target)
ok(not wantReview and why:find("BOTH"),"review prohibited with both settings OFF")
ok(T:SetEnabled(true),"separate guild consent can be enabled explicitly")
wantReview=T:Review(target)
ok(not wantReview,"Direct Master Loot still OFF blocks even review")
N.db.settings.directMasterLootEnabled=true
LootFrame=nil
wantReview,why=T:Review(target)
ok(not wantReview and why:find("Master Loot dropdown"),
    "closed WoW dropdown blocks verified review")
LootFrame={IsShown=function()return true end,selectedSlot=1}
master=2
wantReview,why=T:Review(target)
ok(not wantReview and why:find("not the designated"),
    "leader/officer alone is insufficient; acting character must be Master Looter")
master=1
candidates={"Pikeotter"}
wantReview,why=T:Review(target)
ok(not wantReview and why:find("exactly once"),
    "raid leader absent from Master Loot candidates blocks transfer")
candidates={"Leader","Leader"}
wantReview=T:Review(target)
ok(not wantReview,"ambiguous two candidate indices are unsafe")
candidates={"Leader","Pikeotter"}
wantReview,why=T:Review(reserved)
ok(not wantReview and why:find("reservation changed"),
    "NEED reserved gear never becomes guild item")
local malformed={slotIndex=rows[5].slotIndex,itemID=rows[5].itemID,
    itemLink=rows[5].itemLink,quantity=rows[5].quantity}
wantReview=T:Review(malformed)
ok(not wantReview,"legendary item cannot be guild-transferred through this path")
N.TicketLottery.active={status="COUNTDOWN"}
wantReview,why=T:Review(target)
ok(not wantReview and why:find("ticket lottery"),
    "pending countdown prevents guild transfer")
N.TicketLottery.active=nil
N.AwardWorkflow.verification={dropUID="SOME_OTHER_WINNER",winner="Other"}
wantReview,why=T:Review(target)
ok(not wantReview and why:find("winner review"),
    "unfinished winner award review prevents a competing transfer")
N.AwardWorkflow.verification=nil
N.db.lootAwardHistory={{
    status="AWARD_OUTCOME_UNKNOWN",itemID=17011,
    dropUID="L5:1:17011",winner="Pikeotter"
}}
wantReview,why=T:Review(target)
ok(not wantReview and why:find("unresolved"),
    "old winner transfer uncertainty survives into guild routing guard")
N.LootReceiptTracker={Get=function(_,uid)
    if uid=="L5:1:17011" then
        return {status="WON_AWAITING_ITEM",itemID=17011,
            character="Pikeotter"}
    end
end}
wantReview=T:Review(target)
ok(not wantReview,"winner without recipient receipt remains unresolved")
N.LootReceiptTracker.Get=function(_,uid)
    if uid=="L5:1:17011" then
        return {status="OBTAINED",itemID=17011,
            character="Pikeotter",evidence="LEADER_CONFIRMED_RECIPIENT_INVENTORY"}
    end
end
ok(T:IsUnresolved()==false,
    "exact leader-confirmed winner receipt resolves a global pending-award lock")
N.LootReceiptTracker.Get=function()
    return {status="OBTAINED",itemID=17011,
        character="Impostor",evidence="LEADER_CONFIRMED_RECIPIENT_INVENTORY"}
end
ok(T:IsUnresolved(),
    "different recipient cannot clear someone else's uncertain award")
N.LootReceiptTracker=nil
N.db.lootAwardHistory={}
local okReview,reviewMessage=T:Review(target)
ok(okReview and reviewMessage:find("ARM") and #given==0,
    "review records exact material, quantity and leader without giving")
local reviewed=T.review
ok(reviewed.context.leader=="Leader" and reviewed.context.quantity==2 and
   reviewed.context.candidate==1,"review pins leader, count, and candidate index")
local armed,armMessage=T:Arm()
ok(armed and armMessage:find("15 seconds") and #given==0,
    "first click arms for 15 seconds, still no server transfer")
itemIDs[1]=17011
local sent,msg=T:Commit()
ok(not sent and msg:find("changed") and #given==0,
    "changed live loot item aborts without any GiveMasterLoot")
itemIDs[1]=17010
ok(T:Review(target) and T:Arm(),"review and arm require fresh user actions")
roster[1]="NewLeader"
sent,msg=T:Commit()
ok(not sent and #given==0,"raid leader identity drift blocks GiveMasterLoot")
roster[1]="Leader"
ok(T:Review(target) and T:Arm(),"restored leader requires an entirely new review")
t=t+16
sent,msg=T:Commit()
ok(not sent and msg:find("expired") and #given==0,
    "15-second confirmation expiration fails closed")
ok(T:Review(target) and T:Arm(),"explicit fresh review+arm possible")
locked[1]=true
sent=T:Commit()
ok(not sent and #given==0,"locked loot slot aborts")
locked[1]=false
ok(T:Review(target) and T:Arm(),"valid new attempt after slot unlock")
quantities[1]=1
sent=T:Commit()
ok(not sent and #given==0,"quantity change aborts transfer")
quantities[1]=2
ok(T:Review(target) and T:Arm(),"fresh stable material item can be armed")
local rankAtCall=nil
GiveMasterLoot=function(slot,candidateIndex)
    rankAtCall=N.db.guildLootTransferAudit[#N.db.guildLootTransferAudit]
    given[#given+1]={slot=slot,candidate=candidateIndex}
end
sent,msg=T:Commit()
ok(sent and #given==1 and given[1].slot==1 and given[1].candidate==1,
    "exact single Master Loot API request only on second click")
ok(rankAtCall and rankAtCall.status=="AWARD_REQUESTED" and
    rankAtCall.note:find("NOT verified",1,true),
    "request audit exists before WoW call, final delivery explicitly unverified")
ok(N.db.guildLootTransferAudit[1]==rankAtCall and
    #N.db.guildLootTransferAudit==1,
    "single durable audit row")
sent,msg=T:Commit()
ok(not sent and #given==1,"double-click cannot repeat request")
sent,msg=T:Review(target)
ok(not sent and #given==1,"pending request blocks immediate review and resend")
N.db=nil
N.Database:Initialize()
ok(N.db==reference and N.db.guildLootTransferAudit[1]==rankAtCall and
   N.db.settings.guildLootTransfersEnabled==false and
   N.db.settings.directMasterLootEnabled==false,
   "reload preserves audit and disables both dangerous consents")
ok(N.db.gearNeeds==plan and plan.sentinel.status=="NEEDED" and
   N.db.localWishlists==localPlans and roster==rosterSnapshot,
   "old Playerbot needs and local wishlists never change")
T:OnLootSlotCleared(1)
ok(rankAtCall.status=="LOOT_SLOT_CLEARED" and
    rankAtCall.note:find("NOT verified",1,true),
    "cleared slot is NOT a recipient receipt")
N.db.settings.directMasterLootEnabled=true
T:SetEnabled(true)
sent,msg=T:Review(target)
ok(not sent and msg:find("unresolved"),
    "cleared slot still unverified and stops further transfers")
local confirmable,reason=R:Arm(1)
ok(confirmable and #given==1,
    "intended raid leader reviews own inventory with zero additional awards")
local reconciled,statement=R:Confirm(1)
ok(reconciled and rankAtCall.status=="RECIPIENT_CONFIRMED" and
   rankAtCall.evidence=="RECIPIENT_CHECKED_OWN_INVENTORY",
   "two-click recipient attestation resolves outstanding request only")
sent,msg=T:Review(target)
ok(not sent and msg:find("already requested"),
    "reconciliation never unlocks retry of original item/slot")
local target2={slotIndex=rows[2].slotIndex,itemID=rows[2].itemID,
    itemLink=rows[2].itemLink,quantity=rows[2].quantity}
LootFrame.selectedSlot=2
ok(T:Review(target2) and T:Arm(),"other unreserved material remains separately reviewable")
local failOnce=true
GiveMasterLoot=function() if failOnce then error("WoW denied") end end
sent,msg=T:Commit()
ok(not sent and msg:find("outcome UNKNOWN"),"WoW API failure recorded with unknown outcome")
ok(#N.db.guildLootTransferAudit==2 and
    N.db.guildLootTransferAudit[2].status=="AWARD_OUTCOME_UNKNOWN",
    "unknown outcome preserved; no fabricated successful receipt")
sent,msg=T:Review(target2)
ok(not sent and msg:find("unresolved"),"any uncertain request blocks all future transfers")
T:OnLootClosed()
ok(T.review==nil and
    N.db.guildLootTransferAudit[2].status=="AWARD_OUTCOME_UNKNOWN",
    "loot closed cancels review while keeping unknown audit")
ok(#given==1 and #N.db.lootAwardHistory==0,
    "no duplicate Master Loot or fabricated lottery award receipts")
print("PASS: "..checks.." guarded guild transfer / master / candidate / audit assertions")
