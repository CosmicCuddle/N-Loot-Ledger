-- WoW 3.3.5a / Lua 5.1 Gear Plans footer regression.
-- Owner's 19-entry screenshot showed seven rows crossing the page controls.
local checks=0
local function ok(value,why) assert(value,why);checks=checks+1 end
local function frame()
    local f={}
    function f:SetPoint(...) self.points=self.points or {};self.points[#self.points+1]={...} end
    function f:SetWidth(x)self.width=x end
    function f:SetHeight(y)self.height=y end
    function f:SetAutoFocus()end
    function f:SetText(x)self.text=x end
    function f:GetText()return self.text or "" end
    function f:SetJustifyH()end
    function f:SetScript(key,cb)self.events=self.events or {};self.events[key]=cb end
    function f:CreateFontString()return frame() end
    function f:Show()self.visible=true end
    function f:Hide()self.visible=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=function()return frame() end
UIDropDownMenu_Initialize=function(f,cb)f.menu=cb end
UIDropDownMenu_SetWidth=function(f,x)f.menuWidth=x end
UIDropDownMenu_SetText=function(f,x)f.menuText=x end
UIDropDownMenu_CreateInfo=function()return {} end
local buttons={}
UIDropDownMenu_AddButton=function(info)buttons[#buttons+1]=info end
local needs={}
for i=1,19 do
    needs[i]={key="need"..i,character="Druzz",itemID=1000+i,
        status=i==2 and "OBTAINED" or i==3 and "DISABLED" or "NEEDED",
        source="BOT_GEAR_PLAN",role="CASTER_DPS"}
end
local ref=needs
local statusChanges=0
NaxxLootLottery={
    UI={},
    GetRoleLabel=function()return "Caster DPS" end,
    GearNeeds={
        GetAllNeeds=function()return needs end,
        SetStatus=function()statusChanges=statusChanges+1 end,
        RemoveNeed=function()error("must not remove needs")end
    },
    Data={MoltenCore={GetItem=function(_,id)
        return {itemID=id,name="Item "..tostring(id)} end}}
}
local UI=NaxxLootLottery.UI
function UI:RegisterSkinnedFrame()end
function UI:CreateTextButton(_,text,width)
    local btn=frame()
    btn.label=frame()
    btn.label:SetText(text)
    btn.width=width
    return btn
end
assert(loadfile("NaxxLootLottery/UI/WishlistFrame.lua"))()
UI:CreateGearPlansContent(frame())
UI:RefreshGearPlans()
ok(#UI.gearPlanRows==6,"six rows only, leaving room below list")
ok(UI.gearPlansTotalPages==4,"19 plans use four safe six-row pages")
ok(UI.gearPlansPageText.text=="Page 1 / 4","page footer correct")
ok(UI.gearPlanRows[6].visible,"last row on first page shown")
ok(UI.gearPlanRows[6].remove.needKey=="need6","sixth row has right entry")
ok(UI.gearPlansNext.enabled,"can advance")
UI.gearPlansNext.events.OnClick()
ok(UI.gearPlansPage==2 and UI.gearPlanRows[1].remove.needKey=="need7",
    "second page starts without duplicated row")
UI.gearPlansNext.events.OnClick()
UI.gearPlansNext.events.OnClick()
ok(UI.gearPlansPage==4 and UI.gearPlanRows[1].remove.needKey=="need19",
    "last page contains nineteenth plan")
ok(not UI.gearPlanRows[2].visible and not UI.gearPlansNext.enabled,
    "final page has no phantom rows")
ok(UI.gearInterestDrop.value=="NEEDED","new plan defaults to Need")
buttons={}
UI.gearInterestDrop.menu()
local hasGreed=false
for _,info in ipairs(buttons) do
    if info.text=="Greed / Off-Spec" then hasGreed=true end
end
ok(hasGreed,"creation menu offers Greed before plan is saved")
buttons={}
UI.gearPlanRows[1].statusDrop.menu()
local statuses={}
for _,info in ipairs(buttons) do statuses[info.text]=true end
ok(statuses.NEEDED and statuses.GREED and statuses.OBTAINED and
    statuses.DISABLED,"all four statuses present in row selector")
ok(needs==ref and #needs==19 and statusChanges==0,
    "visual and navigation checks do not rewrite saved Gear Plans")
print("PASS: "..checks.." Gear Plans pagination, GREED menu and saved-data assertions")
