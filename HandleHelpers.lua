local _, NS = ...

local Helpers = {}

function Helpers.IsAnyHandleDragging(handles)
    for _, handle in pairs(handles or {}) do
        if handle and handle.dragging then
            return true
        end
    end
    return false
end

function Helpers.ContainerHasVisibleChild(container)
    if not (container and container.GetChildren) then
        return false
    end
    for _, child in ipairs({ container:GetChildren() }) do
        if child and child.IsShown and child:IsShown() then
            local alpha = child.GetAlpha and child:GetAlpha() or 1
            local w = child.GetWidth and child:GetWidth() or 0
            local h = child.GetHeight and child:GetHeight() or 0
            if alpha > 0.01 and w > 2 and h > 2 then
                return true
            end
        end
    end
    return false
end

function Helpers.GroupHasConfiguredSpells(groupData)
    if type(groupData) ~= "table" then return false end

    local keys = { "spells", "spellIDs", "spellList", "auras", "buffs" }
    for _, key in ipairs(keys) do
        local t = groupData[key]
        if type(t) == "table" and next(t) ~= nil then
            return true
        end
    end

    if type(groupData.iconSpellID) == "number" and groupData.iconSpellID > 0 then
        return true
    end

    for k, v in pairs(groupData) do
        if type(k) == "number" then
            if type(v) == "number" and v > 0 then
                return true
            end
            if type(v) == "table" then
                if (type(v.spellID) == "number" and v.spellID > 0) or (type(v.id) == "number" and v.id > 0) then
                    return true
                end
            end
        end
    end

    return false
end

NS.ExtHandleHelpers = Helpers
