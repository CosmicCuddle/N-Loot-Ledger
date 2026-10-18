-- WoW 3.3.5a / Lua 5.1: read-only import conflict comparison.
-- 604 saved synthetic Playerbot plans; no live user SavedVariables.
local checks=0
local function ok(v,msg)assert(v,msg);checks=checks+1 end
local fake=false
local blocked=false
local N={
    roleLabels={CASTER_DPS="Caster DPS",HEALER="Healer",
        MELEE_DPS="Melee DPS",TANK="Tank",MAIN_TANK="Main Tank"},
    db={gearNeeds={},roleAssignments={BotAA={role="CASTER_DPS"}},
        localWishlists={Owner={MOLTEN_CORE={[10001]=true}}},
        lootAwardHistory={{itemID=10001,status="LOOT_SLOT_CLEARED"}},
        lootReceiptTracker={held={status="WON_AWAITING_ITEM"}},
        lotteryHistory={{winner="Previous"}},
        guildLootTransferAudit={{itemID=17010,status="CLOSED_NO_RETRY"}}},
    Data={MoltenCore={GetItem=function(_,id)
        if id>=10001 and id<=10606 then return {itemID=id} end
        return nil
    end}},
    DebugSimulator={IsActive=function()return fake end},
    LootDetection={lootOpen=false},
    TicketLottery={active=nil},
    Debug=function()end,
}
NaxxLootLottery=N
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearPlanTransfer.lua"))()
local G=N.GearNeeds
local T=N.GearPlanTransfer
local saved=N.db.gearNeeds
local refs={roles=N.db.roleAssignments,wish=N.db.localWishlists,
    award=N.db.lootAwardHistory,receipt=N.db.lootReceiptTracker,
    lottery=N.db.lotteryHistory,guild=N.db.guildLootTransferAudit}
local rowRefs={}
for i=1,604 do
    local group=math.floor((i-1)/16)
    local char="Bot"..string.char(65+math.floor(group/26))..
        string.char(65+(group%26))
    local id=10000+i
    local key=G:MakeKey(char,"MOLTEN_CORE",id,"BOT_GEAR_PLAN")
    saved[key]={key=key,character=char,characterType="PLAYERBOT",
        role="CASTER_DPS",itemID=id,raidKey="MOLTEN_CORE",
        raid="Molten Core",source="BOT_GEAR_PLAN",
        status=i<=469 and "NEEDED" or "GREED"}
    rowRefs[key]=saved[key]
end
local aliasName="Tang"..string.char(195,184)
local incomingAlias="Tang"..string.char(195,152)
local aliasKey=G:MakeKey(aliasName,"MOLTEN_CORE",10605,"BOT_GEAR_PLAN")
saved[aliasKey]={key=aliasKey,character=aliasName,itemID=10605,
    raidKey="MOLTEN_CORE",role="HEALER",status="NEEDED",
    source="BOT_GEAR_PLAN",characterType="PLAYERBOT"}
rowRefs[aliasKey]=saved[aliasKey]
local function encoded(char,id,role,status)
    return table.concat({char,"PLAYERBOT",role,"MOLTEN_CORE",
        tostring(id),"BOT_GEAR_PLAN",status,"1"},"|")
end
local text=T.HEADER.."\n"..
    encoded("BotAA",10001,"HEALER","GREED").."\n"..
    encoded(incomingAlias,10605,"HEALER","NEEDED").."\n"..
    encoded("Freshbot",10606,"CASTER_DPS","NEEDED")
local preview,reason=T:Preview(text)
ok(preview and #preview.rows==3 and #preview.conflicts==2 and
   preview.newCount==1 and not preview.ready,
   reason or "existing differences and aliases block entire import")
ok(preview.conflicts[1].kind=="EXACT_KEY" and
   preview.conflicts[2].kind=="CASE_ALIAS",
   "case-aliased conflicting record distinguished from true field mismatch")
local detail,why=T:CompareConflict(preview,text,1)
ok(detail and not detail.safeToApply and not detail.replaceAuthorized and
   detail.index==1 and detail.total==2 and #detail.changes==2,
   why or "only Role + Interest changed")
