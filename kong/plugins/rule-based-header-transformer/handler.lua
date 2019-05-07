local BasePlugin = require "kong.plugins.base_plugin"

local RuleBasedHeaderTransformerHandler = BasePlugin:extend()

RuleBasedHeaderTransformerHandler.PRIORITY = 904

function RuleBasedHeaderTransformerHandler:new()
  RuleBasedHeaderTransformerHandler.super.new(self, "rule-based-header-transformer")
end

function RuleBasedHeaderTransformerHandler:access(conf)
  RuleBasedHeaderTransformerHandler.super.access(self)

end

return RuleBasedHeaderTransformerHandler
