-- ============================================================
-- Naxxramas Loot Ledger
-- UI/WishlistFrame.lua
--
-- Phase 4:
--   * My local wishlist review
--   * Raid-leader manual Gear Needs
--   * Persistent Playerbot gear plans
--   * NEEDED / OBTAINED / DISABLED state changes
-- ============================================================

local NLL = NaxxLootLottery
local UI = NLL.UI

local LOCAL_ROWS = 7
-- Six 42px rows leave a real footer gap at WoW 3.3.5a UI scales.
-- Seven overlapped pagination in the owner's 19-entry Gear Plans screenshot.
local PLAN_ROWS = 6
-- Reserve a dedicated footer below the Inbox item grid at large UI font scales.
local INBOX_ITEM_ROWS = 4

local function SetRowBackdrop(row, alternate)
    UI:RegisterSkinnedFrame(
        row,
        alternate
            and "rowAlt"
            or "row"
    )
end

-- The existing saved wishlist remains a single set of item IDs.
-- ItemSearch splits the two visual categories without migrating player data.

function UI:CreateWishlistPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local heading = panel:CreateFontString(
        nil, "OVERLAY", "GameFontNormal"
    )
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    heading:SetText("Wishlists & Gear Plans")

    local myButton = self:CreateTextButton(
        panel,
        "My Wishlist",
        92
    )
    myButton:SetPoint(
        "TOPLEFT",
        panel,
        "TOPLEFT",
        10,
        -34
    )

    local plansButton = self:CreateTextButton(
        panel,
        "Gear Plans",
        90
    )
    plansButton:SetPoint("LEFT", myButton, "RIGHT", 4, 0)

    local inboxButton = self:CreateTextButton(
        panel,
        "Inbox",
        72
    )
    inboxButton:SetPoint("LEFT", plansButton, "RIGHT", 4, 0)

    myButton:SetScript("OnClick", function()
        if UI.DismissContextReviews then UI:DismissContextReviews() end
        UI.wishlistMode = "local"
        UI:RefreshWishlistPanel()
    end)

    plansButton:SetScript("OnClick", function()
        if UI.DismissContextReviews then UI:DismissContextReviews() end
        UI.wishlistMode = "plans"
        UI:RefreshWishlistPanel()
    end)

    inboxButton:SetScript("OnClick", function()
        if UI.DismissContextReviews then UI:DismissContextReviews() end
        UI.wishlistMode = "inbox"
        UI:RefreshWishlistPanel()
    end)

    self.wishlistMyButton = myButton
    self.wishlistPlansButton = plansButton
    self.wishlistInboxButton = inboxButton

    self:CreateLocalWishlistContent(panel)
    self:CreateGearPlansContent(panel)
    self:CreateInboxContent(panel)
    self:CreateSimulationWishlistContent(panel)

    self.wishlistMode = "local"
    self.wishlistPanel = panel

    panel:Hide()
end

-- ============================================================
-- MY LOCAL WISHLIST
-- ============================================================

function UI:CreateLocalWishlistContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -66)
    content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    local status = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    status:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -2)
    status:SetWidth(380)
    status:SetJustifyH("LEFT")
    status:SetHeight(19)
    self.localWishlistStatus = status

    -- Compact single-line status and seven rows reserve enough space
    -- for the page controls and status text at the owner's large font.
    local recipesButton = self:CreateTextButton(
        content, "Recipes", 88
    )
    recipesButton:SetPoint(
        "TOPRIGHT", content, "TOPRIGHT", -4, -1
    )

    local itemsButton = self:CreateTextButton(
        content, "Gear / Items", 108
    )
    itemsButton:SetPoint(
        "RIGHT", recipesButton, "LEFT", -4, 0
    )

    itemsButton:SetScript("OnClick", function()
        if UI.CloseProfessionRecipeReview then UI:CloseProfessionRecipeReview() end
        UI.localWishlistCategory = "items"
        UI.localWishlistPage = 1
        UI:RefreshLocalWishlist()
    end)
    recipesButton:SetScript("OnClick", function()
        UI.localWishlistCategory = "recipes"
        UI.localWishlistPage = 1
        UI:RefreshLocalWishlist()
    end)

    -- Access pending human-to-human receipt confirmations from My Wishlist.
    -- A remote leader's whisper never changes this player's wishlist.
    local receiptButton=self:CreateTextButton(content,"Receipt Inbox",112)
    receiptButton:SetPoint("RIGHT",itemsButton,"LEFT",-8,0)
    receiptButton:SetScript("OnClick",function()
        UI:OpenReceiptSyncReview()
    end)
    self.localReceiptInboxButton=receiptButton

    self.localWishlistItemsButton = itemsButton
    self.localWishlistRecipesButton = recipesButton
    self.localWishlistCategory = "items"

    local header = CreateFrame("Frame", nil, content)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -28)
    header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -28)
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Item", 10, 360)
    HeaderText("Boss / Source", 375, 215)
    local interestHeader=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    interestHeader:SetPoint("LEFT",header,"LEFT",648,0)
    interestHeader:SetWidth(76)
    interestHeader:SetJustifyH("LEFT")
    interestHeader:SetText("Interest")
    -- Reuse the Interest *header* only when the Recipes tab is active.
    -- Never overlap the existing eight item rows or bottom pager.
    local professionButton=self:CreateTextButton(header,"Prof. Review",125)
    professionButton:SetPoint("RIGHT",header,"RIGHT",-3,0)
    professionButton:SetScript("OnClick",function()
        if UI.localWishlistCategory~="recipes" then return end
        if UI.ShowProfessionRecipeReview then UI:ShowProfessionRecipeReview() end
    end)
    professionButton:Hide()
    self.localWishlistProfessionButton=professionButton
    self.localWishlistInterestHeader=interestHeader

    self.localWishlistRows = {}

    for rowIndex = 1, LOCAL_ROWS do
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint(
            "TOPLEFT",
            header,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetPoint(
            "TOPRIGHT",
            header,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetHeight(40)

        SetRowBackdrop(row, (rowIndex % 2) == 0)

        local itemText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlight"
        )
        itemText:SetPoint("LEFT", row, "LEFT", 10, 0)
        itemText:SetWidth(355)
        itemText:SetJustifyH("LEFT")

        local bossText = row:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )
        bossText:SetPoint("LEFT", row, "LEFT", 375, 0)
        bossText:SetWidth(225) -- shortened boss label; protect footer
        bossText:SetJustifyH("LEFT")

        local interest=self:CreateTextButton(row,"NEED",102)
        interest:SetPoint("RIGHT",row,"RIGHT",-84,0)
        interest:SetScript("OnClick",function(self)
            if not self.itemID then return end
            local player=NLL.ItemSearch:GetPlayerName()
            local current=NLL.Database:GetLocalInterest(player,"MOLTEN_CORE",self.itemID)
            if current~="NEEDED" and current~="GREED" then return end
            local nextStatus=current=="GREED" and "NEEDED" or "GREED"
            if NLL.Database:SetLocalInterest(player,"MOLTEN_CORE",self.itemID,nextStatus) then
                UI:RefreshWishlistPanel()
            end
        end)

        local remove =
            self:CreateTextButton(row, "Remove", 72)
        remove:SetPoint("RIGHT", row, "RIGHT", -5, 0)

        remove:SetScript("OnClick", function(self)
            if self.itemID then
                NLL.ItemSearch:ToggleReservation(
                    self.itemID
                )
                UI:RefreshWishlistPanel()
            end
        end)

        row.itemText = itemText
        row.bossText = bossText
        row.interest = interest
        row.remove = remove

        self.localWishlistRows[rowIndex] = row
    end

    local previous =
        self:CreateTextButton(content, "Previous", 76)
    previous:SetPoint(
        "BOTTOMLEFT",
        content,
        "BOTTOMLEFT",
        0,
        0
    )

    local nextButton =
        self:CreateTextButton(content, "Next", 64)
    nextButton:SetPoint("LEFT", previous, "RIGHT", 4, 0)

    local pageText = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    pageText:SetPoint("LEFT", nextButton, "RIGHT", 10, 0)

    previous:SetScript("OnClick", function()
        if UI.localWishlistPage > 1 then
            UI.localWishlistPage =
                UI.localWishlistPage - 1

            UI:RefreshLocalWishlist()
        end
    end)

    nextButton:SetScript("OnClick", function()
        if UI.localWishlistPage
            < UI.localWishlistTotalPages then

            UI.localWishlistPage =
                UI.localWishlistPage + 1

            UI:RefreshLocalWishlist()
        end
    end)


    local submitButton =
        self:CreateTextButton(
            content,
            "Submit to Leader",
            122
        )

    submitButton:SetPoint(
        "BOTTOMRIGHT",
        content,
        "BOTTOMRIGHT",
        0,
        0
    )

    submitButton:SetScript(
        "OnClick",
        function()
            NLL.Communication:
                SubmitLocalWishlist()
        end
    )

    local submitStatus =
        content:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontDisableSmall"
        )

    submitStatus:SetPoint(
        "BOTTOMRIGHT", content, "BOTTOMRIGHT", -2, 30
    )

    -- Reserve a separate lower status strip; never share the footer
    -- baseline with Previous / Next / Page at large game font scales.
    submitStatus:SetWidth(245)
    submitStatus:SetHeight(24)
    submitStatus:SetJustifyH("RIGHT")

    self.localSubmitStatus = submitStatus
    self.localSubmitButton = submitButton

    self.localWishlistPrevious = previous
    self.localWishlistNext = nextButton
    self.localWishlistPageText = pageText
    self.localWishlistPage = 1
    self.localWishlistTotalPages = 1
    self.localWishlistContent = content
