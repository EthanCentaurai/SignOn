
local _, SignOn = ...

local L = LibStub("AceLocale-3.0"):GetLocale("SignOn")
local AltDB = LibStub("LibAlts-1.0")
local playerRealm
local db


local hexColors = {}
do
	local red, green, blue

	if CUSTOM_CLASS_COLORS then
		for k, v in pairs(CUSTOM_CLASS_COLORS) do
			red, green, blue = v.r * 255, v.g * 255, v.b * 255

			hexColors[LOCALIZED_CLASS_NAMES_MALE[k]] = ("%02x%02x%02x"):format(red, green, blue)
			hexColors[LOCALIZED_CLASS_NAMES_FEMALE[k]] = ("%02x%02x%02x"):format(red, green, blue)
		end

		CUSTOM_CLASS_COLORS:RegisterCallback(function()
			for k, v in pairs(CUSTOM_CLASS_COLORS) do
				hexColors[LOCALIZED_CLASS_NAMES_MALE[k]] = ("%02x%02x%02x"):format(red, green, blue)
				hexColors[LOCALIZED_CLASS_NAMES_FEMALE[k]] = ("%02x%02x%02x"):format(red, green, blue)
			end
		end)
	else
		for k, v in pairs(RAID_CLASS_COLORS) do
			red, green, blue = v.r * 255, v.g * 255, v.b * 255

			hexColors[LOCALIZED_CLASS_NAMES_MALE[k]] = ("%02x%02x%02x"):format(red, green, blue)
			hexColors[LOCALIZED_CLASS_NAMES_FEMALE[k]] = ("%02x%02x%02x"):format(red, green, blue)
		end
	end
end


-- colour functions
local function RandomColour(text)
	local r = math.random(0, 255)
	local g = math.random(0, 255)
	local b = math.random(0, 255)

	return ("|cff%02x%02x%02x%s|r"):format(r, g, b, text)
end

local function ClassColour(text, c)
	local hex = hexColors[c]
	return "|cff"..hex..text.."|r"
end


-- core functions
local function GetUserData(playerName)
	local u, name = {}

	-- check if the player is an alt or a main
	local main = AltDB:GetMain(playerName)
	local alts = AltDB:GetAlts(playerName)

	u.alts = main or alts or ""

	-- search guild roster
	if IsInGuild() then
		-- to fix a bug caused by Patch 5.4.7
		if not playerName:find("-") then
			playerName = playerName.."-"..playerRealm
		end

		for i=1, GetNumGuildMembers(true) do
			u.type, name, u.rank, _, u.level, u.class, u.zone, u.note, _, _, _ = "GUILD", GetGuildRosterInfo(i)

			if playerName == name then
				--@debug@--
				if db.debug then print(GetGuildRosterInfo(i)) end
				--@end-debug@--

				return u
			end
		end
	end

	-- search friends list
	for i=1, GetNumFriends() do
		u.type, name, u.level, u.class, u.zone, _, _, u.note = "FRIEND", GetFriendInfo(i)

		if playerName == name then
			--@debug@--
			if db.debug then print(GetFriendInfo(i)) end
			--@end-debug@--

			return u
		end
	end
end

local function EnhanceMessage(_, _, message, arg4, ...)
	local name, online

	if message:find(L["has come online"]) then name, online = message:match("|Hplayer:(.-)|h.-|h "..L["has come online"]), true
	elseif message:find(L["has gone offline"]) then name, online = message:match("(.-) "..L["has gone offline"]), false
	else return end

	if not name and arg4 then name = arg4 end -- arg4 is the player's name, supplied by Prat
	if not name then return end -- couldn't get a name, bail out

	name = name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") -- strip out Prat colour codes

	local data = GetUserData(name)
	if not data then return end -- couldn't get information, bail out

	local msg

	if data.type == "GUILD" then
		if online then msg = db.guildOn
		else msg = db.guildOff end
	else
		if online then msg = db.friendOn
		else msg = db.friendOff end
	end

	--@debug@--
	if db.debug then print(msg) end
	--@end-debug@--

	-- add in colours
	msg = msg:gsub("([^%s]+):class", ClassColour("%1", data.class)) -- %1 is the text minus the flags
	msg = msg:gsub("([^%s]+):custom", ("|cff%02x%02x%02x%s|r"):format(db.custom.r*255, db.custom.g*255, db.custom.b*255, "%1"))
	msg = msg:gsub("([^%s]+):random", RandomColour)
	msg = msg:gsub("([^%s]+):green", "|cff00ff00%1|r")
	msg = msg:gsub("([^%s]+):red", "|cffff0000%1|r")
	msg = msg:gsub("([^%s]+):blue", "|cff0000ff%1|r")
	msg = msg:gsub("([^%s]+):pink", "|cffff00ff%1|r")
	msg = msg:gsub("([^%s]+):cyan", "|cff00ffff%1|r")
	msg = msg:gsub("([^%s]+):yellow", "|cffffff00%1|r")
	msg = msg:gsub("([^%s]+):orange", "|cffff7f00%1|r")
	msg = msg:gsub("([^%s]+):white", "|cffffffff%1|r")

	-- add in brackets
	msg = msg:gsub("([^%s]+):bracket", "(%1)")
	msg = msg:gsub("([^%s]+):square", "[%1]")
	msg = msg:gsub("([^%s]+):angle", "<%1>")

	--@debug@--
	if db.debug then print(msg) end
	--@end-debug@--

	-- add in data
	msg = msg:gsub("&name", name):gsub("&alts", data.alts):gsub("&level", tostring(data.level)):gsub("&class", data.class):gsub("&zone", data.zone or ""):gsub("&rank", data.rank or ""):gsub("&note", data.note or "")

	-- remove empty brackets and colour code strings
	msg = msg:gsub("|c%x%x%x%x%x%x%x%x|r", "")
	msg = msg:gsub("(%(%))", ""):gsub("(%[%])", ""):gsub("(<>)", "")

	-- add in player links
	if online then msg = msg:gsub(name, "|Hplayer:"..name.."|h%1|h") end

	--@debug@--
	if db.debug then print(msg) return true, nil end -- nil for Prat
	--@end-debug@--

	if db.chatFrame > 0 then
		local color = ChatTypeInfo["SYSTEM"]
		_G["ChatFrame" .. db.chatFrame]:AddMessage(msg, color.r, color.g, color.b)

		return true
	else
		return false, msg, arg4, ...
	end
