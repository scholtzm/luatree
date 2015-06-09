---------------------------------------------
-- Tests for Bridge submodule
-- @author: Michael Scholtz
---------------------------------------------

describe("bridge submodule", function()
    local ast, graph, bridge, utils

    local code = [==[
        print("foo")

        local function a()
            b()
        end

        local function b()
            print("hi")
        end
    ]==]
  
    setup(function()
        ast = require("luatree.ast.tree")
        graph = require("luatree.graph")
        bridge = require("luatree.bridge")
        utils = require("luatree.utils")
    end)
  
    it("merges luadb graph data - soft", function()
        local t = ast.get_tree(code)
        local g = graph.get_graph(code)

        bridge.merge_graph_into_AST_soft(t, g)

        assert.is.truthy(t)
        assert.is.truthy(g)
        assert.is.truthy(t.luadbgraph)
    end)

    it("merges luadb graph data and creates new nodes", function()
        local t = ast.get_tree(code)
        local g = graph.get_graph(code)

        bridge.merge_graph_into_AST(t, g, true)

        assert.is.truthy(t)
        assert.is.truthy(g)

        local calls = utils.count_all_hypergraph_calls(t)
        local eGlobalFunctions = utils.count_table(utils.get_hypergraph_nodes_by_label(t, "eGlobalFunction"))

        assert.is.equal(3, calls)
        assert.is.equal(1, eGlobalFunctions)
    end)

    it("merges luadb graph data and does not create new nodes", function()
        local t = ast.get_tree(code)
        local g = graph.get_graph(code)

        bridge.merge_graph_into_AST(t, g, false)

        assert.is.truthy(t)
        assert.is.truthy(g)

        local calls = utils.count_all_hypergraph_calls(t)
        local eGlobalFunctions = utils.count_table(utils.get_hypergraph_nodes_by_label(t, "eGlobalFunction"))

        assert.is.equal(3, calls)
        assert.is.equal(0, eGlobalFunctions)
    end)    
end)
