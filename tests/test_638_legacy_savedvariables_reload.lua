-- NLL: synthetic 638-plan legacy account survival through Initialize/reload.
-- This is NOT the owner's real SavedVariables; no game or external file access.
-- Run with stock Lua 5.1. No awards, rolls, network messages or imports.
local checks=0
local function ok(value,message) assert(value,message);checks=checks+1 end
local grants=0
GiveMasterLoot=function()grants=grants+1;error("No live award allowed")end
RandomRoll=function()grants=grants+1;error("No live roll allowed")end
SendAddonMessage=function()grants=grants+1;error("No messaging allowed")end

local settings={
    debug=true,skin="LIGHT",priorityPresetsEnabled=true,
    raidAnnouncementsEnabled=true,raidCountdownEnabled=true,
    customOwnerPreference="preserve-me",
    directMasterLootEnabled=true,winnerQuickAwardEnabled=true,
    guildLootTransfersEnabled=true,guildAutoPreviewEnabled=true,
}
local original={
    version=1,settings=settings,gearNeeds={},
    characters={OldBot={characterType="PLAYERBOT",class="WARRIOR"}},
    roleAssignments={OldBot={role="MAIN_TANK",note="Owner decision"}},
    localWishlists={Owner={MOLTEN_CORE={[18821]=true}}},
    localWishlistGreed={Owner={MOLTEN_CORE={[18821]=true}}},
    localWishlistObtained={Owner={MOLTEN_CORE={[16800]=true}}},
    history={{kind="CUSTOM",note="Keep old event"}},
    lotteryHistory={{dropUID="LEGACY-WIN",winner="OldBot"}},
    lootAwardHistory={{dropUID="LEGACY-AWARD",status="AWARD_OUTCOME_UNKNOWN"}},
    lootReceiptTracker={old={dropUID="LEGACY-AWARD",
        status="WON_AWAITING_ITEM",character="OldBot"}},
    guildLootTransferAudit={{itemID=17010,
        status="LOOT_SLOT_CLEARED",reconciliationStatus="CLOSED_NO_RETRY"}},
    awardAttemptLocks={old={status="AWARD_REQUESTED",dropUID="LEGACY-AWARD"}},
    manualObtainedEvidence={{kind="LEADER_ATTESTED_BOT_HAS_ITEM",
        gearKey="historic",receiptVerified=false}},
    submissionInbox={legacy={player="OldBot",status="PENDING"}},
    localReceiptSyncPending={legacy={recipient="Owner",status="AWAITING_PLAYER"}},
    localReceiptSyncDone={historic={confirmation="PLAYER_CHECKED_OWN_INVENTORY"}},
    candidateAudit={{action="REVIEWED"}},
    raidSession={currentLoot={{dropUID="OLD-CORPSE"}},lootGeneration=42},
    priorityRules={MOLTEN_CORE={[16800]={note="Custom priority"}}},
    customOwnerNotes={red="Do not discard owner extensions"},
}
-- Keep exact row identities, plus representative NEED, GREED, OBTAINED
-- and DISABLED entries. 38 synthetic bots with unique plan item IDs.
local statuses={"NEEDED","GREED","OBTAINED","DISABLED"}
local sources={"BOT_GEAR_PLAN","RAID_LEADER_MANUAL","PLAYER_SUBMITTED"}
local savedRows={}
local savedStatusCounts={NEEDED=0,GREED=0,OBTAINED=0,DISABLED=0}
for i=1,638 do
    local name="Bot"..string.format("%02d",((i-1)%38)+1)
    local id=10000+i
    local source=sources[((i-1)%#sources)+1]
    local status=statuses[((i-1)%#statuses)+1]
    local key=string.lower(name).."|MOLTEN_CORE|"..id.."|"..source
    local row={key=key,character=name,characterType="PLAYERBOT",
        source=source,itemID=id,raidKey="MOLTEN_CORE",
        status=status,role="CASTER_DPS",ownerCustomFlag="untouched"}
    if status=="OBTAINED" then row.obtainedDropUID="LEGACY-"..i end
    original.gearNeeds[key]=row
    savedRows[key]={row=row,status=status,
        obtainedDropUID=row.obtainedDropUID}
    savedStatusCounts[status]=savedStatusCounts[status]+1
end
NaxxLootLotteryDB=original
NaxxLootLottery={databaseVersion=1}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()

local stableKeys={"gearNeeds","characters","roleAssignments",
    "localWishlists","localWishlistGreed","localWishlistObtained",
    "history","lotteryHistory","lootAwardHistory","lootReceiptTracker",
    "guildLootTransferAudit","awardAttemptLocks","manualObtainedEvidence",
    "submissionInbox","localReceiptSyncPending","localReceiptSyncDone",
    "candidateAudit","raidSession","priorityRules","customOwnerNotes"}
local stable={}
for _,name in ipairs(stableKeys) do stable[name]=original[name] end
local savedSettings=settings
local savedAccountWishlist=original.localWishlists.Owner.MOLTEN_CORE
local savedObtained=original.localWishlistObtained.Owner.MOLTEN_CORE
local savedLoot=original.raidSession.currentLoot
local savedPriority=original.priorityRules.MOLTEN_CORE[16800]

local function verify(phase)
    ok(N.db==original and NaxxLootLotteryDB==original,
        phase..": original SavedVariables root never replaced")
    ok(N.db.settings==savedSettings,
        phase..": original settings object never replaced")
    for _,name in ipairs(stableKeys) do
        ok(N.db[name]==stable[name],
            phase..": preserve complete "..name.." table identity")
    end
    ok(N.GearNeeds:GetCount()==638,
        phase..": all 638 synthetic Gear Plans survive initialization")
    local counts={NEEDED=0,GREED=0,OBTAINED=0,DISABLED=0}
    for key,snapshot in pairs(savedRows) do
        local row=N.db.gearNeeds[key]
        ok(row==snapshot.row and row.status==snapshot.status and
            row.obtainedDropUID==snapshot.obtainedDropUID and
            row.ownerCustomFlag=="untouched",
            phase..": preserve every original plan row, status and extra field")
        counts[row.status]=counts[row.status]+1
    end
    for status,n in pairs(savedStatusCounts) do
        ok(counts[status]==n,phase..": preserve "..status.." count")
    end
    ok(N.db.localWishlists.Owner.MOLTEN_CORE==savedAccountWishlist and
       N.db.localWishlists.Owner.MOLTEN_CORE[18821]==true and
       N.db.localWishlistGreed.Owner.MOLTEN_CORE[18821]==true and
       N.db.localWishlistObtained.Owner.MOLTEN_CORE==savedObtained and
       savedObtained[16800]==true,
       phase..": keep all local NEED/GREED/OBTAINED preferences")
    ok(N.db.raidSession.currentLoot==savedLoot and
       N.db.raidSession.lootGeneration==42 and
       N.db.priorityRules.MOLTEN_CORE[16800]==savedPriority,
       phase..": historical loot generation and custom priorities preserved")
    ok(N.db.guildLootTransferAudit[1].reconciliationStatus=="CLOSED_NO_RETRY" and
       N.db.awardAttemptLocks.old.status=="AWARD_REQUESTED" and
       N.db.lootReceiptTracker.old.status=="WON_AWAITING_ITEM" and
       N.db.lootAwardHistory[1].status=="AWARD_OUTCOME_UNKNOWN",
       phase..": receipt uncertainty and permanent locks untouched")
    ok(N.db.settings.directMasterLootEnabled==false and
       N.db.settings.winnerQuickAwardEnabled==false and
       N.db.settings.guildLootTransfersEnabled==false and
       N.db.settings.guildAutoPreviewEnabled==false,
       phase..": all four session-only physical/preview consents reset OFF")
    ok(N.db.settings.debug==true and
       N.db.settings.priorityPresetsEnabled==true and
       N.db.settings.raidAnnouncementsEnabled==true and
       N.db.settings.raidCountdownEnabled==true and
       N.db.settings.customOwnerPreference=="preserve-me",
       phase..": other owner preferences preserved")
    ok(N.db.settings.skin=="DARK",
       phase..": known intentional obsolete theme normalization only")
end

N.Database:Initialize()
verify("first legacy load")
-- A simulated reload calls Initialize against the SAME account save, not a
-- blank account. Re-run after an attempted stale consent enable.
N.db.settings.directMasterLootEnabled=true
N.db.settings.winnerQuickAwardEnabled=true
N.db.settings.guildLootTransfersEnabled=true
N.db.settings.guildAutoPreviewEnabled=true
N.db=nil
N.Database:Initialize()
verify("second load after simulated /reload")
ok(grants==0,"no physical grants, rolls or addon communication occurred")
print("PASS: "..checks..
    " synthetic 638-plan legacy load/reload and history preservation assertions")
