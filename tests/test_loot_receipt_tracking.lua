-- NLL roll winner -> pending -> explicit verified receipt -> OBTAINED.
-- Lua 5.1; all item transfers / actual recipient receipts are simulated.
local checks=0
local function ok(v,why)assert(v,why);checks=checks+1 end
local current="Leader"
UnitName=function()return current end
date=function()return "2026-10-17" end
local debug=false
local leaderAuthority=true
local notices={}
NaxxLootLottery={
    db={
        localWishlists={Leader={MOLTEN_CORE={[18821]=true}}},
        localWishlistGreed={Leader={MOLTEN_CORE={[18821]=true}}},
        localWishlistObtained={},
        lootReceiptTracker={},
        gearNeeds={
            botneed={character="Throgar",itemID=16866,raidKey="MOLTEN_CORE",
                status="NEEDED",source="BOT_GEAR_PLAN",characterType="PLAYERBOT"},
            botgreed={character="Throgar",itemID=16866,raidKey="MOLTEN_CORE",
                status="GREED",source="RAID_LEADER_MANUAL",characterType="PLAYERBOT"},
            sameShortOtherRealm={character="Throgar-OtherRealm",itemID=16866,
                raidKey="MOLTEN_CORE",status="NEEDED",
                source="PLAYER_SUBMITTED",characterType="PLAYER"},
            realmQualifiedLeader={character="Leader-OtherRealm",itemID=18821,
                raidKey="MOLTEN_CORE",status="GREED",
                source="PLAYER_SUBMITTED",characterType="PLAYER"},
            botother={character="Throgar",itemID=18821,raidKey="MOLTEN_CORE",
                status="NEEDED",source="BOT_GEAR_PLAN"},
            otherbot={character="Gorak",itemID=16866,raidKey="MOLTEN_CORE",
                status="NEEDED",source="BOT_GEAR_PLAN"},
            leader={character="Leader",itemID=18821,raidKey="MOLTEN_CORE",
                status="GREED",source="PLAYER_SUBMITTED",characterType="PLAYER"},
            offlineplayer={character="Pikeotter",itemID=16800,raidKey="MOLTEN_CORE",
                status="NEEDED",source="PLAYER_SUBMITTED",characterType="PLAYER"}
        },
        lootAwardHistory={},
    },
    DebugSimulator={IsActive=function()return debug end},
    Print=function(_,v)notices[#notices+1]=v end,
    TicketLottery={AuthorityAllowed=function()return leaderAuthority end},
}
local N=NaxxLootLottery
local refreshes=0
N.UI={gearPlansContent=true,
    RefreshGearPlans=function()refreshes=refreshes+1 end,
    RefreshWishlistPanel=function()end,RefreshCurrentLootPanel=function()end}
local ownStatus={}
N.Database={
    MarkLocalObtained=function(_,character,raid,id)
        ownStatus[character.."|"..raid.."|"..id]=true
        return true
    end
}
assert(loadfile("NaxxLootLottery/Core/LootReceiptTracker.lua"))()
local R=N.LootReceiptTracker
local bot={dropUID="MC1:1:16866",itemID=16866,itemName="Helm of Might",
    raidKey="MOLTEN_CORE",winner="Throgar",selectionType="NEED",status="COMPLETE"}
local actual=N.db.gearNeeds
local ledger=N.db.lootReceiptTracker
ok(R:ObserveWinner(bot),"real bot winner tracked")
ok(ledger[bot.dropUID].status=="WON_AWAITING_ITEM" and
    #ledger[bot.dropUID].needs==2,
    "only the two exact Throgar plans are snapshotted, never Throgar-OtherRealm")
ok(actual.botneed.status=="NEEDED" and actual.botgreed.status=="GREED",
    "winning ticket alone does NOT mark either bot reservation obtained")
local accepted,why=R:CanConfirm(bot.dropUID)
ok(not accepted and why:find("record the award"),
    "roll completion without physical award is not receipt proof")
local winPending=ledger[bot.dropUID]
ok(R:ObserveWinner(bot) and ledger[bot.dropUID]==winPending,
    "repeat event cannot create a second receipt or erase old state")
local corrupt={dropUID=bot.dropUID,itemID=16866,itemName="Helm of Might",
    winner="Gorak",status="COMPLETE"}
ok(not R:ObserveWinner(corrupt),"same drop UID cannot be moved to another winner")
local lookalike={dropUID=bot.dropUID,itemID=16866,itemName="Helm of Might",
    winner="Throgar-OtherRealm",status="COMPLETE"}
ok(not R:ObserveWinner(lookalike) and ledger[bot.dropUID]==winPending,
    "same drop UID may not be claimed by same short name on a different realm")
N.db.lootAwardHistory[#N.db.lootAwardHistory+1]={
    dropUID=bot.dropUID,itemID=16866,winner="Throgar",
    status="AWARD_REQUESTED"
}
accepted,why=R:CanConfirm(bot.dropUID)
ok(not accepted,"GiveMasterLoot request alone is insufficient")
N.db.lootAwardHistory[#N.db.lootAwardHistory].status="LOOT_SLOT_CLEARED"
N.db.lootAwardHistory[#N.db.lootAwardHistory].winner="Throgar-OtherRealm"
local aliasOK,aliasReason=R:CanConfirm(bot.dropUID)
ok(not aliasOK and aliasReason:find("record the award",1,true) and
   winPending.status=="WON_AWAITING_ITEM",
   "another realm's short-name lookalike cannot validate physical receipt")
N.db.lootAwardHistory[#N.db.lootAwardHistory].winner="Throgar"
current="Leader-OtherRealm"
leaderAuthority=false
local aliasAuthority,authReason=R:CanConfirm(bot.dropUID)
ok(not aliasAuthority and
   authReason:find("authority",1,true) and
   winPending.status=="WON_AWAITING_ITEM",
   "different realm's short-name lookalike cannot inherit original leader authority")
current="Leader"
leaderAuthority=true
ok(R:CanConfirm(bot.dropUID),"slot cleared allows separate manual receipt confirmation")
-- Simulate human recipient check; no award is sent by this call.
local committed,message=R:ConfirmReceipt(bot.dropUID)
ok(committed and message:find("2 active Gear Plan"),
    "confirmed bot receipt updates two matching reservations")
ok(actual.botneed.status=="OBTAINED" and
    actual.botgreed.status=="OBTAINED" and
    actual.botneed.obtainedDropUID==bot.dropUID,
    "bot NEED and GREED each transition to OBTAINED")
ok(actual.botother.status=="NEEDED" and
    actual.otherbot.status=="NEEDED" and
    actual.leader.status=="GREED" and
    actual.sameShortOtherRealm.status=="NEEDED",
    "receipt for Throgar cannot mark Throgar-OtherRealm or unrelated wishes")
ok(winPending.status=="OBTAINED" and
    winPending.evidence=="LEADER_CONFIRMED_RECIPIENT_INVENTORY" and
    winPending.confirmedBy=="Leader","receipt audit records human assertion")
ok(not R:ConfirmReceipt(bot.dropUID),"same item cannot be confirmed twice")
ok(N.db.gearNeeds==actual and N.db.lootReceiptTracker==ledger,
    "same Gear Plan and receipt tables preserved, no full rewrite")
local fake={dropUID="TEST:1:16800",itemID=16800,
    winner="Pikeotter",status="COMPLETE",test=true}
ok(not R:ObserveWinner(fake) and ledger[fake.dropUID]==nil,
    "fake winners do not change real reservation history")
local other={dropUID="MC1:2:16800",itemID=16800,
    winner="Pikeotter",raidKey="MOLTEN_CORE",
    selectionType="GREED",status="COMPLETE"}
ok(R:ObserveWinner(other),"separate real player winning GREED recognized")
N.db.lootAwardHistory[#N.db.lootAwardHistory+1]={
    dropUID=other.dropUID,itemID=16800,winner="Pikeotter",
    status="LEADER_REPORTED"
}
local previousRefresh=refreshes
ok(R:ConfirmReceipt(other.dropUID),"explicit receipt for offline player")
ok(actual.offlineplayer.status=="OBTAINED",
    "leader-side PLAYER_SUBMITTED Gear Need becomes obtained")
ok(not ownStatus["Pikeotter|MOLTEN_CORE|16800"],
    "leader may NOT pretend to edit another player's client")
ok(refreshes>previousRefresh,"leader UI refreshes receipt status")
local personal={dropUID="MC1:3:18821",itemID=18821,
    winner="Leader",itemName="Quick Strike Ring",
    raidKey="MOLTEN_CORE",selectionType="GREED",status="COMPLETE"}
ok(R:ObserveWinner(personal),"same-account owner tracked")
N.db.lootAwardHistory[#N.db.lootAwardHistory+1]={
    dropUID=personal.dropUID,itemID=18821,winner="Leader",
    status="LEADER_REPORTED"
}
ok(R:ConfirmReceipt(personal.dropUID),"player checked own inventory")
ok(actual.leader.status=="OBTAINED" and
    ownStatus["Leader|MOLTEN_CORE|18821"] and
    actual.realmQualifiedLeader.status=="GREED",
    "local player mirrors only the exact name; other-realm Gear Plan preserved")
local separateRealm={dropUID="MC1:3:18821:OtherRealm",itemID=18821,
    winner="Leader-OtherRealm",itemName="Quick Strike Ring",
    raidKey="MOLTEN_CORE",selectionType="GREED",status="COMPLETE"}
ok(R:ObserveWinner(separateRealm) and
    #ledger[separateRealm.dropUID].needs==1,
    "a qualified-name winner snapshots only its own exact Gear Plan")
N.db.lootAwardHistory[#N.db.lootAwardHistory+1]={
    dropUID=separateRealm.dropUID,itemID=18821,winner="Leader-OtherRealm",
    status="LEADER_REPORTED"
}
ok(R:ConfirmReceipt(separateRealm.dropUID) and
    actual.realmQualifiedLeader.status=="OBTAINED" and
    actual.realmQualifiedLeader.obtainedDropUID==separateRealm.dropUID and
    not ownStatus["Leader-OtherRealm|MOLTEN_CORE|18821"],
    "separate realm's receipt cannot update this client's local wishlist")
local blocked={dropUID="MC1:4:16866",itemID=16866,
    winner="Gorak",status="COMPLETE",raidKey="MOLTEN_CORE"}
ok(R:ObserveWinner(blocked),"independent second winner recorded pending")
N.db.lootAwardHistory[#N.db.lootAwardHistory+1]={
    dropUID=blocked.dropUID,itemID=16866,winner="Gorak",
    status="LEADER_REPORTED"
}
actual.otherbot.status="DISABLED"
accepted,why=R:ConfirmReceipt(blocked.dropUID)
ok(not accepted and why:find("changed since"),
    "manual status drift refuses confirmation without overwriting a plan")
ok(actual.otherbot.status=="DISABLED" and
    ledger[blocked.dropUID].status=="WON_AWAITING_ITEM",
    "failed confirmation changes nothing")
-- Persistence after /reload: records are still present; caller's
-- Database.Initialize retains these existing tables.
local oldBook=N.db.lootReceiptTracker
local oldGear=N.db.gearNeeds
ok(oldBook==ledger and oldGear==actual and
    R:Get(bot.dropUID).status=="OBTAINED",
    "serialized receipt state and all statuses survive unchanged")
print("PASS: "..checks.." real winner pending / bot-player OBTAINED / safeguards assertions")
