local function CreateReloadButton()
    -- Check if button already exists
    if GameMenuButtonReloadUI then
        return
    end
    
    -- Create the button
    local btn = CreateFrame("Button", "GameMenuButtonReloadUI", GameMenuFrame, "GameMenuButtonTemplate")
    btn:SetSize(144, 21)
    btn:SetText("Reload UI")
    btn:SetPoint("BOTTOM", GameMenuFrame, "TOP", 0, 15)  -- Above the Game Menu
    
    -- Set click behavior
    btn:SetScript("OnClick", function()
        ReloadUI()
    end)
    
    btn:Show()
    
    print("|cff00ff00Reload UI button created!|r")
end

-- Wait for player to enter world
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    -- Wait a bit for UI to fully load
    C_Timer.After(1, function()
        if GameMenuFrame then
            GameMenuFrame:HookScript("OnShow", CreateReloadButton)
            print("|cffFFFF00ReloadUIButton addon loaded. Open ESC menu to create button.|r")
        end
    end)
end)