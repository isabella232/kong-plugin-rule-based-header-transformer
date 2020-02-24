local typedefs = require "kong.db.schema.typedefs"

return {
    name = "rule-based-header-transformer",
    fields = {
        {
            consumer = typedefs.no_consumer
        },
        {
            config = {
                type = "record",
                fields = {
                    {
                        rules = {
                            type = "array",
                            required = true,
                            len_min = 1,
                            elements = {
                                type = "record",
                                fields = {
                                    { input_headers = { type = "array", elements = { type = "string" } } },
                                    { uri_matchers = { type = "array", elements = { type = "string" } } },
                                    { input_query_parameter = { type = "string" } },
                                    { output_header = { type = "string", required = true } },
                                }
                            }
                        }
                    }
                },
            }
        }
    },
    entity_checks = {
        {
            custom_entity_check = {
                field_sources = { "config.rules" },
                fn = function(entity)
                    for _, rule in pairs(entity.config.rules) do
                        local input_headers_list = type(rule.input_headers) == "table" and rule.input_headers or {}
                        local uri_matchers_list = type(rule.uri_matchers) == "table" and rule.uri_matchers or {}

                        if #input_headers_list == 0 and #uri_matchers_list == 0 then
                            if not rule.input_query_parameter or rule.input_query_parameter == ngx.null then
                                return nil, "you must set at least input_headers or uri_matchers or input_query_parameter"
                            end
                        end
                    end

                    return true
                end,
            }
        }
    }
}