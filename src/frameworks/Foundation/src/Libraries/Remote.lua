--[[
    Remote.lua
    Author: Conscience (@MixedConscience)
    -----------------
    Remote library for easy remote interaction. 
	Included in the Foundation framework.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remote = {}

local Private = {}
Private.Location = ReplicatedStorage:FindFirstChild("Remotes")
Private.Runtime = if RunService:IsClient() then "Client" else "Server"
Private.Remotes = {}

export type RemoteType = RemoteEvent | RemoteFunction | UnreliableRemoteEvent
export type RemoteEvents = RemoteEvent | UnreliableRemoteEvent

local function IsARemote(instance: Instance, type: { "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent" }?)
	if typeof(instance) ~= "Instance" then return false end
	
	if type then
		for _, ty in type do
			if instance:IsA(ty) then
				return true
			end
		end

		return false
	end

	return (if instance:IsA("RemoteEvent") or instance:IsA("UnreliableRemoteEvent") or instance:IsA("RemoteFunction") then true else false)
end

local function CacheRemotes()
	if not Private.Location then
		error(`[Foundation<{Private.Runtime}>}][Remote]: Location for remotes is nil or is not an instance (location-not-set)'`)
	end

	for _, remote in Private.Location:GetDescendants() do
		if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") or remote:IsA("RemoteFunction") then
			if Private.Remotes[remote.Name] then
				error(`[Foundation<{Private.Runtime}>}]: Remote with the name '{remote.Name}' already found (duplicate)`)
			end

			Private.Remotes[remote.Name] = remote
		end
	end
end

local function ResolveRemote(path: string)
	local CachedRemote = Private.Remotes[path]

	if CachedRemote then
		return CachedRemote
	end

	--

	local Destination = Private.Location

	for match in string.gmatch(path, "[^%.]+") do
		local NewDestination = Destination:FindFirstChild(match)

		if not NewDestination then
			error(`[Foundation<{Private.Runtime}>}][Remote]: Couldn't find instance {match} inside of '{Destination:GetFullName()}'`)
		end

		Destination = NewDestination
	end

	return (if IsARemote(Destination) then Destination else nil)
end

local function AssertRemote(remote: string | RemoteEvents)
	local Path = remote
	if typeof(remote) == "string" then remote = ResolveRemote(remote) end

	if not remote then
		error(`[Foundation<{Private.Runtime}>}][Remote]: Object passed with path '{Path}' does not refer to a remote (non-remote-instance)`)
	end

	if not IsARemote(remote :: any) then
		error(`[Foundation<{Private.Runtime}>}][Remote]: Object passed with path '{Path}' is not a remote (unknow-instance)`)
	end

	return remote
end

local Server do
	Server = {}
	
	function Server.Send(remote: string | RemoteEvents, player: Player, ...)
		remote = AssertRemote(remote);
		
		if (remote :: any):IsA("RemoteFunction") then
			error(`[Foundation<{Private.Runtime}>}][Remote]: Invoking the client with a RemoteFunction '{(remote :: any):GetFullName()}' is unsupported (invalid-operation)`)
		end
		
		--

		(remote :: any):FireClient(player, ...)
	end
	
	function Server.SendToAll(remote: string | RemoteEvents, ...)
		remote = AssertRemote(remote);
		
		if (remote :: any):IsA("RemoteFunction") then
			error(`[Foundation<{Private.Runtime}>}][Remote]: Invoking the client with a RemoteFunction '{(remote :: any):GetFullName()}' is unsupported (invalid-operation)`)
		end

		--

		(remote :: any):FireAllClients(...)
	end

	function Server.SendToAllExcept(remote: string | RemoteEvents, except: Player, ...)
		remote = AssertRemote(remote);
		
		if (remote :: any):IsA("RemoteFunction") then
			error(`[Foundation<{Private.Runtime}>}][Remote]: Invoking the client with a RemoteFunction '{(remote :: any):GetFullName()}' is unsupported (invalid-operation)`)
		end
		
		--

		for _, player in Players:GetPlayers() do
			if player == except then continue end
			(remote :: any):FireClient(player, ...)
		end
	end

	--

	function Server.Listen(remote: string | RemoteType, callback: (player: Player, ...any) -> (any))
		remote = AssertRemote(remote :: any);
		
		if not callback or typeof(callback) ~= "function" then
			error(`[Foundation<{Private.Runtime}>]: Client callback was not provided as a function or is nil! (remote-callback)`)
		end
		
		--

		if IsARemote(remote :: any, { "RemoteEvent", "UnreliableRemoteEvent" }) then
			(remote :: any).OnServerEvent:Connect(callback)
		elseif IsARemote(remote :: any, { "RemoteFunction" }) then
			(remote :: RemoteFunction).OnServerInvoke = callback
		end
	end
	
	function Server.Wait(remote: string | RemoteType)
		remote = AssertRemote(remote :: any);

		--
		
		local CurrentThread = coroutine.running()
		local Callback = function(player: Player, ...)
			coroutine.resume(CurrentThread, player, ...)
		end

		if IsARemote(remote :: any, { "RemoteEvent", "UnreliableRemoteEvent" }) then
			(remote :: any).OnServerEvent:Connect(Callback)
		elseif IsARemote(remote :: any, { "RemoteFunction" }) then
			(remote :: RemoteFunction).OnServerInvoke = Callback
		end
		
		return coroutine.yield()
	end
end

local Client do
	Client = {}
	
	function Client.Send(remote: string | RemoteEvents, player: Player, ...)
		remote = AssertRemote(remote);

		if (remote :: any):IsA("RemoteFunction") then
			error(`[Foundation<{Private.Runtime}>}][Remote]: Invoking the client with a RemoteFunction '{(remote :: any):GetFullName()}' is unsupported (invalid-operation)`)
		end

		--
		
		if IsARemote(remote :: any, { "RemoteEvent", "UnreliableRemoteEvent" }) then
			(remote :: any):FireServer(...)
		elseif IsARemote(remote :: any, { "RemoteFunction" }) then
			(remote :: any):InvokeServer(...)
		end
	end

	--

	function Client.Listen(remote: string | RemoteType, callback: (...any) -> (any))
		remote = AssertRemote(remote :: any);

		if not callback or typeof(callback) ~= "function" then
			error(`[Foundation<{Private.Runtime}>]: Server callback was not provided as a function or is nil! (remote-callback)`)
		end

		--

		if IsARemote(remote :: any, { "RemoteEvent", "UnreliableRemoteEvent" }) then
			(remote :: any).OnClientEvent:Connect(callback)
		elseif IsARemote(remote :: any, { "RemoteFunction" }) then
			(remote :: RemoteFunction).OnClientInvoke = callback
		end
	end

	function Client.Wait(remote: string | RemoteType)
		remote = AssertRemote(remote :: any);

		--

		local CurrentThread = coroutine.running()
		local Callback = function(...)
			coroutine.resume(CurrentThread, ...)
		end

		if IsARemote(remote :: any, { "RemoteEvent", "UnreliableRemoteEvent" }) then
			(remote :: any).OnClientEvent:Connect(Callback)
		elseif IsARemote(remote :: any, { "RemoteFunction" }) then
			(remote :: RemoteFunction).OnClientInvoke = Callback
		end

		return coroutine.yield()
	end
end

--

function Remote.SetLocation(location: Instance)
	Private.Location = location
end

function Remote.GetRemote(name: string): RemoteEvent | RemoteFunction | UnreliableRemoteEvent
	local RemoteInstance = ResolveRemote(name)
	
	if RemoteInstance then
		return RemoteInstance
	end
	
	error(`[Foundation<{Private.Runtime}>}][Remote]: Couldn't find remote with path or name of '{name}'!`)
end

--

CacheRemotes()

Remote.Server = Server
Remote.Client = Client

return Remote