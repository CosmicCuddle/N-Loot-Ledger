-- Lua 5.1: Gear Plan import/export dialog interaction (no actual game window).
local checks=0
local function ok(value,message)assert(value,message);checks=checks+1 end
local function frame()
    local f={events={},visible=false,enabled=true,text="",height=0}
    function f:SetPoint(...)self.points=self.points or {};self.points[#self.points+1]={...}end
    function f:SetWidth(w)self.width=w end
    function f:SetHeight(h)self.height=h end
    function f:SetText(s)
        self.text=s
        if self.events.OnTextChanged then self.events.OnTextChanged(self) end
    end
    function f:GetText()return self.text end
    function f:SetScript(k,cb)self.events[k]=cb end
    function f:GetScript(k)return self.events[k] end
    function f:CreateFontString()return frame()end
    function f:SetJustifyH()end
    function f:SetFrameStrata()end
    function f:SetMovable()end
    function f:SetClampedToScreen()end
    function f:EnableMouse()end
    function f:RegisterForDrag()end
    function f:StartMoving()end
    function f:StopMovingOrSizing()end
    function f:SetMultiLine(v)self.multiline=v end
    function f:SetAutoFocus()end
    function f:SetFontObject()end
    function f:SetMaxLetters(v)self.maxLetters=v end
    function f:SetScrollChild(v)self.child=v end
    function f:HighlightText()self.highlighted=true end
    function f:SetFocus()self.focused=true end
    function f:ClearFocus()self.focused=false end
    function f:Show()self.visible=true end
    function f:Hide()self.visible=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
-- Simulate the native Wrath UIPanelScrollFrameTemplate OnLoad rule:
-- FrameXML builds '$parentScrollBar' from self:GetName(); nil crashes
-- with "attempt to concatenate a nil value" in ScrollFrame_OnLoad.
local scrollTemplates=0
CreateFrame=function(frameType, frameName, parent, template)
    local created=frame()
    created.frameType=frameType
    created.frameName=frameName
    function created:GetName()return self.frameName end
    if template=="UIPanelScrollFrameTemplate" then
        scrollTemplates=scrollTemplates+1
        assert(frameType=="ScrollFrame","scroll template requires ScrollFrame")
        assert(type(created:GetName())=="string" and
            created:GetName()~="","Wrath 3.3.5a scroll template requires a name")
        local scrollbarName=created:GetName().."ScrollBar"
        assert(scrollbarName=="NaxxLootLotteryGearTransferScrollFrameScrollBar",
            "scrollbar must resolve to the intended named widget")
    end
    return created
end
UIParent=frame()
ChatFontNormal={}
NaxxLootLottery={
    UI={},
    db={gearNeeds={},gearNeedsSchema=1,
        roleAssignments={Owner={role="CASTER_DPS"}},
        localWishlists={Owner={MOLTEN_CORE={[19147]=true}}},
        lootAwardHistory={{winner="OldWinner"}},
        lotteryHistory={{winner="OldWinner"}}},
    roleLabels={CASTER_DPS="Caster DPS",MAIN_TANK="Main Tank"},
    IsValidRole=function(_,role)
        return role=="CASTER_DPS" or role=="MAIN_TANK"
    end,
    Debug=function()end,
    Print=function(self,msg)self.lastPrint=msg end,
    Data={MoltenCore={GetItem=function(_,id)
        if id==19147 then return {name="Ring of Spell Power"}end
    end}}
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
assert(loadfile("NaxxLootLottery/Core/GearPlanTransfer.lua"))()
assert(loadfile("NaxxLootLottery/UI/WishlistFrame.lua"))()
local UI=N.UI
function UI:RegisterSkinnedFrame()end
function UI:CreateTextButton(_,label,width)
    local btn=frame()
    btn.label=frame()
    btn.label:SetText(label)
    btn.width=width
    return btn
end
local refresh=0
UI.RefreshGearPlans=function()refresh=refresh+1 end
local key=N.GearNeeds:MakeKey("Druzz","MOLTEN_CORE",19147,"BOT_GEAR_PLAN")
N.db.gearNeeds[key]={key=key,character="Druzz",itemID=19147,
    raidKey="MOLTEN_CORE",role="CASTER_DPS",status="NEEDED",
    source="BOT_GEAR_PLAN",characterType="PLAYERBOT"}
local refs={gear=N.db.gearNeeds,original=N.db.gearNeeds[key],
    roles=N.db.roleAssignments,wishlist=N.db.localWishlists.Owner.MOLTEN_CORE,
    awards=N.db.lootAwardHistory,lotteries=N.db.lotteryHistory}
local dialog=UI:ShowGearPlanTransfer()
ok(UI.gearTransferDialog and UI.gearTransferDialog.visible,
    "transfer dialog can open as independent panel")
ok(scrollTemplates==1,"actual Wrath scroll template was created exactly once")
ok(UI.gearTransferTextBox.text:find("Druzz",1,true),
    "opens with existing bot plans automatically exported")
ok(UI.gearTransferTextBox.highlighted and UI.gearTransferTextBox.focused,
    "export text is selected and ready to Ctrl+C")
ok(UI.gearTransferConfirm.enabled==false and
   UI.gearTransferPreview.enabled==false,
   "export cannot confirm a saved-data write")
ok(N.db.gearNeeds==refs.gear and N.db.gearNeeds[key]==refs.original and
    N.db.roleAssignments==refs.roles and
    N.db.localWishlists.Owner.MOLTEN_CORE==refs.wishlist,
    "opening export cannot rewrite any data")
UI.gearTransferImport.events.OnClick()
ok(UI.gearTransferPreview.enabled and
    not UI.gearTransferConfirm.enabled and UI.gearTransferTextBox.text=="",
    "import starts blank, enables preview and disables confirmation")
UI.gearTransferPreview.events.OnClick()
ok(not UI.gearTransferConfirm.enabled and
   UI.gearTransferStatus.text:find("text box is EMPTY",1,true),
   "blank paste reports empty text, not a misleading file-format error")
local source="NLL-GEARPLANS-1\nEiga|PLAYERBOT|CASTER_DPS|MOLTEN_CORE|19147|BOT_GEAR_PLAN|GREED|1"
UI.gearTransferTextBox:SetText(source)
ok(UI.gearTransferTextBox.multiline,"paste textbox is multiline")
UI.gearTransferImport.events.OnClick()
ok(UI.gearTransferTextBox.text==source,
    "repeated Paste / Import click must NOT clear an already pasted batch")
ok(not UI.gearTransferConfirm.enabled,
    "repeated mode click cancels any pending confirmation")
UI.gearTransferPreview.events.OnClick()
ok(UI.gearTransferConfirm.enabled,"validated new plan enables Confirm ADD")
UI.gearTransferImport.events.OnClick()
ok(UI.gearTransferTextBox.text==source and
   not UI.gearTransferConfirm.enabled,
    "repeated import-mode click preserves text and revokes stale approval")
UI.gearTransferPreview.events.OnClick()
ok(UI.gearTransferConfirm.enabled,
    "re-preview after import-mode click permits safe confirmation")
ok(refresh==0,"preview alone does not refresh or mutate plans")
-- Editing one byte AFTER preview must invalidate confirmation.
UI.gearTransferTextBox:SetText(source.."\n")
ok(not UI.gearTransferConfirm.enabled,
    "editing after preview immediately revokes confirmation")
UI.gearTransferPreview.events.OnClick()
ok(UI.gearTransferConfirm.enabled,
    "explicitly re-previewing harmless trailing whitespace enables confirmation")
-- Switching back to the original text cancels the re-preview until done again.
UI.gearTransferTextBox:SetText(source)
ok(not UI.gearTransferConfirm.enabled,"subsequent edit revokes the confirmation")
UI.gearTransferPreview.events.OnClick()
ok(UI.gearTransferConfirm.enabled,"valid preview may be re-requested")
UI.gearTransferConfirm.events.OnClick()
local imported=N.GearNeeds:MakeKey("Eiga","MOLTEN_CORE",19147,"BOT_GEAR_PLAN")
ok(N.db.gearNeeds[imported] and N.db.gearNeeds[imported].status=="GREED",
    "explicit Confirm ADD inserts only the new Greed plan")
ok(refresh==1 and not UI.gearTransferConfirm.enabled,
    "confirmed import refreshes Gear Plans once and disables duplicate apply")
ok(N.db.gearNeeds[key]==refs.original and
    N.db.roleAssignments==refs.roles and
    N.db.localWishlists.Owner.MOLTEN_CORE==refs.wishlist and
    N.db.lootAwardHistory==refs.awards and
    N.db.lotteryHistory==refs.lotteries,
    "import confirmation leaves all original records and history untouched")
UI.gearTransferDialog:Hide()
UI:ShowGearPlanTransfer()
ok(UI.gearTransferDialog.visible and
    UI.gearTransferTextBox.text:find("Eiga",1,true),
    "reopened export shows newly imported bot plan")
ok(not UI.gearTransferConfirm.enabled,
    "reopen always clears any prior confirmation")
-- Paged backup UI after a real-sized 604-plan import. All of these
-- changes are limited to the synthetic test database; no live WoW data.
N.Data.MoltenCore.GetItem=function(_,id)
    if id==19147 or (id>=200001 and id<=200602) then
        return {name="Synthetic test item"}
    end
end
for i=1,602 do
    local itemID=200000+i
    local key=G:MakeKey("Meshana","MOLTEN_CORE",itemID,"BOT_GEAR_PLAN")
    N.db.gearNeeds[key]={
        key=key,character="Meshana",itemID=itemID,
        raidKey="MOLTEN_CORE",role="CASTER_DPS",status="NEEDED",
        source="BOT_GEAR_PLAN",characterType="PLAYERBOT",raid="Molten Core"
    }
end
ok(G:GetCount()==604,"604 test entries for export-page UI")
local refPlans=N.db.gearNeeds
local refExisting=N.db.gearNeeds[key]
UI:ShowGearPlanTransfer()
ok(UI.gearTransferExportPageLabel.text:find("Page 1/3",1,true),
    "opening transfer displays page 1 of 3 for 604 plans")
ok(UI.gearTransferExportNext.enabled and
    not UI.gearTransferExportPrev.enabled,
    "page 1 next enabled and previous disabled")
local firstPage=UI.gearTransferTextBox.text
local firstRows,firstParse=N.GearPlanTransfer:Parse(firstPage)
ok(firstRows and #firstRows==250,tostring(firstParse))
UI.gearTransferExportNext.events.OnClick()
ok(UI.gearTransferExportPageLabel.text:find("Page 2/3",1,true),
    "Next Export selects page 2")
ok(UI.gearTransferExportNext.enabled and
    UI.gearTransferExportPrev.enabled,
    "page 2 allows both directions")
local secondRows=N.GearPlanTransfer:Parse(UI.gearTransferTextBox.text)
ok(secondRows and #secondRows==250,
    "page 2 contains 250 valid independent records")
ok(UI.gearTransferTextBox.highlighted and UI.gearTransferTextBox.focused,
    "every new page automatically selects text for Ctrl+C")
UI.gearTransferExportNext.events.OnClick()
ok(UI.gearTransferExportPageLabel.text:find("Page 3/3",1,true),
    "Next Export selects last page")
ok(not UI.gearTransferExportNext.enabled and
    UI.gearTransferExportPrev.enabled,
    "last page disables Next but allows Previous")
local lastRows=N.GearPlanTransfer:Parse(UI.gearTransferTextBox.text)
ok(lastRows and #lastRows==104,
    "page 3 is complete independent 104-row import file")
ok(UI.gearTransferStatus.text:find("104",1,true),
    "status explains last-page count and Ctrl+C")
UI.gearTransferExportPrev.events.OnClick()
ok(UI.gearTransferExportPageLabel.text:find("Page 2/3",1,true),
    "Previous Export navigates backwards")
ok(N.db.gearNeeds==refPlans and
    N.db.gearNeeds[key]==refExisting and N.db.roleAssignments==refs.roles and
    N.db.localWishlists.Owner.MOLTEN_CORE==refs.wishlist and
    N.db.lootAwardHistory==refs.awards,
    "navigation never mutates existing plans/roles/wishlists/history")
UI.gearTransferImport.events.OnClick()
ok(not UI.gearTransferExportPrev.enabled and
    not UI.gearTransferExportNext.enabled and
    UI.gearTransferTextBox.text=="" and
    not UI.gearTransferConfirm.enabled,
    "switching to import clears exported content and disables export pages")
UI.gearTransferExport.events.OnClick()
ok(UI.gearTransferExportPageLabel.text:find("Page 1/3",1,true) and
    UI.gearTransferTextBox.text==firstPage,
    "Export Bot Plans restarts a deterministic export on page 1")
local sample=G:MakeKey("Meshana","MOLTEN_CORE",200001,"BOT_GEAR_PLAN")
N.db.gearNeeds[sample].status="GREED"
UI.gearTransferExportNext.events.OnClick()
ok(not UI.gearTransferExportNext.enabled and
    not UI.gearTransferExportPrev.enabled and
    UI.gearTransferStatus.text:find("changed during export",1,true),
    "active export navigation blocks stale backups if SavedVariables change")
ok(UI.gearTransferTextBox.text=="",
    "stale page data cleared rather than copied as mixed backup")
UI.gearTransferExport.events.OnClick()
ok(UI.gearTransferExportNext.enabled and
    UI.gearTransferExportPageLabel.text:find("Page 1/3",1,true),
    "fresh export recovers after snapshot changes")
N.db.gearNeeds[sample].status="NEEDED"
print("PASS: "..checks.." transfer UI, 604-plan paging, snapshot safety and import isolation assertions")
