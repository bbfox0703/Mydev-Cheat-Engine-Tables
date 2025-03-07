-- Copyright (c) bbfox <at> https://opencheattables.com 2025
--
--
-- CE のメインメニューを取得
local mainMenu = getMainForm().Menu.Items

-- Dev Tools メニューを取得、存在しない場合は作成
function getOrCreateDevToolsMenu()
    for i = 0, mainMenu.Count - 1 do
        local menuItem = mainMenu[i]
        -- **Name と Caption 両方をチェック**
        if menuItem.Name == 'miDevTools' or menuItem.Caption == '&Dev Tools' then
            return menuItem
        end
    end

    -- Dev Tools メニューが存在しない場合、新規作成（synchronize() を使用）
    local devToolsMenu
    synchronize(function()
        devToolsMenu = createMenuItem(mainMenu)
        devToolsMenu.Name = 'miDevTools'
        devToolsMenu.Caption = '&Dev Tools'
        mainMenu.add(devToolsMenu)
    end)

    return devToolsMenu
end

-- Auto Assembler スクリプトの内容
local compactViewScript = [==[
[ENABLE]
{$asm}
// asm code here
{$lua}
if syntaxcheck then return end
clearLuaLog()


closeLuaEngine()
[DISABLE]
{$asm}
// asm code here
{$lua}
if syntaxcheck then return end



closeLuaEngine()
]==]

-- Auto Assembler のメモリレコードを作成
function createCompactViewMemoryRecord()
    local ct = getAddressList()  -- 現在の Cheat Table を取得
    local newRecord = ct.createMemoryRecord()

    newRecord.Description = 'Toggle Compact View'
    newRecord.Type = vtAutoAssembler  -- Auto Assembler スクリプトとして設定
    newRecord.Script = compactViewScript  -- スクリプトの内容を設定
    newRecord.Active = false  -- デフォルトでは無効状態
end

-- Compact View メニューを Dev Tools に追加
function addCompactViewMenu()
    local devToolsMenu = getOrCreateDevToolsMenu()

    -- すでに追加されているか確認し、重複追加を防ぐ
    for i = 0, devToolsMenu.Count - 1 do
        if devToolsMenu[i].Caption == 'Create AA lua script template' then
            return
        end
    end

    -- **メニューを追加（synchronize() を使用）**
    synchronize(function()
        local compactViewItem = createMenuItem(devToolsMenu)
        compactViewItem.Caption = 'Create AA lua script template'
        compactViewItem.OnClick = function()
            createCompactViewMemoryRecord()
        end
        devToolsMenu.add(compactViewItem)
    end)
end

-- 機能を実行
addCompactViewMenu()
