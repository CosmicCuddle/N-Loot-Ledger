-- Lua 5.1: 604-row read-only export batches; all original saves intact.
local checks=0
local function ok(v,m)assert(v,m);checks=checks+1 end
local N={
    roleLabels={CASTER_DPS="Caster DPS"},
    db={gearNeeds={},roleAssignments={Gorak={role="CASTER_DPS"}},
        characters={Gorak={characterType="PLAYERBOT"}},
        localWishlists={Leader={MOLTEN_CORE={[16800]=true}}},
        lotteryHistory={{winner="Historic"}},lootAwardHistory={{winner="Historic"}},
        lootReceiptTracker={historic={status="WON_AWAITING_ITEM"}},
        guildLootTransferAudit={{itemID=17010,status="LOOT_SLOT_CLEARED"}},
        awardAttemptLocks={historic={status="AWARD_REQUESTED"}}},
    Data={MoltenCore={GetItem=function(_,id)
        return id and id>=10001 and id<=10700 and {itemID=id} or nil
    end}},
    DebugSimulator={IsActive=function()return false end},
    LootDetection={lootOpen=false},
    TicketLottery={active=nil},
}
NaxxLootLottery=N
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearPlanTransfer.lua"))()
local G=N.GearNeeds
local T=N.GearPlanTransfer
local identities={}
local need,greed=0,0
for i=1,604 do
    local index=math.floor((i-1)/16)
    local name="Bot"..string.char(65+math.floor(index/26))..
        string.char(65+(index%26))
    local itemID=10000+i
    local key=G:MakeKey(name,"MOLTEN_CORE",itemID,"BOT_GEAR_PLAN")
    local status=i<=469 and "NEEDED" or "GREED"
    N.db.gearNeeds[key]={key=key,character=name,
        characterType="PLAYERBOT",raidKey="MOLTEN_CORE",
        raid="Molten Core",itemID=itemID,role="CASTER_DPS",
        source="BOT_GEAR_PLAN",status=status}
    identities[key]=N.db.gearNeeds[key]
    if status=="NEEDED" then need=need+1 else greed=greed+1 end
end
local saved=N.db.gearNeeds
local roles=N.db.roleAssignments
local wishes=N.db.localWishlists
local history=N.db.lootAwardHistory
local lottery=N.db.lotteryHistory
local receipt=N.db.lootReceiptTracker
local guild=N.db.guildLootTransferAudit
local locks=N.db.awardAttemptLocks
ok(need==469 and greed==135 and G:GetCount()==604,
   "fixture matches exact 469 NEED / 135 GREED / 604 records")
local old,errorText=T:Export()
ok(old==nil and errorText:find("Too many bot plans",1,true),
   "old single-chunk Export() still fails closed for 604")
local all={}
local previous
for page=1,3 do
    local data,count,pages,total=T:ExportChunk(page)
    local expected=page==3 and 104 or 250
    ok(type(data)=="string" and count==expected and pages==3 and total==604,
       "batch count and total match, including final short batch")
    ok(#data<=T.MAX_BYTES and
       data:sub(1,#T.HEADER+1)==T.HEADER.."\n",
       "each batch is bounded V1 import-compatible text")
    local parsed,why=T:Parse(data)
    ok(parsed and #parsed==count,why or
       "each export chunk parses independently without format migration")
    for _,row in ipairs(parsed) do
        ok(not all[row.key],"no character/item pair duplicated across chunks")
        all[row.key]=row
        if previous then
            ok(previous<=row.character:lower().."|"..
                string.format("%06d",row.itemID),
               "sorted export order is deterministic across batches")
        end
        previous=row.character:lower().."|"..
            string.format("%06d",row.itemID)
    end
    ok(select(1,T:ExportChunk(page))==data,
       "repeating a batch returns byte-for-byte same data")
    local preview,err=T:Preview(data)
    ok(preview and preview.unchanged==count and
       preview.newCount==0 and not preview.ready and
       #preview.conflicts==0,err or
       "roundtrip import preview never overwrites existing saved records")
end
local total=0
for _ in pairs(all) do total=total+1 end
ok(total==604,"three individually copied sections cover EVERY bot plan")
for _,invalid in ipairs({0,4,-1,1.5,"2"}) do
    local data,why=T:ExportChunk(invalid)
    ok(not data and why,"invalid batch indices always refused")
end
-- Even when invalidity is in the LAST bot, batch one must fail rather
-- than exposing an incomplete copy that looks like a comprehensive export.
local lastKey=G:MakeKey("BotBL","MOLTEN_CORE",10604,"BOT_GEAR_PLAN")
-- Derive last key from the preserved fixture to avoid trusting sorting.
local finalKey=G:MakeKey("Bot"..string.char(66)..
    string.char(65+(math.floor(603/16)%26)),
    "MOLTEN_CORE",10604,"BOT_GEAR_PLAN")
local row=identities[finalKey]
ok(row~=nil,"last original row selected without constructing a new record")
row.role="INVALID"
local blocked,why=T:ExportChunk(1)
ok(not blocked and why:find("Cannot export",1,true),
   "bad row in final batch blocks all pages rather than silently truncating")
row.role="CASTER_DPS"
ok(select(4,T:ExportChunk(3))==604,
   "restoring record restores all pages without changing saved structures")
ok(N.db.gearNeeds==saved and N.db.roleAssignments==roles and
   N.db.localWishlists==wishes and N.db.lootAwardHistory==history and
   N.db.lotteryHistory==lottery and N.db.lootReceiptTracker==receipt and
   N.db.guildLootTransferAudit==guild and N.db.awardAttemptLocks==locks,
   "export and dry-run import preserve all references")
for key,savedRow in pairs(identities) do
    ok(N.db.gearNeeds[key]==savedRow and
        savedRow.status==(savedRow.itemID<=10469 and "NEEDED" or "GREED"),
        "all 604 original records and statuses unchanged")
end
print("PASS: "..checks.." 604-row chunked export, read-only identity and V1 roundtrip")
