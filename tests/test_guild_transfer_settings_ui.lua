-- Verify Guild Transfers opt-in NEVER turns on Direct Master Loot (Lua 5.1).
local n=0
local function ok(v,why)assert(v,why);n=n+1 end
local function frame()
    local a={enabled=true,events={}}
    function a:SetAllPoints(...)end
    function a:SetPoint(...)end
    function a:SetWidth(v)self.width=v end
    function a:SetJustifyH(...)end
    function a:SetText(v)self.text=v end
    function a:SetScript(k,fn)self.events[k]=fn end
    function a:CreateFontString()return frame()end
    function a:Disable()self.enabled=false end
    function a:Enable()self.enabled=true end
    return a
end
CreateFrame=frame
local fake=false
local notices={}
local settings={directMasterLootEnabled=false,guildLootTransfersEnabled=false,
    winnerQuickAwardEnabled=false}
NaxxLootLottery={
    db={settings=settings},
    Print=function(_,msg)notices[#notices+1]=msg end,
    DebugSimulator={IsActive=function()return fake end},
    UI={},
    AwardWorkflow={
        IsDirectEnabled=function()return settings.directMasterLootEnabled end,
        SetDirectEnabled=function(_,v)
            if fake then return false end
            settings.directMasterLootEnabled=v==true
            if not v then settings.winnerQuickAwardEnabled=false end
            return true
        end,
        IsQuickEnabled=function()
            return settings.directMasterLootEnabled and
                settings.winnerQuickAwardEnabled
        end,
        SetQuickEnabled=function(_,v)
            if fake or (v and not settings.directMasterLootEnabled) then
                return false,'Direct award required'
            end
            settings.winnerQuickAwardEnabled=v==true
            return true
        end
    },
    GuildLootTransfer={
        SetEnabled=function(_,v)
            if fake then return false end
            settings.guildLootTransfersEnabled=v==true
            return true
        end
    }
}
local UI=NaxxLootLottery.UI
function UI:CreateTextButton(_,label,width)
    local a=frame()
    a.label=frame()
    a.label:SetText(label)
    a.width=width
    return a
end
assert(loadfile("NaxxLootLottery/UI/AwardSettingsFrame.lua"))()
UI:CreateAwardSettingsContent(frame())
UI:RefreshAwardSettingsContent()
ok(UI.awardSettingsGuildStatus.text:find("OFF",1,true) and
    UI.awardSettingsStatus.text:find("OFF",1,true),
    "both dangerous transfer switches initially OFF")
ok(UI.awardSettingsGuildToggle.enabled and
    UI.awardSettingsToggle.enabled and
    not UI.awardSettingsQuickToggle.enabled,
    "quick awards OFF and disabled until independent Direct consent")
local guildToggle=UI.awardSettingsGuildToggle
guildToggle.events.OnClick()
ok(settings.guildLootTransfersEnabled and not settings.directMasterLootEnabled,
    "guild switch never enables Direct Master Loot")
ok(UI.awardSettingsGuildStatus.text:find("ON",1,true) and
    UI.awardSettingsStatus.text:find("OFF",1,true),
    "UI clearly distinguishes guild opt-in from real-award opt-in")
UI.awardSettingsToggle.events.OnClick()
ok(settings.guildLootTransfersEnabled and settings.directMasterLootEnabled and
    not settings.winnerQuickAwardEnabled and
    UI.awardSettingsQuickToggle.enabled,
    "ordinary Direct Master Loot does not enable one-click awarding")
UI.awardSettingsQuickToggle.events.OnClick()
ok(settings.winnerQuickAwardEnabled and
    UI.awardSettingsQuickToggle.label.text=="Disable 1-Click Award",
    "second distinct click enables optional one-click winner action")
UI.awardSettingsToggle.events.OnClick()
ok(not settings.directMasterLootEnabled and
    not settings.winnerQuickAwardEnabled and
    not UI.awardSettingsQuickToggle.enabled,
    "turning Direct OFF revokes one-click authorization")
UI.awardSettingsToggle.events.OnClick()
ok(settings.directMasterLootEnabled and
    not settings.winnerQuickAwardEnabled,
    "re-enabling Direct never silently re-enables one-click")
guildToggle.events.OnClick()
ok(not settings.guildLootTransfersEnabled and settings.directMasterLootEnabled,
    "disabling guild routing doesn't change existing winner-award consent")
fake=true
UI:RefreshAwardSettingsContent()
ok(not guildToggle.enabled and not UI.awardSettingsToggle.enabled and
   not UI.awardSettingsQuickToggle.enabled,
   "all real award toggles disabled in fake debug raids")
fake=false
ok(#notices>=3 and not settings.guildLootTransfersEnabled,
    "status messages inform user without granting any loot")
print("PASS: "..n.." independent guild-vs-direct settings toggle assertions")
