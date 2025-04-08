LizardGambling = {}
LizardGambling.name = "LizardGambling"
LizardGambling.questName = "Lizard Racing"
LizardGambling.lostRace = "Lost Race"
LizardGambling.lostRaceJournal = "I've lost the race. I need to talk to Dulan to restart it."
LizardGambling.wonRaceJournal = "I've won the race! I can now collect my winnings from Dulan."
LizardGambling.watchRaceJournal = "I need to watch the race."
LizardGambling.talkingToDulan = false
LizardGambling.journalIndex = -1
LizardGambling.wonPreviousRace = false
LizardGambling.defaults = {
    choice = "Right",
    attempts = 0,
    wins = 0,
    displayResults = true,
    cycle = true,
    timeout = 20
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

local function enumerateChoices()
    if LizardGambling.savedVars.choice == "Left" then 
        LizardGambling.setMiddle()
        return
    elseif LizardGambling.savedVars.choice == "Middle" then 
        LizardGambling.setRight()
        return
    else
        LizardGambling.setLeft()
        return
    end
end

local function chatterBegin(e, optionCount)
    if (optionCount == 0) then
        EndInteraction(INTERACTION_CONVERSATION)
    end
    for i = 1, optionCount do
        local optionString, optionType, optionalArgument, isImportant, chosenBefore, teleportNPC = GetChatterOption(i)
        if LizardGambling.DulanSkippable[optionString] then 
            LizardGambling.talkingToDulan = true
            SelectChatterOption(i)
            break
        elseif LizardGambling.DulanChoices[optionString] == LizardGambling.savedVars.choice then
            LizardGambling.talkingToDulan = true
            if LizardGambling.wonPreviousRace then enumerateChoices() end
            SelectChatterOption(i)
            LizardGambling.savedVars.attempts = LizardGambling.savedVars.attempts + 1
            break
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

local function raceTimeout()
    EVENT_MANAGER:UnregisterForUpdate(LizardGambling.name.."Timeout")
    AbandonQuest(LizardGambling.journalIndex)
end

local function questAdvanced(e, index, name, ...)
    if name == LizardGambling.questName then 
        EVENT_MANAGER:UnregisterForUpdate(LizardGambling.name.."Timeout")
        LizardGambling.journalIndex = index
        local text = GetJournalQuestStepInfo(LizardGambling.journalIndex)
        if text == LizardGambling.wonRaceJournal then 
            LizardGambling.wonPreviousRace = true
        elseif text == LizardGambling.lostRaceJournal then 
            LizardGambling.wonPreviousRace = false
        elseif text == LizardGambling.watchRaceJournal then 
            EVENT_MANAGER:RegisterForUpdate(LizardGambling.name.."Timeout", LizardGambling.savedVars.timeout * 1000, raceTimeout)
        end
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
    [4] = {
        type = "checkbox",
        name = "Cycle choice",
        tooltip = "Change to next lizard periodically",
        getFunc = function() return LizardGambling.savedVars.cycle end,
        setFunc = function(value) LizardGambling.savedVars.cycle = value end,
    },
    [5] = {
        type = "slider",
        name = "Timeout seconds",
        tooltip = "Abandon quest in case it bugs after this amount of seconds",
        min = 16,
        max = 30,
        step = 0.5,
        getFunc = function() return LizardGambling.savedVars.timeout end,
        setFunc = function(value) LizardGambling.savedVars = value end,
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
    EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_QUEST_ADVANCED, questAdvanced)
    if LibAddonMenu2 then
        createOptions()
    end
    ZO_CreateStringId('SI_BINDING_NAME_LIZARDGAMBLING_LEFT', 'Set choice to left')
    ZO_CreateStringId('SI_BINDING_NAME_LIZARDGAMBLING_MIDDLE', 'Set choice to middle')
    ZO_CreateStringId('SI_BINDING_NAME_LIZARDGAMBLING_RIGHT', 'Set choice to right')
end

EVENT_MANAGER:RegisterForEvent(LizardGambling.name, EVENT_ADD_ON_LOADED, Init)