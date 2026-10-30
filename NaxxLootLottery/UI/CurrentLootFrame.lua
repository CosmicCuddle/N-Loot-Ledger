-- ============================================================
-- Naxxramas Loot Ledger
-- UI/CurrentLootFrame.lua
--
-- Phase 6/7 display:
-- detected supported loot + matching NEEDED characters.
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

local DROP_ROWS = 5
local MATCH_ROWS = 6

local function GetItemTexture(itemID)
    if GetItemIcon then
        local texture =
            GetItemIcon(itemID)

        if texture then
            return texture
        end
    end

    if GetItemInfo then
        local _, _, _, _, _, _, _, _, _, texture =
            GetItemInfo(itemID)

        if texture then
            return texture
        end
    end

    return
        "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- This is intentionally the same guarded two-step path as /nll newloot.
-- Never reset a winner directly, award loot or manufacture live loot.
-- Public function permits offline Lua 5.1 regression tests without WoW frames.
function UI:RequestNewDrop()
    local identity=NLL.LootIdentity
    local ok,message
    if self.currentLootNewDropPending then
        self.currentLootNewDropPending=false
        ok,message=identity:ConfirmReset()
    else
        ok,message=identity:PrepareReset()
        self.currentLootNewDropPending=ok==true
    end
    NLL:Print(message)
    if self.RefreshCurrentLootPanel then
        self:RefreshCurrentLootPanel()
    end
    return ok,message
end

