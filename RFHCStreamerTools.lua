--------------------------------------------------
-- GLOBAL DATABASE & FALLBACK INITIALIZATION
--------------------------------------------------
local defaultDB = {
    enableBRB = true,
    streamerMode = true,
    bgDim = true,
    showCounters = true,
    showJukebox = false,
    showModel = false,
    mainText = "BE RIGHT BACK",
    subText = "Stream will resume shortly!",
    avatarTitle = "LIVE AVATAR"
}

-- Session Runtime Variables
local sessionDeaths = 0
local sessionStartGold = 0
local sessionInstances = 0
local sessionHKs = 0
local sessionStartTime = GetTime()
local currentTrackIndex = nil
local isInitializing = true -- Flag to prevent OnTextChanged from overwriting SavedVars during load

--------------------------------------------------
-- 1. MAIN FRAME CREATION
--------------------------------------------------
local mainFrame = CreateFrame("Frame", "MyAddonMainFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(520, 480)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame:Hide()

mainFrame.TitleBg:SetHeight(30)
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, -3)
mainFrame.title:SetText("RFHC Streamer Tools")

mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

mainFrame:SetScript("OnShow", function() PlaySound(808) end)
mainFrame:SetScript("OnHide", function() PlaySound(808) end)

SLASH_MYADDON1 = "/rfhcst"
SLASH_MYADDON2 = "/rfhcstreamertools"
SlashCmdList["MYADDON"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

mainFrame.playerName = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.playerName:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -35)
mainFrame.playerName:SetText("Character: Loading...")


--------------------------------------------------
-- 2. TAB SYSTEM CREATION (3 TABS)
--------------------------------------------------
local tab1Content = CreateFrame("Frame", nil, mainFrame)
tab1Content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -55)
tab1Content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)

local tab2Content = CreateFrame("Frame", nil, mainFrame)
tab2Content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -55)
tab2Content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)
tab2Content:Hide()

local tab3Content = CreateFrame("Frame", nil, mainFrame)
tab3Content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -55)
tab3Content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)
tab3Content:Hide()

local function SelectTab(tabBtn, isSelected)
    if isSelected then
        tabBtn:Disable()
    else
        tabBtn:Enable()
    end
end

local function SetActiveTab(tabID)
    tab1Content:Hide()
    tab2Content:Hide()
    tab3Content:Hide()
    SelectTab(mainFrame.Tab1, false)
    SelectTab(mainFrame.Tab2, false)
    SelectTab(mainFrame.Tab3, false)

    if tabID == 1 then
        tab1Content:Show()
        SelectTab(mainFrame.Tab1, true)
    elseif tabID == 2 then
        tab2Content:Show()
        SelectTab(mainFrame.Tab2, true)
    elseif tabID == 3 then
        tab3Content:Show()
        SelectTab(mainFrame.Tab3, true)
    end
end

mainFrame.Tab1 = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
mainFrame.Tab1:SetSize(100, 24)
mainFrame.Tab1:SetText("Settings")
mainFrame.Tab1:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 10, -2)
mainFrame.Tab1:SetScript("OnClick", function() SetActiveTab(1) end)

mainFrame.Tab2 = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
mainFrame.Tab2:SetSize(100, 24)
mainFrame.Tab2:SetText("Soundboard")
mainFrame.Tab2:SetPoint("LEFT", mainFrame.Tab1, "RIGHT", 5, 0)
mainFrame.Tab2:SetScript("OnClick", function() SetActiveTab(2) end)

mainFrame.Tab3 = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
mainFrame.Tab3:SetSize(100, 24)
mainFrame.Tab3:SetText("Jukebox")
mainFrame.Tab3:SetPoint("LEFT", mainFrame.Tab2, "RIGHT", 5, 0)
mainFrame.Tab3:SetScript("OnClick", function() SetActiveTab(3) end)

SetActiveTab(1)


--------------------------------------------------
-- 3. BE RIGHT BACK OVERLAY FRAME
--------------------------------------------------
local brbFrame = CreateFrame("Frame", "RFHC_BRBFrame", UIParent)
brbFrame:SetAllPoints(UIParent)
brbFrame:SetFrameStrata("FULLSCREEN_DIALOG")
brbFrame:Hide()

brbFrame.bg = brbFrame:CreateTexture(nil, "BACKGROUND")
brbFrame.bg:SetAllPoints(brbFrame)
brbFrame.bg:SetColorTexture(0, 0, 0, 0.75)

brbFrame.text = brbFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
brbFrame.text:SetPoint("CENTER", brbFrame, "CENTER", 0, 30)
brbFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 72, "OUTLINE")
brbFrame.text:SetTextColor(1, 0.82, 0)

brbFrame.subtext = brbFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
brbFrame.subtext:SetPoint("TOP", brbFrame.text, "BOTTOM", 0, -15)
brbFrame.subtext:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")

