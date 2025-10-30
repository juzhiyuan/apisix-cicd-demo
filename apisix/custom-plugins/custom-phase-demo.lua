--
-- Custom plugin demonstrating the main APISIX execution phases.
--
local core = require("apisix.core")
local plugin_name = "custom-phase-demo"
local ngx = ngx

local schema = {
    type = "object",
    properties = {
        message = {type = "string", minLength = 1, description = "Text echoed in headers and body"},
        append_body = {
            type = "boolean",
            default = true,
            description = "Append a marker to the response body in the body_filter phase"
        },
        strip_uri_prefix = {
            type = "string",
            pattern = "^/",
            minLength = 1,
            description = "Remove this prefix from the incoming request URI during the rewrite phase"
        },
    },
    additionalProperties = false,
}

local _M = {
    version = 0.1,
    priority = 50,
    name = plugin_name,
    schema = schema,
}


function _M.check_schema(conf)
    return core.schema.check(schema, conf)
end


local function ensure_state(ctx, message)
    local state = ctx.custom_phase_demo
    if state then
        return state
    end

    state = {
        message = message or "custom-phase-demo",
        start_time = ngx.now(),
    }
    ctx.custom_phase_demo = state

    return state
end


function _M.rewrite(conf, ctx)
    local state = ensure_state(ctx, conf.message)
    state.rewrite_seen = true

    ngx.req.set_header("X-Phase-Demo-Rewrite", state.message)
    local uri = ngx.var.uri

    if conf.strip_uri_prefix then
        local prefix = conf.strip_uri_prefix
        if core.string.has_prefix(uri, prefix) then
            local new_uri = uri:sub(#prefix + 1)
            if new_uri == "" then
                new_uri = "/"
            elseif new_uri:byte(1) ~= 47 then
                new_uri = "/" .. new_uri
            end

            ngx.req.set_uri(new_uri, false)
            ngx.req.set_header("X-Phase-Demo-Rewrite-Uri", new_uri)
            state.rewritten_uri = new_uri
            core.log.debug(plugin_name, " rewrite stripped prefix: ", prefix, " -> ", new_uri)
        end
    end

    core.log.debug(plugin_name, " rewrite executed, route=", ctx.route_id)
end


function _M.access(conf, ctx)
    local state = ensure_state(ctx, conf.message)
    state.access_seen = true

    ngx.req.set_header("X-Phase-Demo-Access", state.message)
    core.log.debug(plugin_name, " access executed, consumer=", ctx.consumer_name)
end


function _M.balancer(conf, ctx)
    local state = ensure_state(ctx, conf.message)
    state.balancer_ip = ctx.balancer_ip or "unknown"
    state.balancer_port = ctx.balancer_port or "unknown"

    core.log.debug(
        plugin_name,
        " balancer resolved target=",
        state.balancer_ip,
        ":",
        state.balancer_port
    )
end


function _M.header_filter(conf, ctx)
    local state = ensure_state(ctx, conf.message)
    ngx.header["X-Phase-Demo"] = state.message

    core.log.debug(plugin_name, " header_filter injected response header")
end


function _M.body_filter(conf, ctx)
    if conf.append_body == false then
        return
    end

    local chunk = ngx.arg[1]
    local eof = ngx.arg[2]

    if not eof or chunk == "" or not chunk then
        return
    end

    local state = ensure_state(ctx, conf.message)
    ngx.arg[1] = chunk .. "\n-- " .. plugin_name .. " body_filter (" .. state.message .. ") --\n"
end


function _M.log(conf, ctx)
    local state = ensure_state(ctx, conf.message)
    local latency = ngx.now() - (state.start_time or ngx.req.start_time())
    local upstream = ngx.var.upstream_addr or "unknown"

    core.log.debug(
        plugin_name,
        " log phase, upstream=",
        upstream,
        ", total_latency=",
        string.format("%.3f", latency),
        "s"
    )
end


return _M
