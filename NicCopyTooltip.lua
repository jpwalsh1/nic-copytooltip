-- NicCopyTooltip
-- Hover over any item and press your keybind (or type /nct) to open a
-- popup with the full tooltip text. Select all and Ctrl+C / Cmd+C to copy.

local ADDON_VERSION = "1.0.22"

-- Keybinding labels shown in the WoW Keybindings UI
BINDING_HEADER_NICCOPYTOOLTIP = "NicCopyTooltip"
BINDING_NAME_NICCOPYTOOLTIP_COPY = "NicCopyTooltip"

-- ─── Popup Frame ─────────────────────────────────────────────────────────────

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

local bg = popup:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

local function AddBorderLine(parent, point, relPoint, x, y, w, h)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetColorTexture(0.4, 0.4, 0.4, 1)
    line:SetPoint(point, parent, relPoint, x, y)
    line:SetSize(w, h)
end
AddBorderLine(popup, "TOPLEFT",    "TOPLEFT",    0, 0, 460,   1)
AddBorderLine(popup, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0, 460,   1)
AddBorderLine(popup, "TOPLEFT",    "TOPLEFT",    0, 0,   1, 340)
AddBorderLine(popup, "TOPRIGHT",   "TOPRIGHT",   0, 0,   1, 340)

local titleText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -14)
titleText:SetText("Nic Copy Tooltip")

local hintText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hintText:SetPoint("BOTTOM", 0, 30)
hintText:SetText("Click 'Select All', then press Ctrl+C (Cmd+C on Mac) to copy.")
hintText:SetTextColor(0.8, 0.8, 0.8)

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

-- ─── Keybind Handler ─────────────────────────────────────────────────────────

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

    local fullKey = modifier .. key
    local action = GetBindingAction(fullKey)
    if action == "NICCOPYTOOLTIP_COPY" then
        self:SetPropagateKeyboardInput(false)
        NicCopyTooltip_ShowPopup()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

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

local function CaptureTooltip(tooltip, data)
    -- In WoW 12.x, data.hyperlink is the full item hyperlink and data.id is the item ID.
    -- Fall back to tooltip:GetItem() for older API versions.
    local itemLink
    local itemId = data and data.id

    if data and data.hyperlink and string.find(data.hyperlink, "|Hitem:", 1, true) then
        itemLink = data.hyperlink
    elseif tooltip.GetItem then
        local _, link = tooltip:GetItem()
        if link and string.find(link, "|Hitem:", 1, true) then
            itemLink = link
        end
    end

    -- Last resort: reconstruct the hyperlink from the item ID via GetItemInfo
    if not itemLink and itemId then
        itemLink = select(2, GetItemInfo(itemId))
    end

    if not itemLink then return end

    local lines = {}
    table.insert(lines, "VERSION: " .. ADDON_VERSION)
    table.insert(lines, "ITEM_LINK: " .. itemLink)
    if itemId then
        table.insert(lines, "ITEM_ID: " .. itemId)
    end
    table.insert(lines, "RARITY: " .. GetRarityFromLink(itemLink))
    table.insert(lines, string.rep("-", 40))

    -- Use data.lines (WoW 12.x TooltipDataProcessor) for taint-free text.
    -- GetText() on font strings returns secret/tainted strings in WoW 12.x
    -- that cannot be used with gsub or string concatenation.
    local dataLines = data and data.lines
    if dataLines then
        for i = 1, #dataLines do
            local leftText  = dataLines[i].leftText  or ""
            local rightText = dataLines[i].rightText or ""

            leftText  = string.gsub(string.gsub(leftText,  "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
            rightText = string.gsub(string.gsub(rightText, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")

            if leftText ~= "" and rightText ~= "" then
                table.insert(lines, leftText .. "  " .. rightText)
            elseif leftText ~= "" then
                table.insert(lines, leftText)
            elseif rightText ~= "" then
                table.insert(lines, rightText)
            end
        end
    else
        -- Fallback for older API versions without data.lines
        local tooltipName = tooltip:GetName()
        for i = 1, tooltip:NumLines() do
            local left  = _G[tooltipName .. "TextLeft"  .. i]
            local right = _G[tooltipName .. "TextRight" .. i]

            local leftText  = (left  and left:GetText())  or ""
            local rightText = (right and right:GetText()) or ""

            leftText  = string.gsub(string.gsub(leftText,  "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
            rightText = string.gsub(string.gsub(rightText, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")

            if leftText ~= "" and rightText ~= "" then
                table.insert(lines, leftText .. "  " .. rightText)
            elseif leftText ~= "" then
                table.insert(lines, leftText)
            elseif rightText ~= "" then
                table.insert(lines, rightText)
            end
        end
    end

    cachedItemString = table.concat(lines, "\n")
end

if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, CaptureTooltip)
else
    GameTooltip:HookScript("OnTooltipSetItem", CaptureTooltip)
end

-- ─── Main Entry Point ────────────────────────────────────────────────────────

function NicCopyTooltip_ShowPopup()
    if not cachedItemString then
        print("|cFF00FF00NicCopyTooltip:|r Hover over an item first, then trigger again.")
        return
    end

    editBox:SetText(cachedItemString)
    editBox:SetCursorPosition(0)
    editBox:SetFocus()
    editBox:HighlightText()

    popup:Show()
    popup:SetPoint("CENTER")
end

-- Slash command: /nct
SLASH_NICCOPYTOOLTIP1 = "/nct"
SlashCmdList["NICCOPYTOOLTIP"] = NicCopyTooltip_ShowPopup