local function UpdateBRBText()
    brbFrame.text:SetText((RFHCStreamerToolsDB and RFHCStreamerToolsDB.mainText) or "BE RIGHT BACK")
    brbFrame.subtext:SetText((RFHCStreamerToolsDB and RFHCStreamerToolsDB.subText) or "Stream will resume shortly!")
    if RFHCStreamerToolsDB and RFHCStreamerToolsDB.bgDim then
        brbFrame.bg:Show()
    else
        brbFrame.bg:Hide()
    end
end

brbFrame:SetScript("OnShow", function()
    PlaySound(8960, "Master")
end)


--------------------------------------------------
-- 4. TAB 1: SETTINGS & CONTROLS
--------------------------------------------------
local jukeboxFrame
local counterFrame
local modelFrame
local camStartBtn

local enableBRBCheckBox = CreateFrame("CheckButton", nil, tab1Content, "UICheckButtonTemplate")
enableBRBCheckBox:SetPoint("TOPLEFT", tab1Content, "TOPLEFT", 10, -10)
enableBRBCheckBox.text = enableBRBCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
enableBRBCheckBox.text:SetPoint("LEFT", enableBRBCheckBox, "RIGHT", 5, 0)
enableBRBCheckBox.text:SetText("Enable Auto AFK BRB Overlay")
enableBRBCheckBox:SetScript("OnClick", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.enableBRB = self:GetChecked()
    if not RFHCStreamerToolsDB.enableBRB then brbFrame:Hide() end
end)

local privacyCheckBox = CreateFrame("CheckButton", nil, tab1Content, "UICheckButtonTemplate")
privacyCheckBox:SetPoint("TOPLEFT", enableBRBCheckBox, "BOTTOMLEFT", 0, -5)
privacyCheckBox.text = privacyCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
privacyCheckBox.text:SetPoint("LEFT", privacyCheckBox, "RIGHT", 5, 0)
privacyCheckBox.text:SetText("Enable Anti-Harassment Mode (Auto-Decline Trades/Duels)")
privacyCheckBox:SetScript("OnClick", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.streamerMode = self:GetChecked()
end)

local counterCheckBox = CreateFrame("CheckButton", nil, tab1Content, "UICheckButtonTemplate")
counterCheckBox:SetPoint("TOPLEFT", privacyCheckBox, "BOTTOMLEFT", 0, -5)
counterCheckBox.text = counterCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counterCheckBox.text:SetPoint("LEFT", counterCheckBox, "RIGHT", 5, 0)
counterCheckBox.text:SetText("Show On-Screen Auto Tracker Window")
counterCheckBox:SetScript("OnClick", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.showCounters = self:GetChecked()
    if RFHCStreamerToolsDB.showCounters then counterFrame:Show() else counterFrame:Hide() end
end)

local jukeboxCheckBox = CreateFrame("CheckButton", nil, tab1Content, "UICheckButtonTemplate")
jukeboxCheckBox:SetPoint("TOPLEFT", counterCheckBox, "BOTTOMLEFT", 0, -5)
jukeboxCheckBox.text = jukeboxCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
jukeboxCheckBox.text:SetPoint("LEFT", jukeboxCheckBox, "RIGHT", 5, 0)
jukeboxCheckBox.text:SetText("Show On-Screen Jukebox Window")
jukeboxCheckBox:SetScript("OnClick", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.showJukebox = self:GetChecked()
    if RFHCStreamerToolsDB.showJukebox then jukeboxFrame:Show() else jukeboxFrame:Hide() end
end)

local modelCheckBox = CreateFrame("CheckButton", nil, tab1Content, "UICheckButtonTemplate")
modelCheckBox:SetPoint("TOPLEFT", jukeboxCheckBox, "BOTTOMLEFT", 0, -5)
modelCheckBox.text = modelCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
modelCheckBox.text:SetPoint("LEFT", modelCheckBox, "RIGHT", 5, 0)
modelCheckBox.text:SetText("Show On-Screen 3D Head Camera")

-- Avatar Custom Title Input
local avatarTitleLabel = tab1Content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
avatarTitleLabel:SetPoint("TOPLEFT", modelCheckBox, "BOTTOMLEFT", 0, -10)
avatarTitleLabel:SetText("3D Avatar Title:")

local avatarTitleBox = CreateFrame("EditBox", nil, tab1Content, "InputBoxTemplate")
avatarTitleBox:SetPoint("TOPLEFT", avatarTitleLabel, "BOTTOMLEFT", 5, -3)
avatarTitleBox:SetSize(250, 20)
avatarTitleBox:SetAutoFocus(false)
avatarTitleBox:SetScript("OnTextChanged", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.avatarTitle = self:GetText()
    if modelFrame and modelFrame.headerText then
        modelFrame.headerText:SetText(self:GetText())
    end
end)

