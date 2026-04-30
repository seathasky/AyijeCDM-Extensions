local ADDON_NAME, NS = ...

NS = NS or {}
NS.MoveTargets = NS.MoveTargets or {}
local M = NS.MoveTargets

local function GetCDM()
    return _G.Ayije_CDM
end

local function Snap(v)
    local CDM = GetCDM()
    if CDM and CDM.Pixel and CDM.Pixel.Snap then
        return CDM.Pixel.Snap(v)
    end
    return math.floor((v or 0) + 0.5)
end

local function EnsureTable(parent, key)
    local t = parent[key]
    if not t then
        t = {}
        parent[key] = t
    end
    return t
end

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function GetCenterOffsets(frame)
    if not frame or not frame.GetCenter then return nil, nil end
    local fx, fy = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not (fx and fy and ux and uy) then return nil, nil end
    return Snap(fx - ux), Snap(fy - uy)
end

local function SaveEssential(container)
    local CDM = GetCDM()
    if not (CDM and CDM.db and CDM.CONST and CDM.CONST.VIEWERS) then return end
    local _, uy = UIParent:GetCenter()
    if not uy then return end

    local x = GetCenterOffsets(container)
    local top = container and container:GetTop()
    if not (x and top) then return end

    local vName = CDM.CONST.VIEWERS.ESSENTIAL
    local pos = EnsureTable(EnsureTable(EnsureTable(CDM.db, "editModePositions"), vName), "Default")
    pos.point = "CENTER"
    pos.x = x
    pos.y = Snap(top - uy)
end

local function SaveBuff(container)
    local CDM = GetCDM()
    if not (CDM and CDM.db and CDM.CONST and CDM.CONST.VIEWERS) then return end
    local _, uy = UIParent:GetCenter()
    if not uy then return end

    local x = GetCenterOffsets(container)
    local bottom = container and container:GetBottom()
    if not (x and bottom) then return end

    local yOffset = 0
    if CDM.GetBuffContainerYOffset then
        yOffset = CDM:GetBuffContainerYOffset() or 0
    end

    local vName = CDM.CONST.VIEWERS.BUFF
    local pos = EnsureTable(EnsureTable(EnsureTable(CDM.db, "editModePositions"), vName), "Default")
    pos.point = "CENTER"
    pos.x = x
    pos.y = Snap(bottom - uy - yOffset)
end

local function SaveBuffBar(container)
    local CDM = GetCDM()
    if not (CDM and CDM.db and CDM.CONST and CDM.CONST.VIEWERS) then return end
    local _, uy = UIParent:GetCenter()
    if not uy then return end

    local x = GetCenterOffsets(container)
    if not x then return end

    local growDirection = CDM.db.buffBarGrowDirection or "DOWN"
    local y
    if growDirection == "DOWN" then
        y = container:GetTop()
    else
        y = container:GetBottom()
    end
    if not y then return end

    local vName = CDM.CONST.VIEWERS.BUFF_BAR
    local pos = EnsureTable(EnsureTable(EnsureTable(CDM.db, "editModePositions"), vName), "Default")
    pos.point = "CENTER"
    pos.x = x
    pos.y = Snap(y - uy)
end

local function SaveUtility(container)
    local CDM = GetCDM()
    if not (CDM and CDM.db and CDM.CONST and CDM.CONST.VIEWERS and CDM.anchorContainers) then return end

    local V = CDM.CONST.VIEWERS
    local essential = CDM.anchorContainers[V.ESSENTIAL]
    if not essential and CDM.GetOrCreateAnchorContainer and _G[V.ESSENTIAL] then
        essential = CDM:GetOrCreateAnchorContainer(_G[V.ESSENTIAL])
    end
    if not essential then return end

    local essLeft = essential:GetLeft()
    local essBottom = essential:GetBottom()
    local utilLeft = container:GetLeft()
    local utilTop = container:GetTop()
    if not (essLeft and essBottom and utilLeft and utilTop) then return end

    local essHalfW = (essential:GetWidth() or 0) / 2
    local utilHalfW = (container:GetWidth() or 0) / 2
    local spacing = (CDM.Sizes and CDM.Sizes.SPACING) or 0

    CDM.db.utilityWrap = true
    CDM.db.utilityUnlock = true
    CDM.db.utilityXOffset = Snap((utilLeft - essLeft) - (essHalfW - utilHalfW))
    CDM.db.utilityYOffset = Snap((utilTop - essBottom) + spacing)
