local _, NS = ...

local ConfigUI = {}

function ConfigUI.Create(ctx)
    local self = {
        ctx = ctx or {},
        guiContainer = nil,
        guiMoveButton = nil,
        guiExtButton = nil,
        guiSubtitle = nil,
        movePopup = nil,
        extensionsPopup = nil,
    }

    local function StylePurpleButton(btn)
        if not btn then return end
        if not btn._purpleStyled then
            if btn.GetNormalTexture and btn:GetNormalTexture() then btn:GetNormalTexture():SetAlpha(0) end
            if btn.GetPushedTexture and btn:GetPushedTexture() then btn:GetPushedTexture():SetAlpha(0) end
            if btn.GetHighlightTexture and btn:GetHighlightTexture() then btn:GetHighlightTexture():SetAlpha(0) end
            if btn.GetDisabledTexture and btn:GetDisabledTexture() then btn:GetDisabledTexture():SetAlpha(0) end
            if btn.GetRegions then
                for _, region in ipairs({ btn:GetRegions() }) do
                    if region and region.IsObjectType and region:IsObjectType("Texture") then
                        region:SetAlpha(0)
                    end
                end
            end

            local bg = btn:CreateTexture(nil, "ARTWORK")
            bg:SetAllPoints()
            btn._purpleBg = bg

            local borderTop = btn:CreateTexture(nil, "BORDER")
            borderTop:SetColorTexture(0.20, 0.08, 0.33, 1)
            borderTop:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
            borderTop:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
            borderTop:SetHeight(1)

            local borderBottom = btn:CreateTexture(nil, "BORDER")
            borderBottom:SetColorTexture(0.20, 0.08, 0.33, 1)
            borderBottom:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
            borderBottom:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
            borderBottom:SetHeight(1)

            local borderLeft = btn:CreateTexture(nil, "BORDER")
            borderLeft:SetColorTexture(0.20, 0.08, 0.33, 1)
            borderLeft:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
            borderLeft:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
            borderLeft:SetWidth(1)

            local borderRight = btn:CreateTexture(nil, "BORDER")
            borderRight:SetColorTexture(0.20, 0.08, 0.33, 1)
            borderRight:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
            borderRight:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
            borderRight:SetWidth(1)

            btn._purpleBorderTop = borderTop
            btn._purpleBorderBottom = borderBottom
            btn._purpleBorderLeft = borderLeft
            btn._purpleBorderRight = borderRight
            btn._purpleStyled = true
        end

        btn._purpleBg:SetColorTexture(0.52, 0.22, 0.78, 1)
        if btn._purpleBorderTop then btn._purpleBorderTop:SetAlpha(1) end
        if btn._purpleBorderBottom then btn._purpleBorderBottom:SetAlpha(1) end
        if btn._purpleBorderLeft then btn._purpleBorderLeft:SetAlpha(1) end
        if btn._purpleBorderRight then btn._purpleBorderRight:SetAlpha(1) end
        local fs = btn:GetFontString()
        if fs then fs:SetTextColor(1, 1, 1, 1) end

        btn:SetScript("OnMouseDown", function(b)
            if b._purpleBg then b._purpleBg:SetColorTexture(0.42, 0.16, 0.62, 1) end
        end)
        btn:SetScript("OnMouseUp", function(b)
            if b._purpleBg then b._purpleBg:SetColorTexture(0.52, 0.22, 0.78, 1) end
        end)
    end

    function self:UpdateGuiButtonVisual()
        if not self.guiMoveButton then return end
        if self.ctx.IsMoveModeEnabled and self.ctx.IsMoveModeEnabled() then
            self.guiMoveButton:SetText("Disable Move")
        else
            self.guiMoveButton:SetText("Move")
        end
    end

    function self:EnsureMovePopup()
        if self.movePopup then return self.movePopup end

        local popup = CreateFrame("Frame", "AyijeCDMExtensionsMovePopup", UIParent, "BackdropTemplate")
        popup:SetSize(380, 130)
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(950)
        popup:SetClampedToScreen(true)
        popup:SetMovable(true)
        popup:EnableMouse(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
        popup:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        popup:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
        popup:SetBackdropBorderColor(0.8, 0.65, 0.15, 1)

        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -14)
        title:SetText("Extensions Move Mode Active")
        title:SetTextColor(0.6, 0.2, 0.9, 1)

        local body = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        body:SetPoint("TOP", title, "BOTTOM", 0, -10)
        body:SetWidth(340)
        body:SetJustifyH("CENTER")
        body:SetText("Drag highlighted CDM elements.\nClick Done to exit move mode and reopen CDM settings.")

        local done = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        done:SetSize(120, 24)
        done:SetPoint("BOTTOM", popup, "BOTTOM", 0, 12)
        done:SetText("Done")
        done:SetScript("OnClick", function()
            if self.ctx.OnMoveDone then self.ctx.OnMoveDone() end
        end)

        popup:Hide()
        self.movePopup = popup
        return popup
    end

    function self:EnsureExtensionsPopup()
        if self.extensionsPopup then return self.extensionsPopup end

        local popup = CreateFrame("Frame", "AyijeCDMExtensionsSettingsPopup", UIParent, "BackdropTemplate")
        popup:SetSize(300, 140)
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(960)
        popup:SetClampedToScreen(true)
        popup:SetMovable(true)
        popup:EnableMouse(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
        popup:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        popup:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
        popup:SetBackdropBorderColor(0.70, 0.40, 1.00, 1)

        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -14)
        title:SetText("Extensions")
        title:SetTextColor(0.70, 0.40, 1.00, 1)

        local check = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", popup, "TOPLEFT", 18, -48)
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.text:SetPoint("LEFT", check, "RIGHT", 4, 1)
        check.text:SetText("Hide Minimap Button")

        check:SetScript("OnClick", function(btn)
            local db = self.ctx.GetExtDB and self.ctx.GetExtDB()
            if not db then return end
            db.minimap.hide = btn:GetChecked()
            if self.ctx.UpdateMinimapButtonVisibility then
                self.ctx.UpdateMinimapButtonVisibility()
            end
        end)

        popup:SetScript("OnShow", function()
            local db = self.ctx.GetExtDB and self.ctx.GetExtDB()
            check:SetChecked(db and db.minimap and db.minimap.hide)
        end)

        local closeBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        closeBtn:SetSize(100, 24)
        closeBtn:SetPoint("BOTTOM", popup, "BOTTOM", 0, 12)
        closeBtn:SetText("Close")
        closeBtn:SetScript("OnClick", function()
            popup:Hide()
        end)

        popup:Hide()
        self.extensionsPopup = popup
        return popup
    end

    function self:EnsureGuiButtons()
        local configFrame = self.ctx.GetGuiButtonParent and self.ctx.GetGuiButtonParent()
        if not configFrame then return end

        local rebuild = (not self.guiContainer) or (self.guiContainer:GetParent() ~= configFrame)
        if rebuild then
            if self.guiContainer then
                self.guiContainer:Hide()
                self.guiContainer:SetParent(nil)
            end
            self.guiContainer = CreateFrame("Frame", nil, configFrame)
            self.guiContainer:SetSize(190, 42)
            self.guiContainer:SetFrameStrata("FULLSCREEN_DIALOG")

            local extBtn = CreateFrame("Button", nil, self.guiContainer, "UIPanelButtonTemplate")
            extBtn:SetSize(95, 22)
            extBtn:SetPoint("TOPRIGHT", self.guiContainer, "TOPRIGHT", 0, 0)
            extBtn:SetText("Extensions")
            extBtn:SetScript("OnClick", function()
                local popup = self:EnsureExtensionsPopup()
                if popup:IsShown() then popup:Hide() else popup:Show() end
            end)

            local moveBtn = CreateFrame("Button", nil, self.guiContainer, "UIPanelButtonTemplate")
            moveBtn:SetSize(80, 22)
            moveBtn:SetPoint("RIGHT", extBtn, "LEFT", -6, 0)
            moveBtn:SetScript("OnClick", function()
                if self.ctx.IsMoveModeEnabled and self.ctx.IsMoveModeEnabled() then
                    if self.ctx.OnDisableMove then self.ctx.OnDisableMove() end
                else
                    if self.ctx.OnEnableMove then self.ctx.OnEnableMove() end
                end
            end)

            local subtitle = self.guiContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            subtitle:SetPoint("TOP", self.guiContainer, "TOP", 0, -28)
            subtitle:SetWidth(190)
            subtitle:SetJustifyH("CENTER")
            subtitle:SetText("Extensions by. Seathasky")
            subtitle:SetTextColor(0.70, 0.40, 1.00, 1)

            self.guiMoveButton = moveBtn
            self.guiExtButton = extBtn
            self.guiSubtitle = subtitle
        end

        self.guiContainer:SetParent(configFrame)
        self.guiContainer:SetFrameLevel((configFrame:GetFrameLevel() or 1) + 200)
        self.guiContainer:ClearAllPoints()
        self.guiContainer:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -44, -25)
        self.guiContainer:Show()

        self.guiMoveButton:SetFrameStrata("FULLSCREEN_DIALOG")
        self.guiExtButton:SetFrameStrata("FULLSCREEN_DIALOG")
        self.guiMoveButton:SetFrameLevel(self.guiContainer:GetFrameLevel() + 2)
        self.guiExtButton:SetFrameLevel(self.guiContainer:GetFrameLevel() + 2)
        StylePurpleButton(self.guiMoveButton)
        StylePurpleButton(self.guiExtButton)
        self.guiMoveButton:Show()
        self.guiExtButton:Show()
        if self.guiSubtitle then self.guiSubtitle:Show() end
        self:UpdateGuiButtonVisual()
    end

    function self:SyncContainerVisibility(configFrame, showButton)
        if self.guiContainer then
            if showButton and configFrame then
                self.guiContainer:ClearAllPoints()
                self.guiContainer:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -44, -25)
            end
            self.guiContainer:SetShown(showButton)
        end
    end

    return self
end

NS.ExtConfigUI = ConfigUI
