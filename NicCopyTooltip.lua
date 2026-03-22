-- NicCopyTooltip
-- Hover over any item and press your keybind (or type /nct) to open a
-- popup with the full tooltip text. Select all and Ctrl+C / Cmd+C to copy.

print("|cFF00FF00NicCopyTooltip:|r Addon loaded.")

-- Keybinding labels shown in the WoW Keybindings UI
BINDING_HEADER_NicCopyTooltip = "NicCopyTooltip"
BINDING_NAME_NICCOPYTOOLTIP_COPY = "Copy Hovered Item"

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

-- Background
local bg = popup:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

-- Border
local border = CreateFrame("Frame", nil, popup, "ThinBorderTemplate")
border:SetAllPoints()

-- Title
local titleText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -14)
titleText:SetText("Nic Copy Tooltip")

-- Hint text
local hintText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hintText:SetPoint("BOTTOM", 0, 30)
hintText:SetText("Click 'Select All', then press Ctrl+C (or Cmd+C on Mac) to copy.")
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

-- ─── Tooltip Cache ────────────────────────────────────────────────────────────

local cachedItemString = nil

local function CaptureTooltip(tooltip)
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end

    local lines = {}
    table.insert(lines, "ITEM_LINK: " .. itemLink)
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
end

GameTooltip:HookScript("OnTooltipSetItem", CaptureTooltip)

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
