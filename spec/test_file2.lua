function printMessage(msg)
    if msg then msg = "" end
    print(msg);
end
function fileExists(file)
    printMessage() -- function call 1
end
function readFile(file)
    fileExists(file) -- function call 2
end
function tblPrint(tbl)
    printKeys(tbl) -- function call 3
    printValues(tbl) -- function call 4
end
function printKeys(tbl)
    printMessage("message content") -- function call 5
end
function printValues(tbl)
    printMessage("message content") -- function call 6
end
local function mergeTbls(tbl1, tbl2)
    testTbl(tbl1) -- function call 7
    testTbl(tbl2) -- function call 8
    testTbl(tbl1) -- added
    -- this call will change callee type since the proceedMerge method is no longer defined as local
    if proceedMerge(tbl1, tbl2) then
        printMessage("succeed") -- function call 9
    else
        printMessage("failed") -- function call 10
    end
    tblPrint(tbl1) -- function call 11
    tblPrint(tbl2) -- function call 12
end
local function testTbl(tbl)
    if tbl then end
end
--local function proceedMerge(tbl1, tbl2)
--    local ano = testTbl(tbl1) -- commented out
--    if tbl1 and tbl2 then end
--end
local function dummy() -- added
    testTbl(nil)
end
