local ADDON_NAME, NS = ...

local EXT = CreateFrame("Frame")
local Shared = NS and NS.MoveTargets
if not Shared then
    return
end

local GetCDM = Shared.GetCDM
local Snap = Shared.Snap
local SaveCooldownGroup = Shared.SaveCooldownGroup
local SaveBuffGroup = Shared.SaveBuffGroup
local KeepUtilityStationaryDuringEssentialDrag = Shared.KeepUtilityStationaryDuringEssentialDrag
local DragTargets = Shared.DragTargets

local moveModeEnabled = false
local miniDataObject
local RefreshCDM
local UpdateGuiButtonVisual
local UpdateHandles
local EnsureExtensionsPopup

local CaptureAllPositionsAndPersist
local moveDirtyThisSession = false
local EnsureConfigHooks
local handlesManager
local Persistence = NS and NS.ExtPersistence
local ProfileHooks = NS and NS.ExtProfileHooks
local Debug = NS and NS.ExtDebug
local MinimapMod = NS and NS.ExtMinimap
local HandleModule = NS and NS.ExtHandles
local BuffPlaceholderHooks = NS and NS.ExtBuffPlaceholderHooks
local ConfigUIMod = NS and NS.ExtConfigUI
local ConfigHooksMod = NS and NS.ExtConfigHooks
local uiManager

local function GetExtDB()
    return Persistence and Persistence.GetExtDB and Persistence.GetExtDB() or {}
end

local function PersistMoveSnapshot()
    if Persistence and Persistence.PersistMoveSnapshot then
        Persistence.PersistMoveSnapshot(GetCDM())
    end
end

RefreshCDM = function()
    local CDM = GetCDM()
    if not CDM then return end
    if CDM.RefreshNow then
        CDM:RefreshNow()
    elseif CDM.Refresh then
        CDM:Refresh()
    end
end

local function EnsureCDMProfileHooks()
    if ProfileHooks and ProfileHooks.EnsureCDMProfileHooks then
        ProfileHooks.EnsureCDMProfileHooks(GetCDM, function()
            if UpdateHandles then UpdateHandles() end
        end)
    end
end

local function EnsureProfileReloadPromptHooks()
    if ProfileHooks and ProfileHooks.EnsureProfileReloadPromptHooks then
        ProfileHooks.EnsureProfileReloadPromptHooks(GetCDM)
    end
end

local function HideConfigFrame()
    local configFrame = _G.Ayije_CDMConfigFrame
    if configFrame and configFrame.IsShown and configFrame:IsShown() then
        configFrame:Hide()
    end
end

local function ShowConfigFrame()
    local CDM = GetCDM()
    if CDM and CDM.RequestConfigOpen then
        CDM:RequestConfigOpen("extensions_minimap", nil)
        return
    end
    if CDM and CDM.API and CDM.API.ShowConfig then
        CDM.API:ShowConfig()
        return
    end
    local configFrame = _G.Ayije_CDMConfigFrame
    if configFrame and configFrame.Show then
        configFrame:Show()
    end
end

local function UpdateMinimapButtonVisibility()
    if MinimapMod and MinimapMod.UpdateMinimapButtonVisibility then
        MinimapMod.UpdateMinimapButtonVisibility(GetExtDB)
    end
end

local function RegisterMinimapButton()
    if MinimapMod and MinimapMod.RegisterMinimapButton then
        miniDataObject = MinimapMod.RegisterMinimapButton({
            miniDataObject = miniDataObject,
            GetExtDB = GetExtDB,
            EnsureExtensionsPopup = function() return EnsureExtensionsPopup and EnsureExtensionsPopup() end,
            ShowConfigFrame = ShowConfigFrame,
        })
    end
end

local function GetGuiButtonParent()
    local configFrame = _G.Ayije_CDMConfigFrame
    if not configFrame then return nil end
    return configFrame
end

local function EnsureUIManager()
    if uiManager or not (ConfigUIMod and ConfigUIMod.Create) then
        return uiManager
    end
    uiManager = ConfigUIMod.Create({
        GetGuiButtonParent = GetGuiButtonParent,
        GetExtDB = GetExtDB,
        UpdateMinimapButtonVisibility = UpdateMinimapButtonVisibility,
        IsMoveModeEnabled = function() return moveModeEnabled end,
        OnEnableMove = function()
            moveModeEnabled = true
            if BuffPlaceholderHooks and BuffPlaceholderHooks.EnableForMoveMode then
                BuffPlaceholderHooks.EnableForMoveMode(GetCDM())
            end
            if UpdateGuiButtonVisual then UpdateGuiButtonVisual() end
            if UpdateHandles then UpdateHandles() end
            HideConfigFrame()
            local p = uiManager and uiManager.EnsureMovePopup and uiManager:EnsureMovePopup()
            if p then p:Show() end
        end,
        OnDisableMove = function()
            if CaptureAllPositionsAndPersist then CaptureAllPositionsAndPersist() end
            local CDM = GetCDM()
            if CDM and CDM.db then
                CDM.db.castBarContainerLocked = true
                PersistMoveSnapshot()
            end
            if BuffPlaceholderHooks and BuffPlaceholderHooks.DisableForMoveMode then
                BuffPlaceholderHooks.DisableForMoveMode(CDM)
            end
            moveModeEnabled = false
            local p = uiManager and uiManager.EnsureMovePopup and uiManager:EnsureMovePopup()
            if p then p:Hide() end
            if UpdateGuiButtonVisual then UpdateGuiButtonVisual() end
            if UpdateHandles then UpdateHandles() end
            RefreshCDM()
            ShowConfigFrame()
        end,
        OnMoveDone = function()
            if uiManager and uiManager.ctx and uiManager.ctx.OnDisableMove then
                uiManager.ctx.OnDisableMove()
            end
        end,
    })
    return uiManager
