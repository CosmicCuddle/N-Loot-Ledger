-- Integrated UI wiring smoke-check (Lua 5.1, NO real item award).
local checks=0
local function ok(test,msg)assert(test,msg);checks=checks+1 end
local function frame()
    local o={shown=false,enabled=true,events={}}
    function o:SetPoint(...)self.point={...}end
    function o:SetWidth(v)self.width=v end
    function o:SetHeight(v)self.height=v end
    function o:SetSize(w,h)self.width=w;self.height=h end
    function o:SetText(v)self.text=v end
    function o:SetJustifyH(...)end
    function o:SetFrameStrata(...)end
    function o:SetFrameLevel(...)end
    function o:GetFrameLevel()return 1 end
    function o:EnableMouse(...)end
    function o:SetBackdrop(...)end
    function o:SetBackdropColor(...)end
    function o:SetBackdropBorderColor(...)end
    function o:SetScript(k,fn)self.events[k]=fn end
    function o:CreateFontString()return frame()end
    function o:Show()self.shown=true end
    function o:Hide()self.shown=false end
    function o:Enable()self.enabled=true end
    function o:Disable()self.enabled=false end
    return o
end
CreateFrame=frame
local calls={review=0,arm=0,commit=0,cancel=0}
local itemRows={}
for i=1,8 do
    itemRows[i]={itemID=17000+i,slotIndex=i,quantity=1,
        itemLink="|Hitem:"..(17000+i)..":0|h[Item "..i.."]|h",
        itemName="Item "..i,leader="Leader",
        status=(i==2 and "RESERVED" or "GUILD_REVIEW"),
        reason=(i==2 and "Existing NEED" or "No accepted wishes")}
end
local previewLive=true
NaxxLootLottery={
    UI={mainFrame=frame()},
    Print=function()end,
    GuildLootReview={Scan=function()
        if not previewLive then
            return {},"CORPSE CLOSED: no live preview"
        end
        return itemRows,"Review-only item list"
    end},
    GuildLootTransfer={
        review=nil,
        IsEnabled=function()return true end,
        Cancel=function(self)
            calls.cancel=calls.cancel+1
            self.review=nil
        end,
        Review=function(self,target)
            calls.review=calls.review+1
            self.review={target=target,context={leader="Leader"}}
            return true,"Reviewed exact item "..target.itemID
        end,
        Arm=function(self)
            calls.arm=calls.arm+1
            if not self.review then return false,"No review" end
            self.review.armedAt=100
            return true,"Armed, no GiveMasterLoot"
        end,
        Commit=function(self)
            calls.commit=calls.commit+1
            if not self.review or not self.review.armedAt then
                return false,"Not armed"
            end
            self.review=nil
            return true,"Test call complete (fixture only)"
        end,
    },
}
local UI=NaxxLootLottery.UI
function UI:CreateTextButton(_,label,width)
    local o=frame()
    o.label=frame()
    o.label:SetText(label)
    o.width=width
    return o
end
function UI:RegisterSkinnedFrame()end
assert(loadfile("NaxxLootLottery/UI/CurrentLootFrame.lua"))()
UI:OpenGuildLootReview()
ok(UI.guildLootDialog.shown and calls.cancel==1,
    "opening guild review clears old armed state without awarding")
ok(UI.guildLootPageText.text=="Page 1/2",
    "eight actual item slots require pagination")
ok(UI.guildLootArm.enabled==false and UI.guildLootConfirm.enabled==false,
    "no Arm/Confirm actions until a reviewed item is selected")
ok(UI.guildLootRows[2].reviewButton.enabled==false,
    "reserved gear cannot invoke Review")
ok(UI.guildLootRows[1].reviewButton.width==90 and
    UI.guildLootRows[1].nameText.width==540,
    "review control reserves room in each loot row")
local target=UI.guildLootRows[1].reviewButton.target
ok(target.itemID==17001 and target.slotIndex==1,
    "per-row review target uses exact actual WoW item index")
UI.guildLootRows[1].reviewButton.events.OnClick(
    UI.guildLootRows[1].reviewButton)
ok(calls.review==1 and UI.guildLootArm.enabled==true and
    UI.guildLootConfirm.enabled==false,
    "Review alone enables Arm, not Give Item")
ok(calls.commit==0,"no transfer action on opening, browsing, or Review")
UI.guildLootArm.events.OnClick()
ok(calls.arm==1 and calls.commit==0 and
    UI.guildLootArm.enabled==false and UI.guildLootConfirm.enabled==true,
    "only explicit Arm unlocks the separately clicked Confirm")
UI.guildLootConfirm.events.OnClick()
ok(calls.commit==1 and UI.guildLootConfirm.enabled==false,
    "Confirm button performs exactly one deliberate commit call")
UI.guildLootNext.events.OnClick()
ok(UI.guildLootPageText.text=="Page 2/2" and
    UI.guildLootRows[1].reviewButton.target.itemID==17007,
    "pagination updates the exact selected recipient target")
UI.guildLootRows[1].reviewButton.events.OnClick(
    UI.guildLootRows[1].reviewButton)
ok(calls.review==2 and calls.commit==1,
    "pagination and reviewing another item does not silently transfer")
previewLive=false
NaxxLootLottery.GuildLootTransfer:Cancel()
UI:RefreshGuildLootDialog()
ok(UI.guildLootStatus.text:find("CORPSE CLOSED",1,true) and
    not UI.guildLootRows[1].shown and
    UI.guildLootArm.enabled==false and UI.guildLootConfirm.enabled==false,
    "corpse closure immediately hides all controls and stale targets")
UI.guildLootDialog:Hide()
ok(calls.commit==1,"no award action on corpse close or window hide")
print("PASS: "..checks.." guild transfer UI select/arm/confirm/paging assertions")
