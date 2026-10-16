-- WoW 3.3.5a Lua 5.1 real Database/GearNeeds SavedVariables regression.
-- Tests fresh initialization, upgrade and second /reload without reset.
local checks=0
local function ok(value,why) assert(value,why);checks=checks+1 end
NaxxLootLottery={
    databaseVersion=1,
    IsValidRole=function(_,role) return role=="CASTER_DPS" or role=="MAIN_TANK" end,
    IsValidClass=function(_,class) return class=="SHAMAN" or class=="WARRIOR" end,
    Debug=function()end,
    Data={MoltenCore={GetItem=function(_,id)
        if tonumber(id)==19147 or tonumber(id)==18821 then
            return {itemID=id,name=id==19147 and "Ring of Spell Power" or
                "Quick Strike Ring"}
        end
    end}}
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
local D=N.Database
local G=N.GearNeeds
-- Fresh installs still get the original SavedVariables shape.
NaxxLootLotteryDB=nil
D:Initialize()
ok(type(N.db.gearNeeds)=="table" and N.db.gearNeedsSchema==1,
    "fresh install preserves existing Gear Needs storage format")
ok(type(N.db.lotteryHistory)=="table" and
   type(N.db.localWishlists)=="table","fresh history and wishlist tables")
ok(N.db.settings.directMasterLootEnabled==false,"Direct Master Loot defaults OFF")
-- Emulate actual pre-Greed v0.1.0.28 records with same four original keys.
local oldNeed={character="Druzz",itemID=19147,status="NEEDED",
    source="BOT_GEAR_PLAN",characterType="PLAYERBOT",role="CASTER_DPS",
    raidKey="MOLTEN_CORE"}
local oldObtained={character="Gorak",itemID=18821,status="OBTAINED",
    source="BOT_GEAR_PLAN",characterType="PLAYERBOT",role="MAIN_TANK",
    raidKey="MOLTEN_CORE"}
local oldDisabled={character="Druzz",itemID=18821,status="DISABLED",
    source="BOT_GEAR_PLAN",characterType="PLAYERBOT",role="CASTER_DPS",
    raidKey="MOLTEN_CORE"}
local needKey=G:MakeKey("Druzz","MOLTEN_CORE",19147,"BOT_GEAR_PLAN")
local obtainedKey=G:MakeKey("Gorak","MOLTEN_CORE",18821,"BOT_GEAR_PLAN")
local disabledKey=G:MakeKey("Druzz","MOLTEN_CORE",18821,"BOT_GEAR_PLAN")
local oldGear={[needKey]=oldNeed,[obtainedKey]=oldObtained,
    [disabledKey]=oldDisabled}
local oldWishlist={[19147]=true,[18821]=true}
local oldRoles={Druzz={role="CASTER_DPS"},Gorak={role="MAIN_TANK"}}
local oldPreset={rolePriority={CASTER_DPS=2,MAIN_TANK=1}}
local oldRules={MOLTEN_CORE={[19147]=oldPreset}}
local oldLottery={{winner="HistoricWinner",status="COMPLETE",winningTicket=3}}
local oldAward={{winner="HistoricWinner",status="LEADER_REPORTED"}}
local oldIdentity={schema=3,rows={{dropUID="old-1",winner="HistoricWinner",processed=true}}}
local oldSession={lootIdentity=oldIdentity,currentLoot={},lootGeneration=7}
local oldDB={
    version=1,settings={debug=false,directMasterLootEnabled=true,skin="VANILLA"},
    gearNeeds=oldGear,gearNeedsSchema=1,
    localWishlists={Druzz={MOLTEN_CORE=oldWishlist}},
    roleAssignments=oldRoles,characters={
        Druzz={class="SHAMAN",characterType="PLAYERBOT"},
        Gorak={class="WARRIOR",characterType="PLAYERBOT"}},
    lotteryHistory=oldLottery,lootAwardHistory=oldAward,
    raidSession=oldSession,priorityRules=oldRules,
    candidateAudit={{action="EXCLUDED",dropUID="old-1"}}
}
local audit=oldDB.candidateAudit
NaxxLootLotteryDB=oldDB
D:Initialize()
ok(N.db==oldDB and N.db.gearNeeds==oldGear,"in-place initialization never replaces old DB/plans")
ok(N.db.localWishlists.Druzz.MOLTEN_CORE==oldWishlist and
    oldWishlist[19147] and oldWishlist[18821],"old wishlist booleans untouched")
ok(N.db.roleAssignments==oldRoles and N.db.priorityRules==oldRules and
    N.db.priorityRules.MOLTEN_CORE[19147]==oldPreset,
    "role assignments and guild priority presets unchanged")
ok(N.db.lotteryHistory==oldLottery and N.db.lootAwardHistory==oldAward and
    N.db.raidSession==oldSession and N.db.raidSession.lootIdentity==oldIdentity and
    N.db.candidateAudit==audit,"old winner, award, identity and audit tables unchanged")
ok(G:GetNeed(needKey)==oldNeed and G:GetNeed(obtainedKey)==oldObtained and
    G:GetNeed(disabledKey)==oldDisabled and
    oldNeed.status=="NEEDED" and oldObtained.status=="OBTAINED" and
    oldDisabled.status=="DISABLED","all three old saved statuses persist unchanged")
ok(N.db.settings.directMasterLootEnabled==false,
    "old direct-award enable flag resets safely each login")
-- New GREED records fit the OLD gearNeeds table with no schema migration.
local created,greed=G:AddNeed("Druzz",18821,"MOLTEN_CORE",
    "CASTER_DPS","GREED","RAID_LEADER_MANUAL","PLAYERBOT")
ok(created and greed.status=="GREED","new GREED entry saves in original table")
ok(N.db.gearNeeds==oldGear and N.db.gearNeedsSchema==1,
    "GREED does not rebuild plans or increment schema")
ok(G:GetNeed(disabledKey)==oldDisabled and oldDisabled.status=="DISABLED",
    "same item in different sources does not overwrite DISABLED record")
local greedKey=greed.key
local savedGreed=G:GetNeed(greedKey)
local refs={db=oldDB,gear=oldGear,oldNeed=oldNeed,oldObtained=oldObtained,
    oldDisabled=oldDisabled,wishlist=oldWishlist,roles=oldRoles,
    rules=oldRules,history=oldLottery,award=oldAward,identity=oldIdentity}
-- Simulate /reload/relog by detaching NLL.db and reinitializing.
N.db=nil
D:Initialize()
ok(N.db==refs.db and N.db.gearNeeds==refs.gear,
    "reload reuses original SavedVariables and Gear Plans table")
ok(G:GetNeed(greedKey)==savedGreed and savedGreed.status=="GREED",
    "new GREED survives reload without conversion")
ok(G:GetNeed(needKey)==refs.oldNeed and
   G:GetNeed(obtainedKey)==refs.oldObtained and
   G:GetNeed(disabledKey)==refs.oldDisabled,
   "old NEEDED, OBTAINED and DISABLED survive alongside GREED")
ok(N.db.localWishlists.Druzz.MOLTEN_CORE==refs.wishlist and
   N.db.roleAssignments==refs.roles and N.db.priorityRules==refs.rules,
   "wishlist, roles and priorities retain reference identity on reload")
ok(N.db.lotteryHistory==refs.history and
   N.db.lootAwardHistory==refs.award and
   N.db.raidSession.lootIdentity==refs.identity and
   refs.history[1].winner=="HistoricWinner",
   "completed winners, award records and loot identities survive reload")
print("PASS: "..checks.." fresh/install, v0.1.0.28 upgrade and /reload assertions")