end

function UI:RefreshLocalWishlist()
    local category = self.localWishlistCategory == "recipes"
        and "recipes" or "items"
    self.localWishlistCategory = category
    if self.localWishlistProfessionButton then
        if category=="recipes" then
            self.localWishlistProfessionButton:Show()
            self.localWishlistInterestHeader:Hide()
        else
            self.localWishlistProfessionButton:Hide()
            self.localWishlistInterestHeader:Show()
        end
    end

    if self.localReceiptInboxButton and NLL.ReceiptSync then
        local pending=NLL.ReceiptSync:GetPendingForLocal()
        self.localReceiptInboxButton.label:SetText(
            "Receipts ("..#pending..")")
    end
    local gearItems = NLL.ItemSearch:GetLocalWishlistItems("items")
    local recipes = NLL.ItemSearch:GetLocalWishlistItems("recipes")
    local items = category == "recipes" and recipes or gearItems
    local count = #items
    local totalCount = #gearItems + #recipes

    self:SetButtonState(
        self.localWishlistItemsButton,
        category == "items" and "active" or "normal"
    )
    self:SetButtonState(
        self.localWishlistRecipesButton,
        category == "recipes" and "active" or "normal"
    )

    local totalPages =
        math.ceil(count / LOCAL_ROWS)

    if totalPages < 1 then
        totalPages = 1
    end

    self.localWishlistTotalPages = totalPages
    self.localWishlistPage =
        self.localWishlistPage or 1

    if self.localWishlistPage > totalPages then
        self.localWishlistPage = totalPages
    end

    self.localWishlistStatus:SetText(
        "MC Wishlist: |cffffffff"..tostring(totalCount)..
        "|r ("..#gearItems.." gear, "..#recipes.." recipes)"
    )

    if self.localSubmitStatus then
        self.localSubmitStatus:SetText(
            NLL.Communication:
                GetOutgoingStatusText()
        )
    end

    local firstIndex =
        ((self.localWishlistPage - 1) * LOCAL_ROWS) + 1

    for rowIndex = 1, LOCAL_ROWS do
        local row = self.localWishlistRows[rowIndex]
        local item = items[firstIndex + rowIndex - 1]

        if item then
            row.itemText:SetText(item.name)
            local boss=NLL.Data.MoltenCore:GetBossText(item) or ""
            -- A long MC boss list can otherwise wrap to 3+ lines,
            -- overlapping the next wishlist row in large-font WoW.
            if #boss>39 then boss=boss:sub(1,36).."..." end
            row.bossText:SetText(boss)
            row.remove.itemID = item.itemID
            row.interest.itemID = item.itemID
            local choice=NLL.Database.GetLocalInterest and
                NLL.Database:GetLocalInterest(
                    NLL.ItemSearch:GetPlayerName(),"MOLTEN_CORE",item.itemID)
                or "NEEDED"
            row.interest.label:SetText(
                choice=="OBTAINED" and "OBTAINED" or
                (choice=="GREED" and "GREED" or "NEED"))
            -- Recipes always remain explicit guild/manual distribution:
            -- interest stays NEED; never imply they can join a normal roll.
            if category=="recipes" or choice=="OBTAINED" then
                row.interest:Disable()
            else row.interest:Enable() end
            row:Show()
        else
            row:Hide()
        end
    end

    self.localWishlistPageText:SetText(
        "Page " ..
        self.localWishlistPage ..
        " / " ..
        totalPages
    )

    if self.localWishlistPage <= 1 then
        self.localWishlistPrevious:Disable()
    else
        self.localWishlistPrevious:Enable()
    end

    if self.localWishlistPage >= totalPages then
        self.localWishlistNext:Disable()
    else
        self.localWishlistNext:Enable()
    end
end

-- ============================================================
-- RAID LEADER / PLAYERBOT GEAR PLANS
-- ============================================================

function UI:CreateGearPlansContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -66)
    content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    -- Character name
    local characterLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    characterLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -3
    )
    characterLabel:SetText("Character")

    local characterBox = CreateFrame(
        "EditBox",
        "NaxxLootLotteryGearCharacterBox",
        content,
        "InputBoxTemplate"
    )
    characterBox:SetWidth(135)
    characterBox:SetHeight(22)
    characterBox:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -20
    )
    characterBox:SetAutoFocus(false)

    -- Character type
    local typeLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    typeLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        150,
        -3
    )
    typeLabel:SetText("Type")

    local typeDrop = CreateFrame(
        "Frame",
        "NaxxLootLotteryGearTypeDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    typeDrop:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        132,
        -14
    )
    UIDropDownMenu_SetWidth(typeDrop, 105)

    typeDrop.value = "PLAYERBOT"

    UIDropDownMenu_Initialize(typeDrop, function()
        local types = {
            { id = "PLAYER", label = "Player" },
            { id = "PLAYERBOT", label = "Playerbot" },
            { id = "UNKNOWN", label = "Unknown" }
        }

        for i = 1, #types do
            local entry = types[i]
            local id = entry.id
            local label = entry.label

            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = typeDrop.value == id

            info.func = function()
                typeDrop.value = id
                UIDropDownMenu_SetText(typeDrop, label)

                if id == "PLAYERBOT" then
                    UI.gearSourceDrop.value =
                        "BOT_GEAR_PLAN"

                    UIDropDownMenu_SetText(
                        UI.gearSourceDrop,
                        "Bot Gear Plan"
                    )
                end
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(typeDrop, "Playerbot")

    -- Role
    local roleLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    roleLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        270,
        -3
    )
    roleLabel:SetText("Role")

    local roleDrop = CreateFrame(
        "Frame",
        "NaxxLootLotteryGearRoleDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    roleDrop:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        250,
        -14
    )
    UIDropDownMenu_SetWidth(roleDrop, 145)
    roleDrop.value = "MAIN_TANK"

    UIDropDownMenu_Initialize(roleDrop, function()
        for i = 1, #NLL.roles do
            local role = NLL.roles[i]
            local roleID = role.id
            local roleText = role.label

            local info = UIDropDownMenu_CreateInfo()
            info.text = roleText
            info.checked = roleDrop.value == roleID

            info.func = function()
                roleDrop.value = roleID
                UIDropDownMenu_SetText(
                    roleDrop,
                    roleText
                )
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(roleDrop, "Main Tank")

    -- Source
    local sourceLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    sourceLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        430,
        -3
    )
    sourceLabel:SetText("Source")

    local sourceDrop = CreateFrame(
        "Frame",
        "NaxxLootLotteryGearSourceDropDown",
        content,
        "UIDropDownMenuTemplate"
    )
    sourceDrop:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        410,
        -14
    )
    UIDropDownMenu_SetWidth(sourceDrop, 145)
    sourceDrop.value = "BOT_GEAR_PLAN"

    UIDropDownMenu_Initialize(sourceDrop, function()
        local sources = {
            {
                id = "BOT_GEAR_PLAN",
                label = "Bot Gear Plan"
            },
            {
                id = "RAID_LEADER_MANUAL",
                label = "Leader Manual"
            }
        }

        for i = 1, #sources do
            local entry = sources[i]
            local id = entry.id
            local label = entry.label

            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = sourceDrop.value == id

            info.func = function()
                sourceDrop.value = id
                UIDropDownMenu_SetText(
                    sourceDrop,
                    label
                )
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(sourceDrop, "Bot Gear Plan")

    -- Item input
    local itemLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    itemLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        585,
        -3
    )
    itemLabel:SetText("Molten Core item")

    local itemBox = CreateFrame(
        "EditBox",
        "NaxxLootLotteryGearItemBox",
        content,
        "InputBoxTemplate"
    )
    itemBox:SetWidth(135)
    itemBox:SetHeight(22)
    itemBox:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        580,
        -20
    )
    itemBox:SetAutoFocus(false)

    local addButton =
        self:CreateTextButton(content, "Add Plan", 78)
    addButton:SetPoint(
        "TOPRIGHT",
        content,
        "TOPRIGHT",
        -2,
        -19
    )

    self.gearCharacterBox = characterBox
    self.gearTypeDrop = typeDrop
    self.gearRoleDrop = roleDrop
    self.gearSourceDrop = sourceDrop
    self.gearItemBox = itemBox

    -- Choose the interest level before saving: an off-spec item should
    -- never become a primary NEED even temporarily.
    local interestLabel = content:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall")
    interestLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 350, -58)
    interestLabel:SetText("New entry interest")
    local interestDrop = CreateFrame("Frame",
        "NaxxLootLotteryNewGearInterestDropDown", content,
        "UIDropDownMenuTemplate")
    interestDrop:SetPoint("TOPLEFT", content, "TOPLEFT", 331, -70)
    UIDropDownMenu_SetWidth(interestDrop, 125)
    interestDrop.value = "NEEDED"
    UIDropDownMenu_Initialize(interestDrop, function()
        for _, choice in ipairs({
            {id="NEEDED", label="Needed (main)"},
            {id="GREED", label="Greed / Off-Spec"}
        }) do
            local id, label = choice.id, choice.label
            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = interestDrop.value == id
            info.func = function()
                interestDrop.value = id
                UIDropDownMenu_SetText(interestDrop, label)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(interestDrop, "Needed (main)")
    self.gearInterestDrop = interestDrop

    addButton:SetScript("OnClick", function()
        local characterName =
            UI.gearCharacterBox:GetText() or ""

        local item, errorMessage =
            NLL.GearNeeds:ResolveItem(
                UI.gearItemBox:GetText() or ""
            )

        if not item then
            NLL:Print(errorMessage)
            return
        end

        local ok, result =
            NLL.GearNeeds:AddNeed(
                characterName,
                item.itemID,
                "MOLTEN_CORE",
                UI.gearRoleDrop.value,
                UI.gearInterestDrop.value,
                UI.gearSourceDrop.value,
                UI.gearTypeDrop.value
            )

        if not ok then
            NLL:Print(result)
            return
        end

        NLL:Print(
            item.name ..
            " added for " ..
            result.character ..
            " (" .. result.status .. ")."
        )

        UI.gearItemBox:SetText("")
        UI:RefreshGearPlans()
    end)

    -- Filter
    local filterLabel = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    filterLabel:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -58
    )
    filterLabel:SetText("Filter character (exact)")

    local filterBox = CreateFrame(
        "EditBox",
        "NaxxLootLotteryGearFilterBox",
        content,
        "InputBoxTemplate"
    )
    filterBox:SetWidth(145)
    filterBox:SetHeight(22)
    filterBox:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        4,
        -74
    )
    filterBox:SetAutoFocus(false)

    local filterButton =
        self:CreateTextButton(content, "Apply", 58)
    filterButton:SetPoint(
        "LEFT",
        filterBox,
        "RIGHT",
        5,
        0
    )

    local clearFilter =
        self:CreateTextButton(content, "All", 48)
    clearFilter:SetPoint(
        "LEFT",
        filterButton,
        "RIGHT",
        4,
        0
    )

    local function ApplyCharacterFilter()
        if NLL.GearPlanReview then NLL.GearPlanReview:Cancel() end
        if UI.CancelGearPlanRolePicker then UI:CancelGearPlanRolePicker() end
        if UI.gearPlanReviewDialog then UI.gearPlanReviewDialog:Hide() end
        -- Filtering is a VIEW operation. Never edit, remove, re-import or
        -- otherwise mutate stored Gear Plans while searching for a bot.
        UI.gearPlanFilter=filterBox:GetText() or ""
        UI.gearPlansPage=1
        UI:RefreshGearPlans()
    end
    filterBox:SetScript("OnTextChanged", ApplyCharacterFilter)
    filterBox:SetScript("OnEnterPressed", function(box)
        ApplyCharacterFilter()
        if box.ClearFocus then box:ClearFocus() end
    end)
    -- Retain Apply for familiar mouse interaction and accessibility.
    filterButton:SetScript("OnClick", ApplyCharacterFilter)

    clearFilter:SetScript("OnClick", function()
        filterBox:SetText("")
        -- OnTextChanged should normally handle this automatically, but
        -- refresh explicitly for test fixtures and non-standard clients.
        UI.gearPlanFilter=""
        UI.gearPlansPage=1
        UI:RefreshGearPlans()
    end)

    self.gearFilterBox = filterBox
    self.gearPlanFilter = ""

    -- Keep the transfer entry point above the list. The six-row footer
    -- must not move back into the saved Gear Plans, at any UI font scale.
    local transferButton =
        self:CreateTextButton(content, "Import / Export", 125)
    transferButton:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -75)
    transferButton:SetScript("OnClick", function()
        UI:ShowGearPlanTransfer()
    end)
    self.gearTransferButton = transferButton

    -- List header
    local header = CreateFrame("Frame", nil, content)
    header:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        0,
        -108
    )
    header:SetPoint(
        "TOPRIGHT",
        content,
        "TOPRIGHT",
        0,
        -108
    )
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Character", 8, 120)
    HeaderText("Item", 132, 220)
    HeaderText("Role", 356, 105)
    HeaderText("Source", 465, 110)
    HeaderText("Status", 580, 120)

    self.gearPlanRows = {}

    for rowIndex = 1, PLAN_ROWS do
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint(
            "TOPLEFT",
            header,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetPoint(
            "TOPRIGHT",
            header,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 42)
        )
        row:SetHeight(40)

        SetRowBackdrop(
            row,
            (rowIndex % 2) == 0
        )

        local characterText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        characterText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            8,
            0
        )
        characterText:SetWidth(120)
        characterText:SetJustifyH("LEFT")

        local itemText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        itemText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            132,
            0
        )
        itemText:SetWidth(220)
        itemText:SetJustifyH("LEFT")

        local roleText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        roleText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            356,
            0
        )
        -- Keep the saved per-item role readable while allocating a
        -- separate, clearly labelled Edit control inside this column.
        -- Source begins at x=465; role-edit ends at x=458.
        roleText:SetWidth(58)
        roleText:SetJustifyH("LEFT")
        local editRole=self:CreateTextButton(row,"Edit",38)
        editRole:SetPoint("LEFT",row,"LEFT",420,0)
        editRole:SetScript("OnClick",function(button)
            if button.needKey then
                UI:OpenGearPlanRolePicker(button.needKey)
            end
        end)

        local sourceText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontDisableSmall"
            )
        sourceText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            465,
            0
        )
        sourceText:SetWidth(110)
        sourceText:SetJustifyH("LEFT")

        local statusName =
            "NaxxLootLotteryNeedStatus" ..
            tostring(rowIndex)

        local statusDrop = CreateFrame(
            "Frame",
            statusName,
            row,
            "UIDropDownMenuTemplate"
        )
        statusDrop:SetPoint(
            "LEFT",
            row,
            "LEFT",
            555,
            -2
        )
        UIDropDownMenu_SetWidth(statusDrop, 100)

        UIDropDownMenu_Initialize(
            statusDrop,
            function()
                local statuses = {
                    "NEEDED",
                    "GREED",
                    "OBTAINED",
                    "DISABLED"
                }

                for i = 1, #statuses do
                    local status = statuses[i]

                    local info =
                        UIDropDownMenu_CreateInfo()

                    info.text = status
                    info.checked =
                        statusDrop.currentStatus
                        == status

                    info.func = function()
                        if statusDrop.needKey then
                            -- Review before saving; no dropdown click
                            -- may mark a bot OBTAINED or change a plan.
                            UI:ReviewBotPlan(statusDrop.needKey,"STATUS",status)
                        end
                    end

                    UIDropDownMenu_AddButton(info)
                end
            end
        )

        local remove =
            self:CreateTextButton(row, "X", 28)
        remove:SetPoint(
            "RIGHT",
            row,
            "RIGHT",
            -4,
            0
        )

        remove:SetScript("OnClick", function(self)
            if self.needKey then
                UI:ReviewBotPlan(self.needKey,"REMOVE")
            end
        end)

        row.characterText = characterText
        row.itemText = itemText
        row.roleText = roleText
        row.roleEdit = editRole
        row.sourceText = sourceText
        row.statusDrop = statusDrop
        row.remove = remove

        self.gearPlanRows[rowIndex] = row
    end

    local statusText = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontDisableSmall"
    )
    statusText:SetPoint(
        "BOTTOMLEFT",
        content,
        "BOTTOMLEFT",
        0,
        2
    )
    statusText:SetWidth(270)
    statusText:SetJustifyH("LEFT")

    local previous =
        self:CreateTextButton(content, "Previous", 76)
    previous:SetPoint(
        "BOTTOM",
        content,
        "BOTTOM",
        -48,
        0
    )

    local nextButton =
        self:CreateTextButton(content, "Next", 64)
    nextButton:SetPoint(
        "LEFT",
        previous,
        "RIGHT",
        4,
        0
    )

    local pageText = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    pageText:SetPoint(
        "LEFT",
        nextButton,
        "RIGHT",
        10,
        0
    )

    previous:SetScript("OnClick", function()
        if NLL.GearPlanReview then NLL.GearPlanReview:Cancel() end
        if UI.CancelGearPlanRolePicker then UI:CancelGearPlanRolePicker() end
        if UI.gearPlanReviewDialog then UI.gearPlanReviewDialog:Hide() end
        if UI.gearPlansPage > 1 then
            UI.gearPlansPage =
                UI.gearPlansPage - 1

            UI:RefreshGearPlans()
        end
    end)

    nextButton:SetScript("OnClick", function()
        if NLL.GearPlanReview then NLL.GearPlanReview:Cancel() end
        if UI.CancelGearPlanRolePicker then UI:CancelGearPlanRolePicker() end
        if UI.gearPlanReviewDialog then UI.gearPlanReviewDialog:Hide() end
        if UI.gearPlansPage
            < UI.gearPlansTotalPages then

            UI.gearPlansPage =
                UI.gearPlansPage + 1

            UI:RefreshGearPlans()
        end
    end)

    self.gearPlansStatus = statusText
    self.gearPlansPrevious = previous
    self.gearPlansNext = nextButton
    self.gearPlansPageText = pageText
    self.gearPlansPage = 1
    self.gearPlansTotalPages = 1
    self.gearPlansContent = content

    content:Hide()
