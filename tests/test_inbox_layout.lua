-- WoW 3.3.5a / Lua 5.1 non-destructive Inbox pagination and layout check.
-- Render 4 review rows so the footer does not overlap a fifth row.
local checks=0
local function check(test,message) assert(test,message); checks=checks+1 end
local function frame()
    local f={}
    function f:SetPoint(...) self.points=self.points or {}; self.points[#self.points+1]={...} end
    function f:SetWidth(v) self.width=v end
    function f:SetHeight(v) self.height=v end
    function f:SetJustifyH(v) self.align=v end
    function f:SetText(v) self.text=v end
    function f:SetScript(key,fn)
        self.events=self.events or {}
        self.events[key]=fn
    end
    function f:CreateFontString() return frame() end
    function f:Show() self.visible=true end
    function f:Hide() self.visible=false end
    function f:Enable() self.enabled=true end
    function f:Disable() self.enabled=false end
    return f
end
CreateFrame=function()return frame() end
local selected={
    key="pikeotter",
    player="Pikeotter",
    raidKey="MOLTEN_CORE",
    itemIDs={18814,17076,17104,18821,16800,16801,16802},
    excluded={},
    status="PENDING",
    receivedAt="2026-10-13"
}
local originalItems=selected.itemIDs
local originalExcluded=selected.excluded
local mutations=0
GetTime=function()return 100 end
local archives,restores=0,0
local submissions={selected}
for i=2,6 do
    submissions[#submissions+1]={
        key="sub"..i,player="Other"..i,raidKey="MOLTEN_CORE",
        receivedAt="2026-10-18",itemIDs={16800},
        excluded={},status=i%2==0 and "ACCEPTED" or "REJECTED"
    }
end
NaxxLootLottery={
    UI={},
    GetRoleLabel=function()return "Melee DPS" end,
    Communication={
        GetInboxSubmissions=function(_,archiveMode)
            local out={}
            for _,item in ipairs(submissions) do
                if (item.archived==true)==(archiveMode==true) then
                    out[#out+1]=item
                end
            end
            return out
        end,
        IsSelfRaidLeader=function() return true end,
        GetSubmission=function(_,key)
            for _,item in ipairs(submissions) do
                if item.key==key then return item end
            end
        end,
        ArchiveSubmission=function(_,key)
            for _,item in ipairs(submissions) do
                if item.key==key then item.archived=true; archives=archives+1
                    return true,"Archived" end
            end
        end,
        RestoreArchivedSubmission=function(_,key)
            for _,item in ipairs(submissions) do
                if item.key==key then item.archived=nil; restores=restores+1
                    return true,"Restored" end
            end
        end,
        GetConflictCount=function()return 0 end,
        ToggleExcludedItem=function()mutations=mutations+1 end,
        AcceptSubmission=function()mutations=mutations+1 end,
        RejectSubmission=function()mutations=mutations+1 end
    },
    Database={GetRoleAssignment=function()return "MELEE_DPS" end},
    GearNeeds={HasOtherSourceNeed=function()return false end},
    Data={MoltenCore={GetItem=function(_,id)return {name="Item "..tostring(id)} end}}
}
local UI=NaxxLootLottery.UI
function UI:RegisterSkinnedFrame() end
function UI:CreateTextButton(_,label,width)
    local f=frame()
    f.label=frame()
    f.label:SetText(label)
    f.width=width
    return f
end
assert(loadfile("NaxxLootLottery/UI/WishlistFrame.lua"))()
UI:CreateInboxContent(frame())
UI.selectedSubmissionKey=selected.key
UI:RefreshInbox()
check(UI.inboxTotalPages==2 and
    UI.inboxTopPageLabel.text=="1/2" and
    UI.inboxOlder.enabled and not UI.inboxNewer.enabled,
    "six stored submissions have independent two-page Inbox list")
UI.inboxOlder.events.OnClick()
check(UI.inboxPage==2 and UI.inboxRows[1].review.submissionKey=="sub5" and
    UI.inboxRows[2].review.submissionKey=="sub6",
    "second Inbox page shows fifth/sixth saved submissions")
UI.inboxNewer.events.OnClick()
check(UI.inboxPage==1,"Newer returns to first Inbox submissions")
check(#UI.inboxItemRows==4,"only four review rows are created")
check(UI.inboxItemTotalPages==2,"seven items require two pages")
check(UI.inboxItemPage==1,"first page selected")
check(UI.inboxItemPageText.text=="Page 1 / 2","page counter correct")
check(UI.inboxPreviousItem.label.text=="Previous" and
    UI.inboxNextItem.label.text=="Next","short footer labels")
check(UI.inboxPreviousItem.width>=100 and UI.inboxNextItem.width>=72,
    "footer button widths expanded for long font")
check(UI.inboxItemPageText.width>=100,"page indicator has reserved width")
check(UI.inboxItemRows[4].toggle.itemID==18821 and
    UI.inboxItemRows[4].visible,"fourth item is on first page")
check(UI.inboxPreviousItem.enabled==false and
    UI.inboxNextItem.enabled==true,"first-page navigation state")
check(UI.inboxAcceptButton.enabled and UI.inboxRejectButton.enabled,
    "actual action controls remain enabled for normal submissions")
UI.inboxNextItem.events.OnClick()
check(UI.inboxItemPage==2 and UI.inboxItemPageText.text=="Page 2 / 2",
    "Next shows second page")
check(UI.inboxItemRows[1].toggle.itemID==16800 and
    UI.inboxItemRows[3].toggle.itemID==16802,
    "remaining three items are on second page")
check(UI.inboxItemRows[4].visible==false,"fourth second-page row hidden")
check(UI.inboxNextItem.enabled==false and UI.inboxPreviousItem.enabled==true,
    "last-page navigation state")
UI.inboxPreviousItem.events.OnClick()
check(UI.inboxItemPage==1,"Previous returns to first page")
check(#selected.itemIDs==7 and selected.itemIDs==originalItems,
    "no submission item was added, removed or replaced")
check(selected.excluded==originalExcluded and mutations==0,
    "no per-item reject, Accept, or Reject action occurred")
check(UI.inboxArchiveButton.visible,
    "selected entry exposes reversible Archive control")
UI.inboxArchiveButton.events.OnClick()
check(UI.inboxArchiveArmed and not selected.archived,
    "first click only ARMS archive and never hides a submission")
UI.inboxArchiveButton.events.OnClick()
check(selected.archived and archives==1 and
    UI.inboxPage==1 and UI.inboxTotalPages==2,
    "second click only archives locally without mutating item list")
UI.inboxArchivedToggle.events.OnClick()
check(UI.inboxShowArchived and UI.inboxRows[1].review.submissionKey=="pikeotter",
    "Archived view can find old submission")
UI.inboxRows[1].review.events.OnClick(UI.inboxRows[1].review)
UI.inboxArchiveButton.events.OnClick()
check(restores==1 and not selected.archived and
    UI.inboxShowArchived and UI.inboxTotalPages==1,
    "Restore returns entire original submission from archive")
UI.inboxArchivedToggle.events.OnClick()
check(not UI.inboxShowArchived and #selected.itemIDs==7 and
    selected.itemIDs==originalItems and selected.excluded==originalExcluded,
    "active inbox restored and item reservations unchanged")
print("PASS: "..checks.." Inbox footer/pagination and non-destructive assertions")
