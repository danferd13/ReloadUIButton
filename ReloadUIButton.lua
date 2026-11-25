-- ReloadUIButton: adds a "Reload UI" entry to the Game Menu (ESC menu).
--
-- Modern clients (retail 11.0+ / Midnight 12.x and World of Warcraft: Forever)
-- rebuild the Game Menu from GameMenuFrame:InitButtons() every time it opens,
-- and the old GameMenuButtonTemplate no longer exists. On those clients we hook
-- InitButtons and register our entry through GameMenuFrame:AddButton(), so it
-- is laid out natively with the rest of the menu.
--
-- Clients without that API fall back to a standalone button above the menu.
-- That button moves itself up past any buttons other addons have placed on
-- top of the menu, so it is never hidden behind them.

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

-- Gap (in pixels) kept between our button and whatever sits below it.
local BASE_OFFSET = 15 -- clears the "Game Menu" header on the menu itself
local SPACING = 4

-- Returns a frame's top/bottom/left/right converted into GameMenuFrame's
-- coordinate space, so frames with a different scale compare correctly.
local function GetBoundsInMenuSpace(frame)
    local top, bottom = frame:GetTop(), frame:GetBottom()
    local left, right = frame:GetLeft(), frame:GetRight()
    if not (top and bottom and left and right) then
        return nil
    end
    local ratio = frame:GetEffectiveScale() / GameMenuFrame:GetEffectiveScale()
    return top * ratio, bottom * ratio, left * ratio, right * ratio
end

-- True if the frame is anchored (directly) to GameMenuFrame.
local function IsAnchoredToMenu(frame)
    for i = 1, frame:GetNumPoints() do
        local _, relativeTo = frame:GetPoint(i)
        if relativeTo == GameMenuFrame then
            return true
        end
    end
    return false
end

-- Finds the highest visible frame that sits on top of the Game Menu (another
-- addon's button, for example) and moves our button just above it.
local function UpdateLegacyButtonPosition(btn)
    local menuTop = GameMenuFrame:GetTop()
    local menuLeft, menuRight = GameMenuFrame:GetLeft(), GameMenuFrame:GetRight()
    if not (menuTop and menuLeft and menuRight) then
        return
    end

    local highestTop = menuTop + BASE_OFFSET - SPACING

    local function Consider(frame)
        if frame == btn or not frame:IsVisible() then
            return
        end
        local top, bottom, left, right = GetBoundsInMenuSpace(frame)
        if not top then
            return
        end
        -- Only frames resting on (or above) the top edge of the menu and
        -- horizontally overlapping it can cover our button.
        if bottom >= menuTop - 2 and right > menuLeft and left < menuRight then
            highestTop = math.max(highestTop, top)
        end
    end

    for _, child in ipairs({ GameMenuFrame:GetChildren() }) do
        Consider(child)
    end
    for _, child in ipairs({ UIParent:GetChildren() }) do
        if child ~= GameMenuFrame and IsAnchoredToMenu(child) then
            Consider(child)
        end
    end

    btn:ClearAllPoints()
    btn:SetPoint("BOTTOM", GameMenuFrame, "TOP", 0, highestTop - menuTop + SPACING)
end

local function SetupLegacyMenu()
    local template = C_XMLUtil and C_XMLUtil.GetTemplateInfo
        and C_XMLUtil.GetTemplateInfo("GameMenuButtonTemplate")
        and "GameMenuButtonTemplate" or "UIPanelButtonTemplate"

    local btn = CreateFrame("Button", "GameMenuButtonReloadUI", GameMenuFrame, template)
    btn:SetSize(144, 21)
    btn:SetText(BUTTON_TEXT)
    btn:SetPoint("BOTTOM", GameMenuFrame, "TOP", 0, BASE_OFFSET)
    btn:SetScript("OnClick", DoReload)

    -- Re-check every time the menu opens. Other addons often place their
    -- buttons from their own OnShow handlers, so check again on the next frame
    -- once they have run.
    GameMenuFrame:HookScript("OnShow", function()
        UpdateLegacyButtonPosition(btn)
        C_Timer.After(0, function()
            if GameMenuFrame:IsShown() then
                UpdateLegacyButtonPosition(btn)
            end
        end)
    end)
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