end

function UI:RefreshGearPlans()
    local needs =
        NLL.GearNeeds:GetAllNeeds(
            self.gearPlanFilter
        )

    local count = #needs
    local totalPages =
        math.ceil(count / PLAN_ROWS)

    if totalPages < 1 then
        totalPages = 1
    end

    self.gearPlansTotalPages = totalPages
    self.gearPlansPage =
        self.gearPlansPage or 1

    if self.gearPlansPage > totalPages then
        self.gearPlansPage = totalPages
    end

    local filter=tostring(self.gearPlanFilter or ""):match("^%s*(.-)%s*$") or ""
    self.gearPlansStatus:SetText(
        tostring(count).." saved Gear Need(s)"..
        (filter~="" and (" for "..filter..
            (count==0 and " (no exact match)" or "")) or "")
    )

    local firstIndex =
        ((self.gearPlansPage - 1) * PLAN_ROWS) + 1

    for rowIndex = 1, PLAN_ROWS do
        local row = self.gearPlanRows[rowIndex]
        local need =
            needs[firstIndex + rowIndex - 1]

        if need then
            local item =
                NLL.Data.MoltenCore:GetItem(
                    need.itemID
                )

            row.characterText:SetText(
                need.character or "Unknown"
            )

            row.itemText:SetText(
                item
                and item.name
                or tostring(need.itemID)
            )

            -- Short labels prevent clipping beside the 38px Edit button.
            -- The selector shows the FULL role name for selection.
            local roleShort={
                MAIN_TANK="Main Tank",TANK="Tank",HEALER="Healer",
                MELEE_DPS="Melee",RANGED_PHYSICAL_DPS="Ranged",
                CASTER_DPS="Caster",
            }
            row.roleText:SetText(roleShort[need.role] or "Unknown")
            row.roleEdit.needKey=need.key

            if need.source == "BOT_GEAR_PLAN" then
                row.sourceText:SetText("Bot Plan")
            elseif need.source
                == "RAID_LEADER_MANUAL" then

                row.sourceText:SetText("Manual")
            else
                row.sourceText:SetText(
                    need.source or "Unknown"
                )
            end

            row.statusDrop.needKey = need.key
            row.statusDrop.currentStatus =
                need.status

            UIDropDownMenu_SetText(
                row.statusDrop,
                need.status or "NEEDED"
            )

            row.remove.needKey = need.key
            -- Only bot plans which are not already OBTAINED can
            -- offer per-item role editing or deletion.
            if need.source=="BOT_GEAR_PLAN" and
               need.characterType=="PLAYERBOT" and
               need.status~="OBTAINED" then
                row.roleEdit:Enable()
            else row.roleEdit:Disable() end
            -- This new editor is for existing Playerbot plans only.
            -- Receipt-confirmed OBTAINED records are never removable.
            if need.source=="BOT_GEAR_PLAN" and
               need.characterType=="PLAYERBOT" and
               need.status~="OBTAINED" then
                row.remove:Enable()
            else row.remove:Disable() end
            row:Show()
        else
            row:Hide()
        end
    end

    self.gearPlansPageText:SetText(
        "Page " ..
        self.gearPlansPage ..
        " / " ..
        totalPages
    )

    if self.gearPlansPage <= 1 then
        self.gearPlansPrevious:Disable()
    else
        self.gearPlansPrevious:Enable()
    end

    if self.gearPlansPage >= totalPages then
        self.gearPlansNext:Disable()
    else
        self.gearPlansNext:Enable()
    end

    if self.RefreshOverview then
        self:RefreshOverview()
    end
