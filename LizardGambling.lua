LizardGambling = {}
LizardGambling.name = "LizardGambling"
LizardGambling.questName = "Lizard Racing"
LizardGambling.lostRace = "Lost Race"
LizardGambling.lostRaceJournal = "I've lost the race. I need to talk to Dulan to restart it."
LizardGambling.talkingToDulan = false
LizardGambling.defaults = {
    choice = "Right",
    attempts = 0,
    wins = 0,
    displayResults = true,
}
LizardGambling.DulanSkippable = {
    ["What's Lizard Racing?"] = true,
    ["What do I do?"] = true,
    ["What do you need from me?"] = true,
    ["I'm ready to begin."] = true,
    ["Can I try again?"] = true,
    ["Thanks."] = true,
    ["Sure."] = true,
}
LizardGambling.DulanChoices = {
    ["The left one."] = "Left",
    ["The middle one."] = "Middle",
    ["The right one."] = "Right",
}

local function chatterBegin(e, optionCount)
    if (optionCount == 0) then
        EndInteraction(INTERACTION_CONVERSATION)
    end
    for i = 1, optionCount do
        local optionString, optionType, optionalArgument, isImportant, chosenBefore, teleportNPC = GetChatterOption(i)
        if LizardGambling.DulanSkippable[optionString] then 
            LizardGambling.talkingToDulan = true
            SelectChatterOption(i)
        elseif LizardGambling.DulanChoices[optionString] == LizardGambling.savedVars.choice then
            LizardGambling.talkingToDulan = true
            SelectChatterOption(i)
            LizardGambling.savedVars.attempts = LizardGambling.savedVars.attempts + 1
        end
    end
end

local function conversationUpdated(e, text, optionCount)
    chatterBegin(e, optionCount)
end

local function chatterEnd(e)
    LizardGambling.talkingToDulan = false
end

local function questComplete(e)
    if LizardGambling.talkingToDulan then
        CompleteQuest()
        LizardGambling.savedVars.wins = LizardGambling.savedVars.wins + 1
        local winRate = (LizardGambling.savedVars.wins / LizardGambling.savedVars.attempts) * 100
        if LizardGambling.savedVars.displayResults then 
            d(string.format("Wins: %d (%.1f%%)", LizardGambling.savedVars.wins, winRate))
        end
    end
end

local function questOffered(e)
    if LizardGambling.talkingToDulan then
        AcceptOfferedQuest()
    end
end

function LizardGambling.setLeft()
    LizardGambling.savedVars.choice = "Left"
end
function LizardGambling.setMiddle()
    LizardGambling.savedVars.choice = "Middle"
end
function LizardGambling.setRight()
    LizardGambling.savedVars.choice = "Right"
end

local optionsTable = {
    [1] = {
        type = "header",
        name = "|cA6E52DOptions|r",
        width = "full",
    },
    [2] = {
        type = "dropdown",
        name = "Lizard Choice",
        choices = {"Left", "Middle", "Right"},
        getFunc = function() return LizardGambling.savedVars.choice end,
        setFunc = function(var) LizardGambling.savedVars.choice = var end,
    },
    [3] = {
        type = "checkbox",
        name = "Display results",
        tooltip = "Print results to chat after every win",
        getFunc = function() return LizardGambling.savedVars.displayResults end,
        setFunc = function(value) LizardGambling.savedVars.displayResults = value end,
    },
}

local panelData = {
    type = "panel",
    name = "Lizard Gambling",
    displayName = "|cA6E52DLIZARD GAMBLING|r",
    author = "TheMrPancake",
    version = "1.0",
    slashCommand = "/lizardgambling",
    registerForRefresh = true,
}

local function createOptions()
    LibAddonMenu2:RegisterAddonPanel(LizardGambling.name.."Options", panelData)
    LibAddonMenu2:RegisterOptionControls(LizardGambling.name.."Options", optionsTable)
end

local function Init(event, name)
    if name ~= LizardGambling.name then return end
    EVENT_MANAGER:UnregisterForEvent(LizardGambling.name, EVENT_ADD_ON_LOADED)
    LizardGambling.savedVars = ZO_SavedVars:NewAccountWide(LizardGambling.name.."SV", 1, nil, LizardGambling.defaults)
    EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_CONVERSATION_UPDATED, conversationUpdated)
    EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_CHATTER_BEGIN, chatterBegin)
    EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_CHATTER_END, chatterEnd)
    EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_QUEST_OFFERED, questOffered)
    EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_QUEST_COMPLETE_DIALOG, questComplete)
    if LibAddonMenu2 then
        createOptions()
    end
    ZO_CreateStringId('SI_BINDING_NAME_LIZARDGAMBLING_LEFT', 'Set choice to left')
    ZO_CreateStringId('SI_BINDING_NAME_LIZARDGAMBLING_MIDDLE', 'Set choice to middle')
    ZO_CreateStringId('SI_BINDING_NAME_LIZARDGAMBLING_RIGHT', 'Set choice to right')
end

EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_ADD_ON_LOADED, Init)