local _, NS = ...

local Hooks = {
    profileHooksInstalled = false,
    profileConfirmHooksInstalled = false,
    profileChangeConfirmBypass = false,
}

local PROFILE_RELOAD_POPUP_ID = "AYIJE_CDM_EXT_PROFILE_RELOAD_CONFIRM"

function Hooks.EnsureCDMProfileHooks(getCDM, updateHandles)
    if Hooks.profileHooksInstalled then
        return
    end

    local CDM = getCDM and getCDM()
    if not CDM then
        return
    end

    local function HandleProfileChange()
        C_Timer.After(0, function()
            if updateHandles then
                updateHandles()
            end
        end)
    end

    if hooksecurefunc and type(CDM.ApplyProfile) == "function" then
        hooksecurefunc(CDM, "ApplyProfile", HandleProfileChange)
    end

    Hooks.profileHooksInstalled = true
end

function Hooks.EnsureProfileReloadPromptHooks(getCDM)
    if Hooks.profileConfirmHooksInstalled then
        return
    end

    local CDM = getCDM and getCDM()
    if not CDM then
        return
    end

    StaticPopupDialogs[PROFILE_RELOAD_POPUP_ID] = StaticPopupDialogs[PROFILE_RELOAD_POPUP_ID] or {
        text = "This profile action requires a UI reload to keep Extensions stable.\n\nProceed?",
        button1 = ACCEPT,
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function(_, data)
            if not data then return end
            local cdm = getCDM and getCDM()
            if not cdm then return end
            local methodName = data.method
            local original = methodName and cdm["_CDMExt_Original_" .. methodName]
            if type(original) ~= "function" then
                return
            end

            Hooks.profileChangeConfirmBypass = true
            local ok, err = pcall(original, cdm, unpack(data.args or {}))
            Hooks.profileChangeConfirmBypass = false
            if not ok then
                geterrorhandler()(err)
                return
            end
            ReloadUI()
        end,
    }

    local function WrapProfileMethod(methodName)
        if type(CDM[methodName]) ~= "function" then
            return false
        end
        if type(CDM["_CDMExt_Original_" .. methodName]) == "function" then
            return true
        end

        CDM["_CDMExt_Original_" .. methodName] = CDM[methodName]
        CDM[methodName] = function(self, ...)
            if Hooks.profileChangeConfirmBypass then
                return CDM["_CDMExt_Original_" .. methodName](self, ...)
            end

            StaticPopup_Hide(PROFILE_RELOAD_POPUP_ID)
            StaticPopup_Show(PROFILE_RELOAD_POPUP_ID, nil, nil, {
                method = methodName,
                args = { ... },
            })
            return true
        end
        return true
    end

    local installedAny = false
    installedAny = WrapProfileMethod("SetProfile") or installedAny
    installedAny = WrapProfileMethod("NewProfile") or installedAny
    installedAny = WrapProfileMethod("CopyProfile") or installedAny
    installedAny = WrapProfileMethod("ResetProfile") or installedAny
    installedAny = WrapProfileMethod("RenameProfile") or installedAny
    Hooks.profileConfirmHooksInstalled = installedAny
end

NS.ExtProfileHooks = Hooks
