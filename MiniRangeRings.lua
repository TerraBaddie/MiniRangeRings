-- MiniRangeRings.lua
-- WoW 1.12.1 – Yard-accurate minimap rings for Hunters

-------------------------------------------------------
-- RING SIZE CALIBRATION (Zoom 3, 4, 5 only)
-------------------------------------------------------
local ringSize = {
    [0] = { ["41"]=0,  ["36"]=0,  ["25"]=0  },
    [1] = { ["41"]=0,  ["36"]=0,  ["25"]=0  },
    [2] = { ["41"]=0,  ["36"]=0,  ["25"]=0  },

    [3] = { ["41"]=45, ["36"]=42, ["25"]=27 },
    [4] = { ["41"]=60, ["36"]=55, ["25"]=38 },
    [5] = { ["41"]=92, ["36"]=85, ["25"]=59 },
}

-------------------------------------------------------
-- GLOBAL USER SETTINGS
-------------------------------------------------------
if not MRR_Alpha then
    MRR_Alpha = 0.30
end

-------------------------------------------------------
-- CENTER OFFSET (perfect for 7x7 blip)
-------------------------------------------------------
local RING_X_OFFSET = 0
local RING_Y_OFFSET = 2   -- final corrected alignment

-------------------------------------------------------
-- Update ring sizes + position
-------------------------------------------------------
function MRR_UpdateRings()
    if not Minimap then return end

    local zoom = Minimap:GetZoom() or 0

    ---------------------------------------------------
    -- Hide rings for zoom 0–2 (too zoomed-out)
    ---------------------------------------------------
    if zoom <= 2 then
        MRR_GreenRing:Hide()
        MRR_OrangeRing:Hide()
        MRR_RedRing:Hide()
        return
    end

    -- Show rings
    MRR_GreenRing:Show()
    MRR_OrangeRing:Show()
    MRR_RedRing:Show()

    ---------------------------------------------------
    -- Apply sizes
    ---------------------------------------------------
    local sizes = ringSize[zoom]
    if not sizes then return end

    MRR_GreenRing:SetWidth(sizes["41"])
    MRR_GreenRing:SetHeight(sizes["41"])

    MRR_OrangeRing:SetWidth(sizes["36"])
    MRR_OrangeRing:SetHeight(sizes["36"])

    MRR_RedRing:SetWidth(sizes["25"])
    MRR_RedRing:SetHeight(sizes["25"])

    ---------------------------------------------------
    -- Apply alpha
    ---------------------------------------------------
    local a = MRR_Alpha or 0.30
    MRR_GreenRing:SetAlpha(a)
    MRR_OrangeRing:SetAlpha(a)
    MRR_RedRing:SetAlpha(a)

    ---------------------------------------------------
    -- Center correction for pfUI + Default UI
    ---------------------------------------------------
    MRR_Frame:ClearAllPoints()
    MRR_Frame:SetPoint("CENTER", Minimap, "CENTER",
        RING_X_OFFSET, RING_Y_OFFSET)
end

-------------------------------------------------------
-- Helper Chat Printer
-------------------------------------------------------
local function MRR_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99MiniRangeRings:|r "..msg)
end

-------------------------------------------------------
-- Slash Commands
-------------------------------------------------------
SLASH_MRR1 = "/mrr"
SlashCmdList["MRR"] = function(msg)
    msg = string.lower(msg or "")

    ---------------------------------------------------
    -- /mrr on
    ---------------------------------------------------
    if msg == "on" then
        MRR_Frame:Show()
        MRR_UpdateRings()
        MRR_Print("Rings enabled.")
        return
    end

    ---------------------------------------------------
    -- /mrr off
    ---------------------------------------------------
    if msg == "off" then
        MRR_Frame:Hide()
        MRR_Print("Rings disabled.")
        return
    end

    ---------------------------------------------------
    -- /mrr alpha #
    ---------------------------------------------------
    if string.find(msg, "alpha") == 1 then
        local _, _, val = string.find(msg, "alpha%s+(%d*%.?%d*)")
        val = tonumber(val)

        if val and val >= 0 and val <= 1 then
            MRR_Alpha = val
            MRR_UpdateRings()
            MRR_Print("Alpha set to "..val)
        else
            MRR_Print("Usage: /mrr alpha 0.0 to 1.0")
        end
        return
    end

    ---------------------------------------------------
    -- /mrr list (status)
    ---------------------------------------------------
    if msg == "list" or msg == "status" then
        local z = Minimap:GetZoom()

        MRR_Print("Status:")
        MRR_Print("  Enabled: "..(MRR_Frame:IsVisible() and "Yes" or "No"))
        MRR_Print("  Alpha: "..MRR_Alpha)
        MRR_Print("  Minimap Zoom: "..z)

        local sizes = ringSize[z]
        if sizes then
            MRR_Print("  41 yards: "..sizes["41"].."px")
            MRR_Print("  36 yards: "..sizes["36"].."px")
            MRR_Print("  25 yards: "..sizes["25"].."px")
        end
        return
    end

    ---------------------------------------------------
    -- Help message
    ---------------------------------------------------
    MRR_Print("Commands:")
    MRR_Print("  /mrr on        - enable rings")
    MRR_Print("  /mrr off       - disable rings")
    MRR_Print("  /mrr alpha #   - set transparency (0–1)")
    MRR_Print("  /mrr list      - show current settings")
end

-------------------------------------------------------
-- Initial event update
-------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("MINIMAP_UPDATE_ZOOM")

ev:SetScript("OnEvent", function()
    MRR_UpdateRings()
end)

-------------------------------------------------------
-- Universal Vanilla-Safe Zoom Watcher (no varargs)
-------------------------------------------------------
local MRR_LastZoom = -1
local zoomWatcher = CreateFrame("Frame", "MRR_ZoomWatcher", UIParent)
local t = 0

zoomWatcher:SetScript("OnUpdate", function()
    t = t + arg1
    if t < 0.1 then return end
    t = 0

    local z = Minimap:GetZoom()
    if z ~= MRR_LastZoom then
        MRR_LastZoom = z
        MRR_UpdateRings()
    end
end)

-------------------------------------------------------
-- Replace ZoomIn / ZoomOut buttons (vanilla-safe)
-------------------------------------------------------
local origZoomIn  = MinimapZoomIn:GetScript("OnClick")
local origZoomOut = MinimapZoomOut:GetScript("OnClick")

MinimapZoomIn:SetScript("OnClick", function()
    if origZoomIn then origZoomIn() end
    MRR_UpdateRings()
end)

MinimapZoomOut:SetScript("OnClick", function()
    if origZoomOut then origZoomOut() end
    MRR_UpdateRings()
end)

-------------------------------------------------------
-- Mousewheel zoom support (Vanilla uses arg1)
-------------------------------------------------------
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function()
    local delta = arg1
    local z = Minimap:GetZoom()

    if delta > 0 and z < 5 then
        Minimap:SetZoom(z + 1)
    elseif delta < 0 and z > 0 then
        Minimap:SetZoom(z - 1)
    end

    MRR_UpdateRings()
end)

-------------------------------------------------------
-- Final initial update
-------------------------------------------------------
MRR_UpdateRings()
