-- NLL receipt sync: OPTIONAL human-to-human notification, NEVER an award.
-- WoW 3.3.5a addon whispers have no cryptographic authentication. The
-- recipient must be in the same raid as the current leader AND explicitly
-- confirm the item in their OWN inventory before local status changes.
-- This module never touches someone else's SavedVariables or GiveMasterLoot.
local NLL=NaxxLootLottery
NLL.ReceiptSync=NLL.ReceiptSync or {}
local S=NLL.ReceiptSync
S.protocol="R1"
local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
local function LocalName()return UnitName and UnitName("player") or nil end
local function Book()
    return NLL.db and NLL.db.localReceiptSyncPending
end
local function Acks()
    return NLL.db and NLL.db.localReceiptSyncDone
end
local function ReceiptID(sender,dropUID)
    return Key(sender)..":"..tostring(dropUID or "")
end
local function ValidDrop(uid,itemID)
    return type(uid)=="string" and #uid<=64 and
        uid:match("^L%d+:%d+:%d+$") and
        tonumber(uid:match(":(%d+)$"))==itemID
end
local function Tell(message)
    if NLL.Print then NLL:Print(message) end
end
function S:IsTrustedLeader(sender)
    local C=NLL.Communication
    if not C or not C.IsSenderCurrentRaidLeader or
       not C:IsSenderCurrentRaidLeader(sender) or
       not C:IsSenderInRaid(sender) then return false end
    -- Refuse split/ambiguous raid leadership before ever offering a
    -- player-controlled SavedVariables write. CHAT_MSG_ADDON sender names
    -- alone are not cryptographic proof of item delivery.
    if not GetNumRaidMembers or not GetRaidRosterInfo then return false end
    local leaders=0
    for i=1,(GetNumRaidMembers() or 0) do
        local _,rank=GetRaidRosterInfo(i)
        if rank==2 then leaders=leaders+1 end
    end
    return leaders==1
end
function S:EligibleHuman(row)
    if not row or type(row.needs)~="table" or
       Key(row.character)=="" then return false end
    for _,snapshot in ipairs(row.needs) do
        local need=NLL.db and NLL.db.gearNeeds and
            NLL.db.gearNeeds[snapshot.key]
        if type(need)=="table" and
            (need.source=="PLAYER_SUBMITTED" or
             need.characterType=="PLAYER") and
            Key(need.character)==Key(row.character) then return true end
    end
    return false
end
function S:SendConfirmed(row)
    if not row or row.status~="OBTAINED" or
       not ValidDrop(row.dropUID,tonumber(row.itemID)) or
       not self:EligibleHuman(row) or not NLL.Communication or
       not NLL.Communication:IsSelfRaidLeader() then
        return false,"Only a current leader can notify a verified human recipient."
    end
    local recipient=Key(row.character)
    if recipient==Key(LocalName()) then
        return false,"This was the leader's own local wishlist."
    end
    if not NLL.Communication:IsSenderInRaid(row.character) then
        row.remoteSyncStatus="WAITING_FOR_PLAYER"
        return false,"Winner not currently in raid. Retry when they return."
    end
    if row.remoteSyncStatus=="ACKNOWLEDGED" then
        return false,"Player already confirmed this receipt."
    end
    local msg="R1|OBTAINED|"..row.dropUID.."|"..
        tostring(row.itemID).."|"..row.raidKey.."|"..row.character
    local sent=NLL.Communication:SendWhisper(row.character,msg)
    if not sent then
        row.remoteSyncStatus="SEND_FAILED"
        return false,"Addon receipt whisper could not be sent."
    end
    row.remoteSyncStatus="AWAITING_PLAYER"
    row.remoteSyncSentAt=date and date("%Y-%m-%d %H:%M:%S") or "unknown"
    return true,"Receipt confirmation offered to "..row.character..
        "; waiting for their own inventory acknowledgement."
end
function S:OnLeaderConfirmed(row)
    if not self:EligibleHuman(row) then return end
    local sent,notice=self:SendConfirmed(row)
    if not sent or notice then Tell("NLL receipt sync: "..tostring(notice)) end
end
function S:HandleReceipt(sender,fields)
    if #fields~=6 or not self:IsTrustedLeader(sender) then return false end
    if not Book() or not Acks() or
       (NLL.DebugSimulator and NLL.DebugSimulator:IsActive()) then
        return false
    end
    local uid,itemID,raidKey,recipient=fields[3],tonumber(fields[4]),fields[5],fields[6]
    if raidKey~="MOLTEN_CORE" or
       not itemID or itemID%1~=0 or
       not ValidDrop(uid,itemID) or
       Key(recipient)~=Key(LocalName()) then return false end
    local person=LocalName()
    local key=ReceiptID(sender,uid)
    local already=Acks()[key]
    if already then
        -- An ACK whisper may be lost while the leader still has the
        -- original receipt pending. An identical replay can re-send only
        -- the ACK, never mark a second item OBTAINED.
        if already.itemID==itemID and
           Key(already.leader)==Key(sender) and
           NLL.Communication and NLL.Communication.SendWhisper then
            return NLL.Communication:SendWhisper(sender,
                "R1|ACK|"..uid.."|"..itemID.."|"..raidKey)
        end
        return false
    end
    if not NLL.Database or not NLL.Database.GetLocalInterest then return false end
    local current=NLL.Database:GetLocalInterest(person,raidKey,itemID)
    if current=="OBTAINED" then return false end
    if current~="NEEDED" and current~="GREED" then
        -- No unsolicited wishlist entries, even from a valid raid leader.
        return false
    end
    local previous=Book()[key]
    if previous then
        return previous.itemID==itemID and
            Key(previous.recipient)==Key(recipient)
    end
    Book()[key]={
        key=key,leader=sender,recipient=person,dropUID=uid,
        itemID=itemID,raidKey=raidKey,
        interestAtOffer=current,status="AWAITING_PLAYER",
        receivedAt=date and date("%Y-%m-%d %H:%M:%S") or "unknown",
    }
    Tell("NLL: Raid leader reports an award for item "..itemID..
        ". Open My Wishlist > Receipt Inbox; check YOUR inventory before confirming.")
    if NLL.UI and NLL.UI.RefreshWishlistPanel then
        NLL.UI:RefreshWishlistPanel()
    end
    return true
