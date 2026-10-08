local ROOT=(arg and arg[1]) or 'NaxxLootLottery/'
local tests=0
local function ok(v,msg) assert(v,msg or 'failed');tests=tests+1 end
local clock=100
GetTime=function()return clock end
time=function()return 1800000000+clock end
date=function()return '2026-10-08' end
UnitName=function()return 'Leader' end
GetNumRaidMembers=function()return 4 end
IsRaidLeader=function()return true end
IsRaidOfficer=function()return false end
GetLootMethod=function()return 'master',nil,1 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local items={}
GetNumLootItems=function()return #items end
GetLootSlotLink=function(i) return items[i] and '|Hitem:'..items[i]..':0|h[X]|h' end
GetLootSlotInfo=function()return nil,nil,1,4,false end
local prints={}
local roster={{name='Leader',classFile='PALADIN',online=true,assignedRole='HEALER'},
{name='BotTank',classFile='WARRIOR',online=true,assignedRole='MAIN_TANK'},
{name='BotHeal',classFile='PRIEST',online=false,assignedRole='HEALER'}}
local db={raidSession={currentLoot={},lootGeneration=0},settings={debug=false},lootIdentityAudit={},
 gearNeeds={tank={character='BotTank',itemID=18821,status='NEEDED',source='BOT_GEAR_PLAN',characterType='PLAYERBOT'},
 heal={character='BotHeal',itemID=16812,status='NEEDED',source='BOT_GEAR_PLAN',characterType='PLAYERBOT'},
 absent={character='BotMissing',itemID=16800,status='NEEDED',source='BOT_GEAR_PLAN',characterType='PLAYERBOT'}}}
NaxxLootLottery={db=db,Print=function(_,s)prints[#prints+1]=s end,Debug=function()end,
 IsValidClass=function(_,c)return c=='WARRIOR' or c=='PRIEST' or c=='PALADIN' end,
 IsValidRole=function(_,r)return r=='MAIN_TANK' or r=='HEALER' end,
 Roster={Refresh=function()end,GetMembers=function()return roster end},
 Database={GetRoleAssignment=function(_,name)return name=='BotTank' and 'MAIN_TANK' or nil end,
 GetCharacterClass=function(_,name)return name=='BotTank' and 'WARRIOR' or nil end},
 UI={RefreshCurrentLootPanel=function()end},
 CandidateReview={OnLootChanged=function()end},
 DebugSimulator={IsActive=function()return false end},
 Data={MoltenCore={GetItem=function(_,id)return {itemID=id,name='Item',bosses={'Ragnaros'}}end}}
}
local n=NaxxLootLottery
local function load(path)assert(loadfile(ROOT..path))()end
load('Core/LootIdentity.lua')
load('Core/TicketLottery.lua')
load('Core/LootDetection.lua')
load('Core/PlayerbotCompatibility.lua')
n.LootIdentity:Initialize()
local function scan(ids)
 clock=clock+1;items=ids;n.LootDetection:ScanLootWindow()
 return n.LootDetection:GetCurrentLoot()
end
local first=scan({16800})[1]
n.LootIdentity:MarkCompleted(first.dropUID,'MageOne',1,'SERVER_RANDOM_ROLL')
ok(n.LootIdentity:IsProcessed(first.dropUID),'A processed')
local second=scan({18821})[1]
ok(second.dropUID~=first.dropUID,'B is another group')
ok(#n.LootIdentity:GetGroup().groups==1,'A archived')
local revisited=scan({16800})[1]
ok(revisited.dropUID==first.dropUID,'A->B->A restores A UID')
ok(n.LootIdentity:IsProcessed(revisited.dropUID),'A remains locked')
ok(n.TicketLottery:GetActiveFor(revisited).winner=='MageOne','A winner restores')
ok(n.LootIdentity:GetRow(revisited.dropUID).awardContextClosed,'revisit is award closed')
local allowed,why=n.TicketLottery:Prepare(revisited)
ok(not allowed and why:find('already has a winner'),'second A roll blocked')
-- Interleaved multiple signatures, live saved reload, old groups not erased.
local third=scan({16812})[1]
ok(third.dropUID~=first.dropUID,'C new group')
n.LootIdentity.initialized=false
n.LootIdentity:Initialize()
local aagain=scan({16800})[1]
ok(aagain.dropUID==first.dropUID,'saved history survives reload')
-- Legitimate NEW A requires explicit action and remains stable on rescans.
local arm=n.LootIdentity:PrepareReset()
ok(arm,'leader may request new genuine corpse')
ok(n.LootIdentity:ConfirmReset(),'leader confirms new corpse')
local newa=n.LootDetection:GetCurrentLoot()[1]
ok(newa.dropUID~=first.dropUID,'new A gets new UID')
ok(newa.identityUncertain==false,'explicitly confirmed new opportunity is usable')
ok(scan({16800})[1].identityUncertain==false,'new A remains usable on re-open')
-- Multi-archived same-looking signature is UNKNOWN, never rollable.
scan({18821});scan({16800}) -- returns last A, kept as active
scan({16812})
local ambiguous=scan({16800})[1]
-- Active C, historical A + NEW A both match, so fail closed.
ok(ambiguous.identityUncertain,'two historical groups lock automatic identity')
local yes,reason=n.TicketLottery:Prepare(ambiguous)
ok(not yes and reason:find('ambiguous'),'ambiguous candidate blocked')
-- Diagnostic only observes real roster and saved gear plans; no writes.
local p=n.PlayerbotCompatibility
local bot=p:Inspect('BotTank')
ok(bot.status=='ROSTER READY' and bot.needed==1,'ready bot shown')
ok(bot.candidate=='NOT CHECKED','no selected ML slot is unverified')
ok(p:Inspect('BotHeal').status=='OFFLINE','offline bot blocked')
roster[2].classFile=nil
ok(p:Inspect('BotTank').status=='CLASS UNVERIFIED','saved class cannot prove real bot class')
roster[2].classFile='WARRIOR'
ok(p:Inspect('BotMissing').status=='NOT IN RAID','absent bot blocked')
LootFrame={selectedSlot=1,IsShown=function()return true end}
GetMasterLootCandidate=function(i) if i==1 then return 'Leader' elseif i==2 then return 'BotTank' end end
scan({18821})
ok(p:Inspect('BotTank').candidate=='LISTED INDEX 2','master loot candidate verified')
ok(p:Inspect('BotHeal').candidate=='NOT LISTED FOR SELECTED ITEM','absent candidate identified')
local before=#prints
ok(p:Report('BotTank'),'botcheck command works')
ok(#prints>before and #prints<before+6,'bounded output')
local fake=n.DebugSimulator
fake.IsActive=function()return true end
local blocked,msg=p:Report()
ok(not blocked and msg:find('fake raid'),'fake diagnostics blocked')
print('PASS: '..tests..' historical opportunity and Playerbot preflight assertions')
