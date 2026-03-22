-- NicCopyTooltip
-- Hover over any item and press your keybind to open a popup with the
-- full tooltip text + item link, ready to paste into the Discord bot.

local ADDON_NAME = "NicCopyTooltip"

-- Keybinding labels shown in the WoW Keybindings UI (header must match Bindings.xml)
BINDING_HEADER_NicCopyTooltip = "NicCopyTooltip"
BINDING_NAME_NICCOPYTOOLTIP_COPY = "Copy Hovered Item"

-- ─── Popup Frame ─────────────────────────────────────────────────────────────

local popup = CreateFrame("Frame", "NicCopyTooltipFrame", UIParent, "BackdropTemplate")
popup:SetSize(460, 340)
popup:SetPoint("CENTER")
popup:SetFrameStrata("DIALOG")
popup:SetMovable(true)
popup:EnableMouse(true)
popup:RegisterForDrag("LeftButton")
popup:SetScript("OnDragStart", popup.StartMoving)
popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
popup:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:Hide()
        self:SetPropagateKeyboardInput(false)
    else
        self:SetPropagateKeyboardInput(true)
    end
end)
popup:SetPropagateKeyboardInput(true)
popup:Hide()

popup:SetBackdrop({
    bgFile   = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile     = true,
    tileSize = 32,
    edgeSize = 32,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 },
})

-- Title bar
local titleText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -14)
titleText:SetText("Nic Copy Tooltip")

-- Divider line below title
local divider = popup:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface/Tooltips/UI-Tooltip-Border")
divider:SetHeight(2)
divider:SetPoint("TOPLEFT", 12, -34)
divider:SetPoint("TOPRIGHT", -12, -34)

-- ─── Scroll + EditBox ─────────────────────────────────────────────────────────

local scrollFrame = CreateFrame("ScrollFrame", "NicCopyTooltipScroll", popup, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",  12, -42)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 44)

local editBox = CreateFrame("EditBox", "NicCopyTooltipEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject(GameFontNormal)
editBox:SetWidth(scrollFrame:GetWidth())
editBox:SetScript("OnEscapePressed", function() popup:Hide() end)
-- Prevent the editbox from eating Enter (keeps scroll working)
editBox:SetScript("OnEnterPressed", function(self) self:Insert("\n") end)
scrollFrame:SetScrollChild(editBox)

-- ─── Buttons ──────────────────────────────────────────────────────────────────

local copyBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
copyBtn:SetSize(140, 24)
copyBtn:SetPoint("BOTTOMLEFT", 12, 12)
copyBtn:SetText("Copy to Clipboard")
copyBtn:SetScript("OnClick", function()
    local text = editBox:GetText()
    if text and text ~= "" then
        CopyToClipboard(text)
        copyBtn:SetText("Copied!")
        C_Timer.After(2, function() copyBtn:SetText("Copy to Clipboard") end)
    end
end)

local closeBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
closeBtn:SetSize(80, 24)
closeBtn:SetPoint("BOTTOMRIGHT", -12, 12)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function() popup:Hide() end)

-- ─── Tooltip Cache ────────────────────────────────────────────────────────────
-- Capture item data on hover so the keybind can use it even after the
-- tooltip has already dismissed (pressing a key hides the tooltip first).

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

        local leftText  = left  and left:GetText()  or ""
        local rightText = right and right:GetText() or ""

        -- Strip WoW color codes for clean output
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

-- Hook every item tooltip show event so we always have fresh cached data
GameTooltip:HookScript("OnTooltipSetItem", CaptureTooltip)

-- ─── Main Entry Point (called by keybind) ────────────────────────────────────

function NicCopyTooltip_ShowPopup()
    if not cachedItemString then
        print("|cFFFF6600NicCopyTooltip:|r Hover over an item first, then press your keybind.")
        return
    end

    editBox:SetText(cachedItemString)
    editBox:SetCursorPosition(0)

    CopyToClipboard(cachedItemString)
    copyBtn:SetText("Copied!")
    C_Timer.After(2, function() copyBtn:SetText("Copy to Clipboard") end)

    popup:Show()
    popup:SetPoint("CENTER")
end

-- Slash command fallback: /nct
SLASH_NICCOPYTOOLTIP1 = "/nct"
SlashCmdList["NICCOPYTOOLTIP"] = NicCopyTooltip_ShowPopup
