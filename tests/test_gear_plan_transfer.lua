-- WoW 3.3.5a / Lua 5.1: Non-destructive Playerbot plan paste/copy tests.
local checks=0
local function ok(condition,message)
    assert(condition,message);checks=checks+1
end
local n=NaxxLootLottery or {}
n.roleLabels={CASTER_DPS="Caster DPS",MAIN_TANK="Main Tank",
    HEALER="Healer",MELEE_DPS="Melee DPS"}
n.Data={MoltenCore={GetItem=function(_,id)
    return ({[19147]={name="Ring of Spell Power"},
        [18821]={name="Quick Strike Ring"},
        [16800]={name="Arcanist Boots"}})[tonumber(id)]
end}}
n.IsValidRole=function(self,id)return self.roleLabels[id]~=nil end
n.Debug=function()end
n.db={
    gearNeeds={},gearNeedsSchema=1,
    characters={Druzz={characterType="PLAYERBOT"}},
    roleAssignments={Druzz={role="CASTER_DPS"}},
    localWishlists={Owner={MOLTEN_CORE={[19147]=true}}},
    lotteryHistory={{winner="OldWinner"}},
    lootAwardHistory={{winner="OldWinner"}},
    raidSession={lootIdentity={rows={{processed=true}}}}
}
NaxxLootLottery=n
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearPlanTransfer.lua"))()
local G=n.GearNeeds
local T=n.GearPlanTransfer
local needKey=G:MakeKey("Druzz","MOLTEN_CORE",19147,"BOT_GEAR_PLAN")
local existing={key=needKey,character="Druzz",itemID=19147,
    role="CASTER_DPS",status="NEEDED",source="BOT_GEAR_PLAN",
    characterType="PLAYERBOT",raidKey="MOLTEN_CORE",raid="Molten Core"}
n.db.gearNeeds[needKey]=existing
local legacy={key="pikeotter|MOLTEN_CORE|18821|PLAYER_SUBMITTED",
    character="Pikeotter",itemID=18821,raidKey="MOLTEN_CORE",
    status="OBTAINED",source="PLAYER_SUBMITTED",characterType="PLAYER"}
n.db.gearNeeds[legacy.key]=legacy
local refs={gear=n.db.gearNeeds,roles=n.db.roleAssignments,
    wish=n.db.localWishlists.Owner.MOLTEN_CORE,
    lottery=n.db.lotteryHistory,award=n.db.lootAwardHistory,
    identity=n.db.raidSession.lootIdentity,legacy=legacy,existing=existing}
local header="NLL-GEARPLANS-1"
local first="Druzz|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|NEEDED|1"
local second="Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|18821|BOT_GEAR_PLAN|GREED|1"
local third="Simra|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|16800|BOT_GEAR_PLAN|DISABLED|1"
local paste=header.."\n"..first.."\n"..second.."\n"..third
local text,count=T:Export()
ok(count==1 and text==header.."\n"..first,
    "export only existing bot plans; do not export personal/player submissions")