end
function S:GetPendingForLocal()
    local rows,person={},Key(LocalName())
    for key,row in pairs(Book() or {}) do
        if type(row)=="table" and row.status=="AWAITING_PLAYER" and
            Key(row.recipient)==person then
            row.key=key
            rows[#rows+1]=row
        end
    end
    table.sort(rows,function(a,b)return a.key<b.key end)
    return rows
end
function S:CanAccept(key)
    local record=Book() and Book()[key]
    if not record or record.status~="AWAITING_PLAYER" then
        return false,"Receipt offer missing or already handled."
    end
    if not self:IsTrustedLeader(record.leader) or
       Key(record.recipient)~=Key(LocalName()) or
       not ValidDrop(record.dropUID,record.itemID) then
        return false,"Original raid leader/recipient not currently verified."
    end
    local interest=NLL.Database and NLL.Database.GetLocalInterest and
        NLL.Database:GetLocalInterest(
            LocalName(),record.raidKey,record.itemID)
    if interest~=record.interestAtOffer or
       (interest~="NEEDED" and interest~="GREED") then
        return false,"Local reservation has changed. Nothing marked obtained."
    end
    if Acks() and Acks()[key] then
        return false,"Receipt already confirmed."
    end
    return true,record
end
function S:Accept(key)
    local ok,row=self:CanAccept(key)
    if not ok then return false,row end
    -- This is ONLY called on a real user click after independent inventory
    -- verification, NEVER in HandleReceipt or a background event.
    if not NLL.Database:MarkLocalObtained(
        LocalName(),row.raidKey,row.itemID) then
        return false,"Your current wishlist no longer contains this item."
    end
    local done=Acks()
    done[key]={
        dropUID=row.dropUID,itemID=row.itemID,leader=row.leader,
        confirmedAt=date and date("%Y-%m-%d %H:%M:%S") or "unknown",
        confirmation="PLAYER_CHECKED_OWN_INVENTORY",
    }
    Book()[key]=nil
    local msg="R1|ACK|"..row.dropUID.."|"..
        row.itemID.."|"..row.raidKey
    local sent=NLL.Communication:SendWhisper(row.leader,msg)
    done[key].leaderAckSent=sent==true
    if NLL.UI and NLL.UI.RefreshWishlistPanel then
        NLL.UI:RefreshWishlistPanel()
    end
    return true,"Your own wishlist now shows OBTAINED. "..
        (sent and "Leader was notified." or
        "Leader notification failed; local confirmation is still saved.")
end
function S:HandleAck(sender,fields)
    if #fields~=5 or not NLL.Communication or
        not NLL.Communication:IsSelfRaidLeader() or
        not NLL.Communication:IsSenderInRaid(sender) then return false end
    local uid,itemID,raidKey=fields[3],tonumber(fields[4]),fields[5]
    if raidKey~="MOLTEN_CORE" or
       not itemID or not ValidDrop(uid,itemID) then return false end
    local row=NLL.LootReceiptTracker and
        NLL.LootReceiptTracker:Get(uid)
    if not row or row.status~="OBTAINED" or
       row.itemID~=itemID or row.raidKey~=raidKey or
       Key(row.character)~=Key(sender) or
       (row.remoteSyncStatus~="AWAITING_PLAYER" and
        row.remoteSyncStatus~="ACKNOWLEDGED") then return false end
    row.remoteSyncStatus="ACKNOWLEDGED"
    row.remoteSyncAcknowledgedAt=date and
        date("%Y-%m-%d %H:%M:%S") or "unknown"
    Tell("NLL: "..row.character..
        " confirmed their own OBTAINED wishlist status for item "..itemID..".")
    return true
end
function S:HandleMessage(sender,fields,channel)
    if channel~="WHISPER" or fields[1]~="R1" then return false end
    if fields[2]=="OBTAINED" then
        return self:HandleReceipt(sender,fields)
    elseif fields[2]=="ACK" then
        return self:HandleAck(sender,fields)
    end
    return false
end
function S:RetryFor(dropUID)
    local row=NLL.LootReceiptTracker and NLL.LootReceiptTracker:Get(dropUID)
    if not row then return false,"No recorded loot receipt with that drop UID." end
    return self:SendConfirmed(row)
end