end


-- ============================================================
-- RAID LEADER SUBMISSION INBOX
-- ============================================================

function UI:CreateInboxContent(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -66)
    content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)

    local status = content:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    status:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -2)
    status:SetWidth(348)
    status:SetHeight(20)
    status:SetJustifyH("LEFT")
    self.inboxStatus = status
    -- The top Inbox list used to show ONLY four submissions even when
    -- six or more were saved. Both lists must have independent pagers.
    local older=self:CreateTextButton(content,"Older",67)
    older:SetPoint("TOPRIGHT",content,"TOPRIGHT",-175,-2)
    local newer=self:CreateTextButton(content,"Newer",70)
    newer:SetPoint("LEFT",older,"RIGHT",5,0)
    local pageLabel=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    pageLabel:SetPoint("RIGHT",content,"RIGHT",-81,197)
    pageLabel:SetWidth(76)
    pageLabel:SetJustifyH("RIGHT")
    local archived=self:CreateTextButton(content,"Archived",84)
    archived:SetPoint("TOPRIGHT",content,"TOPRIGHT",0,-2)
    older:SetScript("OnClick",function()
        if UI.inboxPage<(UI.inboxTotalPages or 1) then
            UI.inboxPage=UI.inboxPage+1
            UI:RefreshInbox()
        end
    end)
    newer:SetScript("OnClick",function()
        if UI.inboxPage>1 then
            UI.inboxPage=UI.inboxPage-1
            UI:RefreshInbox()
        end
    end)
    archived:SetScript("OnClick",function()
        UI.inboxShowArchived=not UI.inboxShowArchived
        UI.inboxPage=1
        UI.inboxItemPage=1
        UI.selectedSubmissionKey=nil
        UI.inboxArchiveArmed=nil
        UI:RefreshInbox()
    end)
    self.inboxOlder=older
    self.inboxNewer=newer
    self.inboxTopPageLabel=pageLabel
    self.inboxArchivedToggle=archived

    local header = CreateFrame("Frame", nil, content)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -28)
    header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -28)
    header:SetHeight(22)
    UI:RegisterSkinnedFrame(
        header,
        "header"
    )

    local function HeaderText(text, x, width)
        local f = header:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
        f:SetPoint("LEFT", header, "LEFT", x, 0)
        f:SetWidth(width)
        f:SetJustifyH("LEFT")
        f:SetText(text)
    end

    HeaderText("Player", 8, 155)
    HeaderText("Items", 168, 60)
    HeaderText("Role", 232, 135)
    HeaderText("Received", 372, 170)
    HeaderText("Status", 548, 100)

    self.inboxRows = {}

    for rowIndex = 1, 4 do
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint(
            "TOPLEFT",
            header,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 36)
        )
        row:SetPoint(
            "TOPRIGHT",
            header,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 36)
        )
        row:SetHeight(34)

        SetRowBackdrop(
            row,
            (rowIndex % 2) == 0
        )

        local playerText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        playerText:SetPoint("LEFT", row, "LEFT", 8, 0)
        playerText:SetWidth(155)
        playerText:SetJustifyH("LEFT")

        local countText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        countText:SetPoint("LEFT", row, "LEFT", 168, 0)
        countText:SetWidth(60)
        countText:SetJustifyH("LEFT")

        local roleText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        roleText:SetPoint("LEFT", row, "LEFT", 232, 0)
        roleText:SetWidth(135)
        roleText:SetJustifyH("LEFT")

        local receivedText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontDisableSmall"
            )
        receivedText:SetPoint("LEFT", row, "LEFT", 372, 0)
        receivedText:SetWidth(170)
        receivedText:SetJustifyH("LEFT")

        local statusText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        statusText:SetPoint("LEFT", row, "LEFT", 548, 0)
        statusText:SetWidth(100)
        statusText:SetJustifyH("LEFT")

        local review =
            self:CreateTextButton(
                row,
                "Review",
                66
            )
        review:SetPoint(
            "RIGHT",
            row,
            "RIGHT",
            -4,
            0
        )

        review:SetScript("OnClick", function(self)
            if self.submissionKey then
                UI.selectedSubmissionKey =
                    self.submissionKey
                UI.inboxArchiveArmed=nil
                UI.inboxItemPage = 1
                UI:RefreshInbox()
            end
        end)

        row.playerText = playerText
        row.countText = countText
        row.roleText = roleText
        row.receivedText = receivedText
        row.statusText = statusText
        row.review = review

        self.inboxRows[rowIndex] = row
    end

    local selectedTitle =
        content:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
    selectedTitle:SetPoint(
        "TOPLEFT",
        header,
        "BOTTOMLEFT",
        4,
        -155
    )
    selectedTitle:SetWidth(582)
    selectedTitle:SetJustifyH("LEFT")
    selectedTitle:SetText(
        "Select a submission to review its items."
    )

    self.inboxSelectedTitle = selectedTitle

    -- Two-click ARCHIVE, never a permanent delete. This works for
    -- an old PENDING submission too, but does not ACCEPT/REJECT it.
    local archive=self:CreateTextButton(content,"Archive",104)
    archive:SetPoint("TOPRIGHT",content,"TOPRIGHT",-3,-206)
    archive:SetScript("OnClick",function()
        local key=UI.selectedSubmissionKey
        if not key then return end
        local submission=NLL.Communication:GetSubmission(key)
        if not submission then return end
        if UI.inboxShowArchived then
            local ok,msg=NLL.Communication:RestoreArchivedSubmission(key)
            UI.selectedSubmissionKey=nil
            UI.inboxArchiveArmed=nil
            if NLL.Print then NLL:Print(msg) end
            UI:RefreshInbox()
            return
        end
        local a=UI.inboxArchiveArmed
        local now=GetTime and GetTime() or nil
        if a and a.key==key and type(now)=="number" and
           now>=a.at and now-a.at<=15 and
           a.reference==submission and a.status==submission.status then
            UI.inboxArchiveArmed=nil
            local ok,msg=NLL.Communication:ArchiveSubmission(key)
            UI.selectedSubmissionKey=nil
            if NLL.Print then NLL:Print(msg) end
            UI:RefreshInbox()
            return
        end
        UI.inboxArchiveArmed=nil
        if type(now)~="number" then return end
        UI.inboxArchiveArmed={
            key=key,at=now,reference=submission,status=submission.status
        }
        archive.label:SetText("CONFIRM")
        if NLL.Print then
            NLL:Print("Confirm ARCHIVE within 15 seconds. The full "..
              "submission stays in SavedVariables and can be restored.")
        end
    end)
    self.inboxArchiveButton=archive

    local itemHeader = CreateFrame("Frame", nil, content)
    itemHeader:SetPoint(
        "TOPLEFT",
        selectedTitle,
        "BOTTOMLEFT",
        -4,
        -8
    )
    itemHeader:SetPoint(
        "TOPRIGHT",
        content,
        "TOPRIGHT",
        0,
        -205
    )
    itemHeader:SetHeight(22)
    UI:RegisterSkinnedFrame(
        itemHeader,
        "header"
    )

    local itemHeaderText =
        itemHeader:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
    itemHeaderText:SetPoint(
        "LEFT",
        itemHeader,
        "LEFT",
        8,
        0
    )
    itemHeaderText:SetText("Submitted Item")

    local decisionHeader =
        itemHeader:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )
    decisionHeader:SetPoint(
        "RIGHT",
        itemHeader,
        "RIGHT",
        -70,
        0
    )
    decisionHeader:SetText("Decision")

    self.inboxItemRows = {}

    for rowIndex = 1, INBOX_ITEM_ROWS do
        local row = CreateFrame(
            "Frame",
            nil,
            content
        )

        row:SetPoint(
            "TOPLEFT",
            itemHeader,
            "BOTTOMLEFT",
            0,
            -((rowIndex - 1) * 31)
        )
        row:SetPoint(
            "TOPRIGHT",
            itemHeader,
            "BOTTOMRIGHT",
            0,
            -((rowIndex - 1) * 31)
        )
        row:SetHeight(29)

        SetRowBackdrop(
            row,
            (rowIndex % 2) == 0
        )

        local itemText =
            row:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontHighlightSmall"
            )
        itemText:SetPoint(
            "LEFT",
            row,
            "LEFT",
            8,
            0
        )
        itemText:SetWidth(600)
        itemText:SetJustifyH("LEFT")

        local toggle =
            self:CreateTextButton(
                row,
                "Reject",
                70
            )
        toggle:SetPoint(
            "RIGHT",
            row,
            "RIGHT",
            -4,
            0
        )

        toggle:SetScript(
            "OnClick",
            function(self)
                if self.submissionKey
                    and self.itemID then

                    NLL.Communication:
                        ToggleExcludedItem(
                            self.submissionKey,
                            self.itemID
                        )
                end
            end
        )

        row.itemText = itemText
        row.toggle = toggle

        self.inboxItemRows[rowIndex] = row
    end

    local previousItem =
        self:CreateTextButton(
            content,
            "Previous",
            100
        )
    previousItem:SetPoint(
        "BOTTOMLEFT",
        content,
        "BOTTOMLEFT",
        0,
        0
    )

    local nextItem =
        self:CreateTextButton(
            content,
            "Next",
            72
        )
    nextItem:SetPoint(
        "LEFT",
        previousItem,
        "RIGHT",
        12,
        0
    )

    local itemPageText =
        content:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontHighlightSmall"
        )
    itemPageText:SetPoint(
        "LEFT",
        nextItem,
        "RIGHT",
        12,
        0
    )
    itemPageText:SetWidth(110)
    itemPageText:SetJustifyH("LEFT")

    previousItem:SetScript(
        "OnClick",
        function()
            if UI.inboxItemPage > 1 then
                UI.inboxItemPage =
                    UI.inboxItemPage - 1
                UI:RefreshInbox()
            end
        end
    )

    nextItem:SetScript(
        "OnClick",
        function()
            if UI.inboxItemPage
                < UI.inboxItemTotalPages then

                UI.inboxItemPage =
                    UI.inboxItemPage + 1
                UI:RefreshInbox()
            end
        end
    )

    local accept =
        self:CreateTextButton(
            content,
            "Accept",
            72
        )
    accept:SetPoint(
        "BOTTOMRIGHT",
        content,
        "BOTTOMRIGHT",
        -82,
        0
    )

    accept:SetScript(
        "OnClick",
        function()
            if UI.selectedSubmissionKey then
                NLL.Communication:
                    AcceptSubmission(
                        UI.selectedSubmissionKey
                    )
            end
        end
    )

    local reject =
        self:CreateTextButton(
            content,
            "Reject",
            72
        )
    reject:SetPoint(
        "LEFT",
        accept,
        "RIGHT",
        4,
        0
    )

    reject:SetScript(
        "OnClick",
        function()
            if UI.selectedSubmissionKey then
                NLL.Communication:
                    RejectSubmission(
                        UI.selectedSubmissionKey
                    )
            end
        end
    )

    self.inboxPreviousItem = previousItem
    self.inboxNextItem = nextItem
    self.inboxItemPageText = itemPageText
    self.inboxAcceptButton = accept
    self.inboxRejectButton = reject
    self.inboxPage = 1
    self.inboxShowArchived=false
    self.inboxTotalPages=1
    self.inboxItemPage = 1
    self.inboxItemTotalPages = 1
    self.inboxContent = content

    content:Hide()
