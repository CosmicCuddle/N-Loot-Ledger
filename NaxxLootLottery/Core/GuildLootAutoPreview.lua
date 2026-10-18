-- Future automatic guild routing: DRY-RUN ONLY, ZERO real transfers.
-- An unreserved item in leader SavedVariables is only a candidate,
-- never proof every remote player's reservations are known.
local NLL=NaxxLootLottery
NLL.GuildLootAutoPreview=NLL.GuildLootAutoPreview or {}
local P=NLL.GuildLootAutoPreview
function P:Build()
    local counts={candidates=0,reserved=0,held=0,blocked=0}
    local rows,message={},nil
    if not NLL.GuildLootReview then
        return {rows=rows,counts=counts,
            message="Guild preview unavailable; no live loot reviewed.",
            automaticTransfers=0}
    end
    local live,reason=NLL.GuildLootReview:Scan()
    message=reason
    local T=NLL.GuildLootTransfer
    local outstanding=T and T.IsUnresolved and T:IsUnresolved()
    for _,entry in ipairs(live or {}) do
        local state,why
        if entry.status=="RESERVED" then
            state="RESERVATION_BLOCKED"
            counts.reserved=counts.reserved+1
            why="Known NEED/GREED reservation; never auto-route"
        elseif entry.status~="GUILD_REVIEW" then
            state="MANUAL_HOLD"
            counts.held=counts.held+1
            why="Pending, unknown, special, locked or incomplete item"
        elseif outstanding then
            state="TRANSFER_HISTORY_BLOCKED"
            counts.blocked=counts.blocked+1
            why="An earlier transfer is unverified; no further requests"
        elseif T and T.WasAttempted and
            T:WasAttempted(entry.itemID,entry.slotIndex) then
            state="PRIOR_ATTEMPT_BLOCKED"
            counts.blocked=counts.blocked+1
            why="Same item and slot attempted before; corpse identity uncertain"
        else
            state="CANDIDATE_ONLY"
            counts.candidates=counts.candidates+1
            why="No known reservation; still needs human roster/recipient review"
        end
        rows[#rows+1]={
            itemID=entry.itemID,itemName=entry.itemName,
            itemLink=entry.itemLink,quantity=entry.quantity,
            slotIndex=entry.slotIndex,leader=entry.leader,
            category=entry.category,status=state,reason=why,
            recipientVerified=false,automaticTransferAuthorized=false
        }
    end
    return {rows=rows,counts=counts,message=message,
        automaticTransfers=0}
end
