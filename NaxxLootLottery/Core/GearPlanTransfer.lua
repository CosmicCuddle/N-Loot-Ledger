-- Naxxramas Loot Ledger / WoW 3.3.5a Lua 5.1.
-- Copy/paste Gear Plan import/export. No file I/O, network, gear award or
-- migration. Import changes only NEW BOT_GEAR_PLAN records after confirmation.
local NLL=NaxxLootLottery
NLL.GearPlanTransfer=NLL.GearPlanTransfer or {}
local T=NLL.GearPlanTransfer
T.HEADER="NLL-GEARPLANS-1"
T.MAX_ROWS=250
T.MAX_BYTES=48000

local function Trim(s)
    return (tostring(s or ""):match("^%s*(.-)%s*$") or "")
end
-- WoW 3.3.5a uses Lua 5.1, where %a is byte/locale based rather
-- than Unicode-aware. Validate UTF-8 bytes explicitly so characters such
-- as TangØ (C3 98) survive *unchanged* instead of being renamed to TangO.
-- Limit this first importer to ASCII/Latin-1 letters and interior hyphens.
-- Other scripts fail closed rather than accepting arbitrary invalid UTF-8.
local function SafeName(s)
    if type(s)~="string" or #s<2 or #s>80 then return false end
    local i,count=1,0
    while i<=#s do
        local b=s:byte(i)
        local letter=(b>=65 and b<=90) or (b>=97 and b<=122)
        if letter then
            i=i+1
        elseif b==45 and count>0 and i<#s then
            -- Hyphen allowed only inside a character name.
            i=i+1
        elseif b==195 then
            local nextByte=s:byte(i+1)
            if not nextByte or not
                ((nextByte>=128 and nextByte<=150) or
                 (nextByte>=152 and nextByte<=182) or
                 (nextByte>=184 and nextByte<=191)) then
                return false
            end
            i=i+2
        else
            return false
        end
        count=count+1
        if count>40 then return false end
    end
    return count>=2
