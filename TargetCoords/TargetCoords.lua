-- ============================================================================
-- TargetCoords.lua
-- Version: 2.1.0
-- Purpose: Display the current target's world coordinates in a movable,
--          fixed-size in-game frame.
-- Notes  : Data updates are separated from display updates. Layout is fixed.
-- ============================================================================

local ADDON_ID = "TargetCoords"
local context = UI.CreateContext("TargetCoordsContext")

-- ----------------------------------------------------------------------------
-- CONFIGURATION
-- ----------------------------------------------------------------------------

local CONFIG = {
    FRAME_WIDTH = 136,
    FRAME_HEIGHT = 88,
    FRAME_ALPHA = 0.60,

    TITLE_TEXT = "TargetCoords",
    TITLE_FONT_SIZE = 15,
    VALUE_FONT_SIZE = 13,

    TITLE_X = 10,
    TITLE_Y = 8,

    ROW_X = 12,
    ROW_Y = 30,
    ROW_GAP = 18,
}

-- ----------------------------------------------------------------------------
-- STATE
-- ----------------------------------------------------------------------------

local STATE = {
    data = {
        targetId = nil,
        hasTarget = false,
        hasCoords = false,
        coordX = nil,
        coordY = nil,
        coordZ = nil,
    },

    display = {
        xText = "X: --",
        yText = "Y: --",
        zText = "Z: --",
    },

    drag = {
        active = false,
        offsetX = 0,
        offsetY = 0,
        anchoredTopLeft = false,
    },
}

-- ----------------------------------------------------------------------------
-- UI REFERENCES
-- ----------------------------------------------------------------------------

local UIREF = {
    frame = nil,
    title = nil,
    labelX = nil,
    labelY = nil,
    labelZ = nil,
}

-- ----------------------------------------------------------------------------
-- UI HELPERS
-- ----------------------------------------------------------------------------

local function CreateTextFrame(name, parent, fontSize, r, g, b, a, text)
    local textFrame = UI.CreateFrame("Text", name, parent)
    textFrame:SetFontSize(fontSize)
    textFrame:SetFontColor(r, g, b, a)
    textFrame:SetText(text)
    return textFrame
end

local function BuildUI()
    UIREF.frame = UI.CreateFrame("Frame", "TargetCoordsFrame", context)
    UIREF.frame:SetWidth(CONFIG.FRAME_WIDTH)
    UIREF.frame:SetHeight(CONFIG.FRAME_HEIGHT)
    UIREF.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    UIREF.frame:SetBackgroundColor(0, 0, 0, CONFIG.FRAME_ALPHA)

    UIREF.title = CreateTextFrame(
        "TargetCoordsTitle",
        UIREF.frame,
        CONFIG.TITLE_FONT_SIZE,
        0.9, 0.9, 0.9, 1,
        CONFIG.TITLE_TEXT
    )

    UIREF.labelX = CreateTextFrame(
        "TargetCoordsLabelX",
        UIREF.frame,
        CONFIG.VALUE_FONT_SIZE,
        1, 1, 0, 1,
        STATE.display.xText
    )

    UIREF.labelY = CreateTextFrame(
        "TargetCoordsLabelY",
        UIREF.frame,
        CONFIG.VALUE_FONT_SIZE,
        1, 1, 0, 1,
        STATE.display.yText
    )

    UIREF.labelZ = CreateTextFrame(
        "TargetCoordsLabelZ",
        UIREF.frame,
        CONFIG.VALUE_FONT_SIZE,
        1, 1, 0, 1,
        STATE.display.zText
    )

    UIREF.title:SetPoint("TOPLEFT", UIREF.frame, "TOPLEFT", CONFIG.TITLE_X, CONFIG.TITLE_Y)
    UIREF.labelX:SetPoint("TOPLEFT", UIREF.frame, "TOPLEFT", CONFIG.ROW_X, CONFIG.ROW_Y)
    UIREF.labelY:SetPoint("TOPLEFT", UIREF.frame, "TOPLEFT", CONFIG.ROW_X, CONFIG.ROW_Y + CONFIG.ROW_GAP)
    UIREF.labelZ:SetPoint("TOPLEFT", UIREF.frame, "TOPLEFT", CONFIG.ROW_X, CONFIG.ROW_Y + (CONFIG.ROW_GAP * 2))
end

local function SetTextIfChanged(frame, stateKey, newText)
    if STATE.display[stateKey] == newText then
        return
    end

    STATE.display[stateKey] = newText
    frame:SetText(newText)
end

local function RefreshDisplay()
    local xText
    local yText
    local zText

    if STATE.data.hasCoords then
        xText = string.format("X: %.2f", STATE.data.coordX)
        yText = string.format("Y: %.2f", STATE.data.coordY)
        zText = string.format("Z: %.2f", STATE.data.coordZ)
    else
        xText = "X: --"
        yText = "Y: --"
        zText = "Z: --"
    end

    SetTextIfChanged(UIREF.labelX, "xText", xText)
    SetTextIfChanged(UIREF.labelY, "yText", yText)
    SetTextIfChanged(UIREF.labelZ, "zText", zText)
end

local function EnsureTopLeftAnchor()
    if STATE.drag.anchoredTopLeft then
        return
    end

    local left = UIREF.frame:GetLeft() or 0
    local top = UIREF.frame:GetTop() or 0

    UIREF.frame:ClearAll()
    UIREF.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, top)

    STATE.drag.anchoredTopLeft = true
