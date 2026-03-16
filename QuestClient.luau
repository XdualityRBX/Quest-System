local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--MODULES -------------------------------------------
local quests = require(ReplicatedStorage:WaitForChild("QuestModule"))

--EVENTS --------------------------------------------
local questEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local appleQuestEvent = ReplicatedStorage:WaitForChild("QuestEvent")
local appleEvent = ReplicatedStorage:WaitForChild("AppleEvent")

--PLAYER --------------------------------------------
local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

--QUEST STUFF ---------------------------------------
local apples = workspace.Apples:GetChildren()
local applesCollected = 0

--NPC -----------------------------------------------
local NPC = workspace:WaitForChild("Xduality_YT")
local prompt = NPC:WaitForChild("ProximityPrompt")

--GUI -----------------------------------------------
local Gui = plr:WaitForChild("PlayerGui"):WaitForChild("NPC_GUI")
local Frame = Gui:WaitForChild("Frame")

local Option1 = Frame:WaitForChild("ListFrame"):WaitForChild("Option 1")
local Option2 = Frame:WaitForChild("ListFrame"):WaitForChild("Option 2")
local Option3 = Frame:WaitForChild("ListFrame"):WaitForChild("Option 3")

local questOption1 = Frame:WaitForChild("ListFrame2"):WaitForChild("Option 1")
local questOption2 = Frame:WaitForChild("ListFrame2"):WaitForChild("Option 2")

local NPC_Text = Frame:WaitForChild("NPC_Text")


local questGui = plr:WaitForChild("PlayerGui"):WaitForChild("QUEST_GUI")

local questFrame = questGui:WaitForChild("QuestFrame")
local bar = questFrame:WaitForChild("Bar")
local progressBar = questFrame:WaitForChild("ProgressBar")
local questText = questFrame:WaitForChild(" QuestText")
local completedText = questFrame:WaitForChild("Completedtext")

local notificationFrame = questGui:WaitForChild("NotificationFrame")
local notificationText = notificationFrame:WaitForChild("TextLabel")


local moneyGui = plr:WaitForChild("PlayerGui"):WaitForChild("MONEY_GUI")
local moneyFrame = moneyGui:WaitForChild("Frame")
local moneyText = moneyFrame:WaitForChild("TextLabel")
local moneyStroke = moneyText:WaitForChild("UIStroke")


--SETTINGS ------------------------------------------
local TYPING_SPEED = .05
local canPrompt = true
local questActive = false
local questCompleted = false

--FUNCTIONS -----------------------------------------

--Locks the camera of the player to the npc to create a cutscene-ish feel with a tween to smoothen it out, also makes the player
--unable to move or jump. To get the player out of the way, we make the player invisible only to themselfs so that
--it doesnt look weird to ther players in the game
local function lockCameraNPC()
	
	local npcTorso = NPC:WaitForChild("Torso")
	
	local offset = npcTorso.CFrame.LookVector * 7
	local cameraPosition = npcTorso.Position + offset + Vector3.new(0,2,0)
	
	camera.CameraType = Enum.CameraType.Scriptable
	local targetCFrame = CFrame.new(cameraPosition, npcTorso.Position)
	
	local tweenInfo = TweenInfo.new(.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	local tween = TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame})
	
	tween:Play()
	
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
		end
	end

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
end


--Undoos everything the lockCameraNPC() function did

local function unlockCameraNPC()
	camera.CameraType = Enum.CameraType.Custom

	humanoid.WalkSpeed = 16  
	humanoid.JumpPower = 50  


	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0
		end
	end
end


--Creates a typewriter effect animation to the selected message, with the options to keep the text as was before and continue with
--the same text that was there before

local function animatetext(text, message, startingText)
	startingText = startingText or "" 

	text.Text = startingText
	text.Transparency = 0
	text.BackgroundTransparency = 1
	text.TextXAlignment = Enum.TextXAlignment.Center

	for i = 1, #message do
		text.Text = startingText .. string.sub(message, 1, i)
		task.wait(TYPING_SPEED)
	end
end


--Deletes the text slowly with the typewriter effect

