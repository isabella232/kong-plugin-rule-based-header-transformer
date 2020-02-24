local helpers = require "spec.helpers"
local kong_client = require "kong_client.spec.test_helpers"

describe("Plugin: rule-based-header-transformer #e2e", function()

    local kong_sdk, send_request, send_admin_request

    setup(function()
        helpers.start_kong({ plugins = 'rule-based-header-transformer' })

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

    context("Rule based header transformer", function()
        local service

        before_each(function()
            service = kong_sdk.services:create({
                name = "test-service",
                url = "http://mockbin:8080/request"
            })

            kong_sdk.routes:create_for_service(service.id, "/")
        end)

        context("input_headers is set", function()
            before_each(function()
                kong_sdk.plugins:create({
                    service = { id = service.id },
                    name = "rule-based-header-transformer",
                    config = {
                        rules = {
                            {
                                output_header = "X-Output-Header",
                                input_headers = { "X-Input-Header", "X-Second-Header" }
                            }
                        }
                    }
                })
            end)

            it("should set output_header when input header is present", function()
                local response = send_request({
                    method = "GET",
                    path = "/",
                    headers = {
                        ["X-Input-Header"] = 112233
                    }
                })

                assert.are.equal(200, response.status)
                assert.are.equal("112233", response.body.headers["x-output-header"])
            end)

            it("should set output_header when not the first input header from the config is present", function()
                local response = send_request({
                    method = "GET",
                    path = "/",
                    headers = {
                        ["X-Second-Header"] = 112233
                    }
                })

                assert.are.equal(200, response.status)
                assert.are.equal("112233", response.body.headers["x-output-header"])
            end)

            it("should set output_header with first input header when multiple input headers are present", function()
                local response = send_request({
                    method = "GET",
                    path = "/",
                    headers = {
                        ["X-Input-Header"] = 554433,
                        ["X-Second-Header"] = 112233
                    }
                })

                assert.are.equal(200, response.status)
                assert.are.equal("554433", response.body.headers["x-output-header"])
            end)

            it("should not set output_header when no valid input headers are present", function()
                local response = send_request({
                    method = "GET",
                    path = "/",
                    headers = {
                        ["X-Not-Input-Header"] = 666
                    }
                })

                assert.are.equal(200, response.status)
                assert.is_nil(response.body.headers["x-output-header"])
            end)
        end)

        context("uri_matchers is set", function()
            before_each(function()
                kong_sdk.plugins:create({
                    service = { id = service.id },
                    name = "rule-based-header-transformer",
                    config = {
                        rules = {
                            {
                                output_header = "X-Output-Header",
                                uri_matchers = { "/valid/(.-)/", "/okay/(.-)/" }
                            }
                        }
                    }
                })
            end)

            it("should set output_header when first uri matcher is present", function()
                local response = send_request({
                    method = "GET",
                    path = "/valid/112233/"
                })

                assert.are.equal(200, response.status)
                assert.are.equal("112233", response.body.headers["x-output-header"])
            end)

            it("should set output_header when not the first uri matcher from the config is present", function()
                local response = send_request({
                    method = "GET",
                    path = "/okay/112233/"
                })

                assert.are.equal(200, response.status)
                assert.are.equal("112233", response.body.headers["x-output-header"])
            end)

            it("should set output_header with first uri matcher when multiple uri matchers are present", function()
                local response = send_request({
                    method = "GET",
                    path = "/valid/554433/okay/112233/"
                })

                assert.are.equal(200, response.status)
                assert.are.equal("554433", response.body.headers["x-output-header"])
            end)

            it("should not set output_header when no valid uri matchers are present", function()
                local response = send_request({
                    method = "GET",
                    path = "/invalid/112233/"
                })

                assert.are.equal(200, response.status)
                assert.is_nil(response.body.headers["x-output-header"])
            end)
        end)

        context("input_query_parameter is set", function()
            before_each(function()
                kong_sdk.plugins:create({
                    service = { id = service.id },
                    name = "rule-based-header-transformer",
                    config = {
                        rules = {
                            {
                                output_header = "X-Output-Header",
                                input_query_parameter = "query_parameter"
                            }
                        }
                    }
                })
            end)

            it("should set output_header when input_query_parameter is present", function()
                local response = send_request({
                    method = "GET",
                    path = "/valid/112233/?query_parameter=value"
                })

                assert.are.equal(200, response.status)
                assert.are.equal("value", response.body.headers["x-output-header"])
            end)

            it("should not set output_header when no input_query_parameter is present", function()
                local response = send_request({
                    method = "GET",
                    path = "/invalid/112233/?not_looking_for_this=value"
                })

                assert.are.equal(200, response.status)
                assert.is_nil(response.body.headers["x-output-header"])
            end)
        end)

        context("multiple inputs are set in one rule", function()
            before_each(function()
                kong_sdk.plugins:create({
                    service = { id = service.id },
                    name = "rule-based-header-transformer",
                    config = {
                        rules = {
                            {
                                output_header = "X-Output-Header",
                                uri_matchers = { "/valid/(.-)/" },
                                input_headers = { "X-Input-Header" },
                                input_query_parameter = "query_parameter"
                            }
                        }
                    }
                })
            end)

            it("should set output_header from input_headers when it is present", function()
                local response = send_request({
                    method = "GET",
                    path = "/valid/111111/?query_parameter=222222",
                    headers = {
                        ["X-Input-Header"] = 333333
                    }
                })

                assert.are.equal(200, response.status)
                assert.are.equal("333333", response.body.headers["x-output-header"])
            end)

            it("should set output_header from query parameter when it is present without input header", function()
                local response = send_request({
                    method = "GET",
                    path = "/valid/111111/?query_parameter=222222"
                })

                assert.are.equal(200, response.status)
                assert.are.equal("222222", response.body.headers["x-output-header"])
            end)
        end)

        context("multiple rules are set", function()
            before_each(function()
                kong_sdk.plugins:create({
                    service = { id = service.id },
                    name = "rule-based-header-transformer",
                    config = {
                        rules = {
                            {
                                output_header = "X-Output-Uri",
                                uri_matchers = { "/valid/(.-)/" }
                            },
                            {
                                output_header = "X-Output-Uri",
                                uri_matchers = { "/okay/(.-)/" }
                            },
                            {
                                output_header = "X-Output-Header",
                                input_headers = { "X-Input-Header" }
                            },
                            {
                                output_header = "X-Output-Header",
                                input_headers = { "X-Second-Header" }
                            },
                            {
                                output_header = "X-Output-Query",
                                input_query_parameter = "query_parameter"
                            },
                            {
                                output_header = "X-Output-Query",
                                input_query_parameter = "other_query_parameter"
                            }
                        }
                    }
                })
            end)

            it("should itarate through all rules and should not override output header", function()
                local response = send_request({
                    method = "GET",
                    path = "/valid/expected_uri_value/okay/wrong_value/?query_parameter=expected_query_param&other_query_parameter=wrong_value",
                    headers = {
                        ["X-Input-Header"] = "expected_header_value",
                        ["X-Second-Header"] = "wrong_value"
                    }
                })

                assert.are.equal(200, response.status)
                assert.are.equal("expected_uri_value", response.body.headers["x-output-uri"])
                assert.are.equal("expected_header_value", response.body.headers["x-output-header"])
                assert.are.equal("expected_query_param", response.body.headers["x-output-query"])
            end)
        end)
    end)
end)
