-- NLL WoW 3.3.5a: manual-only, read-only recipe/profession inspector.
local NLL=NaxxLootLottery
local UI=NLL.UI
local ROWS=4

function UI:CreateProfessionRecipeReview()
    if self.professionRecipePanel then return end
    local panel=CreateFrame("Frame","NaxxLootLotteryProfessionRecipeReview",UIParent)
    panel:SetWidth(695)
    panel:SetHeight(442)
    panel:SetPoint("CENTER",UIParent,"CENTER",0,0)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    self:RegisterSkinnedFrame(panel,"main")
    local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",panel,"TOPLEFT",18,-17)
    title:SetText("Molten Core — Profession Recipe Review")
    local status=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-14)
    status:SetWidth(655)
    status:SetJustifyH("LEFT")
    local itemText=panel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    itemText:SetPoint("TOPLEFT",panel,"TOPLEFT",18,-75)
    itemText:SetWidth(651)
    itemText:SetJustifyH("LEFT")
    local requirement=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    requirement:SetPoint("TOPLEFT",panel,"TOPLEFT",18,-107)
    requirement:SetWidth(650)
    requirement:SetJustifyH("LEFT")
    local warning=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    warning:SetPoint("TOPLEFT",panel,"TOPLEFT",18,-138)
    warning:SetWidth(649)
    warning:SetJustifyH("LEFT")
    warning:SetText("UNVERIFIED: professions, skill, specialisation, learnt recipes and delivery.")
    local info=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    info:SetPoint("TOPLEFT",panel,"TOPLEFT",18,-178)
    info:SetWidth(652)
    info:SetJustifyH("LEFT")
    info:SetText("Saved Gear Plan interests (not verified eligible recipients):")
    local lines={}
    for i=1,ROWS do
        local line=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        line:SetPoint("TOPLEFT",panel,"TOPLEFT",20,-204-(i-1)*35)
        line:SetWidth(651)
        line:SetJustifyH("LEFT")
        lines[i]=line
    end
    local prevRecipe=self:CreateTextButton(panel,"Prev Recipe",96)
    prevRecipe:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",17,55)
    local nextRecipe=self:CreateTextButton(panel,"Next Recipe",96)
    nextRecipe:SetPoint("LEFT",prevRecipe,"RIGHT",6,0)
    local prevCandidate=self:CreateTextButton(panel,"Prev Names",102)
    prevCandidate:SetPoint("LEFT",nextRecipe,"RIGHT",18,0)
    local nextCandidate=self:CreateTextButton(panel,"Next Names",102)
    nextCandidate:SetPoint("LEFT",prevCandidate,"RIGHT",6,0)
    local close=self:CreateTextButton(panel,"Close",90)
    close:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-18,18)
    local footer=panel:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    footer:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",18,18)
    footer:SetWidth(531)
    footer:SetJustifyH("LEFT")
    footer:SetText("REVIEW ONLY — no allocation or recipient confirmation.")

    local function Refresh()
        local catalog=NLL.ProfessionRecipeReview:ListRecipes()
        local recipe=catalog[UI.professionRecipeIndex or 1]
        if not recipe then
            itemText:SetText("No verified MC recipes; no allocations possible.")
            for i=1,ROWS do lines[i]:SetText("") end
            prevRecipe:Disable();nextRecipe:Disable()
            prevCandidate:Disable();nextCandidate:Disable()
            return
        end
        local result=NLL.ProfessionRecipeReview:Build(recipe.itemID)
        if not result then
            itemText:SetText("Recipe cannot be verified; close and investigate.")
            for i=1,ROWS do lines[i]:SetText("") end
            prevRecipe:Disable();nextRecipe:Disable()
            prevCandidate:Disable();nextCandidate:Disable()
            return
        end
        UI.professionRecipeReviewCurrent=result
        status:SetText("Recipe "..UI.professionRecipeIndex.."/"..#catalog..
            "   •   "..#result.candidates.." stored reservation(s): "..
            result.need.." NEED, "..result.greed.." GREED, "..
            result.obtained.." OBTAINED, "..result.disabled.." disabled")
        itemText:SetText(result.name.."    (Item "..result.itemID..")")
        requirement:SetText("Required profession: "..result.profession..
            " (skill "..result.requiredSkill.."); specialty CHECK IN GAME.")
        local pages=math.max(1,math.ceil(#result.candidates/ROWS))
        UI.professionRecipeCandidatePage=math.min(
            pages,math.max(1,UI.professionRecipeCandidatePage or 1))
        local first=(UI.professionRecipeCandidatePage-1)*ROWS
        for i=1,ROWS do
            local candidate=result.candidates[first+i]
            if candidate then
                lines[i]:SetText(candidate.character.." ("..
                    candidate.characterType..", "..candidate.source..") — "..
                    candidate.interest.."  |  profession/skill: UNVERIFIED")
            else
                lines[i]:SetText(i==1 and #result.candidates==0 and
                    "No saved Gear Plan interested in this recipe." or "")
            end
        end
        if UI.professionRecipeIndex>1 then prevRecipe:Enable()
        else prevRecipe:Disable() end
        if UI.professionRecipeIndex<#catalog then nextRecipe:Enable()
        else nextRecipe:Disable() end
        if UI.professionRecipeCandidatePage>1 then prevCandidate:Enable()
        else prevCandidate:Disable() end
        if UI.professionRecipeCandidatePage<pages then nextCandidate:Enable()
        else nextCandidate:Disable() end
        footer:SetText("Names page "..UI.professionRecipeCandidatePage..
            "/"..pages.." — MANUAL REVIEW ONLY. No loot award.")
    end
    prevRecipe:SetScript("OnClick",function()
        if UI.professionRecipeIndex<=1 then return end
        UI.professionRecipeIndex=UI.professionRecipeIndex-1
        UI.professionRecipeCandidatePage=1
        Refresh()
    end)
    nextRecipe:SetScript("OnClick",function()
        local recipes=NLL.ProfessionRecipeReview:ListRecipes()
        if UI.professionRecipeIndex>=#recipes then return end
        UI.professionRecipeIndex=UI.professionRecipeIndex+1
        UI.professionRecipeCandidatePage=1
        Refresh()
    end)
    prevCandidate:SetScript("OnClick",function()
        if UI.professionRecipeCandidatePage<=1 then return end
        UI.professionRecipeCandidatePage=UI.professionRecipeCandidatePage-1
        Refresh()
    end)
    nextCandidate:SetScript("OnClick",function()
        if not UI.professionRecipeReviewCurrent then return end
        local pages=math.max(1,math.ceil(
            #UI.professionRecipeReviewCurrent.candidates/ROWS))
        if UI.professionRecipeCandidatePage>=pages then return end
        UI.professionRecipeCandidatePage=UI.professionRecipeCandidatePage+1
        Refresh()
    end)
    close:SetScript("OnClick",function()panel:Hide()end)
    self.professionRecipePanel=panel
    self.professionRecipeStatus=status
    self.professionRecipeItem=itemText
    self.professionRecipeRequirement=requirement
    self.professionRecipeWarning=warning
    self.professionRecipeLines=lines
    self.professionRecipePrev=prevRecipe
    self.professionRecipeNext=nextRecipe
    self.professionRecipeCandidatePrev=prevCandidate
    self.professionRecipeCandidateNext=nextCandidate
    self.professionRecipeFooter=footer
    self.professionRecipeRefresh=Refresh
    panel:Hide()
end

function UI:ShowProfessionRecipeReview()
    if not NLL.ProfessionRecipeReview then return end
    self:CreateProfessionRecipeReview()
    self.professionRecipeIndex=1
    self.professionRecipeCandidatePage=1
    self.professionRecipeRefresh()
    self.professionRecipePanel:Show()
end
function UI:CloseProfessionRecipeReview()
    if self.professionRecipePanel then self.professionRecipePanel:Hide() end
end
