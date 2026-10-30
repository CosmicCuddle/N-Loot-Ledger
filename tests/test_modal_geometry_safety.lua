-- NLL Lua 5.1 geometry and exact-recipient modal safety regression.
-- Geometry uses actual SetPoint anchors and CreateTextButton dimensions.
-- These are deterministic frame bounds, NOT a substitute for WoW font testing.
local checks=0
local function ok(v,message) assert(v,message);checks=checks+1 end
local frames={}
local function make(parent)
    local f={parent=parent,w=0,h=0,shown=false,enabled=true,events={}}
    function f:SetPoint(point,ref,refPoint,dx,dy)
        self.anchor={point,ref or self.parent,refPoint or point,dx or 0,dy or 0}
    end
    function f:SetWidth(w)self.w=w end
    function f:SetHeight(h)self.h=h end
    function f:SetSize(w,h)self.w=w;self.h=h end
    function f:GetFrameLevel()return 1 end
    function f:SetFrameLevel(...)end
    function f:SetFrameStrata(...)end
    function f:EnableMouse(...)end
    function f:SetBackdrop(...)end
    function f:SetBackdropColor(...)end
    function f:SetBackdropBorderColor(...)end
    function f:SetJustifyH(...)end
    function f:SetText(v)self.text=v end
    function f:CreateFontString()return make(self)end
    function f:SetScript(event,cb)self.events[event]=cb end
    function f:Show()self.shown=true end
    function f:Hide()self.shown=false end
    function f:Enable()self.enabled=true end
    function f:Disable()self.enabled=false end
    frames[#frames+1]=f
    return f
end
CreateFrame=function(_,_,parent)return make(parent)end
local function offset(which,width,height)
    if which=="CENTER" then return width/2,height/2 end
    if which=="LEFT" then return 0,height/2 end
    if which=="RIGHT" then return width,height/2 end
    if which=="TOP" then return width/2,0 end
    if which=="BOTTOM" then return width/2,height end
    if which=="TOPLEFT" then return 0,0 end
    if which=="TOPRIGHT" then return width,0 end
    if which=="BOTTOMLEFT" then return 0,height end
    if which=="BOTTOMRIGHT" then return width,height end
    error("Unknown WoW anchor "..tostring(which))
end
local function box(f,stack)
    if not f then error("Missing anchored frame") end
    stack=stack or {}
    if stack[f] then error("Anchor loop") end
    stack[f]=true
    local x,y=0,0
    if f.anchor then
        local own,ref,relative,dx,dy=unpack(f.anchor)
        local rx,ry,rw,rh=box(ref,stack)
        local ax,ay=offset(relative,rw,rh)
        local bx,by=offset(own,f.w,f.h)
        x=rx+ax+dx-bx
        y=ry+ay-dy-by  -- WoW positive Y points upward.
    end
    stack[f]=nil
    return x,y,f.w,f.h
end
local function rangeX(f)
    local x,_,w=box(f)
    return x,x+w
end
local function rightGap(a,b)
    local _,ar=rangeX(a)
    local bl=rangeX(b)
    return bl-ar
end
local function bottomGap(a,b)
    local _,ay,_,ah=box(a)
    local _,by=box(b)
    return by-(ay+ah)
end
local function rowInside(dialog,row)
    local dx,dy,dw,dh=box(dialog)
    local rx,ry,rw,rh=box(row)
    return rx>=dx+10 and rx+rw<=dx+dw-10 and
        ry>=dy+10 and ry+rh<=dy+dh-10
end
local function footerInside(dialog,buttons)
    local dx,dy,dw,dh=box(dialog)
    for _,b in ipairs(buttons) do
        local x,y,w,h=box(b)
        ok(x>=dx+15 and x+w<=dx+dw-15 and
            y>=dy+15 and y+h<=dy+dh-15,
            "footer control must fit within modal inset")
    end
end
local actor="Officer"
local requested=0
UnitName=function()return actor end
GetTime=function()return 100 end
GetItemCount=function()return 4 end
GiveMasterLoot=function()requested=requested+1;error("NEVER GRANT")end
RandomRoll=function()requested=requested+1;error("NEVER ROLL")end
NaxxLootLottery={
    db={guildLootTransferAudit={{
        itemID=17010,itemLink="|Hitem:17010:0|h[Fiery Core]|h",
        quantity=2,slotIndex=1,recipient="Leader",
        status="LOOT_SLOT_CLEARED",
    }},guildRecipientReceiptAudit={}},
    DebugSimulator={IsActive=function()return false end},
    UI={mainFrame=make(nil)},
    Print=function()end,
}
local N=NaxxLootLottery
N.UI.mainFrame:SetSize(920,700)
local UI=N.UI
function UI:CreateTextButton(parent,label,width)
    local f=make(parent)
    f:SetSize(width,22)
    f.label=make(f)
    f.label:SetText(label)
    return f
end
function UI:RegisterSkinnedFrame()end
N.LootReconciliation={
    armed=nil,
    Cancel=function(self)self.armed=nil end,
    List=function()
        return {{kind="GUILD",id=1,itemID=17010,recipient="Leader",
                 status="LOOT_SLOT_CLEARED",reviewed=false}}
    end,
}
assert(loadfile("NaxxLootLottery/Core/GuildRecipientReceipt.lua"))()
assert(loadfile("NaxxLootLottery/UI/GuildRecipientReceiptFrame.lua"))()
assert(loadfile("NaxxLootLottery/UI/ReconciliationFrame.lua"))()
assert(loadfile("NaxxLootLottery/UI/CurrentLootFrame.lua"))()
-- Modal outer frame, inner rows and right-aligned per-row selection buttons.
UI:CreateGuildLootDialog()
local guild=UI.guildLootDialog
ok(box(guild)~=nil and #UI.guildLootRows==6,
   "guild loot has six rows and a frame")
for _,row in ipairs(UI.guildLootRows) do
    ok(rowInside(guild,row),"every guild loot row inside its modal")
end
ok(rightGap(UI.guildLootPrev,UI.guildLootNext)>=6,
   "guild Prev and Next never overlap")
ok(rightGap(UI.guildLootNext,UI.guildLootInvestigate)>=20,
   "guild investigate action is separated from the pager")
-- Resolve controls by their exported UI references, not a mutable
-- recipient-specific button caption (Guild Master vs Raid Leader).
local guildArm,guildGive,guildDry=
    UI.guildLootArm,UI.guildLootConfirm,UI.guildLootDryRun
ok(guildArm and guildGive and guildDry and
   guildArm.label.text=="Arm Transfer" and
   guildGive.label.text=="CONFIRM GIVE ITEM" and
   guildDry.label.text=="Dry Run: OFF",
   "all three labelled manual/dry-run controls found")
ok(rightGap(guildArm,guildGive)>=6 and
   rightGap(guildGive,guildDry)>=6,
   "guild dangerous and preview controls remain separate")
footerInside(guild,{guildArm,guildGive,guildDry,
    UI.guildLootPrev,UI.guildLootNext,UI.guildLootInvestigate})
ok(bottomGap(UI.guildLootRows[6],guildArm)>=6,
   "sixth loot row must have minimum 6px gutter to ARM button")
ok(bottomGap(guildArm,UI.guildLootPrev)>=6,
   "ARM row must not touch the navigation footer")
-- Independent NO RETRY modal with its extra My Bag Receipt button.
UI:CreateReconciliationDialog()
local rec=UI.reconciliationDialog
ok(#UI.reconciliationRows==5,"no-retry modal has five rows")
for _,row in ipairs(UI.reconciliationRows) do
    ok(rowInside(rec,row.panel),"reconciliation row fits")
end
ok(rightGap(UI.reconciliationArm,UI.reconciliationConfirm)>=6,
   "NO RETRY arm and confirm are not touching")
ok(rightGap(UI.reconciliationConfirm,UI.reconciliationBagReceipt)>=6,
   "My Bag Receipt separated from NO RETRY confirm")
ok(rightGap(UI.reconciliationBagReceipt,UI.reconciliationClose)>=6,
   "My Bag Receipt separated from close/cancel")
ok(rightGap(UI.reconciliationPrev,UI.reconciliationNext)>=6,
   "NO RETRY paging controls separated")
footerInside(rec,{UI.reconciliationArm,UI.reconciliationConfirm,
    UI.reconciliationBagReceipt,UI.reconciliationClose,
    UI.reconciliationPrev,UI.reconciliationNext})
ok(bottomGap(UI.reconciliationRows[5].panel,UI.reconciliationPrev)>=12,
   "last NO RETRY history row separated from footer")
-- Actual recipient-only modal geometry.
UI:CreateGuildRecipientReceiptDialog()
local bag=UI.guildRecipientReceiptDialog
ok(#UI.guildReceiptRows==5,"recipient bag modal has five rows")
for _,row in ipairs(UI.guildReceiptRows) do
    ok(rowInside(bag,row.frame),"bag row fits inside modal")
end
ok(rightGap(UI.guildReceiptArm,UI.guildReceiptConfirm)>=8,
   "first and second recipient action separated")
ok(rightGap(UI.guildReceiptConfirm,UI.guildReceiptClose)>=18,
   "final recipient confirmation away from close")
ok(rightGap(UI.guildReceiptPrev,UI.guildReceiptNext)>=6,
   "recipient paging buttons separated")
footerInside(bag,{UI.guildReceiptArm,UI.guildReceiptConfirm,
    UI.guildReceiptClose,UI.guildReceiptPrev,UI.guildReceiptNext})
ok(bottomGap(UI.guildReceiptRows[5].frame,UI.guildReceiptPrev)>=12,
   "last bag row separated from pager")
-- Wrong client must NOT be invited into someone else's bag assertion.
UI:OpenReconciliationDialog("GUILD",1)
ok(UI.reconciliationSelected and not UI.reconciliationBagReceipt.enabled,
   "wrong recipient: cross-modal My Bag Receipt disabled")
UI.reconciliationBagReceipt.events.OnClick()
ok(not UI.guildRecipientReceiptDialog.shown,
   "forced disabled click fails closed without opening other client's modal")
actor="Leader"
UI:RefreshReconciliationDialog()
ok(UI.reconciliationBagReceipt.enabled,
   "correct exact recipient may open separate bag review")
UI.reconciliationBagReceipt.events.OnClick()
ok(not rec.shown and bag.shown and UI.guildReceiptSelected==1,
   "proper recipient switches to exact-index bag review")
ok(not N.GuildRecipientReceipt.armed and
   not UI.guildReceiptConfirm.enabled,
   "opening does not ARM or attest")
ok(requested==0 and #N.db.guildRecipientReceiptAudit==0,
   "geometry, navigation and wrong-player checks have no physical side effects")
print("PASS: "..checks.." modal bounds/gutters and recipient action isolation")