end


function SignOn:Prat_PreAddMessage(_, message, frame, event, t, r, g, b)
	if event ~= "CHAT_MSG_SYSTEM" then return end

	local _, msg = EnhanceMessage(nil, nil, message.MESSAGE, message.PLAYER)
	if not msg then return end

	-- nil out all message data except actual content
	-- we have to do this otherwise the player's name will appear twice
	message.MESSAGE = msg
	message.PLAYER = ""
	message.PLAYERLINK = ""
	message.PLAYERLINKDATA = ""
	message.PLAYERLEVEL = ""
	message.PREPLAYERDELIM = ""
	message.ALTNAMES = ""
	message.lL = ""
	message.LL = ""
	message.Ll = ""
	message.pP = ""
	message.Pp = ""
end


local chatFrameChoices = {}
local function GetChatFrameChoices()
	wipe(chatFrameChoices)
	chatFrameChoices[0] = DEFAULT

	for i = 1, 10 do
		local chatFrame = _G["ChatFrame" .. i]

		if chatFrame:IsShown() or chatFrame.isDocked then
			chatFrameChoices[i] = chatFrame.name
		end
	end

	return chatFrameChoices
end

function SignOn:OnEnable()
	-- GetRealmName() returns blank if called too early, so we delay it
	playerRealm = GetRealmName():gsub(" ", "")

	db = LibStub("AceDB-3.0"):New("SignOnDB", { profile = {
		debug = false, chatFrame = 0,
		custom = { r = 0.6, g = 0.6, b = 0.6 },
		guildOn = L["<Guild> &rank &name &alts:bracket [&level &class:class] has come:green online:green in &zone &note:bracket"],
		guildOff = L["<Guild> &rank &name &alts:bracket [&level &class:class] has logged:red off:red &note:bracket"],
		friendOn = L["<Friend> &name &alts:bracket [&level &class:class] has signed:green on:green in &zone &note:bracket"],
		friendOff = L["<Friend> &name &alts:bracket [&level &class:class] has logged:red off:red &note:bracket"],
	}}, "Default").profile

	if IsAddOnLoaded("Prat-3.0") then
		Prat.RegisterChatEvent(self, "Prat_PreAddMessage")
	else
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", EnhanceMessage)
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("SignOn", {
		name = "SignOn", type = "group",
		get = function(key) return db[key.arg] end,
		set = function(key, value) db[key.arg] = value end,
		args = {
			desc = {
				type = "description", order = 1,
				name = L["Tutorial"]:format( ClassColour("["..UnitName("player").."]", UnitClass("player")) ),
			},
			guildOn = {
				name = L["Guild Log-on Message"],
				desc = L["Format string for when guild members sign on."],
				type = "input", order = 2, arg = "guildOn", width = "full",
			},
			guildOff = {
				name = L["Guild Log-off Message"],
				desc = L["Format string for when guild members log off."],
				type = "input", order = 3, arg = "guildOff", width = "full",
			},
			friendOn = {
				name = L["Friend Log-on Message"],
				desc = L["Format string for when friends sign on."],
				type = "input", order = 4, arg = "friendOn", width = "full",
			},
			friendOff = {
				name = L["Friend Log-off Message"],
				desc = L["Format string for when friends log off."],
				type = "input", order = 5, arg = "friendOff", width = "full",
			},
			custom = {
				name = L["Custom Colour"],
				desc = L["Set the colour for the :custom colour flag."],
				type = "color", order = 6, arg = "custom", hasAlpha = false,
				get = function()
					return db.custom.r, db.custom.g, db.custom.b
				end,
				set = function(_, r, g, b)
					db.custom.r, db.custom.g, db.custom.b = r, g, b
				end,
			},
			chatFrame = {
				name = L["Chat Frame"],
				desc = L["Select the Chat Frame the message should appear in."],
				type = "select", order = 7, arg = "chatFrame",
				values = GetChatFrameChoices,
			},
			--@debug@--
			debug = {
				name = "|cffc41e3aDebug|r",
				type = "toggle", order = 8, arg = "debug",
			},
			--@end-debug@--
		},
	})

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SignOn", "SignOn")

	local AboutPanel = LibStub("tekKonfig-AboutPanel", true)
	if AboutPanel then AboutPanel.new("SignOn", "SignOn") end

	_G.SlashCmdList["SIGNON"] = function() InterfaceOptionsFrame_OpenToCategory("SignOn") end
	_G["SLASH_SIGNON1"] = "/signon"
	_G["SLASH_SIGNON2"] = "/so"

	--@debug@--
	_G["SLASH_SIGNONTEST1"] = "/sotest"
	_G.SlashCmdList["SIGNONTEST"] = function(msg)
		db.debug = true

		EnhanceMessage(nil, nil, "|Hplayer:"..msg.."|h"..msg.."|h "..L["has come online"]..".")
		EnhanceMessage(nil, nil, msg.." "..L["has gone offline"]..".")
	end
	--@end-debug@--
end


LibStub("AceAddon-3.0"):NewAddon(SignOn, "SignOn")
