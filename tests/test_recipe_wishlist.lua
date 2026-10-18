-- Lua 5.1: recipes are a separate My Wishlist view, not a new SavedVariables schema.
-- Run from repository root: lua5.1 tests/test_recipe_wishlist.lua
local assertions = 0
local function check(condition, message)
    assert(condition, message)
    assertions = assertions + 1
end

local savedWishlist = {
    [16802] = true, -- Arcanist Belt
    [16800] = true, -- Arcanist Boots
    [17010] = true, -- Fiery Core: not a recipe
    [18259] = true, -- Enchant Weapon - Spell Power
    [18257] = true  -- Major Rejuvenation Potion
}
local untouchedReference = savedWishlist
local saves = { Admina = { MOLTEN_CORE = savedWishlist } }
local personalInterests = {}

UnitName = function() return "Admina" end
-- Communication registers a frame at module load time in WoW.
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end
NaxxLootLottery = {
    UI = {},
    Data = {},
    Database = {
        GetLocalWishlist = function(_, character, raid)
            return saves[character][raid]
        end,
        IsLocallyReserved = function(_, character, raid, itemID)
            return saves[character][raid][itemID] == true
        end,
        SetLocalReservation = function(_, character, raid, itemID, wanted)
            saves[character][raid][itemID] = wanted and true or nil
            if not wanted then personalInterests[itemID]=nil end
        end,
        GetLocalInterest = function(_, character, raid, itemID)
            if not saves[character][raid][itemID] then return nil end
            return personalInterests[itemID] or "NEEDED"
        end,
        SetLocalInterest = function(_, character, raid, itemID, status)
            if not saves[character][raid][itemID] or
               (status~="NEEDED" and status~="GREED") then return false end
            personalInterests[itemID]=status=="GREED" and status or nil
            return true
        end
    }
}
local NLL = NaxxLootLottery
assert(loadfile("NaxxLootLottery/Data/MoltenCore.lua"))()
local MC = NLL.Data.MoltenCore
MC:Initialize()
assert(loadfile("NaxxLootLottery/Core/ItemSearch.lua"))()
assert(loadfile("NaxxLootLottery/Core/Communication.lua"))()
local search = NLL.ItemSearch

for _, id in ipairs({ 18264, 18292, 18291, 18290, 18259,
                      18260, 18252, 18265, 21371, 18257 }) do
    check(MC:IsRecipeItem(MC:GetItem(id)), "real MC recipe recognised: "..id)
end
check(not MC:IsRecipeItem(MC:GetItem(17010)), "crafting material is not a recipe")
check(not MC:IsRecipeItem(MC:GetItem(16802)), "equipment is not a recipe")

local function itemNames(items)
    local names = {}
    for _, item in ipairs(items) do
        names[item.name] = true
    end
    return names
end

