-- UI placement regression for the 17 October 2026 overlapping New Drop hotfix.
-- Static layout guard; WoW still requires a visual acceptance screenshot.
local source=assert(io.open('NaxxLootLottery/UI/CurrentLootFrame.lua','rb')):read('*a')
local assertions=0
local function ok(v,why) assert(v,why); assertions=assertions+1 end
local width=tonumber(source:match("dropsHeader:SetWidth%(%s*(%d+)%s*%)"))
local headerOffset=tonumber(source:match('dropsHeader:SetPoint%(%s*"TOPLEFT",%s*panel,%s*"TOPLEFT",%s*(%d+),'))
local buttonWidth=tonumber(source:match("CreateTextButton%(%s*panel,%s*'New Drop',%s*(%d+)%)"))
local rightOffset=tonumber(source:match("newDrop:SetPoint%('TOPRIGHT',%s*dropsHeader,%s*'TOPRIGHT',%s*([%-]?%d+),%s*0%)"))
local pagerX=tonumber(source:match('back:SetPoint%("BOTTOMLEFT",%s*panel,%s*"BOTTOMLEFT",%s*(%d+),%s*37%)'))
ok(width==326,'detected loot column width changed')
ok(headerOffset==8,'header left inset changed')
ok(buttonWidth==106,'new button must fit Confirm Drop label')
ok(rightOffset==-4,'New Drop must remain inset in detected loot header')
ok(pagerX==342,'right-hand paginator start moved; review possible overlap')
local newButtonRight=headerOffset+width+rightOffset
local newButtonLeft=newButtonRight-buttonWidth
ok(newButtonLeft>=headerOffset+144,'button does not cover Detected Loot heading')
ok(newButtonRight<pagerX,'New Drop does not overlap Prev Matches horizontally')
ok(source:find("newDrop:SetPoint%('TOPRIGHT',dropsHeader,'TOPRIGHT'",1)==nil or
    source:find("newDrop:SetPoint('TOPRIGHT',dropsHeader,'TOPRIGHT',-4,0)",1,true),
    'New Drop anchor remains in the left header')
ok(not source:find("newDrop:SetPoint('LEFT',draw,'RIGHT'",1,true),
    'Old overlapping right-of-Start Roll anchor was removed')
ok(source:find("self.currentLootNewDropButton=newDrop",1,true) and
    source:find("UI:RequestNewDrop()",1,true),
    'New Drop stays wired to the existing guarded confirmation')
print('PASS: '..assertions..' New Drop placement and retained guard assertions')