function UI:CreateCurrentLootPanel(parent)
    local panel =
        CreateFrame(
            "Frame",
            nil,
            parent
        )

    panel:SetAllPoints(parent)

    local heading =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormal"
        )

    heading:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        10,
        -8
    )

    heading:SetText("Current Loot")

    local status =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    status:SetPoint(
        "LEFT",
        heading,
        "RIGHT",
        16,
        0
    )

    status:SetWidth(445)
    status:SetJustifyH("LEFT")

    local clear =
        self:CreateTextButton(
            panel,
            "Clear",
            70
        )

    clear:SetPoint(
        "TOPRIGHT",
        panel,
        "TOPRIGHT",
        -8,
        -4
    )

    clear:SetScript(
        "OnClick",
        function()
            if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
                NLL.DebugSimulator:Cancel()
            else
                NLL.LootDetection:ClearCurrentLoot()
            end
            UI.currentLootSelected = 1
            UI:RefreshCurrentLootPanel()
        end
    )

    local previewButton = self:CreateTextButton(panel, "Preview Pool", 116)
    previewButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -92, -4)
    previewButton:SetScript("OnClick", function()
        local preview = NLL.TicketPlanner:PreviewSelectedLoot()
        UI.currentLootPreviewStatus:SetText(preview.message)
        NLL:Print(preview.message)
        if preview.ready then
            for i = 1, #preview.current do
                NLL:Print("Pool " .. i .. ": " .. preview.current[i].character)
            end
        end
    end)
    self.currentLootPreviewButton = previewButton

    -- Manual ticket controls below the detected-item rows. No award button.
    local prepare = self:CreateTextButton(panel, 'Prepare Tickets', 143)
    prepare:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 8, 36)
    prepare:SetScript('OnClick',function()
        local entry=NLL.TicketLottery:GetSelectedEntry()
        local ok,notice
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            ok,notice=NLL.DebugSimulator:Prepare()
        else
            ok,notice=NLL.TicketLottery:Prepare(entry)
        end
        NLL:Print(notice)
        UI:RefreshCurrentLootPanel()
    end)
    local draw=self:CreateTextButton(panel,'Start Roll',130)
    draw:SetPoint('LEFT',prepare,'RIGHT',8,0)
    draw:SetScript('OnClick',function()
        local ok,notice
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            ok,notice=NLL.DebugSimulator:Roll()
            NLL:Print(notice)
        else
            ok,notice=NLL.TicketLottery:StartRoll()
        end
        if not ok then NLL:Print(notice) end
        UI:RefreshCurrentLootPanel()
    end)
    local cancel=self:CreateTextButton(panel,'Cancel Tickets',132)
    cancel:SetPoint('BOTTOMLEFT',panel,'BOTTOMLEFT',8,8)
    cancel:SetScript('OnClick',function()
        local ok,notice
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            ok,notice=NLL.DebugSimulator:Cancel()
        else
            ok,notice=NLL.TicketLottery:Cancel('User cancelled')
        end
        NLL:Print(notice)
        UI:RefreshCurrentLootPanel()
    end)
    local reviewButton=self:CreateTextButton(panel,'Review Pool',128)
    reviewButton:SetPoint('LEFT',cancel,'RIGHT',8,0)
    reviewButton:SetScript('OnClick',function()
        local entry=NLL.LootDetection:GetCurrentLoot()[UI.currentLootSelected or 1]
        if entry and NLL.AwardWorkflow:GetOutcome(entry) then
            -- Opens a guarded review; it NEVER transfers on this click.
            UI:OpenAwardReview()
        elseif NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            UI.settingsMode='debug';UI:ShowPanel('settings')
        else
            UI:OpenCandidateReview()
        end
    end)
    self.currentLootReviewButton=reviewButton
    local lotteryNote=panel:CreateFontString(nil,'OVERLAY','GameFontNormal')
    lotteryNote:SetPoint('BOTTOMLEFT',panel,'BOTTOMLEFT',8,64)
    lotteryNote:SetWidth(310)
    lotteryNote:SetJustifyH('LEFT')
    lotteryNote:SetText('No tickets prepared.')
    self.currentLootPrepareButton=prepare
    self.currentLootRollButton=draw
    self.currentLootCancelButton=cancel
    self.currentLootLotteryNote=lotteryNote

    local dropsHeader =
        CreateFrame(
            "Frame",
            nil,
            panel
        )

    dropsHeader:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        8,
        -40
    )

    dropsHeader:SetWidth(326)
    dropsHeader:SetHeight(22)

    self:RegisterSkinnedFrame(
        dropsHeader,
        "header"
    )

    local dropsHeaderText =
        dropsHeader:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

    dropsHeaderText:SetPoint(
        "LEFT",
        dropsHeader,
        "LEFT",
        8,
        0
    )

    dropsHeaderText:SetText("Detected Loot")
    -- A third ticket-row button intruded into the right-hand match paginator.
    -- Anchor New Drop in the left-hand loot header (inside its 326px column).
    -- This leaves both ticket rows and the right-hand controls unobstructed.
    -- Clicking still uses the identical guarded two-step reset as /nll newloot.
    local newDrop=self:CreateTextButton(panel,'New Drop',106)
    newDrop:SetPoint('TOPRIGHT',dropsHeader,'TOPRIGHT',-4,0)
    newDrop:SetScript('OnClick',function()
        UI:RequestNewDrop()
    end)
    self.currentLootNewDropButton=newDrop

    local matchHeader =
        CreateFrame(
            "Frame",
            nil,
            panel
        )

    matchHeader:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        342,
        -40
    )

    matchHeader:SetPoint(
        "TOPRIGHT",
        panel,
        "TOPRIGHT",
        -8,
        -40
    )

    matchHeader:SetHeight(22)

    self:RegisterSkinnedFrame(
        matchHeader,
        "header"
    )

    local function MatchHeader(
        text,
        x,
        width
    )
        local f =
            matchHeader:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontNormalSmall"
            )

        f:SetPoint(
            "LEFT",
            matchHeader,
            "LEFT",
            x,
            0
        )

        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    MatchHeader("Character", 8, 105)
    MatchHeader("Role", 116, 88)
    MatchHeader("Type", 207, 70)
    MatchHeader("Presence", 280, 86)
    MatchHeader("Priority", 370, 92)

    self.currentLootDropRows = {}

    for rowIndex = 1, DROP_ROWS do
        local row =
            CreateFrame(
                "Frame",
                nil,
                panel
            )

        row:SetPoint(
            "TOPLEFT",
            dropsHeader,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 56)
        )

        row:SetWidth(326)
        row:SetHeight(54)
        row:EnableMouse(true)

        self:RegisterSkinnedFrame(
            row,
            (rowIndex % 2) == 0
                and "rowAlt"
                or "row"
        )

        local icon =
            row:CreateTexture(
                nil,
                "ARTWORK"
            )

        icon:SetWidth(36)
        icon:SetHeight(36)

        icon:SetPoint(
            "LEFT",
            row,
            "LEFT",
            6,
            0
        )

        local iconHit =
            CreateFrame(
                "Button",
                nil,
                row
            )

        iconHit:SetAllPoints(icon)

        iconHit:SetScript(
            "OnEnter",
            function(self)
                if not self.itemID then
                    return
                end

                GameTooltip:SetOwner(
                    self,
                    "ANCHOR_RIGHT"
                )

                GameTooltip:SetHyperlink(
                    "item:" ..
                    tostring(self.itemID) ..
                    ":0:0:0:0:0:0:0"
                )

                GameTooltip:Show()
            end
        )

        iconHit:SetScript(
            "OnLeave",
            function()
                GameTooltip:Hide()
            end
        )

        local name =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlight"
            )

        name:SetPoint(
            "TOPLEFT",
            row,
            "TOPLEFT",
            48,
            -7
        )

        name:SetWidth(268)
        name:SetJustifyH("LEFT")

        local source =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontDisableSmall"
            )

        source:SetPoint(
            "TOPLEFT",
            name,
            "BOTTOMLEFT",
            0,
            -4
        )

        source:SetWidth(268)
        source:SetJustifyH("LEFT")

        row:SetScript(
            "OnMouseDown",
            function(self)
                if self.lootIndex then
                    UI.currentLootSelected = self.lootIndex
                    UI.currentLootMatchPage = 1
                    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
                        NLL.DebugSimulator:SelectDrop(self.lootIndex)
                    else
                        UI:RefreshCurrentLootPanel()
                    end
                end
            end
        )

        iconHit:SetScript('OnClick',function()
            local click=row:GetScript('OnMouseDown')
            if click then click(row) end
        end)
        row.icon = icon
        row.iconHit = iconHit
        row.nameText = name
        row.sourceText = source

        self.currentLootDropRows[rowIndex] =
            row
    end

    -- Independent loot paging. Also works with more than five real drops.
    local prevLoot=self:CreateTextButton(panel,"Prev Loot",91)
    prevLoot:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",8,98)
    prevLoot:SetScript("OnClick",function()
        local page=math.max(1,(UI.currentLootDropPage or 1)-1)
        UI.currentLootDropPage=page
        local index=(page-1)*DROP_ROWS+1
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            NLL.DebugSimulator:SelectDrop(index)
        else
            UI.currentLootSelected=index
            UI.currentLootMatchPage=1
            UI:RefreshCurrentLootPanel()
        end
    end)
    local nextLoot=self:CreateTextButton(panel,"Next Loot",91)
    nextLoot:SetPoint("LEFT",prevLoot,"RIGHT",6,0)
    nextLoot:SetScript("OnClick",function()
        local page=(UI.currentLootDropPage or 1)+1
        UI.currentLootDropPage=page
        local index=(page-1)*DROP_ROWS+1
        if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
            NLL.DebugSimulator:SelectDrop(index)
        else
            UI.currentLootSelected=index
            UI.currentLootMatchPage=1
            UI:RefreshCurrentLootPanel()
        end
    end)
    local lootPageText=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    lootPageText:SetPoint("LEFT",nextLoot,"RIGHT",6,0)
    lootPageText:SetWidth(110)
    lootPageText:SetJustifyH("LEFT")
    self.currentLootDropPrev=prevLoot
    self.currentLootDropNext=nextLoot
    self.currentLootDropPageText=lootPageText
    self.currentLootDropPage=1

    local matchStatus =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )

    matchStatus:SetPoint(
        "TOPLEFT",
        matchHeader,
        "BOTTOMLEFT",
        4,
        -8
    )

    matchStatus:SetWidth(445)
    matchStatus:SetJustifyH("LEFT")

    self.currentLootMatchStatus =
        matchStatus

    self.currentLootMatchRows = {}

    for rowIndex = 1, MATCH_ROWS do
        local row =
            CreateFrame(
                "Frame",
                nil,
                panel
            )

        row:SetPoint(
            "TOPLEFT",
            matchHeader,
            "BOTTOMLEFT",
            0,
            -32 - ((rowIndex - 1) * 38)
        )

        row:SetPoint(
            "TOPRIGHT",
            matchHeader,
            "BOTTOMRIGHT",
            0,
            -32 - ((rowIndex - 1) * 38)
        )

        row:SetHeight(36)

        self:RegisterSkinnedFrame(
            row,
            (rowIndex % 2) == 0
                and "rowAlt"
                or "row"
        )

        local name =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlight"
            )

        name:SetPoint(
            "LEFT",
            row,
            "LEFT",
            8,
            0
        )

        name:SetWidth(105)
        name:SetJustifyH("LEFT")

        local role =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        role:SetPoint(
            "LEFT",
            row,
            "LEFT",
            116,
            0
        )

        role:SetWidth(88)
        role:SetJustifyH("LEFT")

        local charType =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        charType:SetPoint(
            "LEFT",
            row,
            "LEFT",
            207,
            0
        )

        charType:SetWidth(70)
        charType:SetJustifyH("LEFT")

        local presence =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        presence:SetPoint(
            "LEFT",
            row,
            "LEFT",
            280,
            0
        )

        presence:SetWidth(86)
        presence:SetJustifyH("LEFT")

        local priority =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )

        priority:SetPoint(
            "LEFT",
            row,
            "LEFT",
            370,
            0
        )

        priority:SetWidth(92)
        priority:SetJustifyH("LEFT")

        -- Keep this narrow column single-line, with the complete eligibility
        -- reason in a standard WoW 3.3.5a tooltip on hover.
        local priorityHit=CreateFrame("Frame",nil,row)
        priorityHit:SetPoint("LEFT",row,"LEFT",370,0)
        priorityHit:SetWidth(92)
        priorityHit:SetHeight(34)
        priorityHit:EnableMouse(true)
        priorityHit:SetScript("OnEnter",function()
            if GameTooltip and row.priorityExplanation then
                GameTooltip:SetOwner(priorityHit,"ANCHOR_RIGHT")
                GameTooltip:SetText(row.priorityExplanation)
                GameTooltip:Show()
            end
        end)
        priorityHit:SetScript("OnLeave",function()
            if GameTooltip then GameTooltip:Hide() end
        end)

        row.nameText = name
        row.roleText = role
        row.typeText = charType
        row.presenceText = presence
        row.priorityText = priority

        self.currentLootMatchRows[rowIndex] =
            row
    end

    local footer =
        panel:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontDisableSmall"
        )

    footer:SetPoint(
        "BOTTOMLEFT",
        panel,
        "BOTTOMLEFT",
        342,
        10
    )

    footer:SetWidth(440)
    footer:SetJustifyH("LEFT")

    footer:SetText(
        "Post-drop ticket-pool preview only. No tickets, rolls or awards."
    )
    self.currentLootPreviewStatus = footer

    -- A 40-player raid can have more than six NEEDED entries.
    -- Paging keeps every match accessible without expanding the panel.
    local back = self:CreateTextButton(panel, "Prev Matches", 107)
    back:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 342, 37)
    back:SetScript("OnClick", function()
        UI.currentLootMatchPage = math.max(1, (UI.currentLootMatchPage or 1)-1)
        UI:RefreshCurrentLootPanel()
    end)
    local forward = self:CreateTextButton(panel, "Next Matches", 107)
    forward:SetPoint("LEFT", back, "RIGHT", 6, 0)
    forward:SetScript("OnClick", function()
        UI.currentLootMatchPage = (UI.currentLootMatchPage or 1)+1
        UI:RefreshCurrentLootPanel()
    end)
    -- Optional read-only all-slot view; sits on its own footer row,
    -- away from Prev Matches / Prepare Tickets (HF1 overlap regression).
    local guild=self:CreateTextButton(panel,"Guild Loot",104)
    guild:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",342,98)
    guild:SetScript("OnClick",function() UI:OpenGuildLootReview() end)
    self.currentLootGuildReviewButton=guild

    self.currentLootMatchPrev=back
    self.currentLootMatchNext=forward
    self.currentLootMatchPageText=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    self.currentLootMatchPageText:SetPoint("LEFT",forward,"RIGHT",8,0)
    self.currentLootMatchPageText:SetWidth(140)
    self.currentLootMatchPageText:SetJustifyH("LEFT")
    self.currentLootMatchPage=1

    self.currentLootStatus = status
    self.currentLootSelected = 1
    self.currentLootPanel = panel

    panel:Hide()