local items = search:GetLocalWishlistItems("items")
local recipes = search:GetLocalWishlistItems("recipes")
local all = search:GetLocalWishlistItems("all")
check(#items == 3 and #recipes == 2 and #all == 5, "wishlist split counts")
local names = itemNames(items)
check(names["Arcanist Belt"] and names["Arcanist Boots"] and names["Fiery Core"],
    "gear/items view keeps equipment and materials")
local recipeNames = itemNames(recipes)
check(recipeNames["Formula: Enchant Weapon - Spell Power"]
    and recipeNames["Recipe: Major Rejuvenation Potion"],
    "recipes view contains formulas and alchemy recipes only")
check(search:GetLocalWishlistItems("items")[1].name == "Arcanist Belt",
    "items list sorted by name")

local submitted = NLL.Communication:BuildLocalWishlistItemIDs()
check(#submitted == 5, "guild submission still includes gear, materials and recipes")
check(saves.Admina.MOLTEN_CORE == untouchedReference,
    "no SavedVariables migration or new table was introduced")

-- Minimal 3.3.5a-frame stand-ins exercise real UI navigation, not server actions.
local function frame()
    local f = {}
    function f:SetPoint(...) self.anchor = {...} end
    function f:SetWidth(value) self.width = value end
    function f:SetHeight(value) self.height = value end
    function f:SetJustifyH() end
    function f:SetText(text) self.text = text end
    function f:SetScript(action, fn)
        self.scripts = self.scripts or {}
        self.scripts[action] = fn
    end
    function f:CreateFontString() return frame() end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:Enable() self.enabled = true end
    function f:Disable() self.enabled = false end
    return f
end
CreateFrame = function() return frame() end
local UI = NLL.UI
function UI:CreateTextButton(_, label, width)
    local b = frame()
    b.label = frame()
    b.label:SetText(label)
    b.width = width
    return b
end
function UI:RegisterSkinnedFrame() end
function UI:SetButtonState(button, state) button.state = state end
function NLL.Communication:GetOutgoingStatusText() return "No submission currently pending." end
assert(loadfile("NaxxLootLottery/UI/WishlistFrame.lua"))()
UI:CreateLocalWishlistContent(frame())
-- The unit fixture creates only the local page, not full parent Wishlist.
-- Re-route panel refresh to the real local refresh for click assertions.
UI.RefreshWishlistPanel=function(self) self:RefreshLocalWishlist() end
UI:RefreshLocalWishlist()
check(UI.localWishlistCategory == "items", "items are selected by default")
check(UI.localWishlistItemsButton.state == "active"
    and UI.localWishlistRecipesButton.state == "normal",
    "gear/items tab is visibly selected")
check(UI.localWishlistRows[1].shown and UI.localWishlistRows[1].itemText.text == "Arcanist Belt",
    "first original gear item displayed")
check(UI.localWishlistStatus.text:find("5") ~= nil,
    "header shows combined reservation count")
check(UI.localWishlistRows[1].interest.label.text=="NEED",
    "old personal gear reservations display Need by default")
UI.localWishlistRows[1].interest.scripts.OnClick(UI.localWishlistRows[1].interest)
check(personalInterests[16802]=="GREED" and
    UI.localWishlistRows[1].interest.label.text=="GREED",
    "clicking interest changes only this item's preference and label")
check(savedWishlist[16802] and savedWishlist[16800],
    "changing Need to Greed does not remove reservations")
UI.localWishlistRows[1].interest.scripts.OnClick(UI.localWishlistRows[1].interest)
check(personalInterests[16802]==nil and
    UI.localWishlistRows[1].interest.label.text=="NEED",
    "clicking Greed returns to Need without a migration")

UI.localWishlistRecipesButton.scripts.OnClick()
check(UI.localWishlistProfessionButton.shown and
    UI.localWishlistInterestHeader.shown==false,
    "profession review entry replaces only recipe Interest header")
local reviewOpens=0
UI.ShowProfessionRecipeReview=function()reviewOpens=reviewOpens+1 end
UI.localWishlistProfessionButton.scripts.OnClick()
check(reviewOpens==1,
    "recipe category has a discoverable read-only profession review")
check(UI.localWishlistCategory == "recipes"
    and UI.localWishlistPage == 1, "recipes tab resets pagination")
check(UI.localWishlistRecipesButton.state == "active"
    and UI.localWishlistItemsButton.state == "normal", "recipes selected visually")
check(UI.localWishlistRows[1].itemText.text ==
    "Formula: Enchant Weapon - Spell Power", "recipe displayed under Recipes")
check(UI.localWishlistRows[1].interest.enabled==false,
    "guild/manual recipes cannot be toggled into lottery Greed")
check(UI.localWishlistRows[3].shown == false, "only two reserved recipes listed")
UI.localWishlistItemsButton.scripts.OnClick()
check(not UI.localWishlistProfessionButton.shown and
    UI.localWishlistInterestHeader.shown,
    "item category restores original Interest header and hides recipe review")
check(UI.localWishlistRows[1].itemText.text == "Arcanist Belt",
    "returning to Gear / Items restores the same saved gear")

-- Reservation removal remains the existing toggle, never a gear deletion.
search:ToggleReservation(18259)
check(#search:GetLocalWishlistItems("recipes") == 1, "unreserved recipe disappears")
check(#search:GetLocalWishlistItems("items") == 3, "existing gear left unchanged")
check(saves.Admina.MOLTEN_CORE == untouchedReference,
    "unreserve updates the same original table, without replacing it")
print("PASS: "..assertions.." recipe wishlist, shared-reservation and UI assertions")