end

local function KeepUtilityStationaryDuringEssentialDrag(CDM, desiredUtilLeft, desiredUtilTop)
    if not (CDM and CDM.db and CDM.anchorContainers and CDM.CONST and CDM.CONST.VIEWERS) then
        return
    end

    local V = CDM.CONST.VIEWERS
    local essential = CDM.anchorContainers[V.ESSENTIAL]
    local utility = CDM.anchorContainers[V.UTILITY]
    if not (essential and utility and desiredUtilLeft and desiredUtilTop) then
        return
    end

    local essLeft = essential:GetLeft()
    local essBottom = essential:GetBottom()
    local essHalfW = (essential:GetWidth() or 0) / 2
    local utilHalfW = (utility:GetWidth() or 0) / 2
    local spacing = (CDM.Sizes and CDM.Sizes.SPACING) or 0
    if not (essLeft and essBottom) then
        return
    end

    local xOffset = Snap((desiredUtilLeft - essLeft) - (essHalfW - utilHalfW))
    local yOffset = Snap((desiredUtilTop - essBottom) + spacing)

    CDM.db.utilityWrap = true
    CDM.db.utilityUnlock = true
    CDM.db.utilityXOffset = xOffset
    CDM.db.utilityYOffset = yOffset

    utility:ClearAllPoints()
    utility:SetPoint("TOPLEFT", essential, "BOTTOMLEFT", essHalfW - utilHalfW + xOffset, -spacing + yOffset)
end

local function SaveCastBar(container)
    local CDM = GetCDM()
    if not (CDM and CDM.db) then return end

    local cx, cy = container:GetCenter()
    local ux, uy = UIParent:GetCenter()
    local halfH = (container:GetHeight() or 0) / 2
    if not (cx and cy and ux and uy) then return end

    CDM.db.castBarAnchorToResources = false
    CDM.db.castBarOffsetX = Snap(cx - ux)
    CDM.db.castBarOffsetY = Snap(cy - halfH - uy)
end

local function SaveCooldownGroup(container, groupIndex)
    local CDM = GetCDM()
    if not (CDM and CDM.db) then return end
    local x, y = GetCenterOffsets(container)
    if not x then return end

    local groupData
    local specID = CDM.GetCurrentSpecID and CDM:GetCurrentSpecID()
    if specID then
        local groupsBySpec = EnsureTable(CDM.db, "cooldownGroups")
        local specGroups = EnsureTable(groupsBySpec, specID)
        groupData = specGroups[groupIndex]

        if not groupData then
            local runtimeGroups = CDM.CooldownGroupSets and CDM.CooldownGroupSets.groups
            local runtimeData = runtimeGroups and runtimeGroups[groupIndex]
            groupData = runtimeData and DeepCopy(runtimeData) or {}
            specGroups[groupIndex] = groupData
        end

        local runtimeGroups = CDM.CooldownGroupSets and CDM.CooldownGroupSets.groups
        if runtimeGroups then
            runtimeGroups[groupIndex] = groupData
        end
    else
        local runtimeGroups = CDM.CooldownGroupSets and CDM.CooldownGroupSets.groups
        groupData = runtimeGroups and runtimeGroups[groupIndex]
    end

    if not groupData then return end
    groupData.anchorTarget = "screen"
    groupData.offsetX = x
    groupData.offsetY = y
end

