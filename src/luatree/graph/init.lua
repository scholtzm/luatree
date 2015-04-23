---------------------------------------------
-- graph module
-- luadb graph toolkit
-- @author: Michael Scholtz
---------------------------------------------

local extractor = require("luadb.extraction.functioncalls")
local hypergraph = require("luadb.hypergraph")
local utils = require("luatree.utils")

---------------------------------------------
-- Constants & Private methods
---------------------------------------------

local FLAG_CREATED = "created"
local FLAG_DELETED = "deleted"
local SEPARATOR = ":"

--- Edge hashing function.
-- This function returns unique hash for a given edge.
-- @param edge Hypergraph edge
-- @return string Hash
local function edge_hash(edge)
    local edge_from = edge.meta.calleeFunction
    local edge_to = edge.meta.calledFunction
    local edge_text = edge.data.text

    return tostring(edge_from) .. SEPARATOR .. tostring(edge_to) .. SEPARATOR .. tostring(edge_text)
end

--- Get edge information from its hash.
-- @param edge Edge's hash
-- @return string Edge info: from, to, text
local function edge_from_hash(hash)
    local values = { "", "", "" }
    local k = 1

    for i = 1, #hash do
        if hash:sub(i,i) == SEPARATOR then
            k = k + 1
        else
            values[k] = values[k] .. hash:sub(i,i)
        end
    end

    return unpack(values)
end

--- Edge comparator.
-- Compares from, to and text of 2 edges for equality.
-- @param edge1 First hypergraph edge
-- @param edge2 Second hypergraph edge
-- @return boolean Result of comparison
local function equal_edges(edge1, edge2)
    local hash1 = edge_hash(edge1)
    local hash2 = edge_hash(edge2)

    if hash1 == hash2 then
        return true
    else
        return false
    end
end

--- Summarize list of nodes into a hash table.
-- Creates a summary of graph nodes.
-- @param graph Hypergraph
-- @return table Summary of functions
local function summarize_nodes(graph)
    local functions = {}

    for i, v in ipairs(graph.nodes) do
        local func_name = v.data.name
        if functions[func_name] == nil then
            functions[func_name] = 1
        else
            functions[func_name] = functions[func_name] + 1
        end
    end

    return functions
end

--- Summarize list of edges into a hash table.
-- Creates a summary of graph edges.
-- @param graph Hypergraph
-- @return table Summary of function calls
local function summarize_edges(graph)
    local edges = {}

    for i, v in ipairs(graph.edges) do
        local hash = edge_hash(v)

        if edges[hash] == nil then
            edges[hash] = 1
        else
            edges[hash] = edges[hash] + 1
        end
    end

    return edges
end

--- Compare two function summaries.
-- @param summary1 Generated by summarize_nodes
-- @param summary2 Generated by summarize_nodes
-- @param diff (optional) Diff to write into so we don't need to merge
-- @return table Diff table for nodes
local function summary_compare(summary1, summary2, flag, diff)
    local diff = diff or {}

    for k, v in pairs(summary1) do
        for i = 1, v do
            if summary2[k] == nil or summary2[k] == 0 then
                if diff[k]  == nil then
                    diff[k] = {
                        flag = flag,
                        count = 1
                    }
                else
                    diff[k].count = diff[k].count + 1
                end
            else
                if summary1[k] then summary1[k] = summary1[k] - 1 end
                if summary2[k] then summary2[k] = summary2[k] - 1 end
            end
        end
    end

    return diff
end

---------------------------------------------
-- Public methods
---------------------------------------------

--- Function to get function graph from string.
-- @param string Source code
-- @return graph Graph of funtion calls
local function get_graph(string)
    local function_calls_graph = hypergraph.graph.new()
    extractor.extractFromString(string, function_calls_graph)

    return function_calls_graph
end

--- Function to get function graph from file.
-- @param file File path
-- @return graph Graph of funtion calls
local function get_graph_from_file(file)
    local function_calls_graph = hypergraph.graph.new()
    extractor.extract(file, function_calls_graph)

    return function_calls_graph
