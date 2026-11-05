-- ReloadUIButton: adds a "Reload UI" entry to the Game Menu (ESC menu).
--
-- Modern clients (retail 11.0+ / Midnight 12.x and World of Warcraft: Forever)
-- rebuild the Game Menu from GameMenuFrame:InitButtons() every time it opens,
-- and the old GameMenuButtonTemplate no longer exists. On those clients we hook
-- InitButtons and register our entry through GameMenuFrame:AddButton(), so it
-- is laid out natively with the rest of the menu.
--
-- Older clients without that API fall back to a standalone button anchored
-- above the menu.

local addonName = ...
local BUTTON_TEXT = RELOADUI or "Reload UI"

local function DoReload()
    ReloadUI()
end

local function SetupModernMenu()
    hooksecurefunc(GameMenuFrame, "InitButtons", function(self)
        if self.AddSection then
            self:AddSection()
        end
        self:AddButton(BUTTON_TEXT, DoReload)
    end)
end

local function SetupLegacyMenu()
    local template = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("GameMenuButtonTemplate")
        and "GameMenuButtonTemplate" or "UIPanelButtonTemplate"

    local btn = CreateFrame("Button", "GameMenuButtonReloadUI", GameMenuFrame, template)
    btn:SetSize(144, 21)
    btn:SetText(BUTTON_TEXT)
    btn:SetPoint("BOTTOM", GameMenuFrame, "TOP", 0, 15)
    btn:SetScript("OnClick", DoReload)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")

    if not GameMenuFrame then
        return
    end

    if GameMenuFrame.InitButtons and GameMenuFrame.AddButton then
        SetupModernMenu()
    else
        SetupLegacyMenu()
    end
end)

-- /rl as a short alias for /reload
SLASH_RELOADUIBUTTON1 = "/rl"
SlashCmdList.RELOADUIBUTTON = DoReload