local mainTextLabel = tab1Content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mainTextLabel:SetPoint("TOPLEFT", avatarTitleBox, "BOTTOMLEFT", -5, -8)
mainTextLabel:SetText("BRB Main Text:")

local mainEditBox = CreateFrame("EditBox", nil, tab1Content, "InputBoxTemplate")
mainEditBox:SetPoint("TOPLEFT", mainTextLabel, "BOTTOMLEFT", 5, -3)
mainEditBox:SetSize(250, 20)
mainEditBox:SetAutoFocus(false)
mainEditBox:SetScript("OnTextChanged", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.mainText = self:GetText()
end)

local subTextLabel = tab1Content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
subTextLabel:SetPoint("TOPLEFT", mainEditBox, "BOTTOMLEFT", -5, -8)
subTextLabel:SetText("BRB Subtext:")

local subEditBox = CreateFrame("EditBox", nil, tab1Content, "InputBoxTemplate")
subEditBox:SetPoint("TOPLEFT", subTextLabel, "BOTTOMLEFT", 5, -3)
subEditBox:SetSize(250, 20)
subEditBox:SetAutoFocus(false)
subEditBox:SetScript("OnTextChanged", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.subText = self:GetText()
end)

local dimCheckBox = CreateFrame("CheckButton", nil, tab1Content, "UICheckButtonTemplate")
dimCheckBox:SetPoint("TOPLEFT", subEditBox, "BOTTOMLEFT", -5, -8)
dimCheckBox.text = dimCheckBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dimCheckBox.text:SetPoint("LEFT", dimCheckBox, "RIGHT", 5, 0)
dimCheckBox.text:SetText("Enable Dark Screen Overlay")
dimCheckBox:SetScript("OnClick", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.bgDim = self:GetChecked()
end)

local function RefreshUISettings()
    isInitializing = true
    
    enableBRBCheckBox:SetChecked(RFHCStreamerToolsDB.enableBRB)
    privacyCheckBox:SetChecked(RFHCStreamerToolsDB.streamerMode)
    counterCheckBox:SetChecked(RFHCStreamerToolsDB.showCounters)
    jukeboxCheckBox:SetChecked(RFHCStreamerToolsDB.showJukebox)
    modelCheckBox:SetChecked(RFHCStreamerToolsDB.showModel)
    dimCheckBox:SetChecked(RFHCStreamerToolsDB.bgDim)

    avatarTitleBox:SetText(RFHCStreamerToolsDB.avatarTitle or "LIVE AVATAR")
    mainEditBox:SetText(RFHCStreamerToolsDB.mainText or "BE RIGHT BACK")
    subEditBox:SetText(RFHCStreamerToolsDB.subText or "Stream will resume shortly!")
    
    isInitializing = false
end


--------------------------------------------------
-- 5. POPUP NOTIFICATION SYSTEM
--------------------------------------------------
local popupFrame = CreateFrame("Frame", "RFHC_PopupFrame", UIParent)
popupFrame:SetSize(600, 100)
popupFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
popupFrame:SetFrameStrata("FULLSCREEN_DIALOG")
popupFrame:Hide()

popupFrame.icon = popupFrame:CreateTexture(nil, "OVERLAY")
popupFrame.icon:SetSize(64, 64)
popupFrame.icon:SetPoint("LEFT", popupFrame, "LEFT", 10, 0)

popupFrame.text = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
popupFrame.text:SetPoint("LEFT", popupFrame.icon, "RIGHT", 15, 0)
popupFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 54, "OUTLINE")
popupFrame.text:SetTextColor(1, 0.82, 0)

local function TriggerPopup(text, iconTexture)
    if not text then return end
    popupFrame.text:SetText(text)
    if iconTexture then
        popupFrame.icon:SetTexture(iconTexture)
        popupFrame.icon:Show()
        popupFrame.text:SetPoint("LEFT", popupFrame.icon, "RIGHT", 15, 0)
    else
        popupFrame.icon:Hide()
        popupFrame.text:SetPoint("CENTER", popupFrame, "CENTER", 0, 0)
    end
    popupFrame:Show()
    popupFrame:SetAlpha(1)
    UIFrameFadeOut(popupFrame, 3.0, 1, 0)
end


