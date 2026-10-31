-- Independent WoW 3.3.5a Receipt Inbox frame fixture.
local checks=0
local function ok(v,msg)assert(v,msg);checks=checks+1 end
local clock=250
GetTime=function()return clock end
local accepted=0
local inspections=0
local messages={}
local pending={
    {key="leader:L1:1:16800",leader="Leader",dropUID="L1:1:16800",
        itemID=16800,status="AWAITING_PLAYER"},
    {key="leader:L1:2:18821",leader="Leader",dropUID="L1:2:18821",
        itemID=18821,status="AWAITING_PLAYER"},
}
local function frame()
    local x={enabled=true,shown=false,events={}}
    function x:SetSize(w,h)self.width=w;self.height=h end
    function x:SetPoint(...)self.point={...} end
    function x:SetFrameStrata(...)end
    function x:SetFrameLevel(...)end
    function x:GetFrameLevel()return 1 end
    function x:EnableMouse(...)end
    function x:SetBackdrop(...)end
    function x:SetBackdropColor(...)end
    function x:SetBackdropBorderColor(...)end
    function x:CreateFontString()return frame()end
    function x:SetWidth(w)self.width=w end
    function x:SetJustifyH(...)end
    function x:SetText(t)self.text=t end
    function x:SetScript(k,fn)self.events[k]=fn end
    function x:Enable()self.enabled=true end
    function x:Disable()self.enabled=false end
    function x:Show()self.shown=true end
    function x:Hide()self.shown=false end
    return x
end
CreateFrame=frame
NaxxLootLottery={
    UI={mainFrame=frame()},
    Print=function(_,msg)messages[#messages+1]=msg end,
    Data={MoltenCore={GetItem=function(_,id)
        return {name="Item "..id,itemID=id}
    end}},
    ReceiptSync={
        GetPendingForLocal=function()return pending end,
        CanAccept=function(_,key)
            inspections=inspections+1
            for _,row in ipairs(pending) do
                if row.key==key then return true,row end
            end
            return false,"Already handled"
        end,
        Accept=function(_,key)
            accepted=accepted+1
            for i,row in ipairs(pending) do
                if row.key==key then
                    table.remove(pending,i)
                    return true,"Local item is OBTAINED."
                end
            end
            return false,"Unknown receipt"
        end,
    },
}
local UI=NaxxLootLottery.UI
function UI:CreateTextButton(_,label,width)
    local b=frame()
    b.label=frame()
    b.label:SetText(label)
    b.width=width
    return b
end
assert(loadfile("NaxxLootLottery/UI/ReceiptSyncFrame.lua"))()
UI:OpenReceiptSyncReview()
ok(UI.receiptSyncFrame.shown,"receipt dialog opens separately from loot controls")
ok(UI.receiptSyncPageText.text=="Receipt 1 / 2",
    "two independent confirmed human awards are navigable")
ok(UI.receiptSyncConfirm.enabled==false and accepted==0,
    "opening is non-mutating and Confirm begins disabled")
ok(UI.receiptSyncDetail.text:find("Item 16800",1,true),
    "first pending item clearly displayed")
UI.receiptSyncConfirm.events.OnClick()
ok(accepted==0,"even callback bypass cannot confirm without inspection")
UI.receiptSyncVerify.events.OnClick()
ok(UI.receiptSyncConfirm.enabled==true and accepted==0,
    "first human click only arms second confirmation")
-- A stale/missing uptime must NEVER allow a receipt to be marked OBTAINED.
local goodClock=GetTime
local badClocks={
    {name="missing",fn=false},
    {name="nil",fn=function()return nil end},
    {name="negative",fn=function()return -1 end},
    {name="text",fn=function()return "250" end},
    {name="NaN",fn=function()return 0/0 end},
    {name="infinite",fn=function()return math.huge end},
}
for _,test in ipairs(badClocks) do
    GetTime=test.fn or nil
    UI.receiptSyncVerify.events.OnClick()
    ok(not UI.receiptSyncConfirm.enabled and
       UI.receiptSyncArmedAt==nil and accepted==0,
       "remote receipt cannot arm with "..test.name.." uptime")
end
GetTime=goodClock
UI.receiptSyncVerify.events.OnClick()
clock=clock-1
UI.receiptSyncConfirm.events.OnClick()
ok(not UI.receiptSyncConfirm.enabled and accepted==0,
   "backwards remote receipt confirmation clock must be rejected")
clock=clock+1
UI.receiptSyncVerify.events.OnClick()
GetTime=nil
UI.receiptSyncConfirm.events.OnClick()
ok(not UI.receiptSyncConfirm.enabled and accepted==0,
   "lost uptime between clicks cannot mark remote OBTAINED")
GetTime=goodClock
UI.receiptSyncVerify.events.OnClick()
local originalKey=UI.receiptSyncKey
UI.receiptSyncKey=pending[2].key
UI.receiptSyncConfirm.events.OnClick()
ok(accepted==0 and not UI.receiptSyncConfirm.enabled,
   "changed selected offer key cannot inherit another item's inspection")
UI.receiptSyncKey=originalKey
UI.receiptSyncVerify.events.OnClick()
pending[1].itemID=18821
UI.receiptSyncConfirm.events.OnClick()
ok(accepted==0 and not UI.receiptSyncConfirm.enabled,
   "changed item within same pending offer invalidates inventory inspection")
pending[1].itemID=16800
UI.receiptSyncVerify.events.OnClick()
UI.receiptSyncNext.events.OnClick()
ok(UI.receiptSyncPageText.text=="Receipt 2 / 2" and
    UI.receiptSyncConfirm.enabled==false,
    "switching pending item disarms previously inspected receipt")
UI.receiptSyncVerify.events.OnClick()
clock=clock+16
UI.receiptSyncConfirm.events.OnClick()
ok(accepted==0 and not UI.receiptSyncConfirm.enabled,
    "15-second expiry prevents silent obtained change")
UI.receiptSyncVerify.events.OnClick()
UI.receiptSyncConfirm.events.OnClick()
ok(accepted==1 and #pending==1 and
    UI.receiptSyncPageText.text=="Receipt 1 / 1",
    "one explicit second click confirms only selected receipt")
ok(UI.receiptSyncDetail.text:find("Item 16800",1,true),
    "after acceptance, next pending receipt remains available")
UI.receiptSyncVerify.events.OnClick()
UI.receiptSyncClose.events.OnClick()
ok(UI.receiptSyncArmedAt==nil and not UI.receiptSyncFrame.shown,
    "close clears armed state; no item marked from closing dialog")
UI:OpenReceiptSyncReview()
ok(UI.receiptSyncConfirm.enabled==false and accepted==1,
    "reopen requires another explicit inspection")
UI.receiptSyncVerify.events.OnClick()
UI.receiptSyncConfirm.events.OnClick()
ok(accepted==2 and #pending==0 and not UI.receiptSyncVerify.enabled,
    "each valid offer independently confirms then inbox empties")
ok(UI.receiptSyncPageText.text=="Receipt 0 / 0" and
    UI.receiptSyncWarning.text=="No changes to your wishlist.",
    "empty inbox clearly reports no further changes")
print("PASS: "..checks.." remote receipt inbox UI/pager/two-click/expiry assertions")
