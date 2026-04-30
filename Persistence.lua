local _, NS = ...

local Shared = NS and NS.MoveTargets
local Persistence = {}

local DB_NAME = "Ayije_CDM_ExtensionsDB"

function Persistence.GetExtDB()
    _G[DB_NAME] = _G[DB_NAME] or {}
    local db = _G[DB_NAME]
    db.minimap = db.minimap or {}
    db.profiles = nil
    db.byChar = nil
    if db.minimap.hide == nil then
        db.minimap.hide = false
    end
    return db
end

function Persistence.CopyMoveSettingsIntoProfile(CDM, profile)
    if not (CDM and CDM.db and type(profile) == "table") then
        return
    end
    if profile == CDM.db then return end

    local DeepCopy = Shared and Shared.DeepCopy
    if type(CDM.db.editModePositions) == "table" then
        profile.editModePositions = profile.editModePositions or {}
        for viewerName, viewerData in pairs(CDM.db.editModePositions) do
            if type(viewerData) == "table" and DeepCopy then
                profile.editModePositions[viewerName] = DeepCopy(viewerData)
            end
        end
    end

    profile.utilityWrap = CDM.db.utilityWrap
    profile.utilityUnlock = CDM.db.utilityUnlock
    profile.utilityXOffset = CDM.db.utilityXOffset
    profile.utilityYOffset = CDM.db.utilityYOffset
    profile.castBarAnchorToResources = CDM.db.castBarAnchorToResources
    profile.castBarContainerLocked = CDM.db.castBarContainerLocked
    profile.castBarOffsetX = CDM.db.castBarOffsetX
    profile.castBarOffsetY = CDM.db.castBarOffsetY

    local specID = CDM.GetCurrentSpecID and CDM:GetCurrentSpecID()
    if specID and type(CDM.db.cooldownGroups) == "table" and type(CDM.db.cooldownGroups[specID]) == "table" then
        profile.cooldownGroups = profile.cooldownGroups or {}
        profile.cooldownGroups[specID] = profile.cooldownGroups[specID] or {}
        for idx, srcGroup in ipairs(CDM.db.cooldownGroups[specID]) do
            if type(srcGroup) == "table" then
                local dstGroup = profile.cooldownGroups[specID][idx]
                if type(dstGroup) ~= "table" then
                    dstGroup = {}
                    profile.cooldownGroups[specID][idx] = dstGroup
                end
                dstGroup.anchorTarget = srcGroup.anchorTarget
                dstGroup.anchorPoint = srcGroup.anchorPoint
                dstGroup.anchorRelativeTo = srcGroup.anchorRelativeTo
                dstGroup.offsetX = srcGroup.offsetX
                dstGroup.offsetY = srcGroup.offsetY
            end
        end
    end

    if specID and type(CDM.db.buffGroups) == "table" and type(CDM.db.buffGroups[specID]) == "table" then
        profile.buffGroups = profile.buffGroups or {}
        profile.buffGroups[specID] = profile.buffGroups[specID] or {}
        for idx, srcGroup in ipairs(CDM.db.buffGroups[specID]) do
            if type(srcGroup) == "table" then
                local dstGroup = profile.buffGroups[specID][idx]
                if type(dstGroup) ~= "table" then
                    dstGroup = {}
                    profile.buffGroups[specID][idx] = dstGroup
                end
                dstGroup.anchorTarget = srcGroup.anchorTarget
                dstGroup.anchorPoint = srcGroup.anchorPoint
                dstGroup.anchorRelativeTo = srcGroup.anchorRelativeTo
                dstGroup.offsetX = srcGroup.offsetX
                dstGroup.offsetY = srcGroup.offsetY
            end
        end
    end
end

function Persistence.PersistMoveSnapshot(CDM)
    if not (CDM and CDM.db) then
        return
    end

    local stamp = time and time() or 0
    CDM.db.extensionsMoveStamp = stamp

    local globalDB = _G.Ayije_CDMDB
    if not (globalDB and type(globalDB.profiles) == "table") then
        return
    end

    local names = {}
    local function AddProfileName(name)
        if type(name) == "string" and name ~= "" then
            names[name] = true
        end
    end

    AddProfileName(CDM.activeProfileName)
    if type(globalDB.profileKeys) == "table" and type(CDM.charKey) == "string" then
        AddProfileName(globalDB.profileKeys[CDM.charKey])
    end

    if type(globalDB.specProfiles) == "table" and type(CDM.charKey) == "string" then
        local specData = globalDB.specProfiles[CDM.charKey]
        if type(specData) == "table" then
            local specIndex = GetSpecialization and GetSpecialization()
            if specData.enabled and type(specIndex) == "number" and specIndex > 0 then
                AddProfileName(specData[specIndex])
            end
        end
    end

    if type(CDM.activeProfileName) == "string" and globalDB.profiles[CDM.activeProfileName] == CDM.db then
        AddProfileName(CDM.activeProfileName)
    end

    for profileName in pairs(names) do
        local profile = globalDB.profiles[profileName]
        if type(profile) == "table" then
            Persistence.CopyMoveSettingsIntoProfile(CDM, profile)
            profile.extensionsMoveStamp = stamp
        end
    end
end

NS.ExtPersistence = Persistence