ok(detail.changes[1].field=="role" and
   detail.changes[1].saved=="CASTER_DPS" and
   detail.changes[1].pasted=="HEALER",
   "exact saved versus pasted role printed accurately")
ok(detail.changes[2].field=="status" and
   detail.changes[2].saved=="NEEDED" and
   detail.changes[2].pasted=="GREED",
   "exact saved versus pasted Need/Greed printed accurately")
local display,count=T:FormatConflict(preview,text,1)
ok(count==2 and display:find("SAVED [CASTER_DPS]",1,true) and
   display:find("PASTED [HEALER]",1,true) and
   display:find("IMPORT BLOCKED",1,true),
   "full read-only explanation explicitly states import stays blocked")
local a=T:CompareConflict(preview,text,2)
ok(a and a.kind=="CASE_ALIAS" and a.changes[1].field=="character" and
   a.changes[1].saved==aliasName and a.changes[1].pasted==incomingAlias,
   "UTF-8 uppercase/lowercase alias retains original names without rewrite")
local noApply,deny=T:Apply(preview,text)
ok(not noApply and deny:find("Preview again",1,true),
   "conflict preview can never be confirmed as a normal add-only import")
ok(saved[G:MakeKey("Freshbot","MOLTEN_CORE",10606,"BOT_GEAR_PLAN")]==nil,
   "non-conflicting NEW row is not inserted when another row conflicts")
ok(not T:CompareConflict(preview,text.."\n",1),
   "altering pasted text invalidates all old details")
ok(not T:CompareConflict(preview,text,0) and
   not T:CompareConflict(preview,text,3) and
   not T:CompareConflict(preview,text,1.1) and
   not T:CompareConflict(preview,text,"1"),
   "all out-of-bounds or malformed page indices fail closed")
local unrelated=saved[G:MakeKey("BotAA","MOLTEN_CORE",10002,"BOT_GEAR_PLAN")]
unrelated.status="DISABLED"
ok(not T:CompareConflict(preview,text,1),
   "changes ANYWHERE in all 604 saved plans invalidate comparison")
unrelated.status="NEEDED"
fake=true
ok(not T:CompareConflict(preview,text,1),
   "fake raid cannot show stale real Gear Plan comparison")
fake=false
N.LootDetection.lootOpen=true
ok(not T:CompareConflict(preview,text,1),
   "open physical loot window disallows import comparison")
N.LootDetection.lootOpen=false
preview.used=true
ok(not T:CompareConflict(preview,text,1),
   "already used/invalidated preview cannot be inspected")
preview.used=false
local clean=T.HEADER.."\n"..encoded("Freshbot",10606,"CASTER_DPS","NEEDED")
local noConflict=T:Preview(clean)
ok(noConflict and noConflict.ready and #noConflict.conflicts==0 and
   not T:CompareConflict(noConflict,clean,1),
   "new-only V1 import retains normal add-only path without comparison")
local invalid=T:Preview(T.HEADER.."\n"..
    encoded("BotAA",10001,"BOGUS","GREED"))
ok(not invalid,"malformed role refused BEFORE conflict comparison")
for key,row in pairs(rowRefs) do
    ok(saved[key]==row,"original 605 row table references remain identical")
end
ok(G:GetCount()==605 and saved==N.db.gearNeeds and
   N.db.roleAssignments==refs.roles and N.db.localWishlists==refs.wish and
   N.db.lootAwardHistory==refs.award and
   N.db.lootReceiptTracker==refs.receipt and
   N.db.lotteryHistory==refs.lottery and
   N.db.guildLootTransferAudit==refs.guild and
   rowRefs[aliasKey].character==aliasName and
   saved[G:MakeKey("BotAA","MOLTEN_CORE",10001,"BOT_GEAR_PLAN")].status=="NEEDED",
   "zero SavedVariables writes / all 604+alias old Gear Plans and statuses intact")
print("PASS: "..checks.." immutable 604-plan conflict comparison, UTF-8 alias and no-overwrite guard")