end

-- ----------------------------------------------------------------------------
-- DATA HELPERS
-- ----------------------------------------------------------------------------

local function ClearRawData()
    STATE.data.targetId = nil
    STATE.data.hasTarget = false
    STATE.data.hasCoords = false
    STATE.data.coordX = nil
    STATE.data.coordY = nil
    STATE.data.coordZ = nil
end

local function SetRawCoords(x, y, z)
    STATE.data.coordX = x
    STATE.data.coordY = y
    STATE.data.coordZ = z
    STATE.data.hasCoords = (x ~= nil and y ~= nil and z ~= nil)
end

local function RefreshDataFromSnapshot()
    local targetId = Inspect.Unit.Lookup("player.target")

    if not targetId then
        ClearRawData()
        RefreshDisplay()
        return
    end

    STATE.data.targetId = targetId
    STATE.data.hasTarget = true

    local detail = Inspect.Unit.Detail(targetId)
    if detail and detail.coordX ~= nil and detail.coordY ~= nil and detail.coordZ ~= nil then
        SetRawCoords(detail.coordX, detail.coordY, detail.coordZ)
    else
        SetRawCoords(nil, nil, nil)
    end

    RefreshDisplay()
end

local function SyncTargetSelection()
    local currentTargetId = Inspect.Unit.Lookup("player.target")
    if currentTargetId == STATE.data.targetId then
        return
    end

    RefreshDataFromSnapshot()
end

local function RefreshCoordsFromEvent(xValues, yValues, zValues)
    local currentTargetId = Inspect.Unit.Lookup("player.target")

    if currentTargetId ~= STATE.data.targetId then
        RefreshDataFromSnapshot()
        return
    end

    if not currentTargetId then
        ClearRawData()
        RefreshDisplay()
        return
    end

    local changed = false

    if type(xValues) == "table" and xValues[currentTargetId] ~= nil then
        STATE.data.coordX = xValues[currentTargetId]
        changed = true
    end

    if type(yValues) == "table" and yValues[currentTargetId] ~= nil then
        STATE.data.coordY = yValues[currentTargetId]
        changed = true
    end

    if type(zValues) == "table" and zValues[currentTargetId] ~= nil then
        STATE.data.coordZ = zValues[currentTargetId]
        changed = true
    end

    if not changed then
        return
    end

    STATE.data.hasTarget = true
    STATE.data.hasCoords = (
        STATE.data.coordX ~= nil and
        STATE.data.coordY ~= nil and
        STATE.data.coordZ ~= nil
    )

    RefreshDisplay()
end

-- ----------------------------------------------------------------------------
-- DRAG HANDLERS
-- ----------------------------------------------------------------------------

local function OnLeftDown()
    EnsureTopLeftAnchor()

    local mouse = Inspect.Mouse()
    STATE.drag.active = true
    STATE.drag.offsetX = mouse.x - (UIREF.frame:GetLeft() or 0)
    STATE.drag.offsetY = mouse.y - (UIREF.frame:GetTop() or 0)
end

local function OnLeftUp()
    STATE.drag.active = false
end

local function OnMouseMove()
    if not STATE.drag.active then
        return
    end

    local mouse = Inspect.Mouse()
    UIREF.frame:SetPoint(
        "TOPLEFT",
        UIParent,
        "TOPLEFT",
        mouse.x - STATE.drag.offsetX,
        mouse.y - STATE.drag.offsetY
    )
end

-- ----------------------------------------------------------------------------
-- STARTUP
-- ----------------------------------------------------------------------------

BuildUI()

UIREF.frame:EventAttach(Event.UI.Input.Mouse.Left.Down, OnLeftDown, "TargetCoordsLeftDown")
UIREF.frame:EventAttach(Event.UI.Input.Mouse.Left.Up, OnLeftUp, "TargetCoordsLeftUp")
UIREF.frame:EventAttach(Event.UI.Input.Mouse.Cursor.Move, OnMouseMove, "TargetCoordsMouseMove")

-- ----------------------------------------------------------------------------
-- EVENT REGISTRATION
-- ----------------------------------------------------------------------------

table.insert(Event.Addon.Load.End, {
    function(addonId)
        if addonId ~= ADDON_ID then
            return
        end

        Command.Console.Display("general", false, "TargetCoords loaded.", false)
        RefreshDataFromSnapshot()
    end,
    ADDON_ID,
    "OnLoad"
})

table.insert(Event.System.Update.End, {
    function()
        SyncTargetSelection()
    end,
    ADDON_ID,
    "OnUpdate"
})

table.insert(Event.Unit.Availability.Full, {
    function(units)
        local targetId = STATE.data.targetId or Inspect.Unit.Lookup("player.target")
        if targetId and type(units) == "table" and units[targetId] then
            RefreshDataFromSnapshot()
        end
    end,
    ADDON_ID,
    "OnAvailabilityFull"
})

table.insert(Event.Unit.Detail.Coord, {
    function(xValues, yValues, zValues)
        RefreshCoordsFromEvent(xValues, yValues, zValues)
    end,
    ADDON_ID,
    "OnCoord"
})

-- ----------------------------------------------------------------------------
-- END OF FILE
-- ----------------------------------------------------------------------------