end

-- This preview covers every real item-link slot, even non-MC materials.
-- Review-only: there are NO GiveMasterLoot or AwardWorkflow calls here.
function UI:CreateGuildLootDialog()
    if self.guildLootDialog then return end
    local f=CreateFrame("Frame",nil,self.mainFrame)
    f:SetSize(725,440)
    f:SetPoint("CENTER",self.mainFrame,"CENTER",0,0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel((self.mainFrame:GetFrameLevel() or 0)+32)
    f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=16,edgeSize=26,
        insets={left=8,right=8,top=8,bottom=8}})
    f:SetBackdropColor(.055,.065,.085,.99)
    f:SetBackdropBorderColor(.96,.72,.25,1)

    local heading=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    heading:SetPoint("TOP",f,"TOP",0,-23)
    heading:SetText("GUILD LOOT - MANUAL TWO-CLICK REVIEW")
    local status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOP",heading,"BOTTOM",0,-13)
    status:SetWidth(670)
    status:SetJustifyH("CENTER")
    self.guildLootStatus=status
    self.guildLootRows={}
    for i=1,6 do
        local row=CreateFrame("Frame",nil,f)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",25,-101-44*(i-1))
        row:SetWidth(675)
        row:SetHeight(42)
        self:RegisterSkinnedFrame(row,(i%2)==0 and "rowAlt" or "row")
        local name=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        name:SetPoint("TOPLEFT",row,"TOPLEFT",8,-3)
        name:SetWidth(540)
        name:SetJustifyH("LEFT")
        local reason=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        reason:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",8,4)
        reason:SetWidth(540)
        reason:SetJustifyH("LEFT")
        local review=self:CreateTextButton(row,"Review",90)
        review:SetPoint("RIGHT",row,"RIGHT",-7,0)
        review:SetScript("OnClick",function(button)
            if not button.target then return end
            local ok,message=NLL.GuildLootTransfer:Review(button.target)
            NLL:Print(message)
            UI.guildLootLastMessage=message
            UI:RefreshGuildLootDialog()
        end)
        row.reviewButton=review
        row.nameText=name
        row.reasonText=reason
        self.guildLootRows[i]=row
    end
    local prev=self:CreateTextButton(f,"Previous",100)
    prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,20)
    prev:SetScript("OnClick",function()
        UI.guildLootPage=math.max(1,(UI.guildLootPage or 1)-1)
        UI:RefreshGuildLootDialog()
    end)
    local nextB=self:CreateTextButton(f,"Next",85)
    nextB:SetPoint("LEFT",prev,"RIGHT",8,0)
    nextB:SetScript("OnClick",function()
        UI.guildLootPage=(UI.guildLootPage or 1)+1
        UI:RefreshGuildLootDialog()
    end)
    local page=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    page:SetPoint("LEFT",nextB,"RIGHT",12,0)
    page:SetWidth(125)
    self.guildLootPageText=page
    local investigate=self:CreateTextButton(f,"Investigate",134)
    investigate:SetPoint("LEFT",page,"RIGHT",10,0)
    investigate:SetScript("OnClick",function()
        if UI.OpenReconciliationDialog then UI:OpenReconciliationDialog() end
    end)
    self.guildLootInvestigate=investigate
    -- The Review button above is read-only; neither of these controls
    -- can ever send an item without the player's two extra clicks.
    local arm=self:CreateTextButton(f,"Arm Leader Transfer",181)
    -- Leave a readable gutter between the last loot row and both
    -- action rows (before: only 2px above this 22px button).
    arm:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",24,49)
    arm:SetScript("OnClick",function()
        local ok,msg=NLL.GuildLootTransfer:Arm()
        NLL:Print(msg)
        UI.guildLootLastMessage=msg
        UI:RefreshGuildLootDialog()
    end)
    local give=self:CreateTextButton(f,"CONFIRM GIVE ITEM",185)
    give:SetPoint("LEFT",arm,"RIGHT",12,0)
    give:SetScript("OnClick",function()
        local ok,msg=NLL.GuildLootTransfer:Commit()
        NLL:Print(msg)
        UI.guildLootLastMessage=msg
        UI:RefreshGuildLootDialog()
    end)
    self.guildLootArm=arm
    self.guildLootConfirm=give
    -- This control only enables a read-only proposal view. It has no path
    -- to GiveMasterLoot, and does not enable either physical award setting.
    local dry=self:CreateTextButton(f,"Dry Run: OFF",163)
    dry:SetPoint("LEFT",give,"RIGHT",12,0)
    dry:SetScript("OnClick",function()
        local P=NLL.GuildAutoPreview
        if not P then return end
        local ok,note=P:SetEnabled(not P:IsEnabled())
        UI.guildLootLastMessage=nil
        NLL:Print(note)
        UI:RefreshGuildLootDialog()
    end)
    self.guildLootDryRun=dry

    local close=self:CreateTextButton(f,"Close (No Award)",150)
    close:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-24,20)
    close:SetScript("OnClick",function()
        if NLL.GuildLootTransfer then NLL.GuildLootTransfer:Cancel() end
        f:Hide()
    end)
    self.guildLootPrev=prev
    self.guildLootNext=nextB
    self.guildLootDialog=f
    f:Hide()
