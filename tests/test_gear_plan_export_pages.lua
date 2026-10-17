-- WoW 3.3.5a / Lua 5.1: safe multi-page Playerbot export for 604 plans.
local passed=0
local function ok(condition,why) assert(condition,why); passed=passed+1 end
local n={roleLabels={HEALER="Healer",TANK="Tank",
    RANGED_PHYSICAL_DPS="Ranged Physical DPS"},
    Data={MoltenCore={GetItem=function(_,id)
        if id>=200001 and id<=200604 then return {name="Simulated MC item"} end
    end}},
    db={gearNeeds={},roleAssignments={["TangØ"]={role="HEALER"}},
        localWishlists={Owner={MOLTEN_CORE={[19147]=true}}},
        lootAwardHistory={{winner="Before"}},lotteryHistory={{winner="Before"}}}
}
NaxxLootLottery=n
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearPlanTransfer.lua"))()
local G,T=n.GearNeeds,n.GearPlanTransfer
local roleRef=n.db.roleAssignments
local wishlistRef=n.db.localWishlists
local historyRef=n.db.lootAwardHistory
local ledgerRef=n.db.lotteryHistory
local original={}
for i=1,604 do
    local character=(i==604 and "TangØ" or "Meshana")
    local itemID=200000+i
    local status=i<=469 and "NEEDED" or "GREED"
    local role=(i==604 and "HEALER" or "RANGED_PHYSICAL_DPS")
    local key=G:MakeKey(character,"MOLTEN_CORE",itemID,"BOT_GEAR_PLAN")
    n.db.gearNeeds[key]={
        key=key,character=character,itemID=itemID,raidKey="MOLTEN_CORE",
        role=role,status=status,source="BOT_GEAR_PLAN",
        characterType="PLAYERBOT",raid="Molten Core"
    }
    original[key]=status
end
local saved=n.db.gearNeeds
ok(G:GetCount()==604,"604 bot records available in original account")
local pageText,oldCount,pageCount,total,snapshot=T:Export()
ok(pageText and oldCount==250 and pageCount==3 and total==604 and
    type(snapshot)=="string","default export returns complete page 1")
local files,unique={},{}
local sum,needs,greeds=0,0,0
for page=1,pageCount do
    local txt,count,pages,all,returnedSnapshot=T:Export(page,snapshot)
    ok(txt and count==(page==3 and 104 or 250) and pages==3 and
        all==604 and returnedSnapshot==snapshot,
        "page size, total and stable snapshot page "..page)
    ok(#txt<=T.MAX_BYTES and txt:find(T.HEADER,1,true)==1,
        "complete header and <=48KB page "..page)
    local parsed,why=T:Parse(txt)
    ok(parsed and #parsed==count,tostring(why))
    for _,row in ipairs(parsed) do
        ok(not unique[row.key],"no duplicate keys across export pages")
        unique[row.key]=true
        sum=sum+1
        if row.status=="NEEDED" then needs=needs+1
        elseif row.status=="GREED" then greeds=greeds+1
        else error("Unexpected status") end
    end
    files[page]=txt
end
ok(sum==604 and needs==469 and greeds==135,"full 604/469/135 coverage")
ok(files[1]==pageText,"page 1 consistent with old no-argument export")
ok(files[3]:find("TangØ",1,true)~=nil,
    "UTF-8 name survives last page intact, not silently omitted")
local tooEarly,reason=T:Export(0)
ok(not tooEarly and reason:find("Invalid export page"),
    "page 0 is blocked")
local tooLate,reason2=T:Export(4,snapshot)
ok(not tooLate and reason2:find("out of range"),"past-last page blocked")
ok(not T:Export(1.5,snapshot),"fractional page blocked")
local sampleKey=G:MakeKey("Meshana","MOLTEN_CORE",200001,"BOT_GEAR_PLAN")
n.db.gearNeeds[sampleKey].status="GREED"
local invalidated,changedWhy=T:Export(2,snapshot)
ok(not invalidated and changedWhy:find("changed during export"),
    "editing a saved record invalidates the previous export session")
ok(G:GetCount()==604 and n.db.gearNeeds==saved,
    "export failure has no effects on stored records")
n.db.gearNeeds[sampleKey].status="NEEDED"
ok(T:Export(3,snapshot)==files[3],
    "unchanged restored Gear Plans produce deterministic same bytes")
n.db.gearNeeds[sampleKey].status="BOGUS"
local rejected,why=T:Export(1)
ok(not rejected and why:find("Cannot export"),
    "an invalid stored interest blocks all export rather than omitting one")
n.db.gearNeeds[sampleKey].status="NEEDED"
local fresh,_,pc,all,ref=T:Export(1)
ok(fresh==pageText and pc==3 and all==604 and ref==snapshot,
    "fresh export recovers only after a valid database snapshot")
-- A new account with no prior Gear Plans can import each individual page.
n.db.gearNeeds={}
for page=1,3 do
    local preview,why=T:Preview(files[page])
    ok(preview and preview.ready and preview.newCount==(page==3 and 104 or 250) and
        preview.unchanged==0 and #preview.conflicts==0,tostring(why))
    local yes,message=T:Apply(preview,files[page])
    ok(yes and message:find("Added ",1,true),tostring(message))
end
ok(G:GetCount()==604,"restored 604 bot plans by three independent import batches")
for key,status in pairs(original) do
    ok(n.db.gearNeeds[key] and n.db.gearNeeds[key].status==status,
        "exact Need/Greed status and identity roundtrip")
end
for page=1,3 do
    local identical=T:Preview(files[page])
    ok(identical and not identical.ready and identical.newCount==0 and
        identical.unchanged==(page==3 and 104 or 250),
        "re-import is idempotent for complete export page "..page)
end
local allPagesOK=true
for page=1,3 do
    local again=T:Export(page)
    if again~=files[page] then allPagesOK=false end
end
ok(allPagesOK,"re-export from restored 604 plans is byte-for-byte identical")
ok(n.db.roleAssignments==roleRef and
    n.db.localWishlists==wishlistRef and
    n.db.lootAwardHistory==historyRef and
    n.db.lotteryHistory==ledgerRef,
    "all global roles, personal wishlists and real loot histories preserved")
print("PASS: "..passed.." deterministic 604-plan export pages, roundtrip, UTF-8 and data isolation assertions")
