local _, NS = ...

local Minimap = {}

local MINIMAP_ICON_ID = "Ayije_CDM_Extensions"
local MINIMAP_ICON_PATH = "Interface\\AddOns\\Ayije_CDM_Extensions\\Images\\ACDM.png"

function Minimap.UpdateMinimapButtonVisibility(getExtDB)
    local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not DBIcon then return end
    local db = getExtDB and getExtDB()
    if not db then return end
    if db.minimap and db.minimap.hide then
        DBIcon:Hide(MINIMAP_ICON_ID)
    else
        DBIcon:Show(MINIMAP_ICON_ID)
    end
end

function Minimap.RegisterMinimapButton(ctx)
    if not ctx then return nil end
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not (LDB and DBIcon) then return nil end

    if not ctx.miniDataObject then
        ctx.miniDataObject = LDB:NewDataObject(MINIMAP_ICON_ID, {
            type = "launcher",
            label = "Ayije CDM",
            icon = MINIMAP_ICON_PATH,
            OnClick = function(_, button)
                if button == "RightButton" then
                    local popup = ctx.EnsureExtensionsPopup and ctx.EnsureExtensionsPopup()
                    if popup and popup.IsShown and popup:IsShown() then
                        popup:Hide()
                    elseif popup then
                        popup:Show()
                    end
                    return
                end
                if ctx.ShowConfigFrame then
                    ctx.ShowConfigFrame()
                end
            end,
            OnTooltipShow = function(tt)
                tt:AddLine("|cFF3bb273Ayije_CDM|r |cFFB36CFFExtensions|r", 1, 1, 1)
                tt:AddLine("Extensions by. Seathasky", 1, 0.82, 0)
                tt:AddLine("Left Click: Open Ayije CDM", 0.8, 0.8, 0.8)
                tt:AddLine("Right Click: Open Extensions popup", 0.8, 0.8, 0.8)
            end,
        })
    end

    local db = (ctx.GetExtDB and ctx.GetExtDB() or {})
    if not DBIcon:IsRegistered(MINIMAP_ICON_ID) then
        DBIcon:Register(MINIMAP_ICON_ID, ctx.miniDataObject, db.minimap)
    end
    Minimap.UpdateMinimapButtonVisibility(ctx.GetExtDB)
    return ctx.miniDataObject
end

NS.ExtMinimap = Minimap
