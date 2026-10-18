-- NLL exact-character Gear Plans filter, WoW 3.3.5a Lua 5.1.
-- 604 saved rows / 38 bots; no SavedVariables replacement or mutation.
local checks=0
local function ok(value,message)assert(value,message);checks=checks+1 end
local function frame()
    local f={visible=false,enabled=true,events={}}
    function f:SetPoint(...)end
    function f:SetWidth(w)self.width=w end
    function f:SetHeight(h)self.height=h end
    function f:SetAutoFocus()end
    function f:SetJustifyH()end
    function f:SetText(s)
        self.text=s
        if self.events.OnTextChanged then self.events.OnTextChanged(self) end
    end
    function f:GetText()return self.text or "" end
    function f:ClearFocus()self.focusCleared=true end
    function f:SetScript(event,cb)self.events[event]=cb end
    function f:CreateFontString()return frame()end
    function f:Show()self.visible=true end
    function f:Hide()self.visible=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=function()return frame()end
UIDropDownMenu_Initialize=function(f,cb)f.menu=cb end
UIDropDownMenu_SetWidth=function()end
UIDropDownMenu_SetText=function(f,value)f.menuText=value end
UIDropDownMenu_CreateInfo=function()return {} end
UIDropDownMenu_AddButton=function()end
local botNames={"Gorak","Gorakalt","Gorakhan"}
for i=4,38 do botNames[i]="PlanBot"..i end
local data={}
local countNeed,countGreed=0,0
local originalReferences={}
for i=1,604 do
    local name=botNames[((i-1)%38)+1]
    local interest=i<=469 and "NEEDED" or "GREED"
    local key=name.."|MOLTEN_CORE|"..(10000+i).."|BOT_GEAR_PLAN"
    local value={key=key,character=name,itemID=10000+i,
        raidKey="MOLTEN_CORE",status=interest,source="BOT_GEAR_PLAN",
        characterType="PLAYERBOT",role="CASTER_DPS"}
    data[key]=value
    originalReferences[key]=value
    if interest=="NEEDED" then countNeed=countNeed+1 else countGreed=countGreed+1 end
end
local originalCount=0
for _ in pairs(data) do originalCount=originalCount+1 end
ok(originalCount==604 and countNeed==469 and countGreed==135,
    "fixture reproduces saved 604 / 469 NEED / 135 GREED baseline")
local variableContainer={gearNeeds=data}
NaxxLootLottery={
    db=variableContainer,
    UI={},
    Debug=function()end,
    GetRoleLabel=function()return "Caster DPS" end,
    Data={MoltenCore={GetItem=function(_,id)
        return {itemID=id,name="Item "..id} end}},
}
local N=NaxxLootLottery
local UI=N.UI
function UI:RegisterSkinnedFrame()end
local buttons={}
function UI:CreateTextButton(_,title,width)
    local b=frame()
    b.label=frame()
    b.label:SetText(title)
    buttons[title]=b
    return b
end
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
assert(loadfile("NaxxLootLottery/UI/WishlistFrame.lua"))()
local G=N.GearNeeds
local all=G:GetAllNeeds("")
ok(#all==604,"blank filter includes full saved Gear Plans")
local gorak=G:GetAllNeeds("gorak")
ok(#gorak==16 and G:GetAllNeeds("  GoRaK  ")[1].character=="Gorak",
    "exact matching ignores case and leading/trailing spaces")
for _,row in ipairs(gorak) do
    ok(row.character=="Gorak","no Gorakalt/Gorakhan in exact result")
end
ok(#G:GetAllNeeds("Gor")==0 and #G:GetAllNeeds("Gorakalt")==16,
    "partial name never silently includes a different character")
ok(#G:GetAllNeeds("!")==0,"unknown names return no records")
UI:CreateGearPlansContent(frame())
UI:RefreshGearPlans()
ok(UI.gearPlansTotalPages==101 and
   UI.gearPlansStatus.text=="604 saved Gear Need(s)",
   "unfiltered 604 records remain paged six per page")
local input=UI.gearFilterBox
ok(input.events.OnTextChanged and input.events.OnEnterPressed,
    "character filter reacts as text is typed and supports Enter")
input:SetText("g")
ok(UI.gearPlansPage==1 and UI.gearPlansTotalPages==1 and
   UI.gearPlansStatus.text:find("no exact match",1,true) and
   not UI.gearPlanRows[1].visible,
   "incomplete name shows no other character's Gear Plans")
UI.gearPlansPage=7
input:SetText("GoRaK")
ok(UI.gearPlansPage==1 and UI.gearPlansTotalPages==3 and
   UI.gearPlansStatus.text=="16 saved Gear Need(s) for GoRaK",
   "typing full case-insensitive exact name resets paging")
for _,row in ipairs(UI.gearPlanRows) do
    if row.visible then ok(row.characterText.text=="Gorak",
        "visible Gear Plan row belongs only to matching character") end
end
UI.gearPlansNext.events.OnClick()
ok(UI.gearPlansPage==2 and UI.gearPlanRows[1].characterText.text=="Gorak",
   "filtered pagination remains scoped to searched character")
input:SetText("Gorakalt")
ok(UI.gearPlansPage==1 and
   UI.gearPlanRows[1].characterText.text=="Gorakalt",
   "different exact name cannot retain stale Gorak entries")
input:SetText("   gorAK   ")
ok(UI.gearPlansStatus.text:find("16 saved",1,true) and
   UI.gearPlanRows[1].characterText.text=="Gorak",
   "trimmed exact search does not require manual Apply")
input.events.OnEnterPressed(input)
ok(input.focusCleared,"Enter removes input focus without changing plans")
input:SetText("Gorakhan")
ok(UI.gearPlanRows[1].characterText.text=="Gorakhan",
   "third similarly named bot is isolated")
UI.gearFilterBox:SetText("unknown")
ok(not UI.gearPlanRows[1].visible and UI.gearPlansTotalPages==1,
   "no-match state has no leftover results and safe pager")
ok(buttons["Apply"] and buttons["All"],
   "legacy Apply and All buttons remain accessible")
input:SetText("Gorakalt")
buttons["Apply"].events.OnClick()
ok(UI.gearPlanRows[1].characterText.text=="Gorakalt",
   "Apply still works for mouse-only users")
buttons["All"].events.OnClick()
ok(input:GetText()=="" and UI.gearPlanFilter=="",
   "All button clears the search without deleting any Gear Plans")
ok(UI.gearPlansTotalPages==101 and UI.gearPlanRows[1].visible and
   UI.gearPlansStatus.text=="604 saved Gear Need(s)",
   "clearing text instantly restores all saved plans")
local records=0
for key,row in pairs(N.db.gearNeeds) do
    records=records+1
    ok(originalReferences[key]==row and
       row.status==(tonumber(key:match("|(%d+)|"))<=10469 and "NEEDED" or "GREED"),
       "filter never edits or replaces a saved row")
end
ok(records==604 and N.db==variableContainer and
   N.db.gearNeeds==data,"same SavedVariables table and all bot plan records")
print("PASS: "..checks.." exact live Gear Plan filtering and 604-record preservation")