local function SaveBuffGroup(container, groupIndex)
    local CDM = GetCDM()
    if not (CDM and CDM.db) then return end
    local x, y = GetCenterOffsets(container)
    if not x then return end

    local groupData
    local specID = CDM.GetCurrentSpecID and CDM:GetCurrentSpecID()
    if specID then
        local groupsBySpec = EnsureTable(CDM.db, "buffGroups")
        local specGroups = EnsureTable(groupsBySpec, specID)
        groupData = specGroups[groupIndex]

        if not groupData then
            local runtimeGroups = CDM.BuffGroupSets and CDM.BuffGroupSets.groups
            local runtimeData = runtimeGroups and runtimeGroups[groupIndex]
            groupData = runtimeData and DeepCopy(runtimeData) or {}
            specGroups[groupIndex] = groupData
        end

        local runtimeGroups = CDM.BuffGroupSets and CDM.BuffGroupSets.groups
        if runtimeGroups then
            runtimeGroups[groupIndex] = groupData
        end
    else
        local runtimeGroups = CDM.BuffGroupSets and CDM.BuffGroupSets.groups
        groupData = runtimeGroups and runtimeGroups[groupIndex]
    end

    if not groupData then return end
    groupData.anchorTarget = "screen"
    groupData.offsetX = x
    groupData.offsetY = y
end

local DragTargets = {
    { id = "essential", label = "Essential", getFrame = function(CDM) local V = CDM.CONST and CDM.CONST.VIEWERS; if not V then return nil end; local frame = CDM.anchorContainers and CDM.anchorContainers[V.ESSENTIAL]; if not frame and CDM.GetOrCreateAnchorContainer and _G[V.ESSENTIAL] then frame = CDM:GetOrCreateAnchorContainer(_G[V.ESSENTIAL]) end; return frame end, save = SaveEssential },
    { id = "utility", label = "Utility", getFrame = function(CDM) local V = CDM.CONST and CDM.CONST.VIEWERS; if not V then return nil end; local frame = CDM.anchorContainers and CDM.anchorContainers[V.UTILITY]; if not frame and CDM.GetOrCreateAnchorContainer and _G[V.UTILITY] then frame = CDM:GetOrCreateAnchorContainer(_G[V.UTILITY]) end; return frame end, save = SaveUtility },
    { id = "buff", label = "Buffs", getFrame = function(CDM) local V = CDM.CONST and CDM.CONST.VIEWERS; if not V then return nil end; local frame = CDM.anchorContainers and CDM.anchorContainers[V.BUFF]; if not frame and CDM.GetOrCreateAnchorContainer and _G[V.BUFF] then frame = CDM:GetOrCreateAnchorContainer(_G[V.BUFF]) end; return frame end, save = SaveBuff },
    { id = "buffbar", label = "Buff Bar", getFrame = function(CDM) local V = CDM.CONST and CDM.CONST.VIEWERS; if not V then return nil end; local frame = CDM.anchorContainers and CDM.anchorContainers[V.BUFF_BAR]; if not frame and CDM.GetOrCreateAnchorContainer and _G[V.BUFF_BAR] then frame = CDM:GetOrCreateAnchorContainer(_G[V.BUFF_BAR]) end; return frame end, save = SaveBuffBar },
    { id = "castbar", label = "Cast Bar", getFrame = function(CDM) return CDM.castBarContainer end, save = SaveCastBar },
}

M.GetCDM = GetCDM
M.Snap = Snap
M.EnsureTable = EnsureTable
M.DeepCopy = DeepCopy
M.GetCenterOffsets = GetCenterOffsets
M.SaveEssential = SaveEssential
M.SaveBuff = SaveBuff
M.SaveBuffBar = SaveBuffBar
M.SaveUtility = SaveUtility
M.KeepUtilityStationaryDuringEssentialDrag = KeepUtilityStationaryDuringEssentialDrag
M.SaveCastBar = SaveCastBar
M.SaveCooldownGroup = SaveCooldownGroup
M.SaveBuffGroup = SaveBuffGroup
M.DragTargets = DragTargets
