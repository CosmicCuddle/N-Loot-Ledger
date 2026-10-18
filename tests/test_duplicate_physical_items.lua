-- Lua 5.1 regression: new corpse vs reordered item slots; NO unverified duplicates.
-- No real physical item is awarded. All WoW APIs are mocked.
local checks=0
local function ok(v,why)assert(v,why);checks=checks+1 end
GetTime=function()return 100 end
time=function()return 1800000000 end
date=function()return "2026-10-18" end
UnitName=function()return "Leader" end
GetLootMethod=function()return "master",nil,1 end
GetRaidRosterInfo=function(i)
    if i==1 then return "Leader",2 end
end
local awards=0
GiveMasterLoot=function()awards=awards+1;error("No physical transfers in identity test")end
local savedPlans={bot={character="Throgar",itemID=16800,status="NEEDED"}}
local history={
    {dropUID="L99:1:16800",itemID=16800,winner="Pikeotter",
        slotIndex=2,status="LOOT_SLOT_CLEARED",
        reconciliationStatus="CLOSED_NO_RETRY"},
}
local guild={
    {itemID=17010,slotIndex=1,recipient="Leader",
        status="LOOT_SLOT_CLEARED",reconciliationStatus="CLOSED_NO_RETRY"},
}
local notices={}
NaxxLootLottery={
    db={raidSession={lootGeneration=0,currentLoot={}},
        settings={guildAutoPreviewEnabled=true,directMasterLootEnabled=false,
            guildLootTransfersEnabled=false},
        gearNeeds=savedPlans,guildLootTransferAudit=guild,
        lootAwardHistory=history,
        lootIdentityAudit={},lootReceiptTracker={},
        awardAttemptLocks={["L99:1:16800"]={status="AWARD_REQUESTED"}}},
    DebugSimulator={IsActive=function()return false end},
    TicketLottery={liveLootObserved=true,
        AuthorityAllowed=function()return true end,
        GetActiveFor=function()return nil end},
    LootDetection={lootOpen=true,
        GetCurrentLoot=function()return {} end},
    Print=function(_,message)notices[#notices+1]=message end,
}
local N=NaxxLootLottery
local function scanRows()
    return {
        {itemID=17010,itemName="Fiery Core",itemLink="|Hitem:17010:0|h[Fiery Core]|h",
         slotIndex=3,quantity=2,status="GUILD_REVIEW",leader="Leader",
         category="Trade Goods",reason="Locally unreserved"},
        {itemID=16800,itemName="Arcanist Boots",itemLink="|Hitem:16800:0|h[Arcanist Boots]|h",
         slotIndex=4,quantity=1,status="GUILD_REVIEW",leader="Leader",
         category="Armor",reason="Locally unreserved"},
        {itemID=17011,itemName="Lava Core",itemLink="|Hitem:17011:0|h[Lava Core]|h",
         slotIndex=5,quantity=1,status="GUILD_REVIEW",leader="Leader",
         category="Trade Goods",reason="Locally unreserved"},
    }
end
N.GuildLootReview={Scan=function()return scanRows(),"Live items" end}
assert(loadfile("NaxxLootLottery/Core/LootIdentity.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildLootTransfer.lua"))()
assert(loadfile("NaxxLootLottery/Core/GuildAutoPreview.lua"))()
assert(loadfile("NaxxLootLottery/Core/AwardWorkflow.lua"))()
local I=N.LootIdentity
local T=N.GuildLootTransfer
local P=N.GuildAutoPreview
local A=N.AwardWorkflow
ok(T:WasAttempted(17010,1),"original item slot locked")
ok(T:WasAttempted(17010,3) and T:WasAttempted(17010,40),
    "same guild material blocked across every moved slot")
ok(not T:WasAttempted(17011,3),"unrelated material remains separately reviewable")
ok(guild[1].reconciliationStatus=="CLOSED_NO_RETRY",
    "manual NO-RETRY closure does not erase original attempt")
local plan=P:Build()
ok(plan.proposed==1 and plan.held==2 and
    plan.autoEligible==0 and not plan.transferAuthorized,
    "only independent unattempted material may be proposed")
ok(plan.rows[1].decision=="HOLD_PREVIOUS_ATTEMPT" and
    plan.rows[2].decision=="HOLD_PREVIOUS_ATTEMPT" and
    plan.rows[3].decision=="PROPOSE_TO_LEADER",
    "old guild AND winner attempts are held across slot changes")
local blocked={dropUID="L100:1:17010",itemID=17010,
    itemName="Fiery Core",slotIndex=3,identityUncertain=false}
local permitted,reason=A:ValidateLiveContext(blocked,"Pikeotter")
ok(not permitted and reason:find("Guild transfer attempted"),
    "new fake UID/slot cannot bypass old guild itemID lock")
-- Replay a supported gear identity through a normal same-signature rescan.
I:Initialize()
local function entries(ids)
    local rows={}
    for i,id in ipairs(ids) do
        rows[i]={itemID=id,slotIndex=i,itemName="Item "..id}
    end
    return rows
end
local initial=entries({16800,18814})
I:Assign(initial)
local oldUID=initial[1].dropUID
I:MarkCompleted(oldUID,"Pikeotter",3,"SERVER_RANDOM_ROLL","NEED",1)
local reopened=entries({16800,18814})
I:Assign(reopened)
ok(reopened[1].dropUID==oldUID and I:IsProcessed(oldUID),
    "same corpse signature reuses original winner UID")
local different=entries({16800,18814})
I:Assign(different,true) -- only reached after existing explicit New Drop confirmation
ok(different[1].dropUID~=oldUID and
    I:GetRow(oldUID).winner=="Pikeotter" and not I:IsProcessed(different[1].dropUID),
    "new confirmed corpse produces distinct UID without clearing old winner")
ok(N.db.awardAttemptLocks["L99:1:16800"].status=="AWARD_REQUESTED",
    "new corpse preserves older durable winner Master Loot locks")
-- Two indistinguishable physical copies, one processed and one disappears.
local copies=entries({16800,16800})
I:Assign(copies,true)
local copy1,copy2=copies[1].dropUID,copies[2].dropUID
ok(copy1~=copy2,"two same-item slots have independent historical UIDs")
I:MarkCompleted(copy1,"Throgar",8,"SERVER_RANDOM_ROLL","NEED",1)
local subset={{itemID=16800,slotIndex=2,itemName="Item 16800"}}
I:Assign(subset)
ok(subset[1].identityUncertain,
    "partial copy scan refuses to guess which physical copy remains")
ok(I:GetRow(copy1).winner=="Throgar" and
    I:GetRow(copy2).winner==nil,
    "old winner persists and other same-item copy stays unawarded")
-- Unknown outcomes, even from a different slot, freeze unrelated proposals.
history[1].status="AWARD_OUTCOME_UNKNOWN"
history[1].reconciliationStatus=nil
plan=P:Build()
ok(plan.proposed==0 and
    plan.rows[3].decision=="HOLD_UNRESOLVED_REQUEST",
    "unresolved winner award stops the entire auto guild proposal")
history[1].status="LOOT_SLOT_CLEARED"
plan=P:Build()
ok(plan.proposed==0 and plan.rows[3].decision=="HOLD_UNRESOLVED_REQUEST",
    "cleared slot stays globally uncertain until a no-retry review")
history[1].reconciliationStatus="CLOSED_NO_RETRY"
plan=P:Build()
ok(plan.proposed==1 and plan.rows[3].decision=="PROPOSE_TO_LEADER",
    "explicit no-retry review unlocks only unrelated read-only proposals")
ok(N.db.gearNeeds==savedPlans and savedPlans.bot.status=="NEEDED" and
    N.db.guildLootTransferAudit==guild and
    N.db.lootAwardHistory==history and
    #guild==1 and #history==1 and awards==0,
    "no Gear Plans, award histories, saved locks or real Master Loot changed")
print("PASS: "..checks.." moved-slot/material/genuine-new-corpse identity assertions")