--------------------------------------------------
-- 6. TAB 2: SOUNDBOARD GRID
--------------------------------------------------
local soundList = {
    { name = "Murloc", key = "murloc", soundID = 416, popupText = "Aaaaaughibbrgubugbugrgraabol!", popupIcon = "Interface\\Icons\\INV_Misc_MonsterHead_02" },
    { name = "Level Up", key = "levelup", soundID = 888, popupText = "DING!", popupIcon = "Interface\\Icons\\Spell_Holy_DivineIllumination" },
    { name = "Declined / No", key = "no", soundID = 6363, popupText = "DECLINED!", popupIcon = "Interface\\Icons\\Ability_DualWield" },
    { name = "Chicken", key = "chicken", soundID = 43261, popupText = "NEED FOOD!", popupIcon = "Interface\\Icons\\INV_Misc_Food_14" },
    { name = "Raid Warning", key = "rw", soundID = 8960 },
    { name = "Drumroll", key = "drumroll", soundID = 8232 },
    { name = "Leeroy", key = "leeroy", soundID = 43253, popupText = "LEEROY JENKINS!", popupIcon = "Interface\\Icons\\Achievement_GuildPerk_WorkingOvertime" },
    { name = "Millhouse Mana", key = "mana", soundID = 11175, popupText = "Wait till I get some mana!", popupIcon = "Interface\\Icons\\Spell_Frost_ManaRecharge" },
    { name = "Millhouse Sweetcheeks", key = "sweetcheeks", soundID = 11179, popupText = "I'm gonna light you up sweetcheeks!", popupIcon = "Interface\\Icons\\Spell_Frost_ManaRecharge" },
    { name = "Kael'thas Setback", key = "setback", soundID = 12419, popupText = "Merely a setback!", popupIcon = "Interface\\Icons\\Spell_Fire_SoulBurn" },
    { name = "XT-002 Bad Toys", key = "badtoys", soundID = 15726, popupText = "You are bad toys! VERY BAD!", popupIcon = "Interface\\Icons\\INV_Gizmo_02" },
    { name = "Lich King", key = "lichking", soundID = 17397, popupText = "Frostmourne Hungers...", popupIcon = "Interface\\Icons\\Spell_Frost_ChillingArmor" },
    { name = "Illidan Prepared", key = "illidan", soundID = 11466, popupText = "YOU ARE NOT PREPARED!", popupIcon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
    { name = "Putricide News", key = "putricide", soundID = 17142, popupText = "Good news, everyone!", popupIcon = "Interface\\Icons\\INV_Alchemy_Potion_01" },
    { name = "Peon Work", key = "peon", soundID = 7194, popupText = "Work, work!", popupIcon = "Interface\\Icons\\INV_Pick_02" },
    { name = "Wilhelm Scream", key = "wilhelm", soundID = 21978 },
    { name = "Achievement", key = "achievement", soundID = 12891, popupText = "Achievement Unlocked!", popupIcon = "Interface\\Icons\\ACHIEVEMENT_GUILDPERK_HEROICPRESENCE_RANK2" },
    { name = "Bounty / Quest", key = "quest", soundID = 618 },
    { name = "Failure Horn", key = "wipe", soundID = 8456, popupText = "Wipe!", popupIcon = "Interface\\Icons\\Spell_Shadow_DeathScream" },
    { name = "Loot Coins", key = "coins", soundID = 120, popupText = "Cha-ching!", popupIcon = "Interface\\Icons\\INV_Misc_Coin_01" }
}

local function PlaySoundData(soundData)
    if soundData.soundID then PlaySound(soundData.soundID, "Master") end
    if soundData.popupText then TriggerPopup(soundData.popupText, soundData.popupIcon) end
end

local columns = 3
local btnWidth = 145
local btnHeight = 35
local spacingX = 10
local spacingY = 10

for i, soundData in ipairs(soundList) do
    local row = math.floor((i - 1) / columns)
    local col = (i - 1) % columns
    local btn = CreateFrame("Button", nil, tab2Content, "GameMenuButtonTemplate")
    btn:SetSize(btnWidth, btnHeight)
    local posX = 10 + col * (btnWidth + spacingX)
    local posY = -10 - row * (btnHeight + spacingY)
    btn:SetPoint("TOPLEFT", tab2Content, "TOPLEFT", posX, posY)
    btn:SetText(soundData.name)
    btn:SetScript("OnClick", function()
        PlaySoundData(soundData)
    end)
end


--------------------------------------------------
-- 7. TAB 3 & STANDALONE JUKEBOX SYSTEM
--------------------------------------------------
local musicPlaylist = {
    { title = "Horde Tavern", fdid = 53221 },
    { title = "Lover's Tavern", fdid = 53206 },
    { title = "Stormwind Theme", fdid = 53216 },
    { title = "Orgrimmar Theme", fdid = 53213 },
    { title = "Invincible (Arthas Theme)", fdid = 306471 },
    { title = "Grizzly Hills", fdid = 237078 },
    { title = "Naxxramas Raid", fdid = 53472 },
    { title = "Karazhan Opera", fdid = 53198 },
    { title = "Ironforge Theme", fdid = 53203 },
    { title = "Sholazar Basin", fdid = 237277 },
    { title = "Eversong Woods", fdid = 53186 },
    { title = "Black Temple", fdid = 53180 },
    { title = "Boralus Harbor", fdid = 2024286 },
    { title = "Gunships", fdid = 350058 },
    { title = "Level70ETC", fdid = 877254 }
}

local function UpdateJukeboxDisplay()
    if jukeboxFrame and jukeboxFrame.nowPlaying then
        if currentTrackIndex and musicPlaylist[currentTrackIndex] then
            jukeboxFrame.nowPlaying:SetText(musicPlaylist[currentTrackIndex].title)
        else
            local zoneName = GetRealZoneText()
            if not zoneName or zoneName == "" then zoneName = "Azeroth" end
            jukeboxFrame.nowPlaying:SetText("Zone Default: " .. zoneName)
        end
    end
end

local function PlayJukeboxTrack(index)
    if not musicPlaylist[index] then return end
    currentTrackIndex = index
    local track = musicPlaylist[index]
    
    SetCVar("Sound_EnableMusic", 1)
    PlayMusic(track.fdid)
    TriggerPopup("Now Playing: " .. track.title, "Interface\\Icons\\INV_Misc_Gear_01")
    UpdateJukeboxDisplay()
end

local function StopJukeboxTrack()
    StopMusic()
    currentTrackIndex = nil
    TriggerPopup("Music Stopped", "Interface\\Icons\\Spell_Shadow_Anathema")
    UpdateJukeboxDisplay()
end

local function PlayRandomJukeboxTrack()
    local newIndex = math.random(1, #musicPlaylist)
    PlayJukeboxTrack(newIndex)
end

-- Floating Movable Jukebox Window
jukeboxFrame = CreateFrame("Frame", "RFHC_JukeboxFrame", UIParent, "BackdropTemplate")
jukeboxFrame:SetSize(340, 130)
jukeboxFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -520)

jukeboxFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

jukeboxFrame:EnableMouse(true)
jukeboxFrame:SetMovable(true)
jukeboxFrame:RegisterForDrag("LeftButton")
jukeboxFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
jukeboxFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
jukeboxFrame:Hide()

jukeboxFrame.title = jukeboxFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
jukeboxFrame.title:SetPoint("TOP", jukeboxFrame, "TOP", 0, -10)
jukeboxFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
jukeboxFrame.title:SetTextColor(1, 0.82, 0)
jukeboxFrame.title:SetText("STREAM JUKEBOX")

jukeboxFrame.nowPlaying = jukeboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
jukeboxFrame.nowPlaying:SetPoint("TOP", jukeboxFrame.title, "BOTTOM", 0, -8)
jukeboxFrame.nowPlaying:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
jukeboxFrame.nowPlaying:SetTextColor(0.4, 0.8, 1)

local prevBtn = CreateFrame("Button", nil, jukeboxFrame, "GameMenuButtonTemplate")
prevBtn:SetSize(55, 25)
prevBtn:SetPoint("BOTTOMLEFT", jukeboxFrame, "BOTTOMLEFT", 12, 15)
prevBtn:SetText("Prev")
prevBtn:SetScript("OnClick", function()
    local newIndex = (currentTrackIndex or 1) - 1
    if newIndex < 1 then newIndex = #musicPlaylist end
    PlayJukeboxTrack(newIndex)
end)

local playBtn = CreateFrame("Button", nil, jukeboxFrame, "GameMenuButtonTemplate")
playBtn:SetSize(55, 25)
playBtn:SetPoint("LEFT", prevBtn, "RIGHT", 5, 0)
playBtn:SetText("Play")
playBtn:SetScript("OnClick", function() PlayJukeboxTrack(currentTrackIndex or 1) end)

local stopBtn = CreateFrame("Button", nil, jukeboxFrame, "GameMenuButtonTemplate")
stopBtn:SetSize(55, 25)
stopBtn:SetPoint("LEFT", playBtn, "RIGHT", 5, 0)
stopBtn:SetText("Stop")
stopBtn:SetScript("OnClick", function() StopJukeboxTrack() end)

local randBtn = CreateFrame("Button", nil, jukeboxFrame, "GameMenuButtonTemplate")
randBtn:SetSize(55, 25)
randBtn:SetPoint("LEFT", stopBtn, "RIGHT", 5, 0)
randBtn:SetText("Rand")
randBtn:SetScript("OnClick", function() PlayRandomJukeboxTrack() end)

local nextBtn = CreateFrame("Button", nil, jukeboxFrame, "GameMenuButtonTemplate")
nextBtn:SetSize(55, 25)
nextBtn:SetPoint("LEFT", randBtn, "RIGHT", 5, 0)
nextBtn:SetText("Next")
nextBtn:SetScript("OnClick", function()
    local newIndex = (currentTrackIndex or 0) + 1
    if newIndex > #musicPlaylist then newIndex = 1 end
    PlayJukeboxTrack(newIndex)
end)

-- Tab 3 Playlist Buttons
local jukCols = 2
local jukWidth = 220
local jukHeight = 30

for i, track in ipairs(musicPlaylist) do
    local row = math.floor((i - 1) / jukCols)
    local col = (i - 1) % jukCols
    
    local btn = CreateFrame("Button", nil, tab3Content, "GameMenuButtonTemplate")
    btn:SetSize(jukWidth, jukHeight)
    local posX = 15 + col * (jukWidth + 10)
    local posY = -10 - row * (jukHeight + 8)
    btn:SetPoint("TOPLEFT", tab3Content, "TOPLEFT", posX, posY)
    btn:SetText(track.title)
    
    btn:SetScript("OnClick", function() PlayJukeboxTrack(i) end)
end

local tab3StopBtn = CreateFrame("Button", nil, tab3Content, "GameMenuButtonTemplate")
tab3StopBtn:SetSize(140, 30)
tab3StopBtn:SetPoint("BOTTOMLEFT", tab3Content, "BOTTOMLEFT", 15, 10)
tab3StopBtn:SetText("Stop All Music")
tab3StopBtn:SetScript("OnClick", function() StopJukeboxTrack() end)

local tab3RandBtn = CreateFrame("Button", nil, tab3Content, "GameMenuButtonTemplate")
tab3RandBtn:SetSize(140, 30)
tab3RandBtn:SetPoint("LEFT", tab3StopBtn, "RIGHT", 10, 0)
tab3RandBtn:SetText("Random Track")
tab3RandBtn:SetScript("OnClick", function() PlayRandomJukeboxTrack() end)


--------------------------------------------------
-- 8. STANDALONE AUTOMATED TRACKER WINDOW
--------------------------------------------------
counterFrame = CreateFrame("Frame", "RFHC_CounterFrame", UIParent, "BackdropTemplate")
counterFrame:SetSize(380, 290)
counterFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -200)

counterFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

counterFrame:EnableMouse(true)
counterFrame:SetMovable(true)
counterFrame:RegisterForDrag("LeftButton")
counterFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
counterFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
counterFrame:Hide()

counterFrame.title = counterFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
counterFrame.title:SetPoint("TOP", counterFrame, "TOP", 0, -12)
counterFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
counterFrame.title:SetTextColor(1, 0.82, 0)
counterFrame.title:SetText("SESSION STATS")

counterFrame.timerLabel = counterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counterFrame.timerLabel:SetPoint("TOPLEFT", counterFrame, "TOPLEFT", 20, -50)
counterFrame.timerLabel:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
counterFrame.timerLabel:SetTextColor(0.4, 0.8, 1)
counterFrame.timerLabel:SetText("Time: 00:00:00")

counterFrame.deathLabel = counterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counterFrame.deathLabel:SetPoint("TOPLEFT", counterFrame.timerLabel, "BOTTOMLEFT", 0, -12)
counterFrame.deathLabel:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
counterFrame.deathLabel:SetTextColor(1, 1, 1)
counterFrame.deathLabel:SetText("Deaths: 0")

counterFrame.goldLabel = counterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counterFrame.goldLabel:SetPoint("TOPLEFT", counterFrame.deathLabel, "BOTTOMLEFT", 0, -12)
counterFrame.goldLabel:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
counterFrame.goldLabel:SetTextColor(1, 1, 1)
counterFrame.goldLabel:SetText("Gold: +0g")

