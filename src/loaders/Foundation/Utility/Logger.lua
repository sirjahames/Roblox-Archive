local Logger = {}
Logger.__index = Logger

function Logger.new(prefix: string?, recordLogs: boolean?)
    local self = setmetatable({}, Logger)

    self.Name = "Logger"
    self.Prefix = `[{prefix}<{self.name}>]`
    self.Logs = if recordLogs then {} else nil

    return self
end

function Logger:OutputMessage(ty: "Warn" | "Error" | "Output", message: string, ...)
    local Prefix = self.Prefix
    local OutputFunction = if ty == "Warn" then warn elseif ty == "Error" then error else print

    message = `{Prefix}: ` .. if select("#", ...) == 0 then message else string.format(message, ...)

    if self.Logs then
        table.insert(self.Logs, {
            MessageContent = message,
            MessageType = ty,
            MessageTimestamp = os.time()
        })
    end

    return OutputFunction(`{Prefix}: {message}`) 
end

return Logger