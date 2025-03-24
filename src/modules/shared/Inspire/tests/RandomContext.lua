local Inspire = require(...)
local RandomContext = Inspire.CreateContext("RandomContext", { Message = "hi" })

--> Context:Initialize()
--> Initializes this current context. 
--> There are no parameters or return cases for this function.
function RandomContext:Initialize()
	task.wait(15)
	print(`{self.Name}: hi initialize`)	
end

--> Context:Commence()
--> Commences this current context. 
--> There are no parameters or return cases for this function.
function RandomContext:Commence()
	print(`{self.Name}: hi commence`)
    print(`{self.Name}: message '{self.Message}'`)
end

return RandomContext