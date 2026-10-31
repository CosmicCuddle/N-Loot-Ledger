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
UI.receiptReviewCheck.scripts.OnClick()
ok(not UI.receiptReviewComplete.enabled and
    UI.receiptReviewWarning.text:find("Delivery not recorded",1,true),
    "unreported receipt cannot be marked obtained")
can=true
-- The recipient's manual OBTAINED action is a SavedVariables write.
-- The first click cannot arm it when the uptime API is absent/invalid.
local goodClock=GetTime
local badClocks={
    {label="missing GetTime",reader=false},
    {label="nil uptime",reader=function()return nil end},
    {label="text uptime",reader=function()return "500" end},
    {label="negative uptime",reader=function()return -1 end},
    {label="NaN uptime",reader=function()return 0/0 end},
    {label="infinite uptime",reader=function()return math.huge end},
}
for _,case in ipairs(badClocks) do
    GetTime=case.reader or nil
    UI.receiptReviewCheck.scripts.OnClick()
    ok(not UI.receiptReviewComplete.enabled and
       UI.receiptReviewArmedAt==nil and confirms==0 and
       ledger.status=="WON_AWAITING_ITEM",
       "receipt cannot arm on "..case.label)
end
GetTime=goodClock
UI.receiptReviewCheck.scripts.OnClick()
ok(UI.receiptReviewComplete.enabled and confirms==0,
    "verification click enables separate second click but changes nothing")
clock=clock+16
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==0 and not UI.receiptReviewComplete.enabled,
    "confirmation expires after 15 seconds without changing wishlist")
-- Even with a previously armed human claim, backwards or missing time
-- must cancel rather than silently commit OBTAINED.
UI.receiptReviewCheck.scripts.OnClick()
clock=clock-1
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==0 and not UI.receiptReviewComplete.enabled and
   UI.receiptReviewArmedAt==nil and ledger.status=="WON_AWAITING_ITEM",
   "rolled-back receipt clock cancels the second click")
clock=clock+1
UI.receiptReviewCheck.scripts.OnClick()
GetTime=nil
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==0 and not UI.receiptReviewComplete.enabled and
   ledger.status=="WON_AWAITING_ITEM",
   "lost WoW clock between receipt clicks cannot mark OBTAINED")
GetTime=goodClock
UI.receiptReviewCheck.scripts.OnClick()
current={dropUID="DIFFERENT",itemID=18821}
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==0 and not UI.receiptReviewComplete.enabled and
   UI.receiptReviewArmedAt==nil,
    "selected loot changes after verification: no receipt")
current=drop
-- A receipt is a specific person's physical inventory assertion. An
-- edited or swapped ledger row with the SAME drop UID must require a
-- fresh review instead of inheriting the prior human confirmation.
UI.receiptReviewCheck.scripts.OnClick()
ok(UI.receiptReviewComplete.enabled,"original recipient can arm receipt")
ledger.character="WrongRealmRecipient"
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==0 and not UI.receiptReviewComplete.enabled and
   ledger.status=="WON_AWAITING_ITEM",
   "winner changed after inventory check: cannot mark another person OBTAINED")
ledger.character="Throgar"
UI.receiptReviewCheck.scripts.OnClick()
ledger.itemID=16800
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==0 and not UI.receiptReviewComplete.enabled,
   "item changed after inventory check: cannot mark another item OBTAINED")
ledger.itemID=16866
UI.receiptReviewCheck.scripts.OnClick()
local original=ledger
ledger={dropUID="D1",itemID=16866,character="Throgar",
    itemName="Helm of Might",selectionType="NEED",
    status="WON_AWAITING_ITEM"}
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==0 and not UI.receiptReviewComplete.enabled and
   ledger.status=="WON_AWAITING_ITEM",
   "replaced receipt ledger row cannot inherit stale inventory confirmation")
ledger=original
UI.receiptReviewCheck.scripts.OnClick()
ok(UI.receiptReviewComplete.enabled and confirms==0,
    "same original drop may be reviewed again")
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==1 and ledger.status=="OBTAINED" and
    not UI.receiptReviewFrame.shown,
    "only second deliberate click confirms recipient inventory")
UI:OpenReceiptReview(drop)
ok(not UI.receiptReviewComplete.enabled,
    "existing obtained receipt cannot be reconfirmed")
UI.receiptReviewCheck.scripts.OnClick()
ok(not UI.receiptReviewComplete.enabled and confirms==1,
    "idempotent modal refuses duplicate confirmation")
UI.receiptReviewCancel.scripts.OnClick()
ok(not UI.receiptReviewFrame.shown and
    UI.receiptReviewArmedAt==nil,"cancel disarms and hides modal")
-- Historical Award History entries remain reviewable after another corpse
-- replaces the Current Loot queue. Their UID is frozen at modal open.
ledger.status="WON_AWAITING_ITEM"
can=true
current={dropUID="D2",itemID=17010}
ok(UI:OpenReceiptReview("D1") and UI.receiptReviewHistorical,
    "Award History can open an immutable past winner after corpse despawn")
UI.receiptReviewCheck.scripts.OnClick()
ok(UI.receiptReviewComplete.enabled,
    "historical target is verified by drop UID, not live corpse index")
UI.receiptReviewComplete.scripts.OnClick()
ok(confirms==2 and ledger.status=="OBTAINED",
    "later historical receipt updates only its own stored winning drop")
print("PASS: "..assertions.." two-click receipt UI/expiry/history assertions")
