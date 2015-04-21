---------------------------------------------
-- Hypergraph module
-- Hypergraph toolkit for Lua
-- @author: Michael Scholtz
---------------------------------------------

local utils = require("luatree.utils")

---------------------------------------------
-- Constants & Private methods
---------------------------------------------

--- Get group parent
-- This function will find the parent of a group.
-- For example: AssignGroup, FunctionGroup or OthersGroup.
-- @param hypergraph Hypergraph provided by luametrics.
-- @param node Group node.
-- @return Parent node.
local function get_group_parent(hypergraph, node)
    for incidence, edge in pairs(hypergraph[node]) do
        if incidence.label == "groupRoot" and edge.label == "groups" then
            for incidence, node in pairs(hypergraph[edge]) do
                if incidence.label == "groupParent" then
                    return node
                end
            end
        end
    end

    return nil
end

--- Get definer
-- This function will get the closest definer.
-- Useful for global and local funcitons.
-- @param hypergraph Hypergraph provided by luametrics.
-- @param node Hypergraph node.
-- @return Definer node.
local function get_definer(hypergraph, node)
    local IDMAX = 9999999999
    local parent_node = nil

    for incidence, edge in pairs(hypergraph[node]) do
        if incidence.label == "function" and edge.label == "defines" then
            for incidence, node in pairs(hypergraph[edge]) do
                if incidence.label == "definer" then
                    print(node)
                    if utils.get_hypergraph_id_number(node.id) < IDMAX then
                        IDMAX = utils.get_hypergraph_id_number(node.id)
                        parent_node = node
                    end
                end
            end
        end
    end

    return parent_node
end

--- Get definer
-- This function will get the closest executor.
-- Useful for assigns or function calls.
-- @param hypergraph Hypergraph provided by luametrics.
-- @param node Hypergraph node.
-- @return Executor node.
local function get_executor(hypergraph, node)
    local IDMAX = 9999999999
    local parent_node = nil

    for incidence, edge in pairs(hypergraph[node]) do
        if incidence.label == "statement" and edge.label == "executes" then
            for incidence, node in pairs(hypergraph[edge]) do
                if incidence.label == "executor" then
                    if utils.get_hypergraph_id_number(node.id) < IDMAX then
                        IDMAX = utils.get_hypergraph_id_number(node.id)
                        parent_node = node
                    end
                end
            end
        end
    end

    return parent_node
end

--- Get parent
-- This function will get the the parent by their treerelation.
-- @param hypergraph Hypergraph provided by luametrics.
-- @param node Hypergraph node.
-- @return Parent node.
local function get_parent(hypergraph, node)
    for incidence, edge in pairs(hypergraph[node]) do
        if incidence.label == "child" and edge.label == "treerelation" then
            for incidence, node in pairs(hypergraph[edge]) do
                if incidence.label == "parent" then
                    return node
                end
            end
        end
    end

    return nil 
end

---------------------------------------------
-- Public methods
---------------------------------------------

--- Patch text function
-- This function will patch the text contained in the hypergraph.
-- @param hypergraph Hypergraph provided by luametrics.
-- @param vertexid ID of the vertex that has been modified.
-- @param text Modified text.
-- @return Patched text.
local function patch_text(hypergraph, vertexid, text)
    local start_node = utils.get_hypergraph_nodes_by_label(hypergraph, "STARTPOINT")[1] -- node that contains the complete source code
    local full_text = start_node.data.str -- complete source code (before re-parsing)

    local modified_node = hypergraph[vertexid] -- node that is being modified
    local original_text = modified_node.data.str -- node text (before re-parsing)

    local start, stop = modified_node.data.position - 1, modified_node.data.position + #original_text

    -- Final text consists of:
    -- full_text beginning + current text + full_text ending
    local final_text = string.sub(full_text, 1, start)
    final_text = final_text .. text
    final_text = final_text .. string.sub(full_text, stop, #full_text)

    return final_text
end

--- Find node pairs function
-- This function will properly identify nodes in the new tree.
-- @param old_hypergraph Old hypergraph provided by luametrics.
-- @param new_hypergraph New hypergraph provided by luametrics.
-- @param vertex_list List of vertexes that needs to be identified.
-- @return Table of pairs where key = old ID and value = new ID.
local function find_node_pairs(old_hypergraph, new_hypergraph, vertex_list)
    local new_vertex_list = {}

    -- Vertexes must be sorted from lowest to highest
    table.sort(vertex_list, function(a, b)
        return utils.get_hypergraph_id_number(a) < utils.get_hypergraph_id_number(b)
    end)

    local sorted_keys = {}
    for key in pairs(new_hypergraph.Nodes) do
        table.insert(sorted_keys, key.id)
    end
    table.sort(sorted_keys, function(a, b)
        return utils.get_hypergraph_id_number(a) < utils.get_hypergraph_id_number(b)
    end)

    for _, vid in ipairs(vertex_list) do
        local old_node = old_hypergraph[vid]

        if old_node.label == "STARTPOINT" then
            for node in pairs(new_hypergraph.Nodes) do
                if old_node.label == node.label and old_node.data.position == node.data.position then
                    new_vertex_list[vid] = node.id
                    break
                end
            end
        elseif old_node.label == "LocalFunction" or
               old_node.label == "GlobalFunction" or
               old_node.label == "FunctionCall" or
               old_node.label == "LocalAssign" or
               old_node.label == "Assign" then
            local best_candidate = nil
            local old_parent = get_parent(old_hypergraph, old_node)

            for _, key in pairs(sorted_keys) do
                local node = new_hypergraph[key]

                if old_node.label == node.label then
                    local new_parent = get_parent(new_hypergraph, node)

                    if old_parent.data.str == new_parent.data.str then
                        best_candidate = node.id
                        if old_parent.data.position == new_parent.data.position then
                            break
                        end
                    end

                    if old_parent.data.position == new_parent.data.position then
                        best_candidate = node.id
                    end
                end
            end

            new_vertex_list[vid] = best_candidate 
        elseif old_node.label == "eGlobalFunction" then
            for node in pairs(new_hypergraph.Nodes) do
                if old_node.label == node.label and old_node.data.name == node.data.name then
                    new_vertex_list[vid] = node.id
                    break
                end
            end
        elseif old_node.label == "FunctionGroup" or
               old_node.label == "AssignGroup" or
               old_node.label == "OthersGroup" then
            local old_parent = get_group_parent(old_hypergraph, old_node)

            for node in pairs(new_hypergraph.Nodes) do
                if node.label == old_node.label then
                    local new_parent = get_group_parent(new_hypergraph, node)

                    if old_parent.label == new_parent.label then
                        new_vertex_list[vid] = node.id
                        break
                    end
                end
            end
        end
    end

    return new_vertex_list
end

---------------------------------------------
-- Module definition
---------------------------------------------

return {
    patch_text = patch_text,
    find_node_pairs = find_node_pairs
}
