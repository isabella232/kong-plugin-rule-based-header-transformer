local BasePlugin = require "kong.plugins.base_plugin"

local RuleBasedHeaderTransformerHandler = BasePlugin:extend()

RuleBasedHeaderTransformerHandler.PRIORITY = 2000

function RuleBasedHeaderTransformerHandler:new()
  RuleBasedHeaderTransformerHandler.super.new(self, "rule-based-header-transformer")
end

function RuleBasedHeaderTransformerHandler:access(conf)
  RuleBasedHeaderTransformerHandler.super.access(self)

  if conf.say_hello then
    kong.log.debug('Hey!')

    kong.service.request.set_header('X-Upstream-Header', 'Hey Upstream!')
    kong.response.set_header('X-Downstream-Header', 'Hey Downstream!')
  else
    kong.log.debug('Bye!')

    kong.service.request.set_header('X-Upstream-Header', 'Bye Upstream!')
    kong.response.set_header('X-Downstream-Header', 'Bye Downstream!')
  end

end

return RuleBasedHeaderTransformerHandler
