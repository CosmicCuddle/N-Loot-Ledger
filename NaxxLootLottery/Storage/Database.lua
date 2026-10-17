-- ============================================================
-- Naxxramas Loot Ledger
-- Storage/Database.lua
-- ============================================================

local NLL = NaxxLootLottery
NLL.Database = NLL.Database or {}
local Database = NLL.Database

function Database:Initialize()
    if type(NaxxLootLotteryDB) ~= "table" then
        NaxxLootLotteryDB = {}
    end

    local db = NaxxLootLotteryDB

    if type(db.version) ~= "number" then
        db.version = NLL.databaseVersion
    end

    if type(db.settings) ~= "table" then
        db.settings = {}
    end

    if db.settings.debug == nil then
        db.settings.debug = false
    end

    -- Direct real loot transfer must be opted into EACH LOGIN/reload.
    -- Do not persist a previous enabled flag across client restarts.
    db.settings.directMasterLootEnabled = false
    -- Guild-material Master Loot is a separate consent and never persists.
    db.settings.guildLootTransfersEnabled = false
    if type(db.guildLootTransferAudit)~="table" then
        db.guildLootTransferAudit={}
    end
    -- Raid announcements/countdown are separate, non-awarding opt-ins.
    if type(db.settings.raidAnnouncementsEnabled)~="boolean" then
        db.settings.raidAnnouncementsEnabled=false
    end
    if type(db.settings.raidCountdownEnabled)~="boolean" then
        db.settings.raidCountdownEnabled=false
    end

    -- One-click, reversible preset library. Never bulk-overwrites guild rules.
    -- Disabled for all preexisting users until they opt in on Priority Setup.
    if type(db.settings.priorityPresetsEnabled) ~= "boolean" then
        db.settings.priorityPresetsEnabled = false
    end

    -- Only the NLL Dark appearance remains. Normalize obsolete UI choices
    -- without replacing the SavedVariables table or any persisted loot data.
    if db.settings.skin ~= "DARK" then
        db.settings.skin = "DARK"
    end

    if type(db.characters) ~= "table" then
        db.characters = {}
    end

    if type(db.gearNeeds) ~= "table" then
        db.gearNeeds = {}
    end

    if type(db.gearNeedsSchema) ~= "number" then
        db.gearNeedsSchema = 1
    end

    if type(db.roleAssignments) ~= "table" then
        db.roleAssignments = {}
    end

    if type(db.history) ~= "table" then
        db.history = {}
    end

    if type(db.raidSession) ~= "table" then
        db.raidSession = {}
    end

    if type(db.raidSession.currentLoot) ~= "table" then
        db.raidSession.currentLoot = {}
    end
    if type(db.lotteryHistory) ~= "table" then
        db.lotteryHistory = {}
    end
    if type(db.lootAwardHistory) ~= "table" then
        db.lootAwardHistory = {}
    end
    if type(db.lootReceiptTracker) ~= "table" then
        db.lootReceiptTracker = {}
    end
    if type(db.candidateAudit) ~= 'table' then
        db.candidateAudit = {}
    end
    if type(db.raidSession.lootGeneration) ~= "number" then
        db.raidSession.lootGeneration = 0
    end

    -- Persisted local Molten Core reservation IDs. The Gear / Items
    -- and Recipes views share this existing table; no migration needed.
    if type(db.localWishlists) ~= "table" then
        db.localWishlists = {}
    end
    -- Optional per-item interest only for GREED. The original boolean
    -- wishlist is kept untouched so existing reservations remain NEED.
    if type(db.localWishlistGreed) ~= "table" then
        db.localWishlistGreed = {}
    end
    if type(db.localWishlistObtained) ~= "table" then
        db.localWishlistObtained = {}
    end

    if type(db.submissionInbox) ~= "table" then
        db.submissionInbox = {}
    end

    if type(db.priorityRules) ~= "table" then
        db.priorityRules = {}
    end

    if type(db.priorityRules.MOLTEN_CORE) ~= "table" then
        db.priorityRules.MOLTEN_CORE = {}
    end

    NLL.db = db
end

function Database:UpdateCharacterFromRoster(member)
    if not member or not member.name or not NLL.db then
        return
    end

    local character = NLL.db.characters[member.name]
    if type(character) ~= "table" then
        character = {}
        NLL.db.characters[member.name] = character
    end

    character.name = member.name
    character.class = member.classFile
    character.className = member.className
    character.level = member.level

    if character.characterType == nil then
        character.characterType = "UNKNOWN"
    end
end

function Database:GetRoleAssignment(name)
    if not name or not NLL.db then
        return nil
    end

    local entry = NLL.db.roleAssignments[name]

    if type(entry) == "string" then
        if NLL:IsValidRole(entry) then
            return entry
        end
        return nil
    end

    if type(entry) == "table" and NLL:IsValidRole(entry.role) then
        return entry.role
    end

    return nil
