local _, NS = ...

local PlaceholderHooks = {}

local MISSING = {}

local function IsUsableSpellID(v)
    return type(v) == "number" and v > 0
end

local function CollectSpellIDs(spells, out)
    if type(spells) ~= "table" then
        return out
    end

    for _, entry in ipairs(spells) do
        local spellID = entry
        if type(entry) == "table" then
            spellID = entry.spellID or entry.id
        end
        if IsUsableSpellID(spellID) then
            out[spellID] = true
        end
    end

    for k, v in pairs(spells) do
        local spellID = nil
        if type(k) == "number" and type(v) == "boolean" then
            spellID = k
        elseif type(v) == "number" then
            spellID = v
        elseif type(v) == "table" then
            spellID = v.spellID or v.id
        end
        if IsUsableSpellID(spellID) then
            out[spellID] = true
        end
    end

    return out
end

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = DeepCopy(v)
    end
    return out
end

local state = {
    enabled = false,
    savedByGroup = {},
}

local function ResetState()
    state.enabled = false
    state.savedByGroup = {}
end

local function RefreshBuffGroupLayout(CDM)
    if not CDM then return end

    if CDM.UpdateAllBuffGroupContainers then
        CDM:UpdateAllBuffGroupContainers()
    end

    local buffViewerName = CDM.CONST and CDM.CONST.VIEWERS and CDM.CONST.VIEWERS.BUFF
    local buffViewer = buffViewerName and _G[buffViewerName]
    if buffViewer and CDM.ForceReanchor then
        CDM:ForceReanchor(buffViewer)
    end

    if CDM.RefreshNow then
        CDM:RefreshNow()
    elseif CDM.Refresh then
        CDM:Refresh()
    end
end

function PlaceholderHooks.EnableForMoveMode(CDM)
    if not CDM or state.enabled then return end

    local sets = CDM.BuffGroupSets
    local groups = sets and sets.groups
    if type(groups) ~= "table" then
        return
    end

    local changed = false
    for groupIndex, groupData in pairs(groups) do
        local spells = groupData and groupData.spells
        if type(spells) == "table" and next(spells) ~= nil then
            local savedForGroup = state.savedByGroup[groupIndex]
            if not savedForGroup then
                savedForGroup = {}
                state.savedByGroup[groupIndex] = savedForGroup
            end

            groupData.spellOverrides = type(groupData.spellOverrides) == "table" and groupData.spellOverrides or {}
            local overrideMap = groupData.spellOverrides

            local spellIDs = CollectSpellIDs(spells, {})
            for spellID in pairs(spellIDs) do
                if IsUsableSpellID(spellID) and savedForGroup[spellID] == nil then
                    local original = CDM.GetMergedBuffOverrideEntry and CDM:GetMergedBuffOverrideEntry(overrideMap, spellID) or nil
                    savedForGroup[spellID] = original and DeepCopy(original) or MISSING

                    local entry = CDM.EnsureBuffOverrideEntry and CDM:EnsureBuffOverrideEntry(overrideMap, spellID) or nil
                    if not entry then
                        entry = {}
                        overrideMap[spellID] = entry
                    end

                    if entry.placeholder ~= true then
                        entry.placeholder = true
                        changed = true
                    end
                end
            end
        end
    end

    state.enabled = true
    if changed then
        RefreshBuffGroupLayout(CDM)
    end
end

function PlaceholderHooks.DisableForMoveMode(CDM)
    if not CDM or not state.enabled then
        ResetState()
        return
    end

    local sets = CDM.BuffGroupSets
    local groups = sets and sets.groups
    local changed = false

    if type(groups) == "table" then
        for groupIndex, savedForGroup in pairs(state.savedByGroup) do
            local groupData = groups[groupIndex]
            if type(groupData) == "table" and type(savedForGroup) == "table" then
                local overrideMap = groupData.spellOverrides
                if type(overrideMap) == "table" then
                    for spellID, original in pairs(savedForGroup) do
                        if IsUsableSpellID(spellID) then
                            if original == MISSING then
                                if CDM.ExtractMergedBuffOverrideEntry then
                                    local removed = CDM:ExtractMergedBuffOverrideEntry(overrideMap, spellID)
                                    if removed then changed = true end
                                else
                                    local entry = overrideMap[spellID]
                                    if type(entry) == "table" and entry.placeholder ~= nil then
                                        entry.placeholder = nil
                                        changed = true
                                    end
                                end
                            else
                                if CDM.StoreMergedBuffOverrideEntry then
                                    CDM:StoreMergedBuffOverrideEntry(overrideMap, spellID, original)
                                    changed = true
                                else
                                    overrideMap[spellID] = DeepCopy(original)
                                    changed = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    ResetState()
    if changed then
        RefreshBuffGroupLayout(CDM)
    end
end

NS.ExtBuffPlaceholderHooks = PlaceholderHooks
