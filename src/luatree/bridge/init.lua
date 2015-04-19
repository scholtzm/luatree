---------------------------------------------
-- bridge module
-- Tiny module to bridge data structures provided
-- by luametrics and luadb
-- @author: Michael Scholtz
---------------------------------------------

local ast = require("luatree.ast")
local graph = require("luatree.graph")
local utils = require("luatree.utils")
local HG = require("hypergraph")

---------------------------------------------
-- Constants & Private methods
---------------------------------------------

local EXTERNAL_GLOBAL_FUNCTION_LABEL = "eGlobalFunction"

--- Creates external global node.
-- This function creates new external global function node.
-- @param id Should be unique nodeid
-- @param data Data from luadb hypergraph.globalFunctions
-- @param name Function name
local function create_eglobal_function_node(id, name)
    local node = HG.N(EXTERNAL_GLOBAL_FUNCTION_LABEL)
    node.nodeid = id
    node.data = {}
    node.data.name = name
    node.data.position = -1

    return node
end

---------------------------------------------
-- Public methods
---------------------------------------------

--- Merging luadb graph into luametrics hypergraph.
-- This function merges important data from luadb graph
-- into luametrics hypergraph.
-- REMARK: !!! This function only works with luametrics which
-- includes Hypergraph captures !!!
-- NOTE: You can also use luatree to retrieve data_ast
-- and data_graph
-- @param data_ast AST tree provided by luametrics
-- @param data_graph Function call graph provided by luadb
-- @param create_new_nodes If true, this function will create
-- new nodes for GlobalFunctions defined elsewhere. Defaults to false
local function merge_graph_into_AST(data_ast, data_graph, create_new_nodes)
    assert(data_ast.hypergraph ~= nil, "param data_ast does not containt 'hypergraph' data")

    -- We don't create extra nodes by default
    local create_new_nodes = create_new_nodes or false

    -- Node ID assigned to custom created nodes from function calls
    local node_id = -1
    local hypergraph = data_ast.hypergraph

    for _, edge in ipairs(data_graph.edges) do
        local from_position = nil
        local call_position = edge.data.position
        local to_position = nil
        local to_function_name = edge.meta.calledFunction

        -- "from" might be empty for top-level calls
        if utils.live_table(edge.from) then
            from_position = edge.from[1].data.position
        end

        -- "to" might be empty for global functions defined elsewhere
        if utils.live_table(edge.to) then
            to_position = edge.to[1].data.position
        end

        -- These will be actual hypergraph nodes
        local from = nil
        local to = nil
        local actual_call = nil

        for node in pairs(hypergraph.Nodes) do
            if node.label == "LocalFunction" or node.label == "GlobalFunction" then
                if node.data.position == from_position then
                    from = node
                elseif node.data.position == to_position then
                    to = node
                end
            elseif node.label == "FunctionCall" or node.label == "_PrefixExp" then
                if node.data.position == call_position then
                    actual_call = node
                end

            -- This is a top-level call, we will set "from" as STARTPOINT
            elseif node.label == "STARTPOINT" and from_position == nil then
                from = node
            
            -- If eGlobalFunction exists, check it
            elseif node.label == EXTERNAL_GLOBAL_FUNCTION_LABEL and to_position == nil then
                if node.data.name == to_function_name then
                    to = node
                end
            end
        end

        -- At this point, "to" might be nil but we might want to create a new node from the globalFunctions info
        if to == nil and create_new_nodes then
            -- If "to" is nil, the function is either "globalCall" or ..
            if data_graph.globalCalls ~= nil and data_graph.globalCalls[to_function_name] ~= nil then
                -- There might be multiple calls
                for _, v in ipairs(data_graph.globalCalls[to_function_name]) do
                    if v.data.position == call_position then
                        to = create_eglobal_function_node(node_id, to_function_name)

                        node_id = node_id - 1
                    end
                end
            end

            -- ... possibly a "moduleCall".
            if data_graph.moduleCalls ~= nil and data_graph.moduleCalls[to_function_name] ~= nil then
                -- There might be multiple calls
                for _, v in ipairs(data_graph.moduleCalls[to_function_name]) do
                    if v.data.position == call_position then
                        to = create_eglobal_function_node(node_id, to_function_name)

                        node_id = node_id - 1
                    end
                end
            end
        end

        -- Add new incidence data to edges and nodes
        local new_edge = HG.E'call'

        hypergraph:AddEdgesFromNodeData(from, { [HG.I'caller'] = new_edge })
        hypergraph:AddNodesFromEdgeData(new_edge, { [HG.I'caller'] = from })

        hypergraph:AddEdgesFromNodeData(actual_call, { [HG.I'callpoint'] = new_edge })
        hypergraph:AddNodesFromEdgeData(new_edge, { [HG.I'callpoint'] = actual_call })

        -- "to" may be still nil if it's a GlobalFunction and create_new_nodes is false
        if to ~= nil then
            hypergraph:AddEdgesFromNodeData(to, { [HG.I'callee'] = new_edge })
            hypergraph:AddNodesFromEdgeData(new_edge, { [HG.I'callee'] = to })
        end
    end -- for each edge
end -- function

--- Similar to merge_graph_into_AST
-- This function merges important data from luadb graph
-- into luametrics hypergraph - as metadata.
-- @param data_ast AST tree provided by luametrics
-- @param data_graph Function call graph provided by luadb
local function merge_graph_into_AST_meta(data_ast, data_graph)
    assert(data_ast.hypergraph ~= nil, "param data_ast does not contain 'hypergraph' data")

    local hypergraph = data_ast.hypergraph

    for node in pairs(hypergraph.Nodes) do
        for incidence, edge in pairs(hypergraph[node]) do
            if incidence.label == "definer" and edge.label == "defines" then
                for incidence, node in pairs(hypergraph[edge]) do
                    if incidence.label == "function" then
                        local edges = graph.get_edges_by_position(data_graph, node.data.position)
                        if #edges > 0 then
                            node.luadbinfo = edges
                        end
                    end
                end
            end
        end
    end
end

--- Soft merging luadb graph into luametrics output.
-- @param data_ast AST tree provided by luametrics
-- @param data_graph Function call graph provided by luadb
local function merge_graph_into_AST_soft(data_ast, data_graph)
    data_ast.luadbgraph = data_graph
end

---------------------------------------------
-- Module definition
---------------------------------------------

return {
    merge_graph_into_AST = merge_graph_into_AST,
    merge_graph_into_AST_meta = merge_graph_into_AST_meta,
    merge_graph_into_AST_soft = merge_graph_into_AST_soft
}
