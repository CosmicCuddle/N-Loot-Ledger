-- Lua 5.1: Overview overflow directs players to the already-implemented wishlist.
-- No real loot, saved records, or user settings are modified.
local count=0
local function check(ok,message)
    assert(ok,message)
    count=count+1
end

local function frame()
    local f={}
    function f:SetAllPoints() end
    function f:SetPoint(...) self.anchor={...} end
    function f:SetHeight(n) self.height=n end
    function f:SetWidth(n) self.width=n end
    function f:SetJustifyH() end
    function f:SetText(text) self.text=text end
    function f:SetTexture(tex) self.texture=tex end
    function f:SetScript(event,fn) self.events=self.events or {};self.events[event]=fn end
    function f:CreateFontString() return frame() end
    function f:CreateTexture() return frame() end
    function f:Show() self.visible=true end
    function f:Hide() self.visible=false end
    return f
end
CreateFrame=function() return frame() end
UnitName=function() return "Admina" end
GetItemIcon=function() return "Interface\\Icons\\INV_Misc_QuestionMark" end

local simActive=false
local items={}
local reserved={}
local fakeNeeds={}
for i=1,11 do
    local itemID=16800+i
    items[itemID]={itemID=itemID,name=string.format("Item %02d",i),bosses={"Trash"}}
    reserved[itemID]=true
    fakeNeeds[#fakeNeeds+1]={itemID=itemID,state="NEEDED"}
end

NaxxLootLottery={
    UI={},
    Roster={GetCount=function()return 39 end},
    ItemSearch={GetReservationCount=function()return 11 end},
    Database={GetLocalWishlist=function(_,name,raid)
        check(name=="Admina" and raid=="MOLTEN_CORE","read current local wishlist")
        return reserved
    end},
    LootDetection={GetCurrentLoot=function()return {} end},
    Data={MoltenCore={
        GetItem=function(_,id)return items[tonumber(id)] end,
        GetBossText=function()return "Trash" end
    }},
    DebugSimulator={
        active={entries={}},
        IsActive=function()return simActive end,
        GetNeeds=function()return fakeNeeds end,
        GetResultFor=function()return nil end
    }
}
local UI=NaxxLootLottery.UI
function UI:RegisterSkinnedFrame() end
assert(loadfile("NaxxLootLottery/UI/MainFrame.lua"))()
UI:CreateOverviewPanel(frame())
UI:RefreshOverview()
local row=UI.overviewReservedRows[6]
check(row.visible,"overflow row remains visible")
check(row.itemText.text=="+ 6 more reserved item(s)","11 entries abbreviate to first five plus six")
check(row.sourceText.text=="Full list: Wishlists > My Wishlist.",
    "real Overview points to implemented full wishlist")
check(not row.sourceText.text:find("Phase"),"no obsolete feature-phase message")

simActive=true
UI:RefreshOverview()
check(row.sourceText.text=="Fake plans: open Wishlists.",
    "fake Overview directs players to temporary plans, not personal wishlist")
check(row.itemText.text=="+ 6 more reserved item(s)","simulation overflow still calculated")
check(UI.overviewFooter.text:find("SIMULATION")~=nil,
    "real award safety disclaimer preserved for fake raid")

simActive=false
UI:RefreshOverview()
check(row.sourceText.text=="Full list: Wishlists > My Wishlist.",
    "real wishlist guidance returns after fake simulator stops")
check(UI.overviewFooter.text:find("not receipt%-verified")~=nil,
    "real award disclaimer unchanged")
print("PASS: "..count.." Overview full-wishlist guidance and simulation assertions")
