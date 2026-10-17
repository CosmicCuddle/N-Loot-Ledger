-- Existing player NEED/GREED SavedVariables survive and cannot be resubmitted
-- as NEEDED after confirmed receipt; real GearNeeds still support bots.
local n=0
local function ok(v,s)assert(v,s);n=n+1 end
local name="Leader"
UnitName=function()return name end
NaxxLootLottery={
    databaseVersion=1,
    Print=function()end,Debug=function()end,
    IsValidRole=function()return true end,
    Data={MoltenCore={GetItem=function(_,id)
        if id==16800 or id==18821 then return {itemID=id,name="Loot "..id} end
    end}},
}
local N=NaxxLootLottery
assert(loadfile("NaxxLootLottery/Storage/Database.lua"))()
N.Database:Initialize()
assert(loadfile("NaxxLootLottery/Core/GearNeeds.lua"))()
local d=N.Database
local g=N.GearNeeds
ok(d:SetLocalReservation("Leader","MOLTEN_CORE",18821,true),
    "existing boolean reservation saved")
ok(d:SetLocalInterest("Leader","MOLTEN_CORE",18821,"GREED"),
    "existing Greed choice saved")
ok(d:GetLocalInterest("Leader","MOLTEN_CORE",18821)=="GREED",
    "Greed works before physical item receipt")
local wishlist=N.db.localWishlists.Leader.MOLTEN_CORE
local greed=N.db.localWishlistGreed.Leader.MOLTEN_CORE
ok(d:MarkLocalObtained("Leader","MOLTEN_CORE",18821),
    "recipient's own local item marked Obtained")
ok(d:GetLocalInterest("Leader","MOLTEN_CORE",18821)=="OBTAINED" and
    wishlist[18821]==true and greed[18821]==true,
    "Obtained overrides Need/Greed but preserves original wishlist data")
ok(not d:SetLocalInterest("Leader","MOLTEN_CORE",18821,"NEEDED"),
    "obtained cannot silently be toggled back into Need")
local archive=N.db.localWishlistObtained
N.db=nil
N.Database:Initialize()
ok(d:GetLocalInterest("Leader","MOLTEN_CORE",18821)=="OBTAINED" and
    N.db.localWishlistObtained==archive and
    N.db.localWishlists.Leader.MOLTEN_CORE==wishlist,
    "reload retains obtained flag and untouched boolean wishlist")
-- A re-submission of a previously obtained Player-submitted need must
-- never turn it back into NEED even if interest status says NEED.
local role=nil
local first=g:ReplacePlayerSubmitted("Leader","MOLTEN_CORE",{18821},
    {[18821]="NEEDED"})
ok(first==1,"initial submitted Need accepted")
local key=g:MakeKey("Leader","MOLTEN_CORE",18821,"PLAYER_SUBMITTED")
ok(g:SetStatus(key,"OBTAINED"),"leader can retain verified receipt")
local a=g:ReplacePlayerSubmitted("Leader","MOLTEN_CORE",{18821},
    {[18821]="GREED"})
ok(a==1 and g:GetNeed(key).status=="OBTAINED",
    "legacy resubmission cannot promote Obtained into GREED")
local q=g:ReplacePlayerSubmitted("Leader","MOLTEN_CORE",{16800,18821},
    {[18821]="NEEDED",[16800]="GREED"})
ok(q==2 and g:GetNeed(key).status=="OBTAINED",
    "mixed Need/Greed submission still protects prior Obtained record")
local other=g:MakeKey("Leader","MOLTEN_CORE",16800,"PLAYER_SUBMITTED")
ok(g:GetNeed(other).status=="GREED",
    "other, unreceived player items keep their requested interest")
ok(d:SetLocalReservation("Leader","MOLTEN_CORE",18821,false),
    "explicit user removal of an Obtained wishlist entry allowed")
ok(d:GetLocalInterest("Leader","MOLTEN_CORE",18821)==nil and
    (not archive.Leader.MOLTEN_CORE[18821]),
    "removal clears local Obtained flag, does not edit old receipt audit")
ok(d:SetLocalReservation("Leader","MOLTEN_CORE",18821,true) and
    d:GetLocalInterest("Leader","MOLTEN_CORE",18821)=="NEEDED",
    "explicitly adding a fresh reservation resets its local interest to Need")
print("PASS: "..n.." SavedVariables local Obtained / resubmission protection assertions")