end

local function EnsureMovePopup()
    local mgr = EnsureUIManager()
    return mgr and mgr.EnsureMovePopup and mgr:EnsureMovePopup() or nil
end

EnsureExtensionsPopup = function()
    local mgr = EnsureUIManager()
    return mgr and mgr.EnsureExtensionsPopup and mgr:EnsureExtensionsPopup() or nil
end

local function EnsureHandlesManager()
    if handlesManager or not (HandleModule and HandleModule.Create) then
        return handlesManager
    end
    handlesManager = HandleModule.Create({
        GetCDM = GetCDM,
        Snap = Snap,
        DragTargets = DragTargets,
        SaveCooldownGroup = SaveCooldownGroup,
        SaveBuffGroup = SaveBuffGroup,
        KeepUtilityStationaryDuringEssentialDrag = KeepUtilityStationaryDuringEssentialDrag,
        PersistMoveSnapshot = PersistMoveSnapshot,
        RefreshCDM = RefreshCDM,
        IsMoveModeEnabled = function() return moveModeEnabled end,
        SetMoveDirty = function(v) moveDirtyThisSession = v and true or false end,
    })
    return handlesManager
end

UpdateGuiButtonVisual = function()
    local mgr = EnsureUIManager()
    if mgr and mgr.UpdateGuiButtonVisual then
        mgr:UpdateGuiButtonVisual()
    end
end

local function EnsureGuiButtons()
    local mgr = EnsureUIManager()
    if mgr and mgr.EnsureGuiButtons then
        mgr:EnsureGuiButtons()
    end
end

EnsureConfigHooks = function()
    if ConfigHooksMod and ConfigHooksMod.Ensure then
        ConfigHooksMod.Ensure({
            GetCDM = GetCDM,
            EnsureProfileReloadPromptHooks = EnsureProfileReloadPromptHooks,
            UpdateHandles = function()
                if UpdateHandles then UpdateHandles() end
            end,
            OnConfigHide = function()
                local mgr = EnsureUIManager()
                if mgr and mgr.SyncContainerVisibility then
                    mgr:SyncContainerVisibility(nil, false)
                end
            end,
        })
    end
end

CaptureAllPositionsAndPersist = function()
    local mgr = EnsureHandlesManager()
    if mgr and mgr.CaptureAllPositionsAndPersist then
        mgr:CaptureAllPositionsAndPersist()
    end
end

local function IsAnyHandleDragging()
    local mgr = EnsureHandlesManager()
    return mgr and mgr.IsAnyHandleDragging and mgr:IsAnyHandleDragging() or false
end

UpdateHandles = function()
    local CDM = GetCDM()
    if not CDM then return end
    if IsAnyHandleDragging() then return end

    EnsureConfigHooks()
    EnsureGuiButtons()
    local mgr = EnsureHandlesManager()
    if mgr and mgr.UpdateHandles then
        mgr:UpdateHandles()
    end

    local showButton = false
    local configFrame = _G.Ayije_CDMConfigFrame
    if configFrame and configFrame.IsShown then
        showButton = configFrame:IsShown()
    end
    local ui = EnsureUIManager()
    if ui and ui.SyncContainerVisibility then
        ui:SyncContainerVisibility(configFrame, showButton)
    end
end

local function Initialize()
    local CDM = GetCDM()
    if not CDM then return end

    EnsureExtensionsPopup()
    RegisterMinimapButton()
    EnsureCDMProfileHooks()
    EnsureConfigHooks()
    if Debug and Debug.RegisterSlashCommands then
        Debug.RegisterSlashCommands({
            GetCDM = GetCDM,
            CaptureAllPositionsAndPersist = function()
                if CaptureAllPositionsAndPersist then CaptureAllPositionsAndPersist() end
            end,
            GetMoveDirty = function() return moveDirtyThisSession end,
            SetMoveDirty = function(v) moveDirtyThisSession = v and true or false end,
        })
    end

    EXT:SetScript("OnUpdate", function(_, elapsed)
        EXT._tick = (EXT._tick or 0) + elapsed
        if EXT._tick < 0.5 then return end
        EXT._tick = 0
        if IsAnyHandleDragging() then return end
        UpdateHandles()
        if moveModeEnabled and not InCombatLockdown() then
            CaptureAllPositionsAndPersist()
        end
    end)
end

EXT:RegisterEvent("ADDON_LOADED")
EXT:RegisterEvent("PLAYER_ENTERING_WORLD")
EXT:RegisterEvent("PLAYER_REGEN_ENABLED")
EXT:RegisterEvent("PLAYER_LOGOUT")
EXT:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Ayije_CDM" or arg1 == "Ayije_CDM_Options" or arg1 == ADDON_NAME then
            C_Timer.After(0, Initialize)
            C_Timer.After(0.1, UpdateHandles)
        end
    elseif event == "PLAYER_LOGOUT" then
        if moveModeEnabled and BuffPlaceholderHooks and BuffPlaceholderHooks.DisableForMoveMode then
            BuffPlaceholderHooks.DisableForMoveMode(GetCDM())
        end
        if moveDirtyThisSession then
            CaptureAllPositionsAndPersist()
        end
    else
        C_Timer.After(0, UpdateHandles)
    end
end)