end

function UI:RefreshInbox()
    local submissions=NLL.Communication:GetInboxSubmissions(
        self.inboxShowArchived)
    local count=#submissions
    local pages=math.max(1,math.ceil(count/4))
    self.inboxTotalPages=pages
    self.inboxPage=math.max(1,math.min(self.inboxPage or 1,pages))
    local first=(self.inboxPage-1)*4
    self.inboxStatus:SetText(
        count..(self.inboxShowArchived and " archived submission(s)" or
        " active submission(s)"))
    if self.inboxTopPageLabel then
        self.inboxTopPageLabel:SetText(self.inboxPage.."/"..pages)
        if self.inboxPage>=pages then self.inboxOlder:Disable()
        else self.inboxOlder:Enable() end
        if self.inboxPage<=1 then self.inboxNewer:Disable()
        else self.inboxNewer:Enable() end
        self.inboxArchivedToggle.label:SetText(
            self.inboxShowArchived and "Active" or "Archived")
    end

    for rowIndex=1,4 do
        local row=self.inboxRows[rowIndex]
        local submission=submissions[first+rowIndex]

        if submission then
            local role =
                NLL.Database:
                    GetRoleAssignment(
                        submission.player
                    )

            row.playerText:SetText(
                submission.player or "Unknown"
            )
            row.countText:SetText(
                tostring(
                    #(submission.itemIDs or {})
                )
            )
            row.roleText:SetText(
                NLL:GetRoleLabel(role)
            )
            row.receivedText:SetText(
                submission.receivedAt or ""
            )
            row.statusText:SetText(
                submission.status or "PENDING"
            )
            row.review.submissionKey =
                submission.key

            row:Show()
        else
            row:Hide()
        end
    end

    local selected =
        self.selectedSubmissionKey
        and NLL.Communication:
            GetSubmission(
                self.selectedSubmissionKey
            )

    if selected and ((self.inboxShowArchived and selected.archived~=true) or
        (not self.inboxShowArchived and selected.archived==true)) then
        self.selectedSubmissionKey=nil
        selected=nil
    end
    if self.inboxArchiveButton then
        if not selected then
            self.inboxArchiveArmed=nil
            self.inboxArchiveButton:Hide()
        else
            self.inboxArchiveButton:Show()
            self.inboxArchiveButton.label:SetText(
                self.inboxShowArchived and "Restore" or
                (self.inboxArchiveArmed and
                 self.inboxArchiveArmed.key==selected.key and
                 "CONFIRM" or "Archive"))
        end
    end
    if not selected then
        self.inboxSelectedTitle:SetText(
            "Select a submission to review its items."
        )

        for i = 1, #self.inboxItemRows do
            self.inboxItemRows[i]:Hide()
        end

        self.inboxAcceptButton:Disable()
        self.inboxRejectButton:Disable()
        self.inboxPreviousItem:Disable()
        self.inboxNextItem:Disable()
        self.inboxItemPageText:SetText("")
        return
    end

    local conflicts =
        NLL.Communication:
            GetConflictCount(selected)

    self.inboxSelectedTitle:SetText(
        selected.player ..
        " - " ..
        tostring(
            #(selected.itemIDs or {})
        ) ..
        " submitted item(s), " ..
        tostring(conflicts) ..
        " existing manual/bot conflict(s)."
    )

    local totalItems =
        #(selected.itemIDs or {})

    local totalPages =
        math.ceil(totalItems / INBOX_ITEM_ROWS)

    if totalPages < 1 then
        totalPages = 1
    end

    self.inboxItemTotalPages = totalPages

    if self.inboxItemPage > totalPages then
        self.inboxItemPage = totalPages
    end

    local firstIndex =
        ((self.inboxItemPage - 1) * INBOX_ITEM_ROWS) + 1

    selected.excluded =
        selected.excluded or {}

    for rowIndex = 1, INBOX_ITEM_ROWS do
        local row =
            self.inboxItemRows[rowIndex]

        local itemID =
            selected.itemIDs[
                firstIndex + rowIndex - 1
            ]

        if itemID then
            local item =
                NLL.Data.MoltenCore:
                    GetItem(itemID)

            local conflict =
                NLL.GearNeeds:
                    HasOtherSourceNeed(
                        selected.player,
                        selected.raidKey,
                        itemID
                    )

            local text =
                item
                and item.name
                or tostring(itemID)
            local interest=(selected.interests or {})[itemID] or "NEEDED"
            text=text.." ["..(interest=="GREED" and "GREED" or "NEED").."]"

            if conflict then
                text =
                    text ..
                    " |cffff9933[existing manual/bot need]|r"
            end

            row.itemText:SetText(text)
            row.toggle.submissionKey =
                selected.key
            row.toggle.itemID = itemID

            if selected.excluded[itemID] then
                row.toggle.label:SetText("Restore")
            else
                row.toggle.label:SetText("Reject")
            end

            if selected.status == "PENDING" then
                row.toggle:Enable()
            else
                row.toggle:Disable()
            end

            row:Show()
        else
            row:Hide()
        end
    end

    self.inboxItemPageText:SetText(
        "Page " ..
        self.inboxItemPage ..
        " / " ..
        totalPages
    )

    if self.inboxItemPage <= 1 then
        self.inboxPreviousItem:Disable()
    else
        self.inboxPreviousItem:Enable()
    end

    if self.inboxItemPage >= totalPages then
        self.inboxNextItem:Disable()
    else
        self.inboxNextItem:Enable()
    end

    if not self.inboxShowArchived and selected.status == "PENDING" and
       NLL.Communication:IsSelfRaidLeader() then
        self.inboxAcceptButton:Enable()
        self.inboxRejectButton:Enable()
    else
        self.inboxAcceptButton:Disable()
        self.inboxRejectButton:Disable()
    end
