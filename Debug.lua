local _, NS = ...

local Debug = {}

function Debug.RegisterSlashCommands(ctx)
    if not ctx then return end

    SLASH_CDMEXT1 = "/cdmext"
    SlashCmdList["CDMEXT"] = function(msg)
        local cmd = strtrim(msg or ""):lower()
        if cmd == "debug" then
            local CDM = ctx.GetCDM and ctx.GetCDM()
            if not CDM then
                print("|cffff6600[CDM-Ext]|r CDM not loaded.")
                return
            end
            local pName = CDM.activeProfileName or "(nil)"
            local globalDB = _G.Ayije_CDMDB
            local sameRef = globalDB and globalDB.profiles and globalDB.profiles[pName] == CDM.db
            print("|cff00ccff[CDM-Ext]|r Profile: |cffffd200" .. pName .. "|r  db==profile: " .. tostring(sameRef))
            local emp = CDM.db and rawget(CDM.db, "editModePositions")
            if emp then
                for vName, vData in pairs(emp) do
                    if type(vData) == "table" and vData["Default"] then
                        local d = vData["Default"]
                        print("  " .. vName .. ": x=" .. tostring(d.x) .. " y=" .. tostring(d.y) .. " pt=" .. tostring(d.point))
                    end
                end
            else
                print("  editModePositions: |cffff0000NOT in profile (nil rawget)|r")
            end
            local uw = rawget(CDM.db, "utilityWrap")
            local uu = rawget(CDM.db, "utilityUnlock")
            local ux = rawget(CDM.db, "utilityXOffset")
            local uy = rawget(CDM.db, "utilityYOffset")
            print("  utilityWrap=" .. tostring(uw) .. " unlock=" .. tostring(uu) .. " xOff=" .. tostring(ux) .. " yOff=" .. tostring(uy))
            local cbx = rawget(CDM.db, "castBarOffsetX")
            local cby = rawget(CDM.db, "castBarOffsetY")
            local cba = rawget(CDM.db, "castBarAnchorToResources")
            print("  castBar: x=" .. tostring(cbx) .. " y=" .. tostring(cby) .. " anchorRes=" .. tostring(cba))
            print("  moveDirty=" .. tostring(ctx.GetMoveDirty and ctx.GetMoveDirty()))
        elseif cmd == "save" then
            if ctx.CaptureAllPositionsAndPersist then
                ctx.CaptureAllPositionsAndPersist()
            end
            if ctx.SetMoveDirty then
                ctx.SetMoveDirty(true)
            end
            print("|cff00ccff[CDM-Ext]|r Positions captured and persisted. Use /reload to test.")
        else
            print("|cff00ccff[CDM-Ext]|r Commands: /cdmext debug | /cdmext save")
        end
    end
end

NS.ExtDebug = Debug
