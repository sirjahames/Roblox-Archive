local Logger = {}
Logger.__index = Logger

export type MessageType = "Message" | "Warning" | "Exception"
export type MessageLogFormat = { 
	MessageType: string, 
	MessageContent: string,
	MessageTimestamp: DateTime
} 

function Logger.new(prefix: string)
	local self = setmetatable({}, Logger)
	
	self.Name = "Logger"
	self.Prefix = `{prefix}<{self.Name}>`
	self.Logs = {}
	
	return self
end

function Logger:OutputMessage(ty: MessageType, message: string, ...)
	message = if select("#", ...) == 0 then message else string.format(message, ...)
	
	local Prefix = self.Prefix
	local OutputMessage = `[{Prefix}]: {message}`
	local OutputFunction = if ty == "Message" then print elseif ty == "Warning" then warn else error
	
	table.insert(self.Logs, {
		MessageType = ty,
		MessageContent = message,
		MessageTimestamp = DateTime.now()
	})
	
	OutputFunction(OutputMessage)
end

return Logger