end

function UI:RefreshWishlistPanel()
    if not self.wishlistPanel then
        return
    end

    self.localWishlistContent:Hide()
    self.gearPlansContent:Hide()
    self.inboxContent:Hide()
    if self.simulationWishlistContent then self.simulationWishlistContent:Hide() end
    local sim=NLL.DebugSimulator
    if sim and sim:IsActive() then
        self.wishlistMyButton:Disable()
        self.wishlistPlansButton:Disable()
        self.wishlistInboxButton:Disable()
        self.simulationWishlistContent:Show()
        self:RefreshSimulationWishlist()
        return
    end
    self.wishlistMyButton:Enable()
    self.wishlistPlansButton:Enable()
    self.wishlistInboxButton:Enable()

    self:SetButtonState(
        self.wishlistMyButton,
        "normal"
    )

    self:SetButtonState(
        self.wishlistPlansButton,
        "normal"
    )

    self:SetButtonState(
        self.wishlistInboxButton,
        "normal"
    )

    if self.wishlistMode == "plans" then
        self.gearPlansContent:Show()

        self:SetButtonState(
            self.wishlistPlansButton,
            "active"
        )

        self:RefreshGearPlans()
        return
    end

    if self.wishlistMode == "inbox" then
        self.inboxContent:Show()

        self:SetButtonState(
            self.wishlistInboxButton,
            "active"
        )

        self:RefreshInbox()
        return
    end

    self.wishlistMode = "local"
    self.localWishlistContent:Show()

    self:SetButtonState(
        self.wishlistMyButton,
        "active"
    )

    self:RefreshLocalWishlist()
