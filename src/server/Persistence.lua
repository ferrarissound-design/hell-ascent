local DataStoreService = game:GetService("DataStoreService")

local Persistence = {}

local STORE_NAME = "HellAscent_Profile_v1"
local MAX_ATTEMPTS = 3
local RETRY_SECONDS = 1.5

local store = nil
local warnedUnavailable = false

local function getStore()
	if store then
		return store
	end

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	end
	return store
end

local function warnUnavailable(reason)
	if warnedUnavailable then
		return
	end
	warnedUnavailable = true
	warn("[HELL ASCENT][DATA] persistence unavailable, records are session-only:", tostring(reason))
end

local function keyFor(userId)
	return "u_" .. tostring(userId)
end

-- Keeps the better value of every field, so a stale server can never erase progress.
local function mergeProfiles(old, new)
	old = type(old) == "table" and old or {}
	local merged = {
		v = 1,
		escapes = math.max(tonumber(old.escapes) or 0, tonumber(new.escapes) or 0),
		bests = {},
		unlocked = {},
	}

	for _, source in ipairs({old, new}) do
		if type(source.bests) == "table" then
			for difficultyId, best in pairs(source.bests) do
				if type(best) == "table" and tonumber(best.seconds) then
					local current = merged.bests[difficultyId]
					local seconds = tonumber(best.seconds)
					local deaths = tonumber(best.deaths) or 0
					if not current
						or seconds < current.seconds
						or (seconds == current.seconds and deaths < current.deaths)
					then
						merged.bests[difficultyId] = {seconds = seconds, deaths = deaths}
					end
				end
			end
		end

		if type(source.unlocked) == "table" then
			for difficultyId, flag in pairs(source.unlocked) do
				if flag == true then
					merged.unlocked[difficultyId] = true
				end
			end
		end
	end

	return merged
end

-- Returns profile table (possibly empty) and whether the read succeeded.
function Persistence.load(userId)
	local dataStore = getStore()
	if not dataStore then
		warnUnavailable("DataStore service not reachable")
		return nil, false
	end

	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(function()
			return dataStore:GetAsync(keyFor(userId))
		end)
		if ok then
			return type(result) == "table" and result or {}, true
		end

		if attempt == MAX_ATTEMPTS then
			warnUnavailable(result)
		else
			task.wait(RETRY_SECONDS)
		end
	end

	return nil, false
end

function Persistence.save(userId, profile)
	local dataStore = getStore()
	if not dataStore then
		warnUnavailable("DataStore service not reachable")
		return false
	end

	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(function()
			return dataStore:UpdateAsync(keyFor(userId), function(old)
				return mergeProfiles(old, profile)
			end)
		end)
		if ok then
			return true
		end

		if attempt == MAX_ATTEMPTS then
			warnUnavailable(result)
		else
			task.wait(RETRY_SECONDS)
		end
	end

	return false
end

Persistence.merge = mergeProfiles

return Persistence
