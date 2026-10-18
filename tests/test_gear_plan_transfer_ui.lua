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
-- Scale the same owned fixture to the real roster size without touching
-- saved history/roles. Export must move among read-only V1 batches.
N.Data.MoltenCore.GetItem=function(_,id)
    if id==19147 or (id>=10001 and id<=10602) then
        return {itemID=id}
    end
end
for i=1,602 do
    local idx=math.floor((i-1)/16)
    local bot="Bot"..string.char(65+math.floor(idx/26))..
        string.char(65+(idx%26))
    local id=10000+i
    local k=N.GearNeeds:MakeKey(bot,"MOLTEN_CORE",id,"BOT_GEAR_PLAN")
    N.db.gearNeeds[k]={key=k,character=bot,
        itemID=id,raidKey="MOLTEN_CORE",role="CASTER_DPS",
        status=i<=467 and "NEEDED" or "GREED",
        source="BOT_GEAR_PLAN",characterType="PLAYERBOT"}
end
ok(N.GearNeeds:GetCount()==604,"test UI now has 604 bot Gear Plans")
UI:ShowGearPlanTransfer()
ok(UI.gearTransferBatchLabel.text:find("Batch 1/3",1,true) and
    UI.gearTransferTextBox.text:find("NLL-GEARPLANS-1",1,true) and
    not UI.gearTransferPrevBatch.enabled and UI.gearTransferNextBatch.enabled,
    "604 plans open in page 1/3 with Next enabled")
local page1=UI.gearTransferTextBox.text
UI.gearTransferNextBatch.events.OnClick()
ok(UI.gearTransferBatchLabel.text:find("Batch 2/3",1,true) and
    UI.gearTransferPrevBatch.enabled and UI.gearTransferNextBatch.enabled,
    "second 250-row export section is independently selectable")
local page2=UI.gearTransferTextBox.text
ok(page2~=page1 and N.GearPlanTransfer:Parse(page2),
    "export page 2 differs but remains valid V1 text")
UI.gearTransferNextBatch.events.OnClick()
local page3=UI.gearTransferTextBox.text
ok(UI.gearTransferBatchLabel.text:find("Batch 3/3",1,true) and
    UI.gearTransferPrevBatch.enabled and not UI.gearTransferNextBatch.enabled and
    N.GearPlanTransfer:Parse(page3),
    "final 104-row batch is exportable without losing other rows")
UI.gearTransferNextBatch.events.OnClick()
ok(UI.gearTransferTextBox.text==page3,
    "forced Next click at last batch cannot leak outside bounds")
UI.gearTransferPrevBatch.events.OnClick()
ok(UI.gearTransferTextBox.text==page2 and
    UI.gearTransferBatchLabel.text:find("Batch 2/3",1,true),
    "Prev returns the exact same page without changing data")
ok(UI.gearTransferConfirm.enabled==false and
   UI.gearTransferPreview.enabled==false and refresh==1,
   "paging exports never enables import confirmation or edits saved plans")
UI.gearTransferImport.events.OnClick()
ok(not UI.gearTransferPrevBatch.enabled and
   not UI.gearTransferNextBatch.enabled and
   UI.gearTransferTextBox.text=="" and
   UI.gearTransferBatchLabel.text:find("Import mode",1,true),
   "switch to import disables paging and starts with an empty paste")
UI.gearTransferPrevBatch.events.OnClick()
UI.gearTransferNextBatch.events.OnClick()
ok(UI.gearTransferTextBox.text=="" and
   not UI.gearTransferConfirm.enabled,
   "forced disabled export-page clicks cannot change import text or arm Add")
UI.gearTransferExport.events.OnClick()
ok(UI.gearTransferTextBox.text==page1 and
   UI.gearTransferBatchLabel.text:find("Batch 1/3",1,true),
   "explicit Export restores first batch without mutating records")
ok(N.db.gearNeeds==refs.gear and N.db.gearNeeds[key]==refs.original and
    N.db.roleAssignments==refs.roles and
    N.db.localWishlists.Owner.MOLTEN_CORE==refs.wishlist and
    N.db.lootAwardHistory==refs.awards and
    N.db.lotteryHistory==refs.lotteries,
    "604-row UI batch navigation preserves original saved-table identities")
print("PASS: "..checks.." transfer UI export, paste, preview/confirm assertions")
