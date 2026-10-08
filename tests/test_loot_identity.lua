local ROOT=(arg and arg[1]) or 'NaxxLootLottery/'
local tests=0
local function ok(v,m) assert(v,m or 'failed'); tests=tests+1 end
local now=120
GetTime=function() return now end
time=function() return 1800000000+now end
date=function() return '2026-10-08 20:00:00' end
UnitName=function() return 'Leader' end
GetNumRaidMembers=function() return 40 end
IsRaidLeader=function() return true end
IsRaidOfficer=function() return false end
local msgs={}
NaxxLootLottery={db={raidSession={currentLoot={},lootGeneration=0},settings={debug=false},
    lotteryHistory={},lootAwardHistory={},candidateAudit={},lootIdentityAudit={}},
    Print=function(_,msg) msgs[#msgs+1]=msg end, Debug=function() end,
    UI={RefreshCurrentLootPanel=function() end}, Roster={Refresh=function() end},
    CandidateReview={OnLootChanged=function(self) self.calls=(self.calls or 0)+1 end},
    DebugSimulator={IsActive=function()return false end},
    Data={MoltenCore={GetItem=function(self,id) return {itemID=id,name='Item '..id,bosses={'Ragnaros'}} end}},
    TicketPlanner={BuildPreview=function() return {ready=true,current={{character='Alpha'}, {character='Bravo'}},chosenTier=1} end}}
local n=NaxxLootLottery
local fakeFrame=function()
    return {RegisterEvent=function() end, SetScript=function() end}
end
CreateFrame=fakeFrame
local current={}
GetNumLootItems=function()return #current end
GetLootSlotLink=function(i)return current[i] and '|Hitem:'..current[i]..':0:0:0|h[Item]|h' end
GetLootSlotInfo=function(i)return nil,nil,1,4,false end
local function load(name) assert(loadfile(ROOT..name))() end
load('Core/LootIdentity.lua')
load('Core/TicketLottery.lua')
load('Core/LootDetection.lua')
n.LootIdentity:Initialize()
local loot=n.LootDetection
local lottery=n.TicketLottery
local function scan(items, force)
    current=items;now=now+1
    return loot:ScanLootWindow(force)
end
local function finish(entry)
    lottery.active={dropUID=entry.dropUID,status='WAITING_FOR_ROLL',test=false,
        itemID=entry.itemID,itemName=entry.itemName,raidKey=entry.raidKey,boss=entry.boss,
        winner=nil,tickets={{number=1,character='Alpha'}, {number=2,character='Bravo'}},
        candidateKeys={'alpha','bravo'},tier=1,method='SERVER_RANDOM_ROLL'}
    ok(lottery:Finish(1,'SERVER_RANDOM_ROLL'),'finish failed')
end
ok(scan({16800,18814})==true,'first scan')
local entries=loot:GetCurrentLoot()
local first=entries[1].dropUID
local second=entries[2].dropUID
ok(first~=second,'independent drops')
finish(entries[1])
ok(n.LootIdentity:IsProcessed(first),'persistent lock')
ok(lottery:GetActiveFor(entries[1]).winner=='Alpha','winner visible')
lottery.active=nil
lottery.results={} -- simulate /reload
loot.lootOpen=false
lottery.liveLootObserved=false
ok(scan({16800,18814}),'reopen')
entries=loot:GetCurrentLoot()
ok(entries[1].dropUID==first,'reopened original ID')
ok(lottery:GetActiveFor(entries[1]).winner=='Alpha','restored after reload')
local prepared,message=lottery:Prepare(entries[1])
ok(prepared==false and message:find('already has a winner'),'duplicate blocked')
ok(lottery:Prepare(entries[2]),'second item still rollable')
local prep=lottery.active
ok(scan({16800,18814}),'same contents rescan')
ok(lottery.active==prep and lottery.active.status=='PREPARED','prepared state preserved')
lottery:Invalidate('test')
finish(loot:GetCurrentLoot()[2])
local third=loot:GetCurrentLoot()[2].dropUID
ok(third~=first,'second item distinct')
ok(scan({18814}),'subset scan')
ok(loot:GetCurrentLoot()[1].dropUID==third,'subset identity stable')
lottery.active=nil; lottery.results={}
ok(lottery:GetActiveFor(loot:GetCurrentLoot()[1]).winner=='Alpha','other winner restored')
-- Same item again on a new corpse remains blocked until explicit confirmation
ok(scan({18814}),'same-items new corpse')
ok(loot:GetCurrentLoot()[1].dropUID==third,'fail closed for lookalike corpse')
local yes,msg=n.LootIdentity:PrepareReset()
ok(yes,'leader can arm new corpse')
local resetOk=n.LootIdentity:ConfirmReset()
ok(resetOk,'leader can confirm new corpse')
local fresh=loot:GetCurrentLoot()[1]
ok(fresh.dropUID~=third,'new confirmed unique UID')
ok(not lottery:GetActiveFor(fresh),'new corpse is unrolled')
ok(lottery:Prepare(fresh),'new opportunity permits roll')
lottery:Invalidate('test')
local okFirst = n.LootIdentity:PrepareReset()
now=now+30
local expired,msg=n.LootIdentity:ConfirmReset()
ok(okFirst and not expired and msg:find('expired'),'two step expires')
-- Two physical copies with mixed states: partial reopened scan must block.
ok(scan({16800,16800}),'double copy')
local double=loot:GetCurrentLoot()
ok(double[1].dropUID~=double[2].dropUID,'duplicate items get distinct uids')
finish(double[1])
ok(scan({16800}),'partial duplicate scan')
local remainder=loot:GetCurrentLoot()[1]
ok(remainder.identityUncertain,'mixed duplicate cannot be inferred')
ok(lottery:GetActiveFor(remainder)==nil,'no guessed winner for ambiguous copy')
lottery.active=nil
local canPrepare,reason=lottery:Prepare(remainder)
ok(not canPrepare and reason:find('ambiguous'),'ambiguous blocked')
-- Reset any test artifacts safely on next /reload: no silent winner replay.
local snapshot=n.db.raidSession.lootIdentity
ok(type(snapshot)=='table' and #snapshot.rows>=2,'ledger persisted')
-- Unauthorized users cannot bypass the two-step confirmation.
IsRaidLeader=function() return false end
local allowed=n.LootIdentity:PrepareReset()
ok(not allowed,'unauthorized reset blocked')
-- Debug simulator never mutates live loot identity.
n.DebugSimulator.IsActive=function()return true end
local identifier=n.db.raidSession.lootIdentity.id
loot:SetCurrentLoot({{itemID=16800,slotIndex=1}})
ok(n.db.raidSession.lootIdentity.id==identifier,'fake mode cannot mutate real ledger')
print('PASS: '..tests..' deterministic loot-identity / recovery assertions')