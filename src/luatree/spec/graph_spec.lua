---------------------------------------------
-- Tests for Graph submodule
-- @author: Michael Scholtz
---------------------------------------------

describe("graph submodule", function()
    local graph, ast, utils
    local code_a = [==[
        function go()
            print("hi")
        end
    ]==]

    local code_b = [==[
        function go2()
            go()
        end
    ]==]
  
    setup(function()
        graph = require("graph")
        ast = require("ast.tree")
        utils = require("utils")
    end) 
  
    it("gives me graph from string", function()
        local g = graph.get_graph(code_a)

        assert.is.truthy(g)
    end)

    it("gives me graph from file", function()
        local file = "spec/test_file.lua"
        local g = graph.get_graph_from_file(file)

        assert.is.truthy(g)
    end)

    it("gives me graph from existing ast tree", function()
        local a = ast.get_tree(code_a)
        local g = graph.get_graph_from_AST(a)

        assert.is.truthy(g)
    end)

    it("generates two different graphs", function()
        local g_a = graph.get_graph(code_a)
        local g_b = graph.get_graph(code_b)

        assert.is_not.same(g_a, g_b)
    end)

    it("compares two graphs trees", function()
        local file_a = "spec/test_file.lua"
        local file_b = "spec/test_file2.lua"

        local g_a = graph.get_graph_from_file(file_a)
        local g_b = graph.get_graph_from_file(file_b)

        graph.compare(g_a, g_b)

        local total, nodes, edges = utils.get_graph_flag_count(g_b, "identical")
        assert.equals(22, total)
        assert.equals(8, nodes)
        assert.equals(14, edges)

        total, nodes, edges = utils.get_graph_flag_count(g_b, "created")
        assert.equals(3, total)
        assert.equals(1, nodes)
        assert.equals(2, edges)
    end)
end)
