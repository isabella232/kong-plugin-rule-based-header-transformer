local helpers = require "spec.helpers"
local kong_client = require "kong_client.spec.test_helpers"

describe("RuleBasedHeaderTransformer", function()

    local kong_sdk, send_request, send_admin_request

    setup(function()
        helpers.start_kong({ custom_plugins = 'rule-based-header-transformer' })

        kong_sdk = kong_client.create_kong_client()
        send_request = kong_client.create_request_sender(helpers.proxy_client())
        send_admin_request = kong_client.create_request_sender(helpers.admin_client())
    end)

    teardown(function()
        helpers.stop_kong(nil)
    end)

    before_each(function()
        helpers.db:truncate()
    end)

    context("Admin API", function()
        local service

        before_each(function()
            service = kong_sdk.services:create({
                name = "test-service",
                url = "http://mockbin:8080/request"
            })
        end)

        context("Plugin configuration", function()
            it("should respond proper error message when required config values not provided", function()
                local _, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {}
                    })
                end)

                assert.are.equal("rules is required", response.body["config.rules"])
            end)

            it("should respond with error when rules field is not an array", function()
                local _, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {
                            rules = {
                                not_array = "not array"
                            }
                        }
                    })
                end)

                assert.are.equal("rules is not an array", response.body["config.rules"])
            end)

            it("should respond proper error message when required config values not provided", function()
                local _, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {
                            rules = {
                                { input_headers = { "valami" } }
                            }
                        }
                    })
                end)

                assert.are.equal("required field missing", response.body.rules.output_header)
            end)

            it("should respond proper error message when input_headers and uri_matchers and input_query_parameter are missing", function()
                local _, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {
                            rules = {
                                { output_header = "output_header" }
                            }
                        }
                    })
                end)

                assert.are.equal("you must set at least input_headers or uri_matchers or input_query_parameter", response.body.config)
            end)

            it("should repond 201 when input_headers is provided and uri_matchers and input_query_parameter not", function()
                local success, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {
                            rules = {
                                {
                                    output_header = "output_header",
                                    input_headers = { "input_header" }
                                }
                            }
                        }
                    })
                end)

                assert.is_true(success)
            end)

            it("should repond 201 when uri_matchers is provided and input_headers and input_query_parameter not", function()
                local success, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {
                            rules = {
                                {
                                    output_header = "output_header",
                                    uri_matchers = { "matcher" }
                                }
                            }
                        }
                    })
                end)

                assert.is_true(success)
            end)

            it("should repond 201 when input_query_parameter is provided and input_headers and uri_matchers not", function()
                local success, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {
                            rules = {
                                {
                                    output_header = "output_header",
                                    input_query_parameter = "query_parameter"
                                }
                            }
                        }
                    })
                end)

                assert.is_true(success)
            end)

            it("should repond proper error message when not the first record is invalid", function()
                local _, response = pcall(function()
                    kong_sdk.plugins:create({
                        service_id = service.id,
                        name = "rule-based-header-transformer",
                        config = {
                            rules = {
                                {
                                    output_header = "output_header",
                                    input_query_parameter = "query_parameter"
                                },
                                {
                                    output_header = "other_header"
                                }
                            }
                        }
                    })
                end)

                assert.are.equal("you must set at least input_headers or uri_matchers or input_query_parameter", response.body.config)
            end)
        end)
    end)
end)
