-- **Auto Assembler スクリプトの内容**
local aobScanAAScript = [==[
[ENABLE]
{$lua}
if syntaxcheck then return end

-- **デバッグモードの設定 (デフォルト: 無効)**
local debugMode = false

-- **AOB スキャン関数**
if not AOBScanModule then
    function AOBScanModule(moduleName, signature, scanOptions)
        local baseAddr = nil
        local maxAddr = 0
        local modList

        synchronize(function()
            modList = enumModules()
        end)

        for _, mod in ipairs(modList) do
            if string.lower(mod.Name) == string.lower(moduleName) then
                baseAddr = mod.Address
                maxAddr = baseAddr + mod.Size
                break
            end
        end

        if not baseAddr then
            if debugMode then print("❌ Error: Module " .. moduleName .. " not found!") end
            return nil
        end

        if debugMode then
            print(string.format("✅ %s Base Address: 0x%X", moduleName, baseAddr))
            print(string.format("📏 Scanning Range: 0x%X - 0x%X", baseAddr, maxAddr))
        end

        local ms = createMemScan()

        synchronize(function()
            ms.firstScan(
                soExactValue,
                vtByteArray,
                nil,
                signature,
                nil,
                baseAddr,
                maxAddr,
                scanOptions or "+X+R",
                fsmNotAligned,
                "1",
                true,
                true,
                false,
                false
            )
        end)

        ms.waitTillDone()

        local results = createFoundList(ms)
        results.initialize()

        local addr
        synchronize(function()
            if results.getCount() > 0 then
                addr = results[0]
            end
        end)

        if addr then
            if debugMode then print("🎯 AOB found at: 0x" .. addr) end
        else
            if debugMode then print("❌ AOB not found in " .. moduleName) end
        end

        results.destroy()
        ms.destroy()
        return addr
    end
end

registerLuaFunctionHighlight('AOBScanModule')

-- **Lua scripts that table checkbox will not be checked with "NO_ACTIVATE" in comment**
if not onMemRecPostExecute then
    function onMemRecPostExecute(memoryrecord, newState, succeeded)
        if memoryrecord.Type == vtAutoAssembler and memoryrecord.Script:find("NO_ACTIVATE") and newState and succeeded then
            synchronize(function()
                memoryrecord.disableWithoutExecute()
            end)
        end
    end
end

-- **Memory record IDs now allowed to be 'locked'**
IDs = {999999, 9999999}

-- **Determine event trigger sequence**
if not contains then
    function contains(table, val)
       for i = 1, #table do
          if table[i] == val then
             return true
          end
       end
       return false
    end
end

if not onMemRecPreExecute then
    function onMemRecPreExecute(memoryrecord, newstate)
        if contains(IDs, memoryrecord.ID) and newstate then
            synchronize(function()
                if not memoryrecord.OnActivate then
                    memoryrecord.OnActivate = function(memoryrecord, before, currentstate)
                        return false
                    end
                end
            end)
        end
    end
end

-- **Utility Functions**
if not clearLuaLog then
    function clearLuaLog()
        synchronize(function()
          getLuaEngine().MenuItem5.doClick()
        end)
    end
end
registerLuaFunctionHighlight('clearLuaLog')

if not closeLuaEngine then
    function closeLuaEngine()
        synchronize(function()
          getLuaEngine().Close()
        end)
    end
end
registerLuaFunctionHighlight('closeLuaEngine')

if not closeLuaEngine2 then
    function closeLuaEngine2()
        synchronize(function()
          getLuaEngine().MenuItem5.doClick()
          getLuaEngine().Close()
        end)
    end
end
registerLuaFunctionHighlight('closeLuaEngine2')

synchronize(function() AddressList.Header.OnSectionClick = nil end)

[DISABLE]
{$lua}
if AOBScanModule then
    AOBScanModule = nil
end
if onMemRecPostExecute then
    onMemRecPostExecute = nil
end
if onMemRecPreExecute then
    onMemRecPreExecute = nil
end
if clearLuaLog then
    clearLuaLog = nil
end
if closeLuaEngine then
    closeLuaEngine = nil
end
if closeLuaEngine2 then
    closeLuaEngine2 = nil
end
]==]

-- **AA Script を Cheat Table に追加する関数**
function createAOBScanMemoryRecord()
    local ct = getAddressList()
    
    -- **すでに追加されているか確認**
    for i = 0, ct.Count - 1 do
        if ct[i].Description == "AOBScanModule AA Script" then
            --showMessage("📌 AOBScanModule AA Script is already in the Cheat Table.")
            return
        end
    end

    -- **新しいメモリレコードを作成**
    local newRecord = ct.createMemoryRecord()
    newRecord.Description = "AOBScanModule AA Script"
    newRecord.Type = vtAutoAssembler
    newRecord.Script = aobScanAAScript
    newRecord.Active = false

    --showMessage("✅ AOBScanModule AA Script has been added to the Cheat Table!")
end

-- **Dev Tools メニューを取得、存在しない場合は作成**
function getOrCreateDevToolsMenu()
    local mainMenu = MainForm.Menu.Items
    local devToolsMenu

    -- **Dev Tools メニューを検索**
    for i = 0, mainMenu.Count - 1 do
        local menuItem = mainMenu[i]
        if menuItem.Name == 'miDevTools' or menuItem.Caption == '&Dev Tools' then
            return menuItem
        end
    end

    -- **メニューがない場合は作成**
    synchronize(function()
        devToolsMenu = createMenuItem(mainMenu)
        devToolsMenu.Name = 'miDevTools'
        devToolsMenu.Caption = '&Dev Tools'
        mainMenu.add(devToolsMenu)
    end)

    return devToolsMenu
end

-- **Dev Tools メニューに "Add AOBScanModule AA Script" を追加**
function addMenuToDevTools()
    local devToolsMenu = getOrCreateDevToolsMenu()

    -- **すでにメニューが存在する場合は追加しない**
    for i = 0, devToolsMenu.Count - 1 do
        if devToolsMenu[i].Caption == "Enable AOBScanModule" then
            return
        end
    end

    -- **メニューを追加**
    synchronize(function()
        local newItem = createMenuItem(devToolsMenu)
        newItem.Caption = "Add AOBScanModule AA Script"
        newItem.OnClick = createAOBScanMemoryRecord
        devToolsMenu.add(newItem)
    end)
end

-- **メニューを Dev Tools に追加**
addMenuToDevTools()