local p,why=T:Preview(paste)
ok(p and p.ready and p.newCount==2 and p.unchanged==1 and
    #p.conflicts==0,"preview computes two additions, one skip")
ok(n.db.gearNeeds[G:MakeKey("Eiga","MOLTEN_CORE",18821,"BOT_GEAR_PLAN")]==nil,
    "preview did not write any Gear Plans")
ok(n.db.gearNeeds==refs.gear and n.db.roleAssignments==refs.roles and
    n.db.lotteryHistory==refs.lottery and
    n.db.lootAwardHistory==refs.award and n.db.localWishlists.Owner.MOLTEN_CORE==refs.wish,
    "preview preserves all saved tables")
local yes,reason=T:Apply(p,paste.."\n#changed")
ok(not yes and reason:find("Preview again"),
    "changed paste cannot reuse preview")
yes,reason=T:Apply(p,paste)
ok(yes and reason:find("Added 2"),reason)
local newKey=G:MakeKey("Eiga","MOLTEN_CORE",18821,"BOT_GEAR_PLAN")
local new2Key=G:MakeKey("Simra","MOLTEN_CORE",16800,"BOT_GEAR_PLAN")
ok(n.db.gearNeeds[newKey].status=="GREED" and
    n.db.gearNeeds[new2Key].status=="DISABLED",
    "import adds exactly the requested statuses")
ok(n.db.gearNeeds[needKey]==refs.existing and
    n.db.gearNeeds[legacy.key]==refs.legacy and
    n.db.roleAssignments==refs.roles and
    n.db.roleAssignments.Druzz.role=="CASTER_DPS",
    "existing bot plan and global roles unchanged")
ok(n.db.localWishlists.Owner.MOLTEN_CORE==refs.wish and
    n.db.lotteryHistory==refs.lottery and
    n.db.lootAwardHistory==refs.award and
    n.db.raidSession.lootIdentity==refs.identity and
    refs.identity.rows[1].processed,
    "personal wishlist, winners, award history and identities unchanged")
yes,reason=T:Apply(p,paste)
ok(not yes and reason:find("Preview again"),
    "cannot apply same preview twice")
local again=T:Preview(paste)
ok(again and not again.ready and again.unchanged==3 and
    again.newCount==0,"identical import is a no-op and idempotent")
local exported,nExport=T:Export()
ok(nExport==3 and exported:find(second,1,true) and
    exported:find(third,1,true),"new records export and roundtrip")
local differences=header.."\nDruzz|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|GREED|1"..
    "\nWarma|PLAYERBOT|MAIN_TANK|MOLTEN_CORE|18821|BOT_GEAR_PLAN|NEEDED|1"
local conflict=T:Preview(differences)
ok(conflict and not conflict.ready and #conflict.conflicts==1 and
    conflict.newCount==1,"one conflicted row blocks ALL additions")
ok(n.db.gearNeeds[G:MakeKey("Warma","MOLTEN_CORE",18821,"BOT_GEAR_PLAN")]==nil,
    "conflict leaves new rows untouched")
local function invalid(body,contains)
    local before=G:GetCount()
    local reviewed,errorText=T:Preview(header.."\n"..body)
    ok(not reviewed and errorText:find(contains,1,true),
        "invalid paste rejected: "..tostring(errorText))
    ok(G:GetCount()==before,"invalid input writes nothing")
end
invalid(second.."\n"..second,"repeats")
invalid("Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|18821|BOT_GEAR_PLAN|BAD|1",
    "Invalid interest")
invalid("Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|18821|BOT_GEAR_PLAN|GREED|2",
    "Multi-copy")
invalid("Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|18821|RAID_LEADER_MANUAL|GREED|1",
    "Only Playerbot")
invalid("Eiga|PLAYER|HEALER|MOLTEN_CORE|18821|BOT_GEAR_PLAN|GREED|1",
    "Only Playerbot")
invalid("Eiga|PLAYERBOT|UNASSIGNED|MOLTEN_CORE|18821|BOT_GEAR_PLAN|GREED|1",
    "known Raid Role")
invalid("Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|99999|BOT_GEAR_PLAN|GREED|1",
    "Unknown/invalid")
invalid("Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|18821|BOT_GEAR_PLAN|GREED",
    "eight")
invalid("Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|18821|BOT_GEAR_PLAN|GREED|1|EXTRA",
    "eight")
invalid("Eiga|PLAYERBOT|HEALER|BLACKWING_LAIR|18821|BOT_GEAR_PLAN|GREED|1",
    "Molten Core")
invalid("Eiga|PLAYERBOT|HEALER|MOLTEN_CORE|x|BOT_GEAR_PLAN|GREED|1",
    "invalid Item ID")
local malformed,explain=T:Preview("no valid header\n"..second)
ok(not malformed and explain:find("Wrong file format"),
    "unknown format version refused")
-- An in-client multiline Ctrl+V may alter the clipboard payload even
-- when the .txt file is correct. A malformed first line MUST fail closed,
-- but now reports safe diagnostic lengths/bytes instead of vague failure.
local joined,joinedReason=T:Preview(header..first)
ok(not joined and joinedReason:find("LF=0",1,true) and
    joinedReason:find("first=[NLL-GEARPLANS-1",1,true),
    "joined header and record are refused with missing-LF diagnostic: "..tostring(joinedReason))
ok(joinedReason:find("hex=4E 4C 4C 2D",1,true),
    "diagnostic exposes first bytes in safe hex for 3.3.5a clipboard debugging")
local bom,bomWhy=T:Preview(string.char(239,187,191)..header.."\n"..first)
ok(not bom and bomWhy:find("hex=EF BB BF",1,true),
    "invisible UTF-8 BOM is identified and never silently auto-removed")
local wrongHeader,wrongWhy=T:Preview("NLL-GEARPLANS-X\n"..first)
ok(not wrongHeader and wrongWhy:find("Expected "..header,1,true),
    "unknown format version remains blocked")
ok(n.db.gearNeeds[needKey]==refs.existing and
    n.db.roleAssignments==refs.roles,
    "all failed clipboard previews leave pre-existing records untouched")
local nilData=T:Preview(header)
ok(not nilData,"header-only import refused")
local long=T:Preview(string.rep("X",T.MAX_BYTES+1))
ok(not long,"oversized import refused")
local crlf=T:Preview((header.."\n"..second):gsub("\n","\r\n"))
ok(crlf and crlf.unchanged==1 and not crlf.ready,
    "Windows CRLF paste is supported")
-- Detect changes *after* preview but *before* confirmation.
local additive=header.."\nWarma|PLAYERBOT|MAIN_TANK|MOLTEN_CORE|18821|BOT_GEAR_PLAN|GREED|1"
local saved=T:Preview(additive)
ok(saved and saved.ready,"prepare independent addition")
n.db.gearNeeds[needKey].status="OBTAINED"
yes,reason=T:Apply(saved,additive)
ok(not yes and reason:find("changed since preview"),
    "preview rejected after Gear Plans were edited")
n.db.gearNeeds[needKey].status="NEEDED"
-- Safety: no imports while a roll is in progress or fake raid active.
n.TicketLottery={active={status="WAITING_FOR_ROLL"}}
ok(not T:Preview(additive) and not T:Apply(saved,additive),
    "active lottery blocks import and confirm")
n.TicketLottery=nil
n.DebugSimulator={IsActive=function()return true end}
ok(not T:Preview(additive),"Debug Lab prevents importing real plans")
n.DebugSimulator=nil
n.LootDetection={lootOpen=true}
ok(not T:Preview(additive),"loot window blocks imports")
n.LootDetection=nil
GetNumRaidMembers=function()return 40 end
IsRaidLeader=function()return false end
IsRaidOfficer=function()return false end
ok(not T:Preview(additive),"non-officer cannot import in a raid")
IsRaidOfficer=function()return true end
ok(T:Preview(additive).ready,"raid officer can preview")
GetNumRaidMembers=function()return 0 end
-- Saved original values survive unchanged after all tests.
ok(n.db.gearNeeds[needKey]==refs.existing and
    n.db.gearNeeds[legacy.key]==refs.legacy and
    n.db.roleAssignments==refs.roles and
    n.db.lootAwardHistory==refs.award,
    "all initial references remain stable")
-- The owner's original Raid04 bot is TangØ (U+00D8).
-- Preserve the exact UTF-8 bytes; TangO is NOT the same character.
local tangName="TangØ"
local tangRecord=header.."\n"..tangName..
    "|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|GREED|1"
local tangPreview,tangWhy=T:Preview(tangRecord)
ok(tangPreview and tangPreview.ready and tangPreview.newCount==1,tangWhy)
ok(tangPreview.additions[1].character==tangName,
    "UTF-8 Latin-1 name preserved byte-for-byte in the preview")
local tangOK,tangReason=T:Apply(tangPreview,tangRecord)
ok(tangOK,tangReason)
local tangKey=G:MakeKey(tangName,"MOLTEN_CORE",19147,"BOT_GEAR_PLAN")
ok(n.db.gearNeeds[tangKey] and
    n.db.gearNeeds[tangKey].character==tangName and
    n.db.gearNeeds[tangKey].status=="GREED",
    "TangØ saved with exact name and Greed status")
local afterTang,exportCount=T:Export()
ok(exportCount==4 and afterTang:find(tangName,1,true),
    "export preserves original UTF-8 name, not TangO")
local tangAgain=T:Preview(tangRecord)
ok(tangAgain and tangAgain.unchanged==1 and not tangAgain.ready,
    "TangØ import remains idempotent")
local caseVariant=tangRecord:gsub(tangName,"Tangø")
local variantPreview=T:Preview(caseVariant)
ok(variantPreview and not variantPreview.ready and
    #variantPreview.conflicts==1 and variantPreview.newCount==0,
    "Tangø cannot create a duplicate plan for existing TangØ")
local duplicateVariant=T:Preview(tangRecord.."\n"..caseVariant:match("\n(.+)$"))
ok(not duplicateVariant,"uppercase/lowercase Ø duplicate in same batch blocked")
ok(n.db.gearNeeds[tangKey].character==tangName,
    "UTF-8 collision checking never renames or changes saved TangØ")
local renamed=T:Preview((tangRecord:gsub(tangName,"TangO")))
ok(renamed and renamed.ready and renamed.newCount==1,
    "a differently spelled TangO is never silently merged into TangØ")
ok(n.db.gearNeeds[tangKey].character==tangName,
    "checking a different name does not edit the original")
local function invalidCharacter(name)
    local record=header.."\n"..name..
        "|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|GREED|1"
    local before=G:GetCount()
    local result,why=T:Preview(record)
    ok(not result and why and why:find("Invalid character name",1,true),
        "reject malformed UTF-8 or unsafe character: "..tostring(why))
    ok(G:GetCount()==before,"malformed names never change Gear Plans")
end
invalidCharacter("Tang"..string.char(195))           -- cut UTF-8
invalidCharacter("Tang"..string.char(195,151))       -- multiplication sign
invalidCharacter("Tang"..string.char(195,183))       -- division sign
invalidCharacter("Tang"..string.char(192,175))       -- overlong UTF-8
invalidCharacter("Tang_".."O")                       -- punctuation
invalidCharacter("X"..string.rep("y",40))            -- 41 Unicode characters
ok(n.db.localWishlists.Owner.MOLTEN_CORE==refs.wish and
    n.db.roleAssignments==refs.roles and
    n.db.lootAwardHistory==refs.award and
    n.db.lotteryHistory==refs.lottery,
    "UTF-8 name handling never changes protected save tables")
print("PASS: "..checks.." Playerbot import/export, conflict, UTF-8 name and history safety checks")
