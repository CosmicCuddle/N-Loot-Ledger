-- Routing preview UI never includes an award/confirm action.
local checks=0
local function ok(v,m)assert(v,m);checks=checks+1 end
local requested=0
GiveMasterLoot=function()requested=requested+1 end
local function frame()
    local a={enabled=true,shown=false,events={}}
    function a:SetPoint(...)end
    function a:SetSize(w,h)self.width=w;self.height=h end
    function a:SetWidth(w)self.width=w end
    function a:SetHeight(h)self.height=h end
    function a:SetText(t)self.text=t end
    function a:SetJustifyH(...)end
    function a:SetFrameStrata(...)end
    function a:SetFrameLevel(...)end
    function a:GetFrameLevel()return 1 end
    function a:EnableMouse(...)end
    function a:SetBackdrop(...)end
    function a:SetBackdropColor(...)end
    function a:SetBackdropBorderColor(...)end
    function a:CreateFontString()return frame()end
    function a:SetScript(k,f)self.events[k]=f end
    function a:Show()self.shown=true end
    function a:Hide()self.shown=false end
    function a:Enable()self.enabled=true end
    function a:Disable()self.enabled=false end
    return a
end
CreateFrame=frame
local isOpen=true
local plan={items={},proposed=2,held=6,dryRun=true,realTransfers=0,
    notice="Dry run: 2 proposed, 6 held; ZERO items transferred"}
for i=1,8 do
    plan.items[i]={itemID=17000+i,itemName="Fixture "..i,
        slotIndex=i,quantity=1,decision=i==1 and "PROPOSED_ONLY" or "HOLD_RESERVED",
        reason="No automatic action",intendedRecipient="Leader"}
end
NaxxLootLottery={
    UI={mainFrame=frame()},
    GuildAutoPreview={Plan=function()
        if not isOpen then return {items={},proposed=0,held=0,dryRun=true,
            realTransfers=0,notice="CORPSE CLOSED: zero live slots"} end
        return plan
    end}
}
local UI=NaxxLootLottery.UI
function UI:RegisterSkinnedFrame()end
function UI:CreateTextButton(_,label,width)
    local f=frame()
    f.label=frame()
    f.label:SetText(label)
    f.width=width
    return f
end
assert(loadfile("NaxxLootLottery/UI/GuildAutoPreviewFrame.lua"))()
UI:OpenGuildAutoPreview()
ok(UI.guildAutoPreviewFrame.shown and
    UI.guildAutoPreviewPageText.text=="Page 1 / 2",
    "preview opens read-only and paginates all eight item slots")
ok(UI.guildAutoPreviewStatus.text:find("ZERO items",1,true) and
    UI.guildAutoPreviewStatus.text:find("No automatic awards",1,true),
    "clear warning that no items have moved")
ok(UI.guildAutoPreviewRows[1].nameText.text:find("PROPOSED_ONLY",1,true),
    "eligible material shows as suggested only")
ok(UI.guildAutoPreviewLastPlan.dryRun==true and
    UI.guildAutoPreviewLastPlan.realTransfers==0,
    "read-only status preserved")
UI.guildAutoPreviewNext.events.OnClick()
ok(UI.guildAutoPreviewPageText.text=="Page 2 / 2" and
    UI.guildAutoPreviewRows[1].nameText.text:find("Slot 7",1,true),
    "second preview page displays next item; never invokes GiveMasterLoot")
UI.guildAutoPreviewPrevious.events.OnClick()
ok(UI.guildAutoPreviewPageText.text=="Page 1 / 2",
    "previous page resets view safely")
isOpen=false
UI:RefreshGuildAutoPreview()
ok(UI.guildAutoPreviewStatus.text:find("CORPSE CLOSED",1,true) and
    not UI.guildAutoPreviewRows[1].shown,
    "closed corpse immediately hides any old suggested item")
UI.guildAutoPreviewClose.events.OnClick()
ok(not UI.guildAutoPreviewFrame.shown,
    "close preview changes UI only")
ok(requested==0,"no physical award API call from preview")
print("PASS: "..checks.." automatic guild routing read-only UI/pagination assertions")
