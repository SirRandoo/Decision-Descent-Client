-------------------------------------------------
-- This file is part of Decision Descent.      --
--                                             --
-- Decision Descent is free software: you can  --
-- redistribute it and/or modify it under the  --
-- terms of the GNU General Public License as  --
-- published by the Free Software Foundation,  --
-- either version 3 of the License, or (at     --
-- your option) any later version.             --
--                                             --
-- Decision Descent is distributed in the      --
-- hope that it will be useful, but WITHOUT    --
-- ANY WARRANTY; without even the implied      --
-- warranty of MERCHANTABILITY or FITNESS FOR  --
-- A PARTICULAR PURPOSE.  See the GNU General  --
-- Public License for more details.            --
--                                             --
-- You should have received a copy of the GNU  --
-- General Public License along with Decision  --
-- Descent.                                    --
-- If not, see <http://www.gnu.org/licenses/>. --
-------------------------------------------------

--[[  Mini Config  ]]--
local config = { http = { host = "127.0.0.1", port = 25565 } }


--[[  Initial Declarations  ]]--
local name, version, apiVersion = "Decision Descent", "0.1.0", 1.0
local DecisionDescent = RegisterMod(name, apiVersion)
local fLogger = {  -- Fallback logger
	info = function(message) Isaac.DebugString(string.format("[Decision Descent][INFO] %s", message)) end,
	warning = function(message) Isaac.DebugString(string.format("[Decision Descent][WARN] %s", message)) end,
	critical = function(message) Isaac.DebugString(string.format("[Decision Descent][CRITICAL] %s", message)) end,
	debug = function(message) Isaac.DebugString(string.format("[Decision Descent][DEBUG] %s", message)) end,
	fatal = function(message) Isaac.DebugString(string.format("[Decision Descent][FATAL] %s", message)) end,
	log = function(message) Isaac.DebugString(string.format("[Decision Descent][LOG] %s", message)) end
}


--[[  Requires  ]]--
local json_imported, json = pcall(require, "json")
local utils_imported, utils = pcall(require, "utils")
local http_imported, http = pcall(require, "http")


--[[  Environment Checks  ]]--
if not debug then
	fLogger.fatal("Did you make sure to enable luadebug?")
	fLogger.fatal("You can enable luadebug with the following steps...")
	fLogger.fatal("    - Navigate to Isaac in your Steam library")
	fLogger.fatal("    - Right-click Isaac")
	fLogger.fatal("    - Click properties")
	fLogger.fatal("    - Click \"SET LAUNCH OPTIONS...\"")
	fLogger.fatal("    - Type \"--luadebug\" info the text field (without quotations)")
	fLogger.fatal("    - Click OK")
	fLogger.fatal("    - Press CLOSE")
	fLogger.fatal("    - Launch Isaac as normal")

	error("Debug libraries are required to use Decision Descent!")
end

if not json_imported then
	fLogger.fatal("Isaac's JSON library could not be imported!")
	fLogger.fatal("You can verify Isaac's local files with the following steps...")
	fLogger.fatal("    - Navigate to Isaac in your Steam library")
	fLogger.fatal("    - Right-click Isaac")
	fLogger.fatal("    - Click the \"LOCAL FILES\" tab")
	fLogger.fatal("    - Click \"VERIFY INTEGRITY OF GAME FILES...\"")
	fLogger.fatal("    - Launch Isaac as normal")
	fLogger.fatal("")
	
	fLogger.fatal("Error message:")
	fLogger.fatal(json)
	fLogger.fatal("")

	error("Isaac's JSON library is required to use Decision Descent!")
end

if not http_imported then
	fLogger.fatal("Decision Descent's HTTP library is missing!")
	fLogger.fatal("Isaac should have retrieved this file during launch!")
	fLogger.fatal("You can get this file with any of the following options...")
	fLogger.fatal("    - Relaunch Isaac")
	fLogger.fatal("    - Download it from Decision Descent's Github @ https://github.com/SirRandoo/decision-descent")
	fLogger.fatal("")

	fLogger.fatal("Error message:")
	fLogger.fatal(http)
	fLogger.fatal("")

	error("Decision Descent's HTTP library is required to use Decision Descent!")
end

