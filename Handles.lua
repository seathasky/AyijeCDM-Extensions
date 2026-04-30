local _, NS = ...

local HandleHelpers = NS and NS.ExtHandleHelpers

local Handles = {}

function Handles.Create(ctx)
    local self = {
        ctx = ctx or {},
        handles = {},
        buffGroupGhosts = {},
    }

    local function IsMoveModeEnabled()
        return self.ctx.IsMoveModeEnabled and self.ctx.IsMoveModeEnabled() or false
    end

    local function SetHandleVisual(handle, active)
        if not handle or not handle.fill then return end
        if handle.hideBox then
            handle.fill:SetColorTexture(0, 0, 0, 0)
            if handle.top then handle.top:SetAlpha(0) end
            if handle.bottom then handle.bottom:SetAlpha(0) end
            if handle.left then handle.left:SetAlpha(0) end
            if handle.right then handle.right:SetAlpha(0) end
            return
        end
        if handle.useMinimalFill then
            if active then
                handle.fill:SetColorTexture(1, 0.78, 0.07, 0.04)
            else
                handle.fill:SetColorTexture(0, 0, 0, 0)
            end
            return
        end
        if active then
            handle.fill:SetColorTexture(1, 0.78, 0.07, 0.16)
        else
            handle.fill:SetColorTexture(0.7, 0.7, 0.7, 0.09)
        end
    end

    local function BuildHandle(spec, target)
        local h = CreateFrame("Frame", nil, target)
        h:SetPoint("TOPLEFT", target, "TOPLEFT", -6, 6)
        h:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 6, -6)
        h:SetFrameStrata("DIALOG")
        h:SetFrameLevel(400)
        h:EnableMouse(true)
        h:RegisterForDrag("LeftButton")

        local fill = h:CreateTexture(nil, "BACKGROUND")
        fill:SetAllPoints()
        fill:SetColorTexture(0.7, 0.7, 0.7, 0.09)
        h.fill = fill

        local top = h:CreateTexture(nil, "OVERLAY")
        top:SetColorTexture(1, 0.78, 0.07, 0.65)
        top:SetPoint("TOPLEFT")
        top:SetPoint("TOPRIGHT")
        top:SetHeight(1)
        h.top = top

        local bottom = h:CreateTexture(nil, "OVERLAY")
        bottom:SetColorTexture(1, 0.78, 0.07, 0.65)
        bottom:SetPoint("BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT")
        bottom:SetHeight(1)
        h.bottom = bottom

        local left = h:CreateTexture(nil, "OVERLAY")
        left:SetColorTexture(1, 0.78, 0.07, 0.65)
        left:SetPoint("TOPLEFT")
        left:SetPoint("BOTTOMLEFT")
        left:SetWidth(1)
        h.left = left

        local right = h:CreateTexture(nil, "OVERLAY")
        right:SetColorTexture(1, 0.78, 0.07, 0.65)
        right:SetPoint("TOPRIGHT")
        right:SetPoint("BOTTOMRIGHT")
        right:SetWidth(1)
        h.right = right

        local text = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("BOTTOM", h, "TOP", 0, 4)
        local prefix = spec.textPrefix or "CDM "
        text:SetText(prefix .. (spec.label or "Move"))
        text:SetTextColor(1, 0.82, 0, 1)
        h.text = text

        if spec.bigPlus then
            local plus = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            plus:SetPoint("RIGHT", text, "LEFT", -3, 0)
            plus:SetText("+")
            plus:SetTextColor(1, 0.82, 0, 1)
            h.plus = plus
        end

        h.spec = spec
        h.target = target
        h.useMinimalFill = spec.useMinimalFill and true or false
        h.hideBox = spec.hideBox and true or false
        h.dragging = false

        h:SetScript("OnDragStart", function(frameHandle)
            if not IsMoveModeEnabled() or InCombatLockdown() then return end
            local frame = frameHandle.target
            if not frame then return end

            frameHandle.essentialDragUtilLeft = nil
            frameHandle.essentialDragUtilTop = nil
            if frameHandle.spec and frameHandle.spec.id == "essential" then
                local CDM = self.ctx.GetCDM and self.ctx.GetCDM()
                local V = CDM and CDM.CONST and CDM.CONST.VIEWERS
                local util = CDM and V and CDM.anchorContainers and CDM.anchorContainers[V.UTILITY]
                if util then
                    frameHandle.essentialDragUtilLeft = util:GetLeft()
                    frameHandle.essentialDragUtilTop = util:GetTop()
                end
            end

            frame:SetMovable(true)
            frame:SetClampedToScreen(true)
            frame:StartMoving()
            frameHandle.dragging = true
            if self.ctx.SetMoveDirty then self.ctx.SetMoveDirty(true) end
            SetHandleVisual(frameHandle, true)
        end)

        h:SetScript("OnUpdate", function(frameHandle)
            if frameHandle.dragging and frameHandle.spec and frameHandle.spec.save and frameHandle.target then
                if frameHandle.spec.id == "essential" and frameHandle.essentialDragUtilLeft and frameHandle.essentialDragUtilTop then
                    if self.ctx.KeepUtilityStationaryDuringEssentialDrag and self.ctx.GetCDM then
                        self.ctx.KeepUtilityStationaryDuringEssentialDrag(self.ctx.GetCDM(), frameHandle.essentialDragUtilLeft, frameHandle.essentialDragUtilTop)
                    end
                end
                frameHandle.spec.save(frameHandle.target)
            end
        end)

        h:SetScript("OnDragStop", function(frameHandle)
            local frame = frameHandle.target
            if frame then
                frame:StopMovingOrSizing()
            end
            frameHandle.dragging = false
            frameHandle.essentialDragUtilLeft = nil
            frameHandle.essentialDragUtilTop = nil
            SetHandleVisual(frameHandle, IsMoveModeEnabled())

            if frameHandle.spec and frameHandle.spec.save and frameHandle.target then
                frameHandle.spec.save(frameHandle.target)
            end
            if self.ctx.PersistMoveSnapshot then self.ctx.PersistMoveSnapshot() end
            if self.ctx.RefreshCDM then self.ctx.RefreshCDM() end
        end)

        return h
    end

    local function UpsertHandle(id, label, frame, saveFunc, seen, opts)
        if not (id and frame and saveFunc) then return end
        seen[id] = true

        local handle = self.handles[id]
        if not handle or handle.target ~= frame then
            if handle then
                handle:Hide()
                handle:SetParent(nil)
            end
            handle = BuildHandle({
                id = id,
                label = label,
                save = saveFunc,
                textPrefix = opts and opts.textPrefix,
                useMinimalFill = opts and opts.useMinimalFill,
                hideBox = opts and opts.hideBox,
                bigPlus = opts and opts.bigPlus,
            }, frame)
            self.handles[id] = handle
        elseif opts then
            handle.useMinimalFill = opts.useMinimalFill and true or false
            handle.hideBox = opts.hideBox and true or false
            if handle.text then
                local prefix = opts.textPrefix
                if prefix == nil then prefix = "CDM " end
                handle.text:SetText(prefix .. (label or "Move"))
            end
            if handle.plus then
                handle.plus:SetShown(opts.bigPlus and true or false)
            end
        end

        local active = IsMoveModeEnabled()
        handle:EnableMouse(active)
        handle:SetShown(active)
        if handle.text then
            handle.text:SetShown(active)
        end
        SetHandleVisual(handle, active)
    end

    local function GetBuffGroupGhostFrame(CDM, idx, groupData, runtimeContainer)
        if not (CDM and idx and groupData) then return nil end

        local ghost = self.buffGroupGhosts[idx]
        if not ghost then
            ghost = CreateFrame("Frame", nil, UIParent)
            ghost:SetFrameStrata("DIALOG")
            ghost:SetFrameLevel(380)
            ghost.bg = ghost:CreateTexture(nil, "BACKGROUND")
            ghost.bg:SetAllPoints()
            ghost.bg:SetColorTexture(1, 0.82, 0, 0)
            ghost.icon = ghost:CreateTexture(nil, "OVERLAY", nil, 1)
            ghost.icon:SetAllPoints()
            ghost.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            ghost.icon:SetDrawLayer("OVERLAY", 7)
            ghost.border = ghost:CreateTexture(nil, "OVERLAY", nil, 2)
            ghost.border:SetAllPoints()
            ghost.border:SetColorTexture(1, 0.82, 0, 0.85)
            self.buffGroupGhosts[idx] = ghost
        end

        local function ResolveSpellTexture(spellID)
            if type(spellID) ~= "number" or spellID <= 0 then return nil end
            if C_Spell and C_Spell.GetSpellTexture then
                return C_Spell.GetSpellTexture(spellID)
            end
            if GetSpellTexture then
                return GetSpellTexture(spellID)
            end
            return nil
        end

        local iconTex
        local spellList = groupData.spells
        if type(spellList) == "table" then
            for _, entry in ipairs(spellList) do
                local spellID = entry
                if type(entry) == "table" then
                    spellID = entry.spellID or entry.id
                end
                local tex = ResolveSpellTexture(spellID)
                if tex then
                    iconTex = tex
                    break
                end
            end
            if not iconTex then
                for k, v in pairs(spellList) do
                    local spellID = nil
                    if type(k) == "number" and type(v) == "boolean" then
                        spellID = k
                    elseif type(v) == "number" then
                        spellID = v
                    elseif type(v) == "table" then
                        spellID = v.spellID or v.id
                    end
                    local tex = ResolveSpellTexture(spellID)
                    if tex then
                        iconTex = tex
                        break
                    end
                end
            end
        end
        if not iconTex then
            iconTex = ResolveSpellTexture(groupData.iconSpellID)
        end
        if not iconTex then
            iconTex = ResolveSpellTexture(groupData.spellID)
        end
        if iconTex then
            ghost.icon:SetTexture(iconTex)
            ghost.icon:SetVertexColor(1, 1, 1, 0.96)
            ghost.bg:SetColorTexture(1, 0.82, 0, 0)
        else
            ghost.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            ghost.icon:SetVertexColor(1, 1, 1, 0.90)
            ghost.bg:SetColorTexture(1, 0.82, 0, 0.08)
        end

        local snap = self.ctx.Snap or function(v) return v end
        local w = snap((groupData.iconWidth or (CDM.db and CDM.db.sizeBuff and CDM.db.sizeBuff.w) or 40))
        local h = snap((groupData.iconHeight or (CDM.db and CDM.db.sizeBuff and CDM.db.sizeBuff.h) or 30))
        ghost:SetSize(math.max(18, w), math.max(18, h))
        ghost:ClearAllPoints()

        local x = groupData.offsetX
        local y = groupData.offsetY
        if x == nil or y == nil then
            local cx, cy
            if runtimeContainer and runtimeContainer.GetCenter then
                cx, cy = runtimeContainer:GetCenter()
            end
            if cx and cy then
                ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
            else
                ghost:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        else
            ghost:SetPoint("CENTER", UIParent, "CENTER", snap(x), snap(y))
        end

        ghost:SetShown(IsMoveModeEnabled())
        return ghost
    end

    function self:IsAnyHandleDragging()
        return HandleHelpers and HandleHelpers.IsAnyHandleDragging and HandleHelpers.IsAnyHandleDragging(self.handles) or false
    end

    function self:CaptureAllPositionsAndPersist()
        local CDM = self.ctx.GetCDM and self.ctx.GetCDM()
        if not CDM then return end

        for _, spec in ipairs(self.ctx.DragTargets or {}) do
            local frame = spec.getFrame and spec.getFrame(CDM)
            if frame and spec.save then
                spec.save(frame)
            end
        end

        local saveCooldown = self.ctx.SaveCooldownGroup
        local saveBuff = self.ctx.SaveBuffGroup
        local cdContainers = CDM.cooldownGroupContainers
        if cdContainers and saveCooldown then
            for idx, container in pairs(cdContainers) do
                if container then
                    saveCooldown(container, idx)
                end
            end
        end

        local buffContainers = CDM.buffGroupContainers
        if buffContainers and saveBuff then
            for idx, container in pairs(buffContainers) do
                if container then
                    saveBuff(container, idx)
                end
            end
        end

        if self.ctx.PersistMoveSnapshot then self.ctx.PersistMoveSnapshot() end
    end

    function self:UpdateHandles()
        local CDM = self.ctx.GetCDM and self.ctx.GetCDM()
        if not CDM then return end
        if self:IsAnyHandleDragging() then return end

        local seen = {}
        local usingGhostByBuffGroup = {}

        for _, spec in ipairs(self.ctx.DragTargets or {}) do
            local frame = spec.getFrame and spec.getFrame(CDM)
            if frame then
                UpsertHandle(spec.id, spec.label, frame, spec.save, seen)
            end
        end

        local saveCooldown = self.ctx.SaveCooldownGroup
        local saveBuff = self.ctx.SaveBuffGroup
        local cdContainers = CDM.cooldownGroupContainers
        local cdGroups = CDM.CooldownGroupSets and CDM.CooldownGroupSets.groups
        if cdContainers and cdGroups and saveCooldown then
            for idx, container in pairs(cdContainers) do
                if container and container:IsShown() and cdGroups[idx] then
                    local id = "cdgroup:" .. tostring(idx)
                    local label = "CD Group " .. tostring(idx)
                    UpsertHandle(id, label, container, function(frame)
                        saveCooldown(frame, idx)
                    end, seen, { textPrefix = "", useMinimalFill = true, hideBox = true, bigPlus = true })
                end
            end
        end

        local buffContainers = CDM.buffGroupContainers
        local buffGroups = CDM.BuffGroupSets and CDM.BuffGroupSets.groups
        if saveBuff and buffContainers and buffGroups then
            for idx, container in pairs(buffContainers) do
                local groupData = buffGroups[idx]
                if groupData then
                    local id = "buffgroup:" .. tostring(idx)
                    local label = "Buff Group " .. tostring(idx)
                    local configured = HandleHelpers and HandleHelpers.GroupHasConfiguredSpells and HandleHelpers.GroupHasConfiguredSpells(groupData)
                    local target = nil
                    if container and container:IsShown() then
                        target = container
                    elseif configured then
                        target = GetBuffGroupGhostFrame(CDM, idx, groupData, container)
                        if target then
                            usingGhostByBuffGroup[idx] = true
                        end
                    end

                    if target then
                        UpsertHandle(id, label, target, function(frame)
                            saveBuff(frame, idx)
                        end, seen, { textPrefix = "", useMinimalFill = true, hideBox = true, bigPlus = true })
                    end
                end
            end
        elseif saveBuff and buffGroups then
            for idx, groupData in pairs(buffGroups) do
                if HandleHelpers and HandleHelpers.GroupHasConfiguredSpells and HandleHelpers.GroupHasConfiguredSpells(groupData) then
                    local id = "buffgroup:" .. tostring(idx)
                    local label = "Buff Group " .. tostring(idx)
                    local target = GetBuffGroupGhostFrame(CDM, idx, groupData, nil)
                    if target then
                        usingGhostByBuffGroup[idx] = true
                        UpsertHandle(id, label, target, function(frame)
                            saveBuff(frame, idx)
                        end, seen, { textPrefix = "", useMinimalFill = true, hideBox = true, bigPlus = true })
                    end
                end
            end
        end

        for id, handle in pairs(self.handles) do
            if not seen[id] then
                handle:Hide()
                handle:EnableMouse(false)
            end
        end

        local active = IsMoveModeEnabled()
        for idx, ghost in pairs(self.buffGroupGhosts) do
            ghost:SetShown(active and usingGhostByBuffGroup[idx] == true)
        end
    end

    return self
end

NS.ExtHandles = Handles
