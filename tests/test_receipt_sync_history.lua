-- Leader Award History separates physical award from PLAYER ACK.
local n=0
local function ok(v,msg)assert(v,msg);n=n+1 end
local function frame()
    local f={events={},shown=false}
    function f:SetAllPoints(...)end
    function f:SetPoint(...)end
    function f:SetWidth(...)end
    function f:SetHeight(...)end
    function f:SetJustifyH(...)end
    function f:SetText(t)self.text=t end
    function f:GetText()return self.text end
    function f:SetScript(k,v)self.events[k]=v end
    function f:CreateFontString(...)return frame()end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    return f
end
CreateFrame=frame
local loot={dropUID="L2:3:16800",itemID=16800,
    itemName="Arcanist Boots",winner="Pikeotter",
    selectionType="GREED",status="LEADER_REPORTED",
    when="2026-10-17",note="Leader checked physical award"}
local receipt={status="OBTAINED",remoteSyncStatus="AWAITING_PLAYER"}
NaxxLootLottery={
    db={lootAwardHistory={loot}},
    LootReceiptTracker={Get=function(_,uid)
        if uid==loot.dropUID then return receipt end
    end},
    UI={},
}
local UI=NaxxLootLottery.UI
function UI:RegisterSkinnedFrame()end
function UI:CreateTextButton()
    local btn=frame()
    btn.label=frame()
    return btn
end
assert(loadfile("NaxxLootLottery/UI/AwardHistoryFrame.lua"))()
UI:CreateAwardHistoryContent(frame())
ok(UI.awardHistoryRows[1].state.text=="Obtained (ACK pending)",
    "leader confirmed physical receipt while player sync still pending")
ok(UI.awardHistoryRows[1].winner.text=="Pikeotter",
    "leader-facing recipient identity retained")
UI.awardHistoryRows[1].details.events.OnClick()
ok(UI.awardHistoryDetail.text:find("Player%-side receipt: AWAITING_PLAYER"),
    "Award History info distinguishes physical confirmation and remote client pending")
receipt.remoteSyncStatus="ACKNOWLEDGED"
UI:RefreshAwardHistory()
ok(UI.awardHistoryRows[1].state.text=="Obtained + player ACK",
    "leader sees separate acknowledgement when player's client confirms")
UI.awardHistoryRows[1].details.events.OnClick()
ok(UI.awardHistoryDetail.text:find("ACKNOWLEDGED",1,true),
    "exact player ACK stage included in details")
receipt.remoteSyncStatus=nil
UI:RefreshAwardHistory()
ok(UI.awardHistoryRows[1].state.text=="OBTAINED",
    "nonremote or older same-account receipt remains obtained")
receipt.status="WON_AWAITING_ITEM"
UI:RefreshAwardHistory()
ok(UI.awardHistoryRows[1].state.text=="Leader reported",
    "mere roll without verified receipt cannot display obtained")
print("PASS: "..n.." separate leader / player receipt ACK history assertions")
