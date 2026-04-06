local _, NS = ...

local ConfigHooks = {
    hooksInstalled = false,
}

function ConfigHooks.Ensure(ctx)
    if not ctx then return end
    local getCDM = ctx.GetCDM
    local CDM = getCDM and getCDM()
    if not CDM then return end

    if ctx.EnsureProfileReloadPromptHooks then
        ctx.EnsureProfileReloadPromptHooks()
    end

    if not ConfigHooks.hooksInstalled then
        local installedAny = false

        local function RefreshButtonsSoon()
            if ctx.UpdateHandles then
                C_Timer.After(0, ctx.UpdateHandles)
                C_Timer.After(0.05, ctx.UpdateHandles)
                C_Timer.After(0.20, ctx.UpdateHandles)
            end
        end

        if hooksecurefunc and type(CDM.RebuildConfigFrame) == "function" then
            hooksecurefunc(CDM, "RebuildConfigFrame", RefreshButtonsSoon)
            installedAny = true
        end
        if hooksecurefunc and type(CDM.ShowConfig) == "function" then
            hooksecurefunc(CDM, "ShowConfig", RefreshButtonsSoon)
            installedAny = true
        end
        if hooksecurefunc and type(CDM.ApplyProfile) == "function" then
            hooksecurefunc(CDM, "ApplyProfile", RefreshButtonsSoon)
            installedAny = true
        end
        if hooksecurefunc and type(CDM.SetProfile) == "function" then
            hooksecurefunc(CDM, "SetProfile", RefreshButtonsSoon)
            installedAny = true
        end
        if hooksecurefunc and type(CDM.NewProfile) == "function" then
            hooksecurefunc(CDM, "NewProfile", RefreshButtonsSoon)
            installedAny = true
        end
        if hooksecurefunc and type(CDM.CopyProfile) == "function" then
            hooksecurefunc(CDM, "CopyProfile", RefreshButtonsSoon)
            installedAny = true
        end
        if hooksecurefunc and type(CDM.ResetProfile) == "function" then
            hooksecurefunc(CDM, "ResetProfile", RefreshButtonsSoon)
            installedAny = true
        end

        ConfigHooks.hooksInstalled = installedAny
    end

    local configFrame = _G.Ayije_CDMConfigFrame
    if configFrame and not configFrame._cdmExtButtonsHooked then
        configFrame:HookScript("OnShow", function()
            if ctx.UpdateHandles then
                C_Timer.After(0, ctx.UpdateHandles)
                C_Timer.After(0.05, ctx.UpdateHandles)
            end
        end)
        configFrame:HookScript("OnHide", function()
            if ctx.OnConfigHide then
                ctx.OnConfigHide()
            end
        end)
        configFrame._cdmExtButtonsHooked = true
    end
end

NS.ExtConfigHooks = ConfigHooks
