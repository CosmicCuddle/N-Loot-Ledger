-- Lua 5.1 regression for 3.3.5a Raid Loot Search long-name layout.
-- Visual acceptance still requires the owner's actual client font/UI scale.
local assertions = 0
local function check(value, label)
    assert(value, label)
    assertions=assertions+1
end
local function mockFrame()
    local f={}
    function f:SetAllPoints() end
    function f:SetPoint(...) self.points=self.points or {};self.points[#self.points+1]={...} end
    function f:SetWidth(n) self.width=n end
    function f:SetHeight(n) self.height=n end
    function f:SetAutoFocus() end
    function f:SetJustifyH() end
    function f:SetText(s) self.text=s end
    function f:GetText() return self.text end
    function f:SetTexture(t) self.texture=t end
    function f:CreateTexture() return mockFrame() end
    function f:CreateFontString() return mockFrame() end
    function f:SetScript(name,handler)
        self.events=self.events or {}
        self.events[name]=handler
    end
    function f:GetStringWidth()
        local plain=(self.text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        return #plain*12 -- intentionally wide custom-client test font
    end
    function f:Show() self.visible=true end
    function f:Hide() self.visible=false end
    function f:Enable() self.enabled=true end
    function f:Disable() self.enabled=false end
    return f
end
CreateFrame=function() return mockFrame() end
GetItemIcon=function(id)return "icon:"..tostring(id) end
GameTooltip={
    SetOwner=function()end,
    SetHyperlink=function(_,link) GameTooltip.link=link end,
    AddLine=function(_,line) GameTooltip.line=line end,
    Show=function()end, Hide=function()end
}
local results={
    {name="Formula: Enchant Weapon - Healing Power",itemID=18260,manualOnly=true},
    {name="Formula: Enchant Weapon - Spell Power",itemID=18259,manualOnly=true},
    {name="Schematic: Biznicks 247x128 Accurascope",itemID=18290,manualOnly=true},
    {name="Arcanist Boots",itemID=16800,manualOnly=false}
}
NaxxLootLottery={
    UI={},
    ItemSearch={
        results={},
        GetSelectedRaid=function() return "MOLTEN_CORE" end,
        GetResults=function(self) return self.results end,
        GetReservationCount=function()return 2 end,
        IsReserved=function(_,id)return id==18260 or id==18259 end
    },
    Data={MoltenCore={
        GetBossText=function()return "All bosses" end
    }},
    PriorityEngine={
        GetDisplayLabel=function(_,_,id)
            if id==16800 then return "Not configured" end
            return "Manual: Profession recipe"
        end
    }
}
local UI=NaxxLootLottery.UI
function UI:RegisterSkinnedFrame() end
function UI:CreateTextButton(_,label,width)
    local f=mockFrame()
    f.label=mockFrame()
    f.label:SetText(label)
    f.width=width
    return f
end
function UI:SetButtonState(button,state) button.state=state end
assert(loadfile("NaxxLootLottery/UI/SearchFrame.lua"))()
UI:CreateSearchPanel(mockFrame())
NaxxLootLottery.ItemSearch.results=results
UI:RefreshSearchPanel()

check(UI.searchTotalPages==1,"all four items fit page one")
check(#UI.searchRows==6,"original six-row layout retained")
local healing=UI.searchRows[1]
local spell=UI.searchRows[2]
check(healing.visible and spell.visible,"both formulas visible")
check(healing.nameText.text=="Formula: Healing Power","healing formula visibly distinguished")
check(spell.nameText.text=="Formula: Spell Power","spell formula visibly distinguished")
check(healing.nameText:GetStringWidth()<=282,"healing formula fits name slot")
check(spell.nameText:GetStringWidth()<=282,"spell formula fits name slot")
check(healing.idText.text=="Item ID: 18260" and spell.idText.text=="Item ID: 18259",
    "item IDs retained separately")
check(healing.nameText.height==18 and healing.idText.height==14,
    "text occupies separate one-line-height regions")
check(healing.priorityText.height==18 and healing.priorityText.width==92,
    "priority remains a single line within its column")
check(healing.priorityText.text=="|cffff9933Manual|r",
    "manual recipe reason compacted only for display")
check(healing.priorityHit.fullPriority=="Manual: Profession recipe",
    "full manual policy retained in tooltip")
healing.priorityHit.events.OnEnter(healing.priorityHit)
check(GameTooltip.line=="Manual: Profession recipe",
    "priority hover explains the policy")
healing.nameHit.events.OnEnter(healing.nameHit)
check(GameTooltip.link:find("item:18260:",1,true)~=nil,
    "full item tooltip remains available for shortened title")
check(healing.reserveButton.label.text=="Remove" and healing.reserveButton.state=="danger",
    "existing reservation remains and Remove control unchanged")
local long=UI.searchRows[3]
check(long.nameText:GetStringWidth()<=282 and
    long.nameText.text:sub(-3)=="...",
    "other long titles are safely truncated with ellipsis")
check(long.nameHit.itemID==18290,
    "full long-title tooltip still links the exact item")
local regular=UI.searchRows[4]
check(regular.nameText.text=="Arcanist Boots","regular short equipment name unchanged")
check(regular.priorityText.text=="Not set","unconfigured rule compacted for display")
check(regular.reserveButton.label.text=="Reserve","regular reserve button retained")
check(UI.searchRows[5].visible==false and UI.searchRows[5].nameHit.itemID==nil,
    "empty rows clear tooltip identity")
print("PASS: "..assertions.." search name/ID/priority layout assertions")