local function reverseAnimateText(text)
	for i = #text.Text, 0, -1 do
		text.Text = string.sub(text.Text, 1, i)
		task.wait(TYPING_SPEED)
	end
end


--Makes the notification UI visible with an animation to signal the player they have a quest active

local function showNotification()
	notificationFrame.Visible = true
	notificationFrame.BackgroundTransparency = 1
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad)
	
	local goal = {
		TextTransparency = 0,
		Position = notificationText.Position + UDim2.new(0,0,-.1,0)
	}
	
	local tween = TweenService:Create(notificationText, tweenInfo, goal)
	tween:Play()
	
	task.delay(3.5, function()
		notificationFrame.Visible = false
		notificationFrame.Position = notificationFrame.Position - UDim2.new(0,0,-2,0)
	end)
end


--Makes it so that the prompt can only be pressed while the quest is active

local function updateApplePrompt()
	for _, apple in pairs(apples) do
		local prompt = apple:FindFirstChild("ProximityPrompt")
		if prompt then
			prompt.Enabled = questActive and not questCompleted
		end
	end
end


--Shows the buttons given in the part of the dialogue where the player chooses to accept the quest or not, if they choose not to,
--it will unlock the camera , and delete the text with the reverseAnimationText() function.
--If accepted, it will unlock the camera and delete the text using the reverseAnimationText(), but will also make the notification pop up
--and fire the remote evettn to the server

local function showQuestButton()
	local questButtons = {questOption1, questOption2}

	for _, btn in pairs(questButtons) do
		btn.Visible = true
		btn.TextTransparency = 1
		btn.BackgroundTransparency = 1

		local goal = {
			TextTransparency = 0,
			Position = btn.Position + UDim2.new(0,0,-0.1,0)
		}
		local tween = TweenService:Create(btn, TweenInfo.new(.5, Enum.EasingStyle.Quad), goal)
		tween:Play()
	end

	questOption1.MouseButton1Click:Connect(function()
		print("No Quest")
		for _, btn in pairs(questButtons) do
			btn.Visible = false
		end
		unlockCameraNPC()
		reverseAnimateText(NPC_Text)
	end)

	questOption2.MouseButton1Click:Connect(function()
		print("Quest Accepted")
		for _, btn in pairs(questButtons) do
			btn.Visible = false
		end
		unlockCameraNPC()
		reverseAnimateText(NPC_Text)
		questEvent:FireServer()
		showNotification()
		
		questActive = true
		questFrame.Visible = true
		
		
		questText.Text = string.gsub(questText.Text, "QuestName", quests.CollectApples.Name)
		questText.Text = string.gsub(questText.Text, "Amount", quests.CollectApples.Amount)
		
		updateApplePrompt()
	end)
end


--Shows the buttons/options the player has after talking to the npc. None of them changes anything, they will just continue the dialogue
--And after the dialogue is dont it will show them the option to take the quest or not.

local function showButtons()
	local buttons = {Option1, Option2, Option3}

	for _, btn in pairs(buttons) do
		-- Reset button state
		btn.Visible = true
		btn.TextTransparency = 1
		btn.BackgroundTransparency = 1
		btn.Position = btn.Position + UDim2.new(0, 0, -0.1, 0)

		local goal = {
			TextTransparency = 0,
			Position = btn.Position - UDim2.new(0, 0, -0.1, 0)
		}

		local tween = TweenService:Create(btn, TweenInfo.new(0.5, Enum.EasingStyle.Quad), goal)
		tween:Play()
		
		
		btn.MouseButton1Click:Connect(function()
			for _, b in pairs(buttons) do
				b.Visible = false
			end

			NPC_Text.Text = ""
			task.wait(0.3)
			animatetext(NPC_Text, "I don't care")
			task.wait(0.3)
			animatetext(NPC_Text, "Look, I just need you to go fetch some apples")
			task.wait(0.4)
			animatetext(NPC_Text, "Can you do that?")
			task.wait(.3)


			showQuestButton()
		end)
	end
end


--The first dialogue when the player talks to the npc for the first time or afte rdeclining the quest.

