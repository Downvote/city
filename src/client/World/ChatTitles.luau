--!strict
-- Titles in chat (the user: "make titles appear to the left of names in chat"). The server marks
-- each player with the title they wear (their `Title` attribute, Services/Titles); this screen puts
-- it in gold before their name on every message they send (Util/TitleTag.chatPrefix). Roblox's chat
-- takes one OnIncomingMessage callback, so this is the only one: anything else that wants to
-- change how a message reads does it here.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local TitleTag = require(Shared.Util.TitleTag)

local ChatTitles = {}

function ChatTitles.start()
	local ok, why = pcall(function()
		local TextChatService = game:GetService("TextChatService")
		TextChatService.OnIncomingMessage = function(message: TextChatMessage)
			local props = Instance.new("TextChatMessageProperties")
			local source = message.TextSource
			local sender = source and Players:GetPlayerByUserId(source.UserId)
			local title = sender and sender:GetAttribute("Title")
			if type(title) == "string" and title ~= "" then
				props.PrefixText = TitleTag.chatPrefix(title, message.PrefixText)
			end
			return props
		end
	end)
	if not ok then
		warn("[ChatTitles] " .. tostring(why))
	end
end

return ChatTitles
