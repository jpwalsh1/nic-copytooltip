-- NicCopyTooltip
-- Hover over any item and press your keybind (or type /nct) to open a
-- popup with the full tooltip text. Select all and Ctrl+C / Cmd+C to copy.

print("|cFF00FF00NicCopyTooltip:|r Addon loaded. Step 1.")

-- Keybinding labels shown in the WoW Keybindings UI
BINDING_HEADER_NICCOPYTOOLTIP = "NicCopyTooltip"
BINDING_NAME_NICCOPYTOOLTIP_COPY = "Copy Hovered Item"

-- ─── Popup Frame ─────────────────────────────────────────────────────────────

print("|cFF00FF00NicCopyTooltip:|r Creating frame. Step 2.")

local popup = CreateFrame("Frame", "NicCopyTooltipFrame", UIParent)
popup:SetSize(460, 340)
popup:SetPoint("CENTER")
popup:SetFrameStrata("DIALOG")
popup:SetMovable(true)
popup:EnableMouse(true)
popup:RegisterForDrag("LeftButton")
popup:SetScript("OnDragStart", popup.StartMoving)
popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
popup:Hide()

-- Background
local bg = popup:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

-- Border (4 lines, no template dependency)
local function AddBorderLine(parent, point, relPoint, x, y, w, h)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetColorTexture(0.4, 0.4, 0.4, 1)
    line:SetPoint(point, parent, relPoint, x, y)
    line:SetSize(w, h)
end
AddBorderLine(popup, "TOPLEFT",     "TOPLEFT",     0,  0, 460,   1)
AddBorderLine(popup, "BOTTOMLEFT",  "BOTTOMLEFT",  0,  0, 460,   1)
AddBorderLine(popup, "TOPLEFT",     "TOPLEFT",     0,  0,   1, 340)
AddBorderLine(popup, "TOPRIGHT",    "TOPRIGHT",    0,  0,   1, 340)

-- Title
local titleText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -14)
titleText:SetText("Nic Copy Tooltip")

-- Hint text
local hintText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hintText:SetPoint("BOTTOM", 0, 30)
hintText:SetText("Click 'Select All', then press Ctrl+C (Cmd+C on Mac) to copy.")
hintText:SetTextColor(0.8, 0.8, 0.8)

print("|cFF00FF00NicCopyTooltip:|r Frame created. Step 3.")

-- ─── Scroll + EditBox ─────────────────────────────────────────────────────────

local scrollFrame = CreateFrame("ScrollFrame", "NicCopyTooltipScroll", popup, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",  12, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

local editBox = CreateFrame("EditBox", "NicCopyTooltipEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject(GameFontNormal)
editBox:SetWidth(scrollFrame:GetWidth())
editBox:SetScript("OnEscapePressed", function() popup:Hide() end)
scrollFrame:SetScrollChild(editBox)

print("|cFF00FF00NicCopyTooltip:|r EditBox created. Step 4.")

-- ─── Buttons ─────────────────────────────────────────────────────────────────

local selectAllBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
selectAllBtn:SetSize(100, 24)
selectAllBtn:SetPoint("BOTTOMLEFT", 12, 12)
selectAllBtn:SetText("Select All")
selectAllBtn:SetScript("OnClick", function()
    editBox:SetFocus()
    editBox:HighlightText()
end)

local closeBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
closeBtn:SetSize(80, 24)
closeBtn:SetPoint("BOTTOMRIGHT", -12, 12)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function() popup:Hide() end)

print("|cFF00FF00NicCopyTooltip:|r Buttons created. Step 5.")

-- ─── Keybind Handler (OnKeyDown — bypasses Bindings.xml execution) ───────────
-- Bindings.xml registers the binding name in the UI; this frame handles the press.

local keyHandlerFrame = CreateFrame("Frame", nil, UIParent)
keyHandlerFrame:SetFrameStrata("TOOLTIP")
keyHandlerFrame:SetAllPoints(UIParent)
keyHandlerFrame:Show()
keyHandlerFrame:EnableKeyboard(true)
keyHandlerFrame:SetPropagateKeyboardInput(true)
keyHandlerFrame:SetScript("OnKeyDown", function(self, key)
    local modifier = ""
    if IsShiftKeyDown()   then modifier = "SHIFT-"  .. modifier end
    if IsControlKeyDown() then modifier = "CTRL-"   .. modifier end
    if IsAltKeyDown()     then modifier = "ALT-"    .. modifier end

    local action = GetBindingAction(modifier .. key)
    if action == "NICCOPYTOOLTIP_COPY" then
        self:SetPropagateKeyboardInput(false)
        NicCopyTooltip_ShowPopup()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

print("|cFF00FF00NicCopyTooltip:|r Key handler created. Step 5b.")

-- ─── Rarity Lookup ───────────────────────────────────────────────────────────

local QUALITY_NAMES = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
    [7] = "Heirloom",
}

local function GetRarityFromLink(itemLink)
    local _, _, quality = GetItemInfo(itemLink)
    if quality then
        return QUALITY_NAMES[quality] or "Unknown"
    end
    return "Unknown"
end

-- ─── Tooltip Cache ────────────────────────────────────────────────────────────

local cachedItemString = nil

local function CaptureTooltip(tooltip)
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end

    local lines = {}
    table.insert(lines, "ITEM_LINK: " .. itemLink)
    table.insert(lines, "RARITY: " .. GetRarityFromLink(itemLink))
    table.insert(lines, string.rep("-", 40))

    for i = 1, tooltip:NumLines() do
        local left  = _G["GameTooltipTextLeft"  .. i]
        local right = _G["GameTooltipTextRight" .. i]

        local leftText  = (left  and left:GetText())  or ""
        local rightText = (right and right:GetText()) or ""

        leftText  = leftText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        rightText = rightText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

        if leftText ~= "" and rightText ~= "" then
            table.insert(lines, leftText .. "  " .. rightText)
        elseif leftText ~= "" then
            table.insert(lines, leftText)
        elseif rightText ~= "" then
            table.insert(lines, rightText)
        end
    end

    cachedItemString = table.concat(lines, "\n")
    print("|cFF00FF00NicCopyTooltip:|r Item cached: " .. (select(2, tooltip:GetItem()) or "unknown"))
end

-- WoW Midnight replaced OnTooltipSetItem with TooltipDataProcessor
if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, CaptureTooltip)
else
    GameTooltip:HookScript("OnTooltipSetItem", CaptureTooltip)
end

print("|cFF00FF00NicCopyTooltip:|r Tooltip hook set. Step 6.")

-- ─── Main Entry Point ────────────────────────────────────────────────────────

function NicCopyTooltip_ShowPopup()
    print("|cFF00FF00NicCopyTooltip:|r ShowPopup called.")
    if not cachedItemString then
        print("|cFF00FF00NicCopyTooltip:|r No item cached yet — hover over an item first.")
        return
    end

    editBox:SetText(cachedItemString)
    editBox:SetCursorPosition(0)
    editBox:SetFocus()
    editBox:HighlightText()

    popup:Show()
    popup:SetPoint("CENTER")
    print("|cFF00FF00NicCopyTooltip:|r Popup shown.")
end

-- Slash command: /nct
SLASH_NICCOPYTOOLTIP1 = "/nct"
SlashCmdList["NICCOPYTOOLTIP"] = NicCopyTooltip_ShowPopup

print("|cFF00FF00NicCopyTooltip:|r Ready. Type /nct or use your keybind. Step 7.")
