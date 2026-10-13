-- ============================================================
-- Naxxramas Loot Ledger
-- UI/SkinManager.lua
--
-- Centralized appearance system.
-- Functionality and data never depend on the selected skin.
--
-- Dark-only presentation. Wrath-era Lua 5.1 and NLL's existing
-- dark backdrops, button dimensions and hover states remain unchanged.
-- ============================================================

local NLL = NaxxLootLottery
NLL.UI = NLL.UI or {}
local UI = NLL.UI

UI.skinnedFrames = UI.skinnedFrames or {}

UI.skins = {
    DARK = {
        name = "NLL Dark",

        mainBackdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = {
                left = 3,
                right = 3,
                top = 3,
                bottom = 3
            }
        },

        contentBackdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = true,
            tileSize = 16,
            edgeSize = 0,
            insets = {
                left = 0,
                right = 0,
                top = 0,
                bottom = 0
            }
        },

        main = { 0.035, 0.035, 0.045, 0.96 },
        mainBorder = { 0.28, 0.28, 0.32, 1 },

        content = { 0, 0, 0, 0.03 },

        title = { 0.08, 0.08, 0.10, 1 },
        header = { 0.12, 0.12, 0.14, 1 },

        row = { 0.045, 0.045, 0.055, 0.90 },
        rowAlt = { 0.075, 0.075, 0.09, 0.90 },

        button = { 0.09, 0.09, 0.11, 1 },
        buttonHover = { 0.17, 0.17, 0.20, 1 },
        buttonActive = { 0.22, 0.16, 0.05, 1 },
        buttonDanger = { 0.20, 0.09, 0.09, 1 },

        border = { 0.28, 0.28, 0.32, 1 }
    },

}


local function ApplyColor(
    frame,
    methodName,
    color
)
    if not frame or not color then
        return
    end

    local method = frame[methodName]

    if not method then
        return
    end

    method(
        frame,
        color[1],
        color[2],
        color[3],
        color[4]
    )
end

local function ClearButtonTextures(button)
    button:SetNormalTexture(nil)
    button:SetPushedTexture(nil)
    button:SetHighlightTexture(nil)
end

local function RestoreDarkButtonSize(button)
    if button.nllBaseWidth then
        button:SetWidth(
            button.nllBaseWidth
        )
    end

    if button.nllBaseHeight then
        button:SetHeight(
            button.nllBaseHeight
        )
    end
end

function UI:GetSkinID()
    return "DARK"
end

function UI:GetSkin()
    return self.skins[self:GetSkinID()]
        or self.skins.DARK
end

function UI:RegisterSkinnedFrame(
    frame,
    kind
)
    if not frame then
        return
    end

    frame.nllSkinKind = kind or "row"

    if not frame.nllSkinRegistered then
        frame.nllSkinRegistered = true

        table.insert(
            self.skinnedFrames,
            frame
        )
    end

    self:ApplySkinToFrame(frame)
end

function UI:SetButtonState(
    button,
    state
)
    if not button then
        return
    end

    button.nllButtonState =
        state or "normal"

    self:ApplySkinToFrame(button)
end

function UI:ApplySkinToFrame(frame)
    if not frame then
        return
    end

    local skin = self:GetSkin()
    local kind =
        frame.nllSkinKind
        or "row"

    if kind == "button" then
        RestoreDarkButtonSize(frame)
        ClearButtonTextures(frame)

        frame:SetBackdrop({
            bgFile =
                "Interface\\Buttons\\WHITE8X8",
            edgeFile =
                "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = {
                left = 2,
                right = 2,
                top = 2,
                bottom = 2
            }
        })

        local color = skin.button

        if frame.nllHover then
            color = skin.buttonHover
        elseif frame.nllButtonState ==
            "active" then

            color = skin.buttonActive
        elseif frame.nllButtonState ==
            "danger" then

            color = skin.buttonDanger
        end

        ApplyColor(
            frame,
            "SetBackdropColor",
            color
        )

        ApplyColor(
            frame,
            "SetBackdropBorderColor",
            skin.border
        )

        return
    end

    if not frame.SetBackdrop then
        return
    end

    if kind == "main" then
        frame:SetBackdrop(
            skin.mainBackdrop
        )

        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.main
        )

        ApplyColor(
            frame,
            "SetBackdropBorderColor",
            skin.mainBorder
        )

        return
    end

    if kind == "content" then
        frame:SetBackdrop(skin.contentBackdrop)
        ApplyColor(frame, "SetBackdropColor", skin.content)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
        return
    end

    frame:SetBackdrop({
                edgeFile =
                    "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = false,
                edgeSize = 18,
                insets = {
                    left = 6,
                    right = 6,
                    top = 6,
                    bottom = 6
                }
            })

            frame:SetBackdropColor(
                0,
                0,
                0,
                0
            )

            ApplyColor(
                frame,
                "SetBackdropBorderColor",
                skin.border
            )

            ShowVanillaParchment(
                frame
            )
        else
            HideVanillaParchment(
                frame
            )

            frame:SetBackdrop(
                skin.contentBackdrop
            )

            ApplyColor(
                frame,
                "SetBackdropColor",
                skin.content
            )

            frame:SetBackdropBorderColor(
                0,
                0,
                0,
                0
            )
        end

        return
    end

    frame:SetBackdrop({
        bgFile =
            "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 16,
        edgeSize = 0,
        insets = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0
        }
    })

    if kind == "title" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.title
        )
        return
    end

    if kind == "header" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.header
        )
        return
    end

    if kind == "rowAlt" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.rowAlt
        )
        return
    end

    if kind == "row" then
        ApplyColor(
            frame,
            "SetBackdropColor",
            skin.row
        )
        return
    end
end

function UI:AttachButtonSkin(button)
    if not button then
        return
    end

    self:RegisterSkinnedFrame(
        button,
        "button"
    )

    button.nllButtonState =
        button.nllButtonState
        or "normal"

    button:SetScript(
        "OnEnter",
        function(self)
            self.nllHover = true
            UI:ApplySkinToFrame(self)
        end
    )

    button:SetScript(
        "OnLeave",
        function(self)
            self.nllHover = false
            UI:ApplySkinToFrame(self)
        end
    )
end

function UI:ApplySkin()
    for i = 1, #self.skinnedFrames do
        self:ApplySkinToFrame(
            self.skinnedFrames[i]
        )
    end

    if self.RefreshSettingsPanel then
        self:RefreshSettingsPanel()
    end
end

function UI:SetSkin(skinID)
    -- Compatibility guard for older callers: DARK is the only available skin.
    if skinID ~= "DARK" or not NLL.db or not NLL.db.settings then
        return false
    end
    NLL.db.settings.skin = "DARK"
    self:ApplySkin()
    return true
end
