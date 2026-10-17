-- READ-ONLY guild loot preview: includes all item slots, materials & unknowns.
-- Must never send a GiveMasterLoot request or change SavedVariables.
local checks=0
local function ok(v,msg)assert(v,msg);checks=checks+1 end
local transfers=0
GiveMasterLoot=function()transfers=transfers+1;error("never award")end
local itemIDs={16800,18821,17010,18259,17204,17011,17012,17013,17014,17015,0}
local locked=false
GetNumLootItems=function()return #itemIDs end
GetLootSlotLink=function(i)
    if itemIDs[i]==0 then return nil end
    return "|Hitem:"..itemIDs[i]..":0|h[Item "..itemIDs[i].."]|h"
end
GetLootSlotInfo=function(i)return nil,nil,2,4,i==9 end
local unknownCache=false
GetItemInfo=function(id)
    if id==17013 then return nil end
    return "Material "..id,nil,(id==17204 and 5 or 2),nil,nil,
        ((id==17015 and "Quest") or ((id==16800 or id==18821) and "Armor" or "Trade Goods"))
end
GetNumRaidMembers=function()return 3 end
local duplicate=false
GetRaidRosterInfo=function(i)
    if i==1 or (i==2 and duplicate) then return "Leader"..i,2 end
    return "Other"..i,0
end
local storedNeed={itemID=16800,status="NEEDED",
    raidKey="MOLTEN_CORE",character="Throgar",characterType="PLAYERBOT"}
local storedGreed={itemID=18821,status="GREED",
    raidKey="MOLTEN_CORE",character="Pikeotter",characterType="PLAYER"}
local gear={first=storedNeed,second=storedGreed}
local localWishlists={Pikeotter={MOLTEN_CORE={[17010]=true}}}
local inbox={one={raidKey="MOLTEN_CORE",status="PENDING",itemIDs={18259},
    excluded={}}}
local history={{winner="HistoricRaidWinner"}}
local obj={localWishlists=localWishlists,gearNeeds=gear,submissionInbox=inbox,
    lotteryHistory=history,lootAwardHistory={}}
local special={itemID=17204,name="Eye of Sulfuras",manualOnly=true,legendary=true}
local known={itemID=18259,name="Recipe: X"}
local debug=false
NaxxLootLottery={
    db=obj,
    DebugSimulator={IsActive=function()return debug end},
    LootDetection={lootOpen=true},
    TicketLottery={liveLootObserved=true},
    Data={MoltenCore={GetItem=function(_,id)
        if id==17204 then return special end
        if id==18259 then return known end
        return nil
    end,IsRecipeItem=function(_,item)return item==known end}},
    UI={mainFrame=nil},
}
local n=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GuildLootReview.lua"))()
local g=n.GuildLootReview
local rows,msg=g:Scan()
ok(#rows==10 and msg:find("non%-item slot"),"ten item slots incl. unlisted mats")
local byId={}
for _,x in ipairs(rows) do byId[x.itemID]=x end
ok(byId[16800].status=="RESERVED" and byId[16800].need==1,
    "offline bot NEED is never treated as unreserved")
ok(byId[18821].status=="RESERVED" and byId[18821].greed==1,
    "GREED interests also protect against guild routing")
ok(byId[17010].status=="UNRESOLVED" and byId[17010].localCount==1,
    "unsubmitted local reservation blocks routing")
ok(byId[18259].status=="UNRESOLVED" and byId[18259].pending==1,
    "pending recipe submission blocks guild routing")
ok(byId[17204].status=="SPECIAL_HOLD",
    "legendary/manual-only item can never be silently routed")
ok(byId[17011].status=="GUILD_REVIEW" and
    byId[17011].category=="Trade Goods",
    "non-database crafting materials appear in guild review")
ok(byId[17012].status=="GUILD_REVIEW",
    "unreserved general gear appears in guild review")
ok(byId[17013].status=="UNRESOLVED",
    "uncached unknown item does not become proven unreserved")
ok(byId[17014].status=="LOCKED",
    "locked slot excluded from guild candidate consideration")
ok(byId[17015].status=="SPECIAL_HOLD",
    "quest-class items must receive manual/special review")
ok(byId[17011].leader=="Leader1" and
    not byId[17011].recipientVerified and
    not byId[17011].transferAuthorized,
    "leader is only a PROPOSED recipient, not a verified candidate")
ok(transfers==0 and obj.gearNeeds==gear and
    obj.localWishlists==localWishlists and obj.submissionInbox==inbox and
    obj.lotteryHistory==history,
    "scanning never awards, writes history or replaces Gear Plans")
local previous=rows
n.LootDetection.lootOpen=false
rows,msg=g:Scan()
ok(#rows==0 and msg:find("CORPSE CLOSED",1,true),
    "despawned loot cannot be proposed using a saved item record")
ok(transfers==0,"closed-corpse recheck remains non-awarding")
n.LootDetection.lootOpen=true
duplicate=true
rows,msg=g:Scan()
ok(#rows==0 and msg:find("ambiguous"),"duplicate leader identity blocks review")
duplicate=false
debug=true
rows,msg=g:Scan()
ok(#rows==0 and msg:find("Fake raid"),"fake raid never mixes with real guild loot")
debug=false
-- Modal UI: browse more than six different item slots without mutation.
local function frame()
    local f={shown=false,events={}}
    function f:SetPoint(...)self.point={...}end
    function f:SetSize(...)end
    function f:SetWidth(v)self.width=v end
    function f:SetHeight(v)self.height=v end
    function f:SetFrameStrata(...)end
    function f:SetFrameLevel(...)end
    function f:GetFrameLevel()return 1 end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:SetJustifyH(...)end
    function f:SetText(t)self.text=t end
    function f:CreateFontString()return frame()end
    function f:SetScript(k,fn)self.events[k]=fn end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=frame
function n.UI:CreateTextButton(_,label,width)
    local f=frame()
    f.label=frame()
    f.label:SetText(label)
    f.width=width
    return f
end
function n.UI:RegisterSkinnedFrame()end
n.UI.mainFrame=frame()
assert(loadfile("NaxxLootLottery/UI/CurrentLootFrame.lua"))()
n.UI:OpenGuildLootReview()
ok(n.UI.guildLootDialog.shown and n.UI.guildLootPageText.text=="Page 1/2",
    "all-slot guild modal paginates beyond six items")
ok(n.UI.guildLootRows[1].nameText.text:find("RESERVED",1,true),
    "first page labels reserved gear")
n.UI.guildLootNext.events.OnClick()
ok(n.UI.guildLootPageText.text=="Page 2/2" and
    n.UI.guildLootRows[3].shown,
    "next guild loot page displays remaining materials")
n.UI.guildLootPrev.events.OnClick()
ok(n.UI.guildLootPageText.text=="Page 1/2",
    "backward pagination restores first page")
n.LootDetection.lootOpen=false
n.UI:RefreshGuildLootDialog()
ok(not n.UI.guildLootRows[1].shown and
    n.UI.guildLootStatus.text:find("CORPSE CLOSED",1,true),
    "live preview clears immediately after corpse closes")
ok(transfers==0 and #obj.lootAwardHistory==0 and
    obj.gearNeeds.first==storedNeed and obj.gearNeeds.second==storedGreed,
    "even the UI cannot transfer items or change reservations")
print("PASS: "..checks.." all-item guild review / materials / conservative guards")