end

function UI:RefreshGuildLootDialog()
    if not self.guildLootDialog or not NLL.GuildLootReview then return end
    local rows,message=NLL.GuildLootReview:Scan()
    local candidates=0
    for _,item in ipairs(rows) do
        if item.status=="GUILD_REVIEW" then candidates=candidates+1 end
    end
    local P=NLL.GuildAutoPreview
    local dryRun=P and P:IsEnabled() and P:Build() or nil
    local proposalBySlot={}
    if dryRun then
        for _,v in ipairs(dryRun.rows) do proposalBySlot[v.slotIndex]=v end
    end
    if self.guildLootDryRun and self.guildLootDryRun.label then
        self.guildLootDryRun.label:SetText(
            dryRun and "Dry Run: ON" or "Dry Run: OFF")
    end
    local T=NLL.GuildLootTransfer
    local transferState=T and T:IsEnabled() and
        "OPTIONAL TRANSFER ON (double confirm)" or "TRANSFER OFF"
    -- Live-corpse status has priority over any older arm/review message.
    -- Otherwise the stale old message can hide a despawned corpse.
    local label=(#rows==0 and tostring(message)) or self.guildLootLastMessage or
        (dryRun and dryRun.message or
        ("Eligible for guild REVIEW: "..candidates..". "..transferState..
         ". NO AUTO-ROUTING."))
    self.guildLootStatus:SetText(tostring(label))
    if self.guildLootArm and self.guildLootConfirm then
        local review=T and T.review
        if review and review.armedAt then
            self.guildLootArm:Disable()
            self.guildLootConfirm:Enable()
        elseif review then
            self.guildLootArm:Enable()
            self.guildLootConfirm:Disable()
        else
            self.guildLootArm:Disable()
            self.guildLootConfirm:Disable()
        end
    end
    local pages=math.max(1,math.ceil(#rows/6))
    self.guildLootPage=math.min(pages,math.max(1,self.guildLootPage or 1))
    self.guildLootPageText:SetText("Page "..self.guildLootPage.."/"..pages)
    if self.guildLootPage<=1 then self.guildLootPrev:Disable()
    else self.guildLootPrev:Enable() end
    if self.guildLootPage>=pages then self.guildLootNext:Disable()
    else self.guildLootNext:Enable() end
    for i=1,6 do
        local row=self.guildLootRows[i]
        local item=rows[(self.guildLootPage-1)*6+i]
        if item then
            local proposal=proposalBySlot[item.slotIndex]
            local state=proposal and proposal.decision or item.status
            row.nameText:SetText(
                "Slot "..item.slotIndex..": "..item.itemName..
                " x"..item.quantity.." ["..state.."]")
            row.reasonText:SetText(tostring(proposal and proposal.reason or item.reason)..
                (item.guildMaterial and
                  (" | Guild master: "..tostring(item.guildMaster or
                    "UNAVAILABLE (open Guild roster)")) or
                  (" | Raid leader: "..tostring(item.leader))))
            row.reviewButton.label:SetText(
                item.guildMaterial and "Guild" or "Review")
            row.reviewButton.target={
                slotIndex=item.slotIndex,itemID=item.itemID,
                itemLink=item.itemLink,quantity=item.quantity,
            }
            if item.status=="GUILD_REVIEW" then
                row.reviewButton:Enable()
            else row.reviewButton:Disable() end
            row:Show()
        else
            row.reviewButton.target=nil
            row:Hide()
        end
    end
end

function UI:OpenGuildLootReview()
    self:CreateGuildLootDialog()
    if NLL.GuildLootTransfer then NLL.GuildLootTransfer:Cancel() end
    self.guildLootLastMessage=nil
    self.guildLootPage=1
    self:RefreshGuildLootDialog()
    self.guildLootDialog:Show()
end

function UI:RefreshCurrentLootPanel()
    if not self.currentLootPanel then
        return
    end

    local loot =
        NLL.LootDetection:GetCurrentLoot()
        or {}

    local simulation=NLL.DebugSimulator and NLL.DebugSimulator:IsActive()
    local fresh=NLL.LootDetection and NLL.LootDetection.lootOpen and
        NLL.TicketLottery and NLL.TicketLottery.liveLootObserved
    self.currentLootStatus:SetText(
        (simulation and ("|cffffcc33[SIMULATION]|r "..#loot.." fake boss drop(s).") or
        (fresh and (#loot.." supported item(s). LIVE CORPSE LOOT.") or
        ("|cffff9933"..#loot.." saved item(s). CORPSE CLOSED - no live rolls.|r")))
    )

    self.currentLootSelected =
        self.currentLootSelected or 1

    if self.currentLootSelected > #loot then
        self.currentLootSelected =
            #loot > 0 and #loot or 1
    end

    local pages=math.max(1,math.ceil(#loot / DROP_ROWS))
    self.currentLootDropPage=math.min(pages,
        math.max(1,math.ceil(self.currentLootSelected / DROP_ROWS)))
    local page=self.currentLootDropPage
    local first=(page-1)*DROP_ROWS
    self.currentLootDropPageText:SetText("Page "..page.."/"..pages)
    if page<=1 then self.currentLootDropPrev:Disable()
    else self.currentLootDropPrev:Enable() end
    if page>=pages then self.currentLootDropNext:Disable()
    else self.currentLootDropNext:Enable() end

    for rowIndex = 1, DROP_ROWS do
        local row =
            self.currentLootDropRows[
                rowIndex
            ]

        local absoluteIndex=first+rowIndex
        local entry = loot[absoluteIndex]

        if entry then
            row.lootIndex = absoluteIndex
            row.iconHit.itemID =
                entry.itemID

            row.icon:SetTexture(
                GetItemTexture(
                    entry.itemID
                )
            )

            local quantityText = ""

            if (entry.quantity or 1) > 1 then
                quantityText =
                    " x" ..
                    tostring(entry.quantity)
            end

            row.nameText:SetText(
                entry.itemName ..
                quantityText
            )

            local source=tostring(entry.boss or 'Unknown source')
            if NLL.AwardWorkflow then
                local outcome=NLL.AwardWorkflow:GetOutcome(entry)
                if outcome and outcome.winner then
                    source='Winner: '..outcome.winner..
                        (outcome.awardStatus and
                            (' ['..tostring(outcome.awardStatus)..']') or ' [ROLL]')
                end
            end
            row.sourceText:SetText(source)

            if absoluteIndex ==
                self.currentLootSelected then

                self:RegisterSkinnedFrame(
                    row,
                    "header"
                )
            else
                self:RegisterSkinnedFrame(
                    row,
                    (rowIndex % 2) == 0
                        and "rowAlt"
                        or "row"
                )
            end

            row:Show()
        else
            row.lootIndex = nil
            row.iconHit.itemID = nil
            row:Hide()
        end
    end

    local selected =
        loot[self.currentLootSelected]

    if not selected then
        self:RefreshTicketLotteryControls(nil)
        self.currentLootPreviewButton:Disable()
        self.currentLootPreviewStatus:SetText("No detected drop; no ticket pool.")
        self.currentLootMatchPageText:SetText("0 matches")
        self.currentLootMatchPrev:Disable()
        self.currentLootMatchNext:Disable()
        self.currentLootMatchStatus:SetText(
            "Open a supported raid loot window to detect items."
        )

        for i = 1, MATCH_ROWS do
            self.currentLootMatchRows[i]:Hide()
        end

        return
    end

    self:RefreshTicketLotteryControls(selected)
    self.currentLootPreviewButton:Enable()
    self.currentLootPreviewStatus:SetText(
        "Preview: Need tiers first, then optional greed. No roll or award."
    )

    local neededMatches = NLL.NeedMatcher:GetMatchesForItem(selected.itemID)
    local matches = NLL.NeedMatcher:GetMatchesForReview(selected.itemID)
    local greedCount = #matches - #neededMatches
    if not simulation then
        matches=NLL.CandidateReview:MergeMatches(selected,matches)
    end

    local eligible = 0

    for i = 1, #matches do
        if matches[i].eligiblePresence and
            not (simulation and NLL.DebugSimulator.active.exclusions[
                string.lower(matches[i].character or "")]) and
            (simulation or not NLL.CandidateReview:IsExcluded(
                selected,matches[i].character)) then
            eligible = eligible + 1
        end
    end

    local priorityLabel =
        NLL.PriorityEngine:GetDisplayLabel(
            selected.raidKey
                or "MOLTEN_CORE",
            selected.itemID
        )

    if simulation then
        local _,source=NLL.DebugSimulator:GetRule(selected.itemID)
        priorityLabel="Fake rule: "..tostring(source)
    end
    local statusText =
        "Need: " .. tostring(#neededMatches) ..
        " | Greed: " .. tostring(greedCount) ..
        " | Present: " .. tostring(eligible) ..
        " (before priority checks) | Rule: " .. priorityLabel

    local selectedPolicy=NLL.Data and NLL.Data.MoltenCore and
        NLL.Data.MoltenCore:GetItem(selected.itemID)
    if selectedPolicy and selectedPolicy.reservationLottery and
        (selected.itemID==18563 or selected.itemID==18564) then
        statusText=statusText..
            "  |cff66ff99Saved Windseeker reservations: equal tickets; manual award.|r"
    elseif selected.manualOnly then
        statusText=statusText..
            "  |cffff9933Guild/manual item - no normal lottery.|r"
    end

    self.currentLootMatchStatus:SetText(
        statusText
    )

    local matchPages = math.max(1, math.ceil(#matches / MATCH_ROWS))
    self.currentLootMatchPage = math.min(matchPages,
        math.max(1,self.currentLootMatchPage or 1))
    self.currentLootMatchPageText:SetText(
        "Page " .. self.currentLootMatchPage .. "/" .. matchPages ..
        " (" .. #matches .. ")")
    if self.currentLootMatchPage == 1 then self.currentLootMatchPrev:Disable()
    else self.currentLootMatchPrev:Enable() end
    if self.currentLootMatchPage == matchPages then self.currentLootMatchNext:Disable()
    else self.currentLootMatchNext:Enable() end

    for rowIndex = 1, MATCH_ROWS do
        local row =
            self.currentLootMatchRows[
                rowIndex
            ]

        local match =
            matches[(self.currentLootMatchPage-1)*MATCH_ROWS + rowIndex]

        if match then
            row.nameText:SetText(
                match.character
                or "Unknown"
            )

            -- Keep class separate from the narrow role column:
            -- appending it here caused text wrapping and overlap.
            row.roleText:SetText(
                match.roleLabel or "Unassigned"
            )

            if simulation then
                row.typeText:SetText("Fake Bot")
            elseif match.characterType ==
                "PLAYERBOT" then

                row.typeText:SetText(
                    "Playerbot"
                )
            elseif match.characterType ==
                "PLAYER" then

                row.typeText:SetText(
                    "Player"
                )
            else
                row.typeText:SetText(
                    "Unknown"
                )
            end

            if not match.inRaid then
                row.presenceText:SetText(
                    "|cffff7777Not in raid|r"
                )
            elseif not match.online then
                row.presenceText:SetText(
                    "|cffffaa55Offline|r"
                )
            else
                row.presenceText:SetText(
                    "|cff66ff66In raid|r"
                )
            end

            local _, priorityLabel =
                NLL.PriorityEngine:GetCandidatePriority(
                    selected.raidKey
                        or "MOLTEN_CORE",
                    selected.itemID,
                    match
                )

            row.priorityExplanation = tostring(priorityLabel or "Unresolved")
            if simulation then
                local _,simLabel=NLL.DebugSimulator:GetCandidatePriority(match)
                if NLL.DebugSimulator.active.exclusions[
                   string.lower(match.character or "")] then simLabel="Excluded" end
                row.priorityText:SetText(simLabel or "Unconfigured")
                row.priorityExplanation=tostring(simLabel or "Unconfigured")
            elseif NLL.CandidateReview:IsExcluded(selected,match.character) then
                row.priorityText:SetText('Excluded')
                row.priorityExplanation="Leader exclusion for this drop"
            elseif match.interestStatus == 'GREED' then
                local greedEligible = priorityLabel == "Tier 1" or
                    priorityLabel == "Tier 2" or priorityLabel == "Tier 3"
                row.priorityExplanation="GREED interest: "..
                    tostring(priorityLabel or "Unresolved")
                local shortLabel=greedEligible and "GREED" or
                    (priorityLabel=="Wrong class" and "G:Class" or
                     priorityLabel=="Not eligible" and "G:Excluded" or "G:Review")
                row.priorityText:SetText(shortLabel)
            else
                row.priorityText:SetText(priorityLabel or '')
            end

            row:Show()
        else
            row:Hide()
        end
    end
end


function UI:RefreshTicketLotteryControls(selected)
    if not self.currentLootPrepareButton then return end
    local S=NLL.DebugSimulator
    if S and S:IsActive() then
        self.currentLootNewDropButton:Disable()
        self.currentLootNewDropButton.label:SetText('New Drop')
        self.currentLootNewDropPending=false
        local a=S.active
        if a.result then
            self.currentLootLotteryNote:SetText(
              "|cff66ff99SIM "..tostring(a.result.selectionType or "NEED")..
              " WINNER: "..a.result.winner.." (#"..a.result.number..")|r" ..
              (a.result.awardStatus and ' [FAKE AWARDED]' or ' [PENDING AWARD]'))
        elseif a.prepared then
            self.currentLootLotteryNote:SetText(
              "[SIMULATION] "..tostring(a.prepared.selectionType or "NEED")..
              " - "..#a.prepared.tickets.." tickets ready")
        else
            self.currentLootLotteryNote:SetText(
              "[SIMULATION] Prepare tickets to test a fake roll.")
        end
        if selected and not a.result and not a.prepared then
            self.currentLootPrepareButton:Enable()
        else self.currentLootPrepareButton:Disable() end
        if a.prepared and not a.result then self.currentLootRollButton:Enable()
        else self.currentLootRollButton:Disable() end
        self.currentLootCancelButton:Enable()
        self.currentLootReviewButton.label:SetText(a.result and 'Review Award' or 'Review Pool')
        self.currentLootReviewButton:Enable()
        return
    end
    local L=NLL.TicketLottery
    local live=NLL.LootDetection and NLL.LootDetection.lootOpen and
        L.liveLootObserved
    local pending=L.active and (L.active.status=='WAITING_FOR_ROLL' or
        L.active.status=='ROLL_UNCONFIRMED')
    local canNew=live and selected and selected.slotIndex and
        selected.slotIndex>0 and L:AuthorityAllowed(false) and not pending
    if canNew then self.currentLootNewDropButton:Enable()
    else self.currentLootNewDropButton:Disable() end
    self.currentLootNewDropButton.label:SetText(
        self.currentLootNewDropPending and 'Confirm Drop' or 'New Drop')
    local a=L:GetActiveFor(selected)
    local receipt=a and NLL.LootReceiptTracker and
        NLL.LootReceiptTracker:Get(a.dropUID)
    self.currentLootReviewButton.label:SetText(
        receipt and receipt.status=="OBTAINED" and "Obtained" or
        (receipt and a.awardStatus and "Confirm Receipt" or
        (a and a.status=='COMPLETE' and a.winner and
            not a.awardStatus and 'Award Winner' or
            (a and a.status=='COMPLETE' and 'Award Status' or 'Review Pool'))))
    if a and a.status == "COMPLETE" and a.winner then
        local awardTag = '[NOT AWARDED]'
        if a.awardStatus == 'LEADER_REPORTED' then awardTag='[REPORTED]'
        elseif a.awardStatus == 'AWARD_REQUESTED' then awardTag='[REQUEST SENT]'
        elseif a.awardStatus == 'LOOT_SLOT_CLEARED' then awardTag='[SLOT CLEARED]'
        elseif a.awardStatus == 'AWARD_OUTCOME_UNKNOWN' then awardTag='[UNKNOWN]' end
        self.currentLootLotteryNote:SetText(
          (a.test and "|cff66ff99TEST WINNER: " or "|cff66ff99WINNER: ") ..
          tostring(a.selectionType or "NEED").." "..a.winner ..
          " (#" .. tostring(a.winningTicket) .. ")|r " .. awardTag)
    else
        self.currentLootLotteryNote:SetText(L:GetStatus(selected))
    end
    if self.currentLootNewDropPending then
        self.currentLootLotteryNote:SetText(
            "|cffffcc33NEW CORPSE? Click Confirm Drop (20s).|r")
    elseif not live then
        self.currentLootLotteryNote:SetText(
            "|cffff9933CORPSE CLOSED: reopen to roll.|r")
    elseif selected and selected.identityUncertain then
        self.currentLootLotteryNote:SetText(
            "|cffff9933Repeated loot? Use New Drop ONLY for new corpse.|r")
    elseif a and a.status=='COMPLETE' then
        self.currentLootLotteryNote:SetText(
            "|cffffcc33Old winner locked. New Drop = new corpse only.|r")
    end
    local allowed=selected and selected.dropUID and not selected.identityUncertain and
        live and L:AuthorityAllowed(selected.slotIndex==0)
    if allowed and (not a or a.status=='PREPARED') then
        self.currentLootPrepareButton:Enable()
    else self.currentLootPrepareButton:Disable() end
    if allowed and a and a.status=='PREPARED' then
        self.currentLootRollButton:Enable()
    else self.currentLootRollButton:Disable() end
    if a and a.status~='COMPLETE' and L:AuthorityAllowed(a.test) then
        self.currentLootCancelButton:Enable()
    else self.currentLootCancelButton:Disable() end
end
