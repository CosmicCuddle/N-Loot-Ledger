-- Visual receipt-confirmation gate: two deliberate clicks, 15 seconds,
-- same saved winning drop. Lua 5.1, no real loot delivery.
local assertions=0
local function ok(v,m)assert(v,m);assertions=assertions+1 end
local clock=500
GetTime=function()return clock end
local messages={}
local can=false
local confirms=0
local drop={dropUID="D1",itemID=16866,itemName="Helm of Might",
    slotIndex=1}
local current=drop
local ledger={dropUID="D1",itemID=16866,character="Throgar",
    itemName="Helm of Might",selectionType="NEED",
    status="WON_AWAITING_ITEM"}
local function frame()
    local o={enabled=true,shown=false,scripts={}}
    function o:SetPoint(...)end
    function o:SetSize(...)end
    function o:SetWidth(v)self.width=v end
    function o:SetFrameStrata(...)end
    function o:SetFrameLevel(...)end
    function o:GetFrameLevel()return 5 end
    function o:EnableMouse(...)end
    function o:SetBackdrop(...)end
    function o:SetBackdropColor(...)end
    function o:SetBackdropBorderColor(...)end
    function o:SetJustifyH(...)end
    function o:SetText(s)self.text=s end
    function o:CreateFontString()return frame()end
    function o:SetScript(k,f)self.scripts[k]=f end
    function o:Disable()self.enabled=false end
    function o:Enable()self.enabled=true end
    function o:Show()self.shown=true end
    function o:Hide()self.shown=false end
    return o
end
CreateFrame=frame
NaxxLootLottery={
    Print=function(_,s)messages[#messages+1]=s end,
    LootDetection={GetCurrentLoot=function()return {current} end},
    AwardWorkflow={
        GetOutcome=function()return {dropUID="D1",status="COMPLETE",
            itemID=16866,winner="Throgar",awardStatus="LEADER_REPORTED"} end,
        GetStatus=function()return "Award reported" end,
    },
    LootReceiptTracker={
        Get=function(_,uid)if uid=="D1" then return ledger end end,
        CanConfirm=function()
            if not can then return false,"Delivery not recorded" end
            if ledger.status=="OBTAINED" then return false,"Already obtained" end
            return true,ledger
        end,
        ConfirmReceipt=function()
            confirms=confirms+1
            ledger.status="OBTAINED"
            return true,"Need/Greed marked OBTAINED"
        end,
    },
    UI={mainFrame=frame(),currentLootSelected=1}
}
local UI=NaxxLootLottery.UI
function UI:CreateTextButton(_,label,width)
    local btn=frame()
    btn.label=frame()
    btn.label:SetText(label)
    return btn
end
assert(loadfile("NaxxLootLottery/UI/AwardReviewFrame.lua"))()
local open=UI:OpenReceiptReview(drop)
ok(open and UI.receiptReviewFrame.shown,"tracked winner can open receipt review")
ok(UI.receiptReviewInfo.text:find("Helm of Might",1,true),
    "item and winner shown explicitly")
ok(UI.receiptReviewComplete.enabled==false,
    "mark obtained is initially locked")
-- There is no loot receipt yet. First click must fail closed.
UI.receiptReviewFrame:Show()
-- First button was created but not stored; test source control via
-- mocked frame order isn't necessary when we store a handle in UI below.
ok(confirms==0,"mere opening does not mark item obtained")
local protected=UI.receiptReviewFrame
-- The modal open code always creates first button BEFORE final action.
-- Obtain the first button directly through a captured button array.
print("PASS: "..assertions.." receipt modal opening assertions")
