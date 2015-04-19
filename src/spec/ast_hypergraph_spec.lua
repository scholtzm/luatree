---------------------------------------------
-- Tests for AST hypergraph submodule
-- @author: Michael Scholtz
---------------------------------------------

describe("ast hypergraph submodule", function()
    local ast, hypergraph, utils
    local tree

    local code_full = [==[
        local function __a()
            __b()
        end

        local function __b()
        end
    ]==]

    -- Ugly but spaces here need to be exact!
    local code_modified = [==[
local function __b()
            c()
        end]==]

    local code_final = [==[
        local function __a()
            __b()
        end

        local function __b()
            c()
        end
    ]==]

    -- These are specific for 'code_final'
    local visible_vertexes = {
        "N138", "N229", "N257", "N258"
    }
    local should_be_new_visible_vertexes = {
        N138 = "N397", N229 = "N547", N257 = "N577", N258 = "N578"
    }
  
    setup(function()
        ast = require("luatree.ast.tree")
        hypergraph = require("luatree.ast.hypergraph")
        utils = require("luatree.utils")

        tree = ast.get_tree(code_full)
    end)

    it("patches the given text if it's not modified at all", function()
        local patched_text = hypergraph.patch_text(tree.hypergraph, "N257", code_full)

        assert.are.equal(code_full, patched_text)
    end)

    it("patches the given text if the startpoint is modified", function()
        local patched_text = hypergraph.patch_text(tree.hypergraph, "N257", code_final)

        assert.are.equal(code_final, patched_text)
    end) 
  
    it("patches the given text if a function is modified", function()
        local patched_text = hypergraph.patch_text(tree.hypergraph, "N229", code_modified)

        assert.are.equal(code_final, patched_text)
    end)

    it("creates node pairs for 2 related hypergraphs", function()
        local patched_text = hypergraph.patch_text(tree.hypergraph, "N229", code_modified)

        assert.are.equal(code_final, patched_text)

        local new_tree = ast.get_tree(patched_text)
        local new_visible_vertexes = hypergraph.find_node_pairs(tree.hypergraph, new_tree.hypergraph, visible_vertexes)

        assert.are.same(should_be_new_visible_vertexes, new_visible_vertexes)

        for old, new in pairs(new_visible_vertexes) do
            assert.are.equal(tree.hypergraph[old].label, new_tree.hypergraph[new].label)
        end
    end)
end)
