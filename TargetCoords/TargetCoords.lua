local context = UI.CreateContext("TargetCoordsContext")
local initDone = false
local needsLayout = true
local pad = 8
local gap = 2
local titleGap = 4

local frame = UI.CreateFrame("Frame", "TargetCoordsFrame", context)
frame:SetWidth(10)
frame:SetHeight(10)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackgroundColor(0, 0, 0, 0.6)

local titleLabel = UI.CreateFrame("Text", "TargetCoordsTitle", frame)
titleLabel:SetFontSize(15)
titleLabel:SetFontColor(0.9, 0.9, 0.9, 1)
titleLabel:SetText("TargetCoords")

local labelX = UI.CreateFrame("Text", "TargetCoordsLabelX", frame)
labelX:SetFontSize(12)
labelX:SetFontColor(1, 1, 0, 1)
labelX:SetText("X: --")

local labelY = UI.CreateFrame("Text", "TargetCoordsLabelY", frame)
labelY:SetFontSize(12)
labelY:SetFontColor(1, 1, 0, 1)
labelY:SetText("Y: --")

local labelZ = UI.CreateFrame("Text", "TargetCoordsLabelZ", frame)
labelZ:SetFontSize(12)
labelZ:SetFontColor(1, 1, 0, 1)
labelZ:SetText("Z: --")

table.insert(Event.System.Update.End, { function()
    if not needsLayout then return end
    needsLayout = false

    local tw, th = titleLabel:GetWidth(), titleLabel:GetHeight()
    local w1, h1 = labelX:GetWidth(), labelX:GetHeight()
    local w2 = labelY:GetWidth()
    local w3 = labelZ:GetWidth()
    local lh = h1

    local fw = math.max(tw, w1, w2, w3) + pad * 2
    local fh = th + titleGap + lh * 3 + gap * 2 + pad * 2

    if not initDone then
        local cx = frame:GetLeft() + frame:GetWidth() / 2
        local cy = frame:GetTop() + frame:GetHeight() / 2
        frame:ClearAll()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", cx - fw / 2, cy - fh / 2)
        initDone = true
    end

    frame:SetWidth(fw)
    frame:SetHeight(fh)

    titleLabel:ClearAll()
    titleLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", (fw - tw) / 2, pad)

    labelX:ClearAll()
    labelX:SetPoint("TOPLEFT", frame, "TOPLEFT", (fw - w1) / 2, pad + th + titleGap)

    labelY:ClearAll()
    labelY:SetPoint("TOPLEFT", frame, "TOPLEFT", (fw - w2) / 2, pad + th + titleGap + lh + gap)

    labelZ:ClearAll()
    labelZ:SetPoint("TOPLEFT", frame, "TOPLEFT", (fw - w3) / 2, pad + th + titleGap + lh * 2 + gap * 2)
end, "TargetCoords", "Layout" })

frame:EventAttach(Event.UI.Input.Mouse.Left.Down, function(self)
    local m = Inspect.Mouse()
    self.drag = true
    self.ox = m.x - frame:GetLeft()
    self.oy = m.y - frame:GetTop()
end, "D")

frame:EventAttach(Event.UI.Input.Mouse.Left.Up, function(self)
    self.drag = false
end, "U")

frame:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function(self)
    if not self.drag then return end
    local m = Inspect.Mouse()
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", m.x - self.ox, m.y - self.oy)
end, "M")

local function UpdateCoords()
    local detail = Inspect.Unit.Detail("player.target")
    if detail and detail.coordX and detail.coordY and detail.coordZ then
        labelX:SetText(string.format("X: %.2f", detail.coordX))
        labelY:SetText(string.format("Y: %.2f", detail.coordY))
        labelZ:SetText(string.format("Z: %.2f", detail.coordZ))
    else
        labelX:SetText("X: --")
        labelY:SetText("Y: --")
        labelZ:SetText("Z: --")
    end
    needsLayout = true
end

table.insert(Event.Addon.Load.End, { function(addonId)
    if addonId ~= "TargetCoords" then return end
    Command.Console.Display("general", false, "TargetCoords loaded.", false)
    UpdateCoords()
end, "TargetCoords", "OnLoad" })

table.insert(Event.Unit.Add, { function(units)
    UpdateCoords()
end, "TargetCoords", "OnUnitAdd" })

table.insert(Event.Unit.Remove, { function(units)
    UpdateCoords()
end, "TargetCoords", "OnUnitRemove" })

table.insert(Event.Unit.Availability.Full, { function(units)
    UpdateCoords()
end, "TargetCoords", "OnAvail" })

table.insert(Event.Unit.Detail.Coord, { function(x, y, z)
    UpdateCoords()
end, "TargetCoords", "OnCoord" })