counterFrame.instanceLabel = counterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counterFrame.instanceLabel:SetPoint("TOPLEFT", counterFrame.goldLabel, "BOTTOMLEFT", 0, -12)
counterFrame.instanceLabel:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
counterFrame.instanceLabel:SetTextColor(1, 1, 1)
counterFrame.instanceLabel:SetText("Dungeons: 0")

counterFrame.pvpLabel = counterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counterFrame.pvpLabel:SetPoint("TOPLEFT", counterFrame.instanceLabel, "BOTTOMLEFT", 0, -12)
counterFrame.pvpLabel:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
counterFrame.pvpLabel:SetTextColor(1, 0.3, 0.3)
counterFrame.pvpLabel:SetText("HKs: 0")

C_Timer.NewTicker(1, function()
    if counterFrame:IsShown() then
        local elapsed = math.floor(GetTime() - sessionStartTime)
        local hours = math.floor(elapsed / 3600)
        local mins = math.floor((elapsed % 3600) / 60)
        local secs = elapsed % 60
        counterFrame.timerLabel:SetText(string.format("Time: %02d:%02d:%02d", hours, mins, secs))
    end
end)


--------------------------------------------------
-- 9. RESIZABLE 3D AVATAR WEBCAM (GOLD BORDER)
--------------------------------------------------
modelFrame = CreateFrame("Frame", "RFHC_ModelFrame", UIParent, "BackdropTemplate")
modelFrame:SetSize(220, 240)
modelFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, -200)