end
local function Fields(line)
    local cells={}
    -- Capture empty fields too; do not let a missing status shift columns.
    for value in (line.."|"):gmatch("(.-)|") do
        cells[#cells+1]=value
    end
    return cells
end
local function SortRows(a,b)
    local ca,cb=string.lower(a.character),string.lower(b.character)
    if ca~=cb then return ca<cb end
    if a.itemID~=b.itemID then return a.itemID<b.itemID end
    return a.status<b.status
end
local function Existing()
    if not NLL.db or type(NLL.db.gearNeeds)~="table" then
        return nil,"Gear Plans database not ready."
    end
    return NLL.db.gearNeeds
end
local function Valid(row)
    local G=NLL.GearNeeds
    if row.characterType~="PLAYERBOT" or row.source~="BOT_GEAR_PLAN" then
        return false,"Only Playerbot BOT_GEAR_PLAN records are supported."
    end
    if not SafeName(row.character) then
        return false,"Invalid character name (2-40 letters; hyphens allowed)."
    end
    if row.raidKey~="MOLTEN_CORE" then
        return false,"Only Molten Core plans are supported."
    end
    if row.role=="-" then row.role=nil end
    if not row.role or not NLL.roleLabels[row.role] then
        return false,"A known Raid Role is required."
    end
    if not G:IsValidStatus(row.status) then
        return false,"Invalid interest/status."
    end
    if row.copyIndex~="1" then
        return false,"Multi-copy import is not enabled; copy index must be 1."
    end
    if not row.itemID or row.itemID<1 or row.itemID>999999 or
       row.itemID%1~=0 or
       not NLL.Data.MoltenCore:GetItem(row.itemID) then
        return false,"Unknown/invalid Molten Core Item ID."
    end
    return true
end
local function Snapshot()
    local gear=Existing()
    if not gear then return nil end
    local parts={}
    -- Snapshot *all* Gear Needs, not only bot records. No other source can
    -- be silently overwritten between preview and Confirm.
    for key,row in pairs(gear) do
        if type(row)=="table" then
            parts[#parts+1]=tostring(key).."="..
                tostring(row.character)..":"..tostring(row.itemID)..":"..
                tostring(row.raidKey)..":"..tostring(row.role)..":"..
                tostring(row.status)..":"..tostring(row.source)..":"..
                tostring(row.characterType)
        else
            parts[#parts+1]=tostring(key).."=INVALID:"..tostring(row)
        end
    end
    table.sort(parts)
    return table.concat(parts,"\n")
end
local function Matching(saved,row)
    return saved.character==row.character and
        saved.itemID==row.itemID and
        saved.raidKey==row.raidKey and
        saved.role==row.role and
        saved.status==row.status and
        saved.source==row.source and
        saved.characterType==row.characterType
end
function T:IsBlocked()
    if NLL.DebugSimulator and NLL.DebugSimulator:IsActive() then
        return true,"Stop the Debug Lab before importing real Gear Plans."
    end
    local active=NLL.TicketLottery and NLL.TicketLottery.active
    if active and active.status and active.status~="COMPLETE" then
        return true,"A lottery is active; finish/cancel before importing."
    end
    if NLL.LootDetection and NLL.LootDetection.lootOpen then
        return true,"Close the real loot window before importing."
    end
    if GetNumRaidMembers and (GetNumRaidMembers() or 0)>0 and
       not ((IsRaidLeader and IsRaidLeader()) or
            (IsRaidOfficer and IsRaidOfficer())) then
        return true,"Only the raid leader/officer can import while in a raid."
    end
    return false
end
function T:Export()
    local gear,errorText=Existing()
    if not gear then return nil,errorText end
    local rows={}
    for key,need in pairs(gear) do
        if type(need)=="table" and
           (need.source=="BOT_GEAR_PLAN" or
            need.characterType=="PLAYERBOT" and need.source==nil) then
            -- Never silently omit invalid records or pretend unknown data
            -- roundtrips successfully.
            local row={
                character=need.character,
                characterType=need.characterType,
                role=need.role,
                raidKey=need.raidKey,
                itemID=need.itemID,
                source=need.source,
                status=need.status,
                copyIndex="1"
            }
            local valid,why=Valid(row)
            if not valid then
                return nil,"Cannot export "..tostring(key)..": "..why
            end
            local expected=NLL.GearNeeds:MakeKey(
                row.character,row.raidKey,row.itemID,row.source)
            if key~=expected then
                return nil,"Stored Gear Plan key is inconsistent: "..tostring(key)
            end
            rows[#rows+1]=row
        end
    end
    if #rows>self.MAX_ROWS then
        return nil,"Too many bot plans to export in one chunk ("..
            #rows.." / "..self.MAX_ROWS..")."
    end
    table.sort(rows,SortRows)
    local out={self.HEADER}
    for _,row in ipairs(rows) do
        out[#out+1]=table.concat({
            row.character,row.characterType,row.role,row.raidKey,
            tostring(row.itemID),row.source,row.status,row.copyIndex},"|")
    end
    local text=table.concat(out,"\n")
    if #text>self.MAX_BYTES then
        return nil,"Export exceeds the text-size limit; split into batches."
    end
    return text,#rows
end
function T:Parse(text)
    if type(text)~="string" or #text>self.MAX_BYTES then
        return nil,"Paste is missing or larger than 48,000 bytes."
    end
    text=text:gsub("\r\n","\n"):gsub("\r","\n")
    if text:find("[%z\1-\8\11\12\14-\31]") then
        return nil,"Paste contains unsupported control characters."
    end
    local lines={}
    for line in (text.."\n"):gmatch("(.-)\n") do
        if #line>512 then return nil,"A line exceeds 512 characters." end
        if Trim(line)~="" then lines[#lines+1]=Trim(line) end
    end
    if lines[1]~=self.HEADER then
        return nil,"Wrong file format. First line must be "..self.HEADER.."."
    end
    if #lines-1>self.MAX_ROWS then
        return nil,"More than "..self.MAX_ROWS.." plans; split the paste."
    end
    local rows,seen={},{}
    for lineNo=2,#lines do
        local fields=Fields(lines[lineNo])
        if #fields~=8 then
            return nil,"Line "..lineNo.." needs exactly eight | fields."
        end
        local rawID=fields[5]
        if not rawID:match("^%d+$") then
            return nil,"Line "..lineNo.." has an invalid Item ID."
        end
        local row={
            character=fields[1],characterType=fields[2],
            role=fields[3],raidKey=fields[4],itemID=tonumber(rawID),
            source=fields[6],status=fields[7],copyIndex=fields[8]
        }
        local valid,why=Valid(row)
        if not valid then return nil,"Line "..lineNo..": "..why end
        local key=NLL.GearNeeds:MakeKey(
            row.character,row.raidKey,row.itemID,row.source)
        if seen[key] then
            return nil,"Line "..lineNo.." repeats the same character/item/source."
        end
        seen[key]=true
        row.key=key
        rows[#rows+1]=row
    end
    if #rows==0 then
        return nil,"No plans supplied. Header-only paste cannot import anything."
    end
    return rows
end
function T:Preview(text)
    local gear,why=Existing()
    if not gear then return nil,why end
    local blocked,reason=self:IsBlocked()
    if blocked then return nil,reason end
    local rows,errorText=self:Parse(text)
    if not rows then return nil,errorText end
    local preview={
        sourceText=text,rows={},additions={},unchanged=0,
        conflicts={},newCount=0,currentSnapshot=Snapshot(),used=false
    }
    for _,row in ipairs(rows) do
        local saved=gear[row.key]
        if saved==nil then
            preview.additions[#preview.additions+1]=row
            preview.newCount=preview.newCount+1
        elseif type(saved)=="table" and Matching(saved,row) then
            preview.unchanged=preview.unchanged+1
        else
            preview.conflicts[#preview.conflicts+1]={
                character=row.character,itemID=row.itemID,key=row.key}
        end
        preview.rows[#preview.rows+1]=row
    end
    preview.ready=#preview.conflicts==0 and preview.newCount>0
    return preview
end
function T:Summary(p)
    if not p then return "No preview." end
    local result="Parsed "..#p.rows.." plans: "..p.newCount.." NEW, "..
        p.unchanged.." already identical, "..#p.conflicts.." CONFLICTS."
    if #p.conflicts>0 then
        local first=p.conflicts[1]
        return result.."\nBLOCKED: existing "..first.character..
            " / item "..first.itemID.." differs. Nothing will be overwritten."
    end
    if p.newCount==0 then
        return result.."\nNo changes needed. Import cannot be applied."
    end
    return result.."\nPreview only. Confirm to ADD the new plans. "..
        "Existing plans, raid roles and history are left untouched."
end
function T:Apply(preview,currentText)
    if type(preview)~="table" or preview.used or not preview.ready or
       type(currentText)~="string" or currentText~=preview.sourceText then
        return false,"Paste or preview changed. Preview again before confirming."
    end
    local blocked,why=self:IsBlocked()
    if blocked then return false,why end
    if Snapshot()~=preview.currentSnapshot then
        return false,"Saved Gear Plans changed since preview. Preview again."
    end
    -- Re-parse/re-validate source at the confirmation boundary, then ensure
    -- the exact batch and expected additions still agree.
    local verified,errorText=self:Preview(currentText)
    if not verified or not verified.ready or
       verified.newCount~=preview.newCount or
       verified.unchanged~=preview.unchanged or
       #verified.conflicts>0 or
       verified.currentSnapshot~=preview.currentSnapshot then
        return false,errorText or "Candidate plans changed. Preview again."
    end
    local gear=Existing()
    for _,row in ipairs(verified.additions) do
        if gear[row.key]~=nil then
            return false,"A plan was added while confirming. Preview again."
        end
    end
    -- Apply is synchronous and add-only. Do NOT call AddNeed here: it also
    -- rewrites global raid role/type assignments, which an import must not do.
    for _,row in ipairs(verified.additions) do
        gear[row.key]={
            key=row.key,character=row.character,itemID=row.itemID,
            raid="Molten Core",raidKey=row.raidKey,role=row.role,
            status=row.status,source=row.source,
            characterType=row.characterType
        }
    end
    preview.used=true
    return true,"Added "..#verified.additions.." Playerbot Gear Plans. "..
        verified.unchanged.." identical plan(s) left unchanged. "..
        "No existing plans, raid roles or loot history changed."
end