end

function Database:SetRoleAssignment(name, roleID, member)
    if not name or name == "" or not NLL.db then
        return false
    end

    if roleID == nil then
        NLL.db.roleAssignments[name] = nil
        return true
    end

    if not NLL:IsValidRole(roleID) then
        return false
    end

    local entry = NLL.db.roleAssignments[name]
    if type(entry) ~= "table" then
        entry = {}
        NLL.db.roleAssignments[name] = entry
    end

    entry.role = roleID

    if member then
        entry.class = member.classFile
        entry.className = member.className
    end

    return true
end


function Database:GetCharacterClass(name)
    if not name
        or name == ""
        or not NLL.db then

        return nil, nil
    end

    local function Normalize(value)
        value = tostring(value or "")
        value =
            string.match(
                value,
                "^([^%-]+)"
            )
            or value

        return string.lower(value)
    end

    local wanted =
        Normalize(name)

    local direct =
        NLL.db.characters[name]

    if type(direct) == "table" then
        return direct.class,
            direct.className
    end

    for characterName, character
        in pairs(
            NLL.db.characters
        ) do

        if type(character) == "table"
            and Normalize(characterName)
                == wanted then

            return character.class,
                character.className
        end
    end

    local roleEntry =
        NLL.db.roleAssignments[name]

    if type(roleEntry) == "table" then
        return roleEntry.class,
            roleEntry.className
    end

    return nil, nil
end

function Database:GetLocalWishlist(characterName, raidKey)
    if not characterName or not raidKey or not NLL.db then
        return nil
    end

    if type(NLL.db.localWishlists[characterName]) ~= "table" then
        NLL.db.localWishlists[characterName] = {}
    end

    if type(NLL.db.localWishlists[characterName][raidKey]) ~= "table" then
        NLL.db.localWishlists[characterName][raidKey] = {}
    end

    return NLL.db.localWishlists[characterName][raidKey]
end

function Database:IsLocallyReserved(characterName, raidKey, itemID)
    local wishlist = self:GetLocalWishlist(characterName, raidKey)
    return wishlist and wishlist[itemID] == true
end

function Database:GetLocalInterest(characterName, raidKey, itemID)
    local wishlist=self:GetLocalWishlist(characterName,raidKey)
    if not wishlist or wishlist[itemID]~=true then return nil end
    local obtained=NLL.db.localWishlistObtained and
        NLL.db.localWishlistObtained[characterName]
    local complete=type(obtained)=="table" and obtained[raidKey]
    if type(complete)=="table" and complete[itemID]==true then
        return "OBTAINED"
    end
    local character=NLL.db.localWishlistGreed and
        NLL.db.localWishlistGreed[characterName]
    local raid=type(character)=="table" and character[raidKey]
    if type(raid)=="table" and raid[itemID]==true then
        return "GREED"
    end
    return "NEEDED"
end

function Database:SetLocalInterest(characterName, raidKey, itemID, status)
    if status~="NEEDED" and status~="GREED" then return false end
    if not self:IsLocallyReserved(characterName,raidKey,itemID) then
        return false
    end
    local all=NLL.db.localWishlistGreed
    if type(all[characterName])~="table" then
        all[characterName]={}
    end
    if type(all[characterName][raidKey])~="table" then
        all[characterName][raidKey]={}
    end
    all[characterName][raidKey][itemID]=(status=="GREED" and true or nil)
    return true
end

function Database:SetLocalReservation(characterName, raidKey, itemID, wanted)
    local wishlist = self:GetLocalWishlist(characterName, raidKey)
    if not wishlist then return false end
    if wanted then
        wishlist[itemID] = true
    else
        wishlist[itemID] = nil
        local character=NLL.db.localWishlistGreed and
            NLL.db.localWishlistGreed[characterName]
        local raid=type(character)=="table" and character[raidKey]
        if type(raid)=="table" then raid[itemID]=nil end
    end
    return true
end

function Database:GetLocalReservationCount(characterName, raidKey)
    local wishlist = self:GetLocalWishlist(characterName, raidKey)
    local count = 0

    if wishlist then
        for itemID, wanted in pairs(wishlist) do
            if wanted then
                count = count + 1
            end
        end
    end

    return count
end


-- ============================================================
-- PHASE 4 CHARACTER / GEAR PLAN HELPERS
-- ============================================================

function Database:SetCharacterType(name, characterType)
    if not name or name == "" or not NLL.db then
        return false
    end

    local character = NLL.db.characters[name]
    if type(character) ~= "table" then
        character = {
            name = name
        }
        NLL.db.characters[name] = character
    end

    character.characterType = characterType
    return true
end

function Database:GetCharacterType(name)
    if not name or not NLL.db then
        return "UNKNOWN"
    end

    local character = NLL.db.characters[name]
    if type(character) == "table" and character.characterType then
        return character.characterType
    end

    return "UNKNOWN"
end