if modelFrame.SetResizeBounds then
    modelFrame:SetResizeBounds(140, 140, 500, 500)
end
modelFrame:SetResizable(true)

modelFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true, tileSize = 16, edgeSize = 20,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})

modelFrame:EnableMouse(true)
modelFrame:SetMovable(true)
modelFrame:RegisterForDrag("LeftButton")
modelFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
modelFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
modelFrame:Hide()

modelFrame.headerText = modelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
modelFrame.headerText:SetPoint("TOP", modelFrame, "TOP", 0, -10)
modelFrame.headerText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
modelFrame.headerText:SetTextColor(1, 0.82, 0)

modelFrame.model = CreateFrame("PlayerModel", nil, modelFrame)
modelFrame.model:SetPoint("TOPLEFT", modelFrame, "TOPLEFT", 10, -32)
modelFrame.model:SetPoint("BOTTOMRIGHT", modelFrame, "BOTTOMRIGHT", -10, 10)

local function ApplyHeadCamera(model)
    model:SetUnit("player")
    model:SetPortraitZoom(1)
    model:SetRotation(0)
end

-- Manual Initialization Button for Virtual Webcam Loading Timing Fix
camStartBtn = CreateFrame("Button", "RFHC_CamStartBtn", modelFrame, "GameMenuButtonTemplate")
camStartBtn:SetSize(120, 30)
camStartBtn:SetPoint("CENTER", modelFrame, "CENTER", 0, -10)
camStartBtn:SetText("Start Cam")
camStartBtn:SetFrameLevel(modelFrame.model:GetFrameLevel() + 5)
camStartBtn:Hide()

camStartBtn:SetScript("OnClick", function()
    ApplyHeadCamera(modelFrame.model)
    camStartBtn:Hide()
end)

local isDraggingModel = false
local prevMouseX = 0

modelFrame.model:EnableMouse(true)
modelFrame.model:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        isDraggingModel = true
        prevMouseX = GetCursorPosition()
    end
end)

modelFrame.model:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then isDraggingModel = false end
end)

modelFrame.model:SetScript("OnUpdate", function(self)
    if isDraggingModel then
        local currentX = GetCursorPosition()
        local diffX = currentX - prevMouseX
        prevMouseX = currentX
        self:SetRotation(self:GetFacing() + (diffX * 0.02))
    end
end)

modelFrame.model:EnableMouseWheel(true)
modelFrame.model:SetScript("OnMouseWheel", function(self, delta)
    local zoomLevel = self.zoomLevel or 1
    zoomLevel = zoomLevel + (delta * 0.1)
    if zoomLevel < 0.2 then zoomLevel = 0.2 end
    if zoomLevel > 1.8 then zoomLevel = 1.8 end
    self.zoomLevel = zoomLevel
    self:SetPortraitZoom(zoomLevel)
end)

local resizeGrip = CreateFrame("Button", nil, modelFrame)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", modelFrame, "BOTTOMRIGHT", -4, 4)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        modelFrame:StartSizing("BOTTOMRIGHT")
    end
end)

resizeGrip:SetScript("OnMouseUp", function(self, button)
    modelFrame:StopMovingOrSizing()
end)

modelCheckBox:SetScript("OnClick", function(self)
    if isInitializing then return end
    RFHCStreamerToolsDB.showModel = self:GetChecked()
    if RFHCStreamerToolsDB.showModel then
        modelFrame:Show()
        camStartBtn:Show()
    else
        camStartBtn:Hide()
        modelFrame:Hide()
    end
end)


--------------------------------------------------
-- 10. AUTOMATED EVENT LISTENERS & INITIALIZATION
--------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
eventFrame:RegisterEvent("TRADE_REQUEST")
eventFrame:RegisterEvent("DUEL_REQUESTED")
eventFrame:RegisterEvent("GUILD_INVITE_REQUEST")