end

--- Function to get function graph from existing AST tree.
-- @param ast AST tree retrieved from `ast` submodule.
-- @return graph Graph of funtion calls
local function get_graph_from_AST(ast)
    local function_calls_graph = hypergraph.graph.new()
    extractor.extractFromAST(ast, function_calls_graph)

    return function_calls_graph
end

--- Function to compare 2 function call graphs.
-- This function compares 2 function call graphs - new and old graph.
-- @param graph_new New function call graph returned from `get_graph` function
-- @param graph_old Old function call graph returned from `get_graph` function
local function compare(graph_old, graph_new)
    -- To speed up things, we will use internal cache
    local cache = setmetatable({}, { __index = function() return 0 end })

    -- Let's compare list of nodes first
    for _, old_node in ipairs(graph_old.nodes) do
        cache[old_node.data.name] = cache[old_node.data.name] + 1
    end

    for _, new_node in ipairs(graph_new.nodes) do
        if cache[new_node.data.name] > 0 then
            cache[new_node.data.name] = cache[new_node.data.name] - 1
            new_node.flag = "identical"
        else
            new_node.flag = "created"
        end
    end

    -- Compare edges
    for _, old_edge in ipairs(graph_old.edges) do
        local hash = edge_hash(old_edge)
        cache[hash] = cache[hash] + 1
    end

    for _, new_edge in ipairs(graph_new.edges) do
        local hash = edge_hash(new_edge)
        if cache[hash] > 0 then
            cache[hash] = cache[hash] - 1
            new_edge.flag = "identical"
        else
            new_edge.flag = "created"
        end
    end
end

-- Function to generate a diff of 2 call graphs.
-- @param graph_new New function call graph returned from `get_graph` function
-- @param graph_old Old function call graph returned from `get_graph` function
-- @return table Graph diff
local function diff(graph_old, graph_new)
    local diff = {
        nodes = {},
        edges = {}
    }

    -- Process nodes first ...
    local functions_old = summarize_nodes(graph_old)
    local functions_new = summarize_nodes(graph_new)

    diff.nodes = summary_compare(functions_old, functions_new, FLAG_DELETED)
    diff.nodes = summary_compare(functions_new, functions_old, FLAG_CREATED, diff.nodes)

    -- Let's do edges now ...
    local edges_old = summarize_edges(graph_old)
    local edges_new = summarize_edges(graph_new)

    diff.edges = summary_compare(edges_old, edges_new, FLAG_DELETED)
    diff.edges = summary_compare(edges_new, edges_old, FLAG_CREATED, diff.edges)

    -- Return the final diff
    return diff
end

--- Function to patch old graph to generate a new graph.
-- @param graph Old function call graph returned from `get_graph` function
-- @param diff Diff generated by the diff function
-- @return graph New function call graph.
local function patch(graph, diff)
    error("not implemented")
end

--- Get edges by their data.position info
-- Function to retrieve all edges which contain data with specific position
-- @param graph luadb.hypergraph
-- @param position position in source code
-- @return table with edges
local function get_edges_by_position(graph, position)
    local result = {}

    for _, edge in ipairs(graph.edges) do
        for __, from in ipairs(edge.from) do
            if from.data.position == position then
                local edge = edge
                edge.data.role = "caller"
                table.insert(result, edge)
            end
        end

        for __, to in ipairs(edge.to) do
            if to.data.position == position then
                local edge = edge
                edge.data.role = "callee"
                table.insert(result, edge)
            end
        end
    end

    return result
end

---------------------------------------------
-- Module definition
---------------------------------------------

return {
    get_graph = get_graph,
    get_graph_from_file = get_graph_from_file,
    get_graph_from_AST = get_graph_from_AST,
    compare = compare,
    diff = diff,
    patch = patch,
    get_edges_by_position = get_edges_by_position
}