local function dialogue()
	canPrompt = false
	Frame.Visible = true
	
	prompt.Enabled = false
	
	animatetext(NPC_Text, "Hey! ")
	task.wait(.45)
	animatetext(NPC_Text, ". . .  ", NPC_Text.Text)
	task.wait(.25)
	animatetext(NPC_Text, "How are you doing player?", NPC_Text.Text)
	task.wait(.3)
	showButtons()
	task.wait(1)
	canPrompt = true
	task.delay(3, function()
		prompt.Enabled = true
	end)
end


--Handles the prompt in the apples making sure the apples can only be picked up during the quest, also fires a remote event to the server
--to destroy the apple. Alos fills up the bar and also handles when the quest is completed.

for _, apple in pairs(apples) do
	local prompt = apple:WaitForChild("ProximityPrompt")
	
	if not questActive then
		prompt.Enabled = false
	end
	
	if questCompleted then
		prompt.Enabled = false
	end
	
	prompt.Triggered:Connect(function()
		if not questActive then return end

		if questCompleted then return end

		prompt.Enabled = true
		
		applesCollected += 1
		appleEvent:FireServer(apple)

		questText.Text = quests.CollectApples.Name .. ": " .. applesCollected .. " / " .. quests.CollectApples.Amount

		local progress = applesCollected / quests.CollectApples.Amount
		progress = math.clamp(progress, 0, .93)
		progressBar.Size = UDim2.new(progress, 0, 0.234, 0)

		if applesCollected >= quests.CollectApples.Amount then
			questCompleted = true
			completedText.Visible = true
			questActive = false
			updateApplePrompt()
		end

	end)
end


--first it will check if player has completed the quest, if they have, it does the dialogue of the player completing the quest, 
--as also firing a remote event to the server to give t he player the reward and make a quick notification that he money is given.
--If quest is active it says to come back later after quest is finished and dissmisses the player.
--If none, it will just do the first time interaction dialogue.

prompt.Triggered:Connect(function()
	if questCompleted then
		canPrompt = false
		prompt.Enabled = false
		
		questFrame.Visible = false
		
		lockCameraNPC()
		animatetext(NPC_Text,"Thank you ")
		task.wait(.1)
		animatetext(NPC_Text, ". . .  ", NPC_Text.Text)
		task.wait(.3)
		animatetext(NPC_Text, "Took you long enough", NPC_Text.Text)
		task.wait(1.3)
		unlockCameraNPC()
		task.delay(.3, function()
			reverseAnimateText(NPC_Text)
		end)
		
		moneyText.Text = string.gsub(moneyText.Text, "Reward", quests.CollectApples.Reward)
		
		appleQuestEvent:FireServer()
		
		local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad)
		
		local goal = {
			TextTransparency = 0,
			Position = UDim2.new(0,0,-.1,0)
		}
		
		local tween = TweenService:Create(moneyText, tweenInfo, goal)
		
		
		
		local tweenInfo2 = TweenInfo.new(2, Enum.EasingStyle.Quad)
		
		local goal2 = {
			Transparency = 0
		}
		
		local tween2 = TweenService:Create(moneyStroke, tweenInfo2, goal2)
		
		moneyFrame.Visible = true
		tween:Play()
		tween2:Play()
		
		
		task.delay(1, function()
			moneyText.TextTransparency = 1
			moneyStroke.Transparency = 1
			moneyText.Position = moneyText.Position + UDim2.new(0,0,.1,0)
			moneyFrame.Visible = false
		end)
		
		
		return
	end
	
	if questActive then
		canPrompt = false
		prompt.Enabled = false
		lockCameraNPC()
		animatetext(NPC_Text, "Youd don't have what I'm looking for")
		task.wait(.7)
		animatetext(NPC_Text, "Come back when you have what you need")
		unlockCameraNPC()
		task.delay(1.5, function()
			reverseAnimateText(NPC_Text)
		end)

		canPrompt = true
		task.delay(4, function()
			prompt.Enabled = true
		end)

		return 
	end
	
	lockCameraNPC()
	dialogue()
end)