end


-- Normal Wishlists window, but with a separate read-only, in-memory
-- fake Gear Plans view while a Debug Raid Simulator scenario is active.
function UI:CreateSimulationWishlistContent(parent)
    local panel=CreateFrame("Frame",nil,parent)
    panel:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-65)
    panel:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-8,8)
    local status=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOPLEFT",panel,"TOPLEFT",8,-4)
    status:SetWidth(740);status:SetJustifyH("LEFT")
    status:SetText("[SIMULATION] Fake Playerbot Gear Plans - no saved data")
    local header=CreateFrame("Frame",nil,panel)
    header:SetPoint("TOPLEFT",panel,"TOPLEFT",4,-27)
    header:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-4,-27)
    header:SetHeight(24);self:RegisterSkinnedFrame(header,"header")
    local function Head(txt,x,w)
        local f=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        f:SetPoint("LEFT",header,"LEFT",x,0);f:SetWidth(w);f:SetText(txt)
        f:SetJustifyH("LEFT")
    end
    Head("Fake Playerbot",9,165);Head("Class / Role",180,183)
    Head("Wanted Loot",380,310);Head("Status",695,85)
    self.simulationWishlistRows={}
    for i=1,9 do
        local row=CreateFrame("Frame",nil,panel)
        row:SetPoint("TOPLEFT",header,"BOTTOMLEFT",0,-(i-1)*36)
        row:SetPoint("TOPRIGHT",header,"BOTTOMRIGHT",0,-(i-1)*36)
        row:SetHeight(34)
        self:RegisterSkinnedFrame(row,i%2==0 and "rowAlt" or "row")
        local fields={}
        for j,s in ipairs({{9,165},{180,183},{380,310},{695,85}}) do
            local f=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            f:SetPoint("LEFT",row,"LEFT",s[1],0)
            f:SetWidth(s[2]);f:SetJustifyH("LEFT")
            fields[j]=f
        end
        row.fields=fields;self.simulationWishlistRows[i]=row
    end
    local back=self:CreateTextButton(panel,"Previous",82)
    back:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",6,4)
    local nextB=self:CreateTextButton(panel,"Next",65)
    nextB:SetPoint("LEFT",back,"RIGHT",7,0)
    back:SetScript("OnClick",function()
        UI.simulationNeedsPage=math.max(1,(UI.simulationNeedsPage or 1)-1)
        UI:RefreshSimulationWishlist()
    end)
    nextB:SetScript("OnClick",function()
        UI.simulationNeedsPage=(UI.simulationNeedsPage or 1)+1
        UI:RefreshSimulationWishlist()
    end)
    self.simulationWishlistPrev=back;self.simulationWishlistNext=nextB
    local pages=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    pages:SetPoint("LEFT",nextB,"RIGHT",10,0)
    self.simulationWishlistPageText=pages
    self.simulationWishlistContent=panel
    panel:Hide()
end
function UI:RefreshSimulationWishlist()
    if not self.simulationWishlistContent then return end
    local S=NLL.DebugSimulator
    local rows=S and S:GetNeeds() or {}
    local count=#rows
    local pages=math.max(1,math.ceil(count/9))
    self.simulationNeedsPage=math.min(pages,math.max(1,self.simulationNeedsPage or 1))
    for i,row in ipairs(self.simulationWishlistRows) do
        local r=rows[(self.simulationNeedsPage-1)*9+i]
        if r then
            row.fields[1]:SetText(r.character)
            row.fields[2]:SetText(NLL:GetClassLabel(r.classFile).." / "..NLL:GetRoleLabel(r.role))
            row.fields[3]:SetText(r.itemName)
            row.fields[4]:SetText(r.state)
            row:Show()
        else row:Hide() end
    end
    self.simulationWishlistPageText:SetText("Page "..self.simulationNeedsPage.."/"..pages..
        " ("..count.." fake needs)")
    if self.simulationNeedsPage<=1 then self.simulationWishlistPrev:Disable()
    else self.simulationWishlistPrev:Enable() end
    if self.simulationNeedsPage>=pages then self.simulationWishlistNext:Disable()
    else self.simulationWishlistNext:Enable() end
end


