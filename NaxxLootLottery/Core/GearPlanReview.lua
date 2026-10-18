-- NLL guarded, item-specific edit/remove review for existing BOT_GEAR_PLAN rows.
-- No AddNeed: that would silently rewrite shared role/type assignments.
-- Never permit manual OBTAINED; only independent recipient receipt can do so.
local NLL=NaxxLootLottery
NLL.GearPlanReview=NLL.GearPlanReview or {}
local R=NLL.GearPlanReview
R.armed=nil
local MAX_AGE=15
local function Now()return GetTime and GetTime() or nil end
local function Actor()return UnitName and UnitName("player") or nil end
local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function Active()
    -- Do not rely solely on the import/loot guard implementation: a
    -- simulator cannot certify the real actor's receipt or inventory.
    if NLL.DebugSimulator and NLL.DebugSimulator.IsActive and
       NLL.DebugSimulator:IsActive() then
        return false,"Stop the Debug Lab before changing real Gear Plans."
    end
    if not NLL.db or type(NLL.db.gearNeeds)~="table" then
        return false,"Gear Plans database unavailable."
    end
    if not NLL.GearPlanTransfer or not NLL.GearPlanTransfer.IsBlocked then
        return false,"Safe edit controls unavailable."
    end
    local blocked,why=NLL.GearPlanTransfer:IsBlocked()
    if blocked then return false,why end
    if type(Now())~="number" then
        return false,"WoW monotonic clock unavailable."
    end
    if type(Actor())~="string" or Actor()=="" then
        return false,"Verified acting player unavailable."
    end
    return true
end
local function Outstanding(row)
    local char=Key(row.character)
    local item=tonumber(row.itemID)
    -- Any retained recipient receipt without an independent completed
    -- delivery must block edits, even if the old Gear Plan disappeared.
    for _,receipt in pairs(NLL.db.lootReceiptTracker or {}) do
        if type(receipt)=="table" and tonumber(receipt.itemID)==item and
           Key(receipt.character)==char and
           (receipt.status~="OBTAINED" or
            (receipt.remoteSyncStatus and
             receipt.remoteSyncStatus~="ACKNOWLEDGED")) then
            return true
        end
    end
    for _,history in ipairs(NLL.db.lootAwardHistory or {}) do
        if type(history)=="table" and tonumber(history.itemID)==item and
           Key(history.winner)==char and
           history.status~="CANCELLED" and
           history.status~="INVALIDATED" then
            -- Do not treat a cleared loot slot or closed investigation as
            -- a recipient receipt. Conservatively keep winner plans held.
            local receipt=NLL.db.lootReceiptTracker and
                NLL.db.lootReceiptTracker[history.dropUID]
            if not receipt or receipt.status~="OBTAINED" then
                return true
            end
        end
    end
    return false
end
local function Fingerprint(gear)
    local all={}
    for k,row in pairs(gear or {}) do
        if type(row)~="table" then return nil end
        all[#all+1]=tostring(k).."="..
            tostring(row.key)..":"..tostring(row.character)..":"..
            tostring(row.itemID)..":"..tostring(row.raidKey)..":"..
            tostring(row.role)..":"..tostring(row.source)..":"..
            tostring(row.characterType)..":"..tostring(row.status)
    end
    table.sort(all)
    return table.concat(all,"\n")
end
function R:Cancel()self.armed=nil end
function R:CanEdit(key,action,newStatus)
    local allowed,why=Active()
    if not allowed then return false,why end
    if type(key)~="string" or key=="" then
        return false,"Select an existing Gear Plan."
    end
    local row=NLL.db.gearNeeds[key]
    if type(row)~="table" or row.source~="BOT_GEAR_PLAN" or
       row.characterType~="PLAYERBOT" or
       row.raidKey~="MOLTEN_CORE" or
       type(row.character)~="string" or
       type(row.itemID)~="number" or
       not NLL.GearNeeds or
       NLL.GearNeeds:MakeKey(row.character,row.raidKey,row.itemID,row.source)~=key then
        return false,"Only a valid existing Playerbot Gear Plan may be reviewed."
    end
    if row.status=="OBTAINED" then
        return false,"OBTAINED is receipt evidence; manual editing/removal is blocked."
    end
    if Outstanding(row) then
        return false,"A winner/recipient receipt is outstanding. Preserve this Gear Plan."
    end
    if action=="STATUS" then
        if newStatus~="NEEDED" and newStatus~="GREED" and
           newStatus~="DISABLED" then
            return false,"Manual OBTAINED is forbidden; use recipient receipt review."
        end
        if row.status==newStatus then
            return false,"Already "..newStatus.."; no change necessary."
        end
    elseif action~="REMOVE" then
        return false,"Unknown review action."
    end
    local stamp=Fingerprint(NLL.db.gearNeeds)
    if not stamp then return false,"Saved Gear Plan table is inconsistent." end
    return true,row,stamp
end
function R:Arm(key,action,newStatus)
    self:Cancel()
    local ok,row,stamp=self:CanEdit(key,action,newStatus)
    if not ok then return false,row end
    self.armed={
        key=key,action=action,newStatus=newStatus,reference=row,
        snapshot=stamp,oldStatus=row.status,character=row.character,
        itemID=row.itemID,actor=Actor(),started=Now(),
    }
    return true,"REVIEW "..row.character.." item "..row.itemID..": "..
        (action=="REMOVE" and "REMOVE existing bot plan" or
         (row.status.." -> "..newStatus))..
        ". Confirm within 15 seconds. No changes have been made."
end
function R:Confirm()
    local armed=self.armed
    self:Cancel()
    local now=Now()
    if not armed or type(now)~="number" or
       now<armed.started or now-armed.started>MAX_AGE then
        return false,"Review missing/expired. Nothing was changed."
    end
    if Actor()~=armed.actor then
        return false,"Review actor changed; nothing was changed."
    end
    local ok,row,stamp=self:CanEdit(armed.key,armed.action,armed.newStatus)
    if not ok then return false,row end
    if row~=armed.reference or stamp~=armed.snapshot or
       row.status~=armed.oldStatus or row.itemID~=armed.itemID or
       row.character~=armed.character then
        return false,"Saved Gear Plans changed after review; nothing was changed."
    end
    if armed.action=="STATUS" then
        row.status=armed.newStatus
        return true,"Updated only "..row.character.." item "..row.itemID..
            " to "..row.status..". Winner receipts and role data unchanged."
    end
    NLL.db.gearNeeds[armed.key]=nil
    return true,"Removed only the explicitly reviewed bot plan "..
        armed.character.." item "..armed.itemID..
        ". Receipt, lottery, global roles and history unchanged."
end
