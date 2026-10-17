-- AUTO GUILD ROUTING PLANNER -- DRY RUN ONLY.
-- This module cannot transfer an item. It classifies EVERY observed loot
-- slot, including material/reagent links outside the normal gear database.
-- Per-slot Master Loot candidate identity is NOT available without
-- opening each Blizzard dropdown, so NO row can be auto-authorized.
local NLL=NaxxLootLottery
NLL.GuildAutoPreview=NLL.GuildAutoPreview or {}
local P=NLL.GuildAutoPreview
local function Key(name)
    return string.lower((tostring(name or ""):match("^([^%-]+)") or ""))
end
function P:Plan()
    local plan={items={},proposed=0,held=0,reserved=0,uncertain=0,
        special=0,blocked=0,dryRun=true,realTransfers=0,
        automaticTransfersEnabled=false}
    if not NLL.GuildLootReview or not NLL.GuildLootReview.Scan then
        plan.notice="Guild review is unavailable. Zero candidates."
        return plan
    end
    local rows,diagnostic=NLL.GuildLootReview:Scan()
    plan.notice=diagnostic or "No live item slots"
    if #rows==0 then return plan end

    local method,masterIndex
    if type(GetLootMethod)=="function" then
        method,_,masterIndex=GetLootMethod()
    end
    local masterName
    if method=="master" and type(masterIndex)=="number" and
       type(GetRaidRosterInfo)=="function" then
        masterName=GetRaidRosterInfo(masterIndex)
    end
    local acting=UnitName and UnitName("player")
    local masterOK=method=="master" and Key(masterName)~="" and
        Key(masterName)==Key(acting)
    local leader=NLL.GuildLootReview:GetLeader()
    local lottery=NLL.TicketLottery and NLL.TicketLottery.active
    local lotteryBusy=lottery and
        lottery.status~="COMPLETE" and
        lottery.status~="CANCELLED" and
        lottery.status~="INVALIDATED"
    local unresolved=NLL.GuildLootTransfer and
        NLL.GuildLootTransfer.IsUnresolved and
        NLL.GuildLootTransfer:IsUnresolved()
    for _,row in ipairs(rows) do
        local proposal={
            slotIndex=row.slotIndex,itemID=row.itemID,
            itemName=row.itemName,itemLink=row.itemLink,
            quantity=row.quantity,classification=row.category,
            intendedRecipient=leader,originalStatus=row.status,
            recipientVerified=false,candidateVerified=false,
            transferAuthorized=false,physicalAwardRequested=false,
            dryRun=true,
        }
        if row.status=="RESERVED" then
            proposal.decision="HOLD_RESERVED"
            proposal.reason=row.reason
            plan.reserved=plan.reserved+1
        elseif row.status=="SPECIAL_HOLD" then
            proposal.decision="HOLD_SPECIAL"
            proposal.reason=row.reason
            plan.special=plan.special+1
        elseif row.status=="UNRESOLVED" or row.status=="LOCKED" then
            proposal.decision="HOLD_UNCERTAIN"
            proposal.reason=row.reason
            plan.uncertain=plan.uncertain+1
        elseif row.status~="GUILD_REVIEW" then
            proposal.decision="HOLD_UNCLASSIFIED"
            proposal.reason="Unknown loot classification - never assume unreserved"
            plan.uncertain=plan.uncertain+1
        elseif unresolved then
            proposal.decision="HOLD_PRIOR_AWARD"
            proposal.reason="Earlier Master Loot delivery is not independently confirmed"
            plan.blocked=plan.blocked+1
        elseif NLL.GuildLootTransfer and NLL.GuildLootTransfer.WasAttempted and
            NLL.GuildLootTransfer:WasAttempted(row.itemID,row.slotIndex) then
            proposal.decision="HOLD_DUPLICATE"
            proposal.reason="An old attempt used this item+slot; ambiguous corpse identity"
            plan.blocked=plan.blocked+1
        elseif lotteryBusy then
            proposal.decision="HOLD_ACTIVE_ROLL"
            proposal.reason="An NLL ticket lottery is still underway"
            plan.blocked=plan.blocked+1
        elseif not masterOK then
            proposal.decision="HOLD_MASTER_LOOT"
            proposal.reason="Current actor is not the verified WoW Master Looter"
            plan.blocked=plan.blocked+1
        elseif not leader or Key(leader)=="" or
            Key(leader)~=Key(row.leader) then
            proposal.decision="HOLD_LEADER"
            proposal.reason="Raid leader changed or is not uniquely identified"
            plan.blocked=plan.blocked+1
        else
            proposal.decision="PROPOSED_ONLY"
            proposal.reason="No KNOWN reservation. Leader candidate NOT validated."..
                " Human review required; NEVER automatically grant."
            plan.proposed=plan.proposed+1
        end
        if proposal.decision~="PROPOSED_ONLY" then
            plan.held=plan.held+1
        end
        plan.items[#plan.items+1]=proposal
    end
    plan.notice="Dry run: "..plan.proposed.." proposed for manual leader check, "..
        plan.held.." held; ZERO items transferred. Candidate indices unverified."
    return plan
end