-- ============================================================
-- OPTIONAL PLAYERBOT GEAR PLAN COPY / PASTE
-- ============================================================
-- This dialog never writes data without a separate Preview -> Confirm.
-- It does not use local files, account SavedVariables, chat or addon messages.
function UI:CreateGearPlanTransfer()
    if self.gearTransferDialog then return end
    local panel=CreateFrame("Frame","NaxxLootLotteryGearTransferDialog",UIParent)
    panel:SetWidth(744)
    panel:SetHeight(477)
    panel:SetPoint("CENTER",UIParent,"CENTER",0,0)
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart",function(frame)frame:StartMoving()end)
    panel:SetScript("OnDragStop",function(frame)frame:StopMovingOrSizing()end)
    self:RegisterSkinnedFrame(panel,"main")

    local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-14)
    title:SetText("Playerbot Gear Plans - Import / Export")

    local hint=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-12)
    hint:SetWidth(700)
    hint:SetJustifyH("LEFT")
    hint:SetText("Copy existing bot plans, or paste a NLL-GEARPLANS-1 list. Preview first. Existing plans are NEVER overwritten.")
    local format=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    format:SetPoint("TOPLEFT",hint,"BOTTOMLEFT",0,-8)
    format:SetWidth(700)
    format:SetJustifyH("LEFT")
    format:SetText("Format: Character | PLAYERBOT | Role | MOLTEN_CORE | Item ID | BOT_GEAR_PLAN | Status | 1")

    local exportButton=self:CreateTextButton(panel,"Export Bot Plans",130)
    exportButton:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-91)
    local importButton=self:CreateTextButton(panel,"Paste / Import",120)
    importButton:SetPoint("LEFT",exportButton,"RIGHT",10,0)
    local previewButton=self:CreateTextButton(panel,"Preview Changes",125)
    previewButton:SetPoint("LEFT",importButton,"RIGHT",10,0)
    local confirmButton=self:CreateTextButton(panel,"Confirm ADD",115)
    confirmButton:SetPoint("LEFT",previewButton,"RIGHT",10,0)
    local compareButton=self:CreateTextButton(panel,"Compare Conflicts",140)
    compareButton:SetPoint("LEFT",confirmButton,"RIGHT",9,0)
    local closeButton=self:CreateTextButton(panel,"Close",66)
    closeButton:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-15,-13)

    local well=CreateFrame("Frame",nil,panel)
    well:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-129)
    well:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-16,86)
    self:RegisterSkinnedFrame(well,"row")
    -- Wrath 3.3.5a's UIPanelScrollFrameTemplate accesses
    -- frame:GetName() while creating $parentScrollBar. An unnamed
    -- ScrollFrame makes FrameXML/ScrollFrame_OnLoad concatenate nil.
    -- Give this singleton dialog's scroll frame a stable global name.
    local scroll=CreateFrame(
        "ScrollFrame",
        "NaxxLootLotteryGearTransferScrollFrame",
        well,
        "UIPanelScrollFrameTemplate"
    )
    scroll:SetPoint("TOPLEFT",well,"TOPLEFT",8,-8)
    scroll:SetPoint("BOTTOMRIGHT",well,"BOTTOMRIGHT",-30,8)
    local edit=CreateFrame("EditBox",nil,scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(656)
    edit:SetHeight(255)
    edit:SetMaxLetters(0)
    edit:SetScript("OnEscapePressed",function(box)box:ClearFocus()end)
    scroll:SetScrollChild(edit)

    local status=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",18,18)
    status:SetWidth(705)
    status:SetJustifyH("LEFT")
    status:SetText("No changes made. Export is read-only; Import requires a preview and confirmation.")

    -- Batch navigator lives BELOW the text well, never above the
    -- six-row Gear Plans grid. Every button only changes read-only text.
    local prevBatch=self:CreateTextButton(panel,"Prev Batch",102)
    prevBatch:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",16,58)
    local nextBatch=self:CreateTextButton(panel,"Next Batch",102)
    nextBatch:SetPoint("LEFT",prevBatch,"RIGHT",8,0)
    local batchLabel=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    batchLabel:SetPoint("LEFT",nextBatch,"RIGHT",12,0)
    batchLabel:SetWidth(445)
    batchLabel:SetJustifyH("LEFT")
    batchLabel:SetText("Export batches: no saved data changed.")
    prevBatch:Disable()
    nextBatch:Disable()

    local preview=nil
    local mode="EXPORT"
    local exportPage=1
    local exportPages=1
    confirmButton:Disable()
    previewButton:Disable()
    compareButton:Disable()

    local function ClearPreview()
        preview=nil
        confirmButton:Disable()
        compareButton:Disable()
        if UI.CloseGearPlanConflictDialog then
            UI:CloseGearPlanConflictDialog()
        end
    end
    local function SetStatus(message)
        status:SetText(tostring(message or ""))
    end
    local function SetMode(nextMode)
        mode=nextMode
        ClearPreview()
        if mode=="EXPORT" then
            previewButton:Disable()
        else
            previewButton:Enable()
            prevBatch:Disable()
            nextBatch:Disable()
            batchLabel:SetText("Import mode: batch paging is unavailable.")
        end
    end
    local function DisplayExportPage(page)
        if mode~="EXPORT" then
            SetStatus("Choose Export Bot Plans to view read-only batches.")
            return
        end
        -- ExportChunk validates ALL saved bot plans before returning a
        -- bounded, deterministic batch. Failed exports do not leave a
        -- stale text block that might be mistaken for a complete backup.
        local data,count,pages,total=NLL.GearPlanTransfer:ExportChunk(page)
        if not data then
            edit:SetText("")
            prevBatch:Disable()
            nextBatch:Disable()
            batchLabel:SetText("Export unavailable — no plans were changed.")
            SetStatus("EXPORT BLOCKED: "..tostring(count))
            return
        end
        exportPage=page
        exportPages=pages
        edit:SetText(data)
        edit:SetFocus()
        edit:HighlightText()
        if page>1 then prevBatch:Enable() else prevBatch:Disable() end
        if page<pages then nextBatch:Enable() else nextBatch:Disable() end
        batchLabel:SetText("Batch "..page.."/"..pages.." — "..
            count.." of "..total.." bot plans on this page.")
        SetStatus("Read-only export batch "..page.."/"..pages..
            ". Press Ctrl+C and SAVE this batch separately; use Next Batch "..
            "until all "..pages.." batches are copied. NOTHING was modified.")
    end

    edit:SetScript("OnTextChanged",function(box)
        -- Invalidate confirmation if the user changes even one byte.
        ClearPreview()
        -- ScrollFrame needs a child taller than the visible area when
        -- pasting larger multi-line lists on the 3.3.5a client.
        local length=#(box:GetText() or "")
        local _,newlines=(box:GetText() or ""):gsub("\n","\n")
        local visualLines=math.max(17,newlines+1,math.ceil(length/74))
        box:SetHeight(math.max(255,visualLines*14))
    end)

    exportButton:SetScript("OnClick",function()
        SetMode("EXPORT")
        exportPage=1
        DisplayExportPage(exportPage)
    end)
    prevBatch:SetScript("OnClick",function()
        if mode~="EXPORT" or exportPage<=1 then return end
        DisplayExportPage(exportPage-1)
    end)
    nextBatch:SetScript("OnClick",function()
        if mode~="EXPORT" or exportPage>=exportPages then return end
        DisplayExportPage(exportPage+1)
    end)

    importButton:SetScript("OnClick",function()
        local alreadyImport=(mode=="IMPORT")
        SetMode("IMPORT")
        -- Only discard the read-only export when FIRST entering import mode.
        -- A second click must not silently delete a player's pasted raid list.
        if not alreadyImport then
            edit:SetText("")
        end
        edit:SetFocus()
        if alreadyImport then
            SetStatus("Import mode: existing pasted text kept. Click in the large box and press Ctrl+V if needed, then Preview Changes.")
        else
            SetStatus("Import mode ready. Click inside the large text box and press Ctrl+V, THEN Preview Changes. No plans changed.")
        end
    end)

    previewButton:SetScript("OnClick",function()
        ClearPreview()
        if mode~="IMPORT" then
            SetStatus("Choose Paste / Import before previewing.")
            return
        end
        local pastedText=edit:GetText() or ""
        if #pastedText==0 then
            SetStatus("PREVIEW BLOCKED: The import text box is EMPTY. Click inside the large box and press Ctrl+V. Do not click Import Mode again after pasting.")
            return
        end
        local candidate,errorText=NLL.GearPlanTransfer:Preview(pastedText)
        if not candidate then
            SetStatus("PREVIEW BLOCKED: "..tostring(errorText))
            return
        end
        preview=candidate
        SetStatus(NLL.GearPlanTransfer:Summary(candidate))
        if #candidate.conflicts>0 then
            -- Conflicts always prevent Confirm ADD, even when the
            -- same paste also includes valid new plans.
            compareButton:Enable()
        elseif candidate.ready then
            confirmButton:Enable()
        end
    end)

    compareButton:SetScript("OnClick",function()
        if mode~="IMPORT" or not preview or
           #preview.conflicts==0 then
            SetStatus("Preview a conflicting paste before comparing.")
            return
        end
        -- No import, no mutation, no confirm action. This report is
        -- shown only for this exact preview and saved-data snapshot.
        local ok,message=UI:ShowGearPlanConflictDialog(preview)
        SetStatus((ok and "READ ONLY: " or "COMPARE BLOCKED: ")..
            tostring(message))
        confirmButton:Disable()
    end)

    confirmButton:SetScript("OnClick",function()
        if mode~="IMPORT" or not preview then
            SetStatus("Preview the import before confirming.")
            confirmButton:Disable()
            return
        end
        local ok,message=NLL.GearPlanTransfer:Apply(preview,edit:GetText())
        ClearPreview()
        SetStatus((ok and "IMPORT COMPLETE: " or "IMPORT BLOCKED: ")..
            tostring(message))
        if ok and UI.RefreshGearPlans then
            UI:RefreshGearPlans()
        end
    end)
    closeButton:SetScript("OnClick",function()
        UI:CloseGearPlanTransfer()
    end)
    -- The same revocation path is used by direct Close, changing
    -- Wishlist tabs, navigating to another panel and Escape.
    self.gearTransferCancelTransient=ClearPreview

    self.gearTransferDialog=panel
    self.gearTransferTextBox=edit
    self.gearTransferPreview=previewButton
    self.gearTransferCompare=compareButton
    self.gearTransferConfirm=confirmButton
    self.gearTransferStatus=status
    self.gearTransferExport=exportButton
    self.gearTransferImport=importButton
    self.gearTransferPrevBatch=prevBatch
    self.gearTransferNextBatch=nextBatch
    self.gearTransferBatchLabel=batchLabel
    panel:Hide()
end

function UI:CloseGearPlanTransfer()
    if self.gearTransferCancelTransient then
        self.gearTransferCancelTransient()
    end
    if self.gearTransferTextBox and self.gearTransferTextBox.ClearFocus then
        self.gearTransferTextBox:ClearFocus()
    end
    if self.gearTransferDialog then self.gearTransferDialog:Hide() end
end

function UI:ShowGearPlanTransfer()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        NLL:Print("Stop the fake raid before using real Gear Plan Import / Export.")
        return
    end
    if self.DismissContextReviews then self:DismissContextReviews() end
    self:CreateGearPlanTransfer()
    self.gearTransferDialog:Show()
    -- Open safely in read-only export mode and highlight the text.
    self.gearTransferExport:GetScript("OnClick")()
end
