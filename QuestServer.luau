local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--MODULES -------------------------------------------
local quests = require(ReplicatedStorage:WaitForChild("QuestModule"))

--EVENTS --------------------------------------------
local appleQuestEvent = ReplicatedStorage:WaitForChild("QuestEvent")
local appleEvent = ReplicatedStorage:WaitForChild("AppleEvent")
local questEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

--NPC -----------------------------------------------
local NPC = workspace:WaitForChild("Xduality_YT")
local prompt = NPC:WaitForChild("ProximityPrompt")


local playerQuests = {}

--Creates leaderstats and the assignes the player quests to the player when joining.
Players.PlayerAdded:Connect(function(plr)
	local leaderstats = Instance.new("Folder", plr)
	leaderstats.Name = "leaderstats"
	
	local Money = Instance.new("IntValue", leaderstats)
	Money.Value = 50
	Money.Name = "Money"
	
	playerQuests[plr] = {
		Progress = 0,
		Active = false,
		Completed = false
	}
end)

--When the player leaves it disconnects the player quests to the player
Players.PlayerRemoving:Connect(function(plr)
	playerQuests[plr] = nil
end)

--Checks if the player has the quest assigned to the table and if the quest is active, if not then it does nothing
--If it yes, then the apple will destroy and add 1 apple to the progress
--Then checks if the player has completed the quest, if yes then it tells that to the data
appleEvent.OnServerEvent:Connect(function(plr, apple)
	local data = playerQuests[plr]
	if not data or not data.Active then return end
	if not apple or not apple:IsDescendantOf(workspace.Apples) then return end

	data.Progress += 1
	apple:Destroy()
	
	
	if data.Progress >= quests.CollectApples.Amount then
		data.Completed = true
		data.Active = false
	end
end)

--Checks  if the player has completed the quest, if they have, it will give them the reward assign in the module
--Then resets everything
appleQuestEvent.OnServerEvent:Connect(function(plr)
	local data = playerQuests[plr]
	if not data or not data.Completed then return end
	
	plr.leaderstats.Money.Value += quests.CollectApples.Reward
	
	data.Progress = 0
	data.Completed = false
	data.Active = false
end)

--Activates the quest so that the other functions can run
questEvent.OnServerEvent:Connect(function(plr)
	local data = playerQuests[plr]
	if not data then return end
	data.Active = true
	data.Progress = 0
	data.Completed = false
end)