if not utils_imported then
	fLogger.fatal("Decision Descent's utils library is missing!")
	fLogger.fatal("Isaac should have retrieved this file during launch!")
	fLogger.fatal("You can get this file with any of the following options...")
	fLogger.fatal("    - Relaunch Isaac")
	fLogger.fatal("    - Download it from Decision Descent's Github @ https://github.com/SirRandoo/decision-descent")
	fLogger.fatal("")

	fLogger.fatal("Error message:")
	fLogger.fatal(utils)
	fLogger.fatal("")

	error("Decision Descent's utils library is required to use Decision Descent!")
end


--[[  Post-Check Variables  ]]--
DecisionDescent.logger = utils.getLogger("decision_descent")
DecisionDescent.http = http.create()

local DDLog = DecisionDescent.logger


--[[  Additional Intents  ]]--
DecisionDescent.http.intents.state = {
	config = {
		update = function(modConf)
			local httpConfig = config.http

			config = modConf
			config.http = httpConfig
		end
	}
}


--[[  HTTP Checks  ]]--
local succeeded, response = pcall(function() DecisionDescent.http:connect(config.http.host, config.http.port) end)

if not succeeded then
	DDLog:critical("Could not connect to client!")
	DDLog:critical("The Lua half of Decision Descent is merely the client's puppet, and cannot function on its own!")
	DDLog:critical(string.format("Error message: %s", response))
else
	DDLog:critical("Successfully connected to the client!")
end


--[[  Generator Declaration  ]]--

local function generatePoll()
	local maximumChoices = 2
	local game = Game()
	local room = game:GetRoom()
	local roomType = room:GetType()
	local roomSeed = room:GetAwardSeed()
	local itemConfig = Isaac.GetItemConfig()
	local itemPool = game:GetItemPool()
	local choices = {}

	if config.core then
		if config.core.maximum_choices < 0 then
			maximumChoices = 10000
		elseif config.core.maximum_choices == 0 then
			maximumChoices = 0
		else
			maximumChoices = config.core.maximum_choices
		end
	end

	if roomType == RoomType.ROOM_ERROR or roomType == RoomType.ROOM_TREASURE 
		or roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_SUPERSECRET 
		or roomType == RoomType.ROOM_CURSE or roomType == RoomType.ROOM_DEVIL 
		or roomType == RoomType.ROOM_ANGEL or roomType == RoomType.ROOM_BOSSRUSH 
		or roomType == RoomType.ROOM_BLACK_MARKET then

		local roomPool = itemPool:GetPoolForRoom(roomType, roomSeed)

		while #choices < maximumChoices do
			local choice = itemPool:GetCollectible(roomPool, false, roomSeed)

			if choice ~= nil then
				local item = itemConfig:GetCollectible(choice)
				local duplicate = false

				for a=1, #choices do
					if choices[a] == choice then duplicate = true end
				end

				if not duplicate then table.insert(choices, {item.ID, item.Name}) end
			else
				break
			end
		end

		if #choices > 1 then
			directChoices = {}
			aliases = {}

			for _, itemArray in pairs(choices) do
				directChoice = tostring(itemArray[1])
				table.insert(directChoices, directChoice)
				
				if aliases[directChoice] ~= nil then
					table.insert(aliases[directChoice], itemArray[2])
				else
					aliases[directChoice] = {itemArray[2]}
				end
			end

			if roomType ~= RoomType.ROOM_DEVIL then
				DecisionDescent.http:sendMessage("polls.create", directChoices, aliases, "player.grant.collectible")
			elseif roomType == RoomType.ROOM_DEVIL or roomType == RoomType.ROOM_BLACK_MARKET then
				DecisionDescent.http:sendMessage("polls.multi.create", directChoices, aliases, "player.grant.devil")
			end
		else
			DDLog:info("Insufficient choices!")
		end
	end
end


--[[  Callbacks  ]]--
function DecisionDescent.POST_GAME_STARTED(isSave) if not isSave then DecisionDescent.http:sendMessage("polls.delete.all") end end
function DecisionDescent.PRE_GAME_EXIT(shouldSave) if shouldSave then DecisionDescent.http:sendMessage("client.close") end end
function DecisionDescent.POST_NEW_LEVEL() DecisionDescent.http:sendMessage("client.state.level.changed") end
function DecisionDescent.POST_RENDER()
	local game = Game()
	local room = game:GetRoom()
	local topLeft = room:WorldToScreenPosition(room:GetTopLeftPos())
	local bottomRight = room:WorldToScreenPosition(room:GetBottomRightPos())
	local renderPos = Vector(bottomRight.X, topLeft.Y)
	local renderText = string.format("Decision Descent v%s", version)

	Isaac.RenderText(renderText, math.abs(renderPos.X - math.ceil(Isaac.GetTextWidth(renderText) / 2)), renderPos.Y, 1.0, 1.0, 1.0, 0.8)
end
function DecisionDescent.POST_UPDATE()
	if Isaac.GetFrameCount() % 30 == 0 then
		local status = coroutine.status(DecisionDescent.http.listener)

		if status == "suspended" then
			coroutine.resume(DecisionDescent.http.listener)
		elseif status == "dead" then
			DDLog:critical("Listener coroutine is dead!")
			DDLog:critical("Reviving coroutine...")
			DecisionDescent.http.listener = coroutine.create(function() DecisionDescent.http:onMessage() end)
		end
	end
end
function DecisionDescent.POST_NEW_ROOM()
	DecisionDescent.http:sendMessage("client.state.room.changed")
	local maximumChoices = 2
	local game = Game()

	if config.core then
		if config.core.maximum_choices < 0 then
			maximumChoices = 10000
		elseif config.core.maximum_choices == 0 then
			maximumChoices = 0
		else
			maximumChoices = config.core.maximum_choices
		end
	end

	--[[  Room Checks  ]]--
	local currentRoom = game:GetRoom()
	local roomType = currentRoom:GetType()
	local roomSeed = currentRoom:GetAwardSeed()
	local itemConfig = Isaac.GetItemConfig()
	local itemPool = game:GetItemPool()
	local roomPool = itemPool:GetPoolForRoom(roomType, roomSeed)

	DDLog:info(string.format("ROOM_ERROR %s", roomType == RoomType.ROOM_ERROR))
	DDLog:info(string.format("ROOM_TREASURE %s", roomType == RoomType.ROOM_TREASURE))
	DDLog:info(string.format("ROOM_BOSS %s", roomType == RoomType.ROOM_BOSS))
	DDLog:info(string.format("ROOM_SUPERSECRET %s", roomType == RoomType.ROOM_SUPERSECRET))
	DDLog:info(string.format("ROOM_CURSE %s", roomType == RoomType.ROOM_CURSE))
	DDLog:info(string.format("ROOM_DEVIL %s", roomType == RoomType.ROOM_DEVIL))
	DDLog:info(string.format("ROOM_ANGEL %s", roomType == RoomType.ROOM_ANGEL))
	DDLog:info(string.format("ROOM_BOSSRUSH %s", roomType == RoomType.ROOM_BOSSRUSH))
	DDLog:info(string.format("ROOM_BLACK_MARKET %s", roomType == RoomType.ROOM_BLACK_MARKET))

	if roomType == RoomType.ROOM_ERROR or roomType == RoomType.ROOM_TREASURE 
		or roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_SUPERSECRET 
		or roomType == RoomType.ROOM_CURSE or roomType == RoomType.ROOM_DEVIL 
		or roomType == RoomType.ROOM_ANGEL or roomType == RoomType.ROOM_BOSSRUSH 
		or roomType == RoomType.ROOM_BLACK_MARKET then
		local generator = coroutine.create(generatePoll)

      	coroutine.resume(generator)
	end
end


--[[  Main  ]]--
DDLog:warning("Decision Descent current only supports Windows 10!")
DDLog:warning("If you are using Decision Descent on an operating system other than Windows 10, be sure to submit your issues on the Github page @ https://github.com/sirrandoo/decision-descent")


DDLog:info("Registering callbacks...")

DDLog:info("Registering MC_POST_GAME_STARTED callback...")
DecisionDescent:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DecisionDescent.POST_GAME_STARTED)

DDLog:info("Registering MC_PRE_GAME_EXIT callback...")
DecisionDescent:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, DecisionDescent.PRE_GAME_EXIT)

DDLog:info("Registering MC_POST_NEW_LEVEL callback...")
DecisionDescent:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, DecisionDescent.POST_NEW_LEVEL)

DDLog:info("Registering MC_POST_NEW_ROOM callback...")
DecisionDescent:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DecisionDescent.POST_NEW_ROOM)

DDLog:info("Registering MC_POST_RENDER callback...")
DecisionDescent:AddCallback(ModCallbacks.MC_POST_RENDER, DecisionDescent.POST_RENDER)

DDLog:info("Registering MC_POST_UPDATE callback...")
DecisionDescent:AddCallback(ModCallbacks.MC_POST_UPDATE, DecisionDescent.POST_UPDATE)

DDLog:info("Callbacks registered!")
DDLog:info(string.format("Decision Descent v%s loaded!", version))