eventFrame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        -- Flexible addon name match
        if loadedAddon == "RFHCStreamerTools" or loadedAddon == "RFHC_StreamerTools" or loadedAddon == "MyAddon" then
            if not RFHCStreamerToolsDB then RFHCStreamerToolsDB = {} end
            for k, v in pairs(defaultDB) do
                if RFHCStreamerToolsDB[k] == nil then
                    RFHCStreamerToolsDB[k] = v
                end
            end
            RefreshUISettings()
        end

    elseif event == "PLAYER_LOGIN" then
        sessionStartGold = GetMoney()

        -- Safely fetch unit details once loaded into the world
        local pName = UnitName("player") or "Unknown"
        local pLevel = UnitLevel("player") or 1
        mainFrame.playerName:SetText("Character: " .. pName .. " (Level " .. pLevel .. ")")
        
        -- Fallback merge in case ADDON_LOADED fired early
        if not RFHCStreamerToolsDB then RFHCStreamerToolsDB = {} end
        for k, v in pairs(defaultDB) do
            if RFHCStreamerToolsDB[k] == nil then
                RFHCStreamerToolsDB[k] = v
            end
        end
        RefreshUISettings()

        -- Restore visible windows based on SavedVariables
        if RFHCStreamerToolsDB.showCounters then counterFrame:Show() else counterFrame:Hide() end
        if RFHCStreamerToolsDB.showJukebox then jukeboxFrame:Show() else jukeboxFrame:Hide() end
        if RFHCStreamerToolsDB.showModel then
            modelFrame:Show()
            camStartBtn:Show()
        else
            camStartBtn:Hide()
            modelFrame:Hide()
        end

        UpdateJukeboxDisplay()
        if modelFrame and modelFrame.headerText then
            modelFrame.headerText:SetText(RFHCStreamerToolsDB.avatarTitle or "LIVE AVATAR")
        end
    
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if modelFrame and modelFrame:IsShown() and not camStartBtn:IsShown() then
            ApplyHeadCamera(modelFrame.model)
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        UpdateJukeboxDisplay()
        if event == "ZONE_CHANGED_NEW_AREA" then
            local isInstance, instanceType = IsInInstance()
            if isInstance and (instanceType == "party" or instanceType == "raid") then
                sessionInstances = sessionInstances + 1
                counterFrame.instanceLabel:SetText("Dungeons: " .. sessionInstances)
            end
        end

    elseif event == "PLAYER_FLAGS_CHANGED" and unit == "player" then
        local isAFK = false
        
        -- Safely query UnitIsAFK without invoking non-existent security API calls
        local inInstance, instanceType = IsInInstance()
        if not (inInstance and (instanceType == "pvp" or instanceType == "arena")) then
            local success, result = pcall(UnitIsAFK, "player")
            if success and result == true then
                isAFK = true
            end
        end

        if RFHCStreamerToolsDB and RFHCStreamerToolsDB.enableBRB and isAFK then
            UpdateBRBText()
            brbFrame:Show()
        else
            brbFrame:Hide()
        end

    elseif event == "PLAYER_DEAD" then
        sessionDeaths = sessionDeaths + 1
        counterFrame.deathLabel:SetText("Deaths: " .. sessionDeaths)
        PlaySound(8456, "Master")
        TriggerPopup("Wipe!", "Interface\\Icons\\Spell_Shadow_DeathScream")

    elseif event == "PLAYER_MONEY" then
        local currentGold = GetMoney()
        local netChange = math.floor((currentGold - sessionStartGold) / 10000)
        if netChange >= 0 then
            counterFrame.goldLabel:SetText("Gold: |cFF00FF00+" .. netChange .. "g|r")
        else
            counterFrame.goldLabel:SetText("Gold: |cFFFF0000" .. netChange .. "g|r")
        end

    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ... or UnitLevel("player")
        local pName = UnitName("player") or "Unknown"
        mainFrame.playerName:SetText("Character: " .. pName .. " (Level " .. newLevel .. ")")
        PlaySound(888, "Master")
        TriggerPopup("LEVEL UP!", "Interface\\Icons\\Spell_Holy_DivineIllumination")

    elseif event == "PLAYER_PVP_KILLS_CHANGED" then
        sessionHKs = sessionHKs + 1
        counterFrame.pvpLabel:SetText("HKs: " .. sessionHKs)
    end

    if RFHCStreamerToolsDB and RFHCStreamerToolsDB.streamerMode then
        if event == "TRADE_REQUEST" then
            CancelTrade()
            StaticPopup_Hide("TRADE")
        elseif event == "DUEL_REQUESTED" then
            CancelDuel()
            StaticPopup_Hide("DUEL_REQUESTED")
        elseif event == "GUILD_INVITE_REQUEST" then
            DeclineGuild()
            StaticPopup_Hide("GUILD_INVITE")
        end
    end
end)


--------------------------------------------------
-- 11. MACRO SLASH COMMAND INTEGRATION
--------------------------------------------------
SLASH_RFHCSOUND1 = "/rfhcsound"
SlashCmdList["RFHCSOUND"] = function(msg)
    local targetKey = msg:match("^%s*(.-)%s*$"):lower()
    for _, soundData in ipairs(soundList) do
        if soundData.key == targetKey or soundData.name:lower() == targetKey then
            PlaySoundData(soundData)
            return
        end
    end
    print("|cFF00FF00[RFHC Tools]|r Sound key not found. Example usage: /rfhcsound murloc")
end

print("RFHC Streamer Tools successfully loaded! Use /rfhcst to open settings.")