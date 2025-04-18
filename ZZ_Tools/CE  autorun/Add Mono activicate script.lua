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
local monoEnableScript = [==[
[ENABLE]
{$asm}
//registersymbol(MyAttack) // if registerd

{$lua}
if syntaxcheck then return end
-- 📏 SafeMonoDestroy: Clean up all Mono-related state
if _G.SafeMonoDestroy == nil then
  _G.SafeMonoDestroy = function()
    print("🪚 SafeMonoDestroy: Begin cleanup...")

    -- 1. Stop symbol enumeration thread if running
    if monoSymbolEnum then
      print("🚬 Terminating monoSymbolEnum thread...")
      pcall(function()
        monoSymbolEnum.terminate()
        if not monoSymbolEnum.waitfor(3000) then
          print("⚠ Timeout: monoSymbolEnum didn't terminate in time")
        end
        monoSymbolEnum.destroy()
        monoSymbolEnum = nil
      end)
    end

    -- 2. Stop progressbar timer
    if monoSymbolList and monoSymbolList.progressbar then
      monoSymbolList.progressbar.OnTimer = nil
    end

    -- 3. Unlock pipe (try unlock even if uncertain)
    print("🔓 Attempting to unlock pipe...")
    pcall(function()
      if monopipe and monopipe.unlock then
        monopipe.unlock()
      end
    end)

    -- 4. Delay before destroy to let MonoCollector finish its work
    print("⌛ Waiting before destroy (sleep 250ms)...")
    sleep(250)  -- let it flush pipe state

    -- 5. Destroy main pipe
    local t0 = os.clock()
    print(string.format("🚨 Destroying monopipe，This may take several minutes👺👺👺... [Start: %.3fs]", t0))

    pcall(function()
      if monopipe then
        monopipe.destroy()
        monopipe = nil
      end
    end)

    local t1 = os.clock()
    print(string.format("👻 monopipe.destroy() completed [End: %.3fs | Duration: %.3fs]", t1, t1 - t0))


    -- 6. Destroy symbol list
    if monoSymbolList then
      monoSymbolList.destroy()
      monoSymbolList = nil
    end

    -- 7. Destroy event pipe if exists
    if monoeventpipe then
      monoeventpipe.destroy()
      monoeventpipe = nil
    end

    print("👻 SafeMonoDestroy: Cleanup complete.")
  end
end

-- 📏 Register symbol by parameter type array (exact match)
if _G.mono_registerSymbolEx == nil then
  _G.mono_registerSymbolEx = function(symbolname, namespace, classname, methodname, paramTypes)
    local cls = mono_findClass(namespace, classname)
    if not cls then
      print(string.format("💔 Error: Class not found - %s.%s", namespace, classname))
      return
    end

    local methods = mono_class_enumMethods(cls)
    for _, m in ipairs(methods) do
      if m.name == methodname then
        local p = mono_method_get_parameters(m.method)
        local matched = true

        if #p.parameters ~= #paramTypes then
          matched = false
        else
          for i = 1, #paramTypes do
            if not string.find(p.parameters[i].typename, paramTypes[i], 1, true) then
              matched = false
              break
            end
          end
        end

        if matched then
          local addr = mono_compile_method(m.method)
          if addr == 0 then
            print("💔 Error: Method found but failed to compile.")
            return
          end
          registerSymbol(symbolname, addr)
          print(string.format("🪧 Symbol registered: %s = %X", symbolname, addr))
          return
        end
      end
    end

    print(string.format("💔 Error: No matching method found - %s.%s.%s", namespace, classname, methodname))
  end
end

-- 📏 Register symbol by partial signature match (overload-safe)
if _G.mono_registerSymbolBySignatureMatch == nil then
  _G.mono_registerSymbolBySignatureMatch = function(symbolname, namespace, classname, methodname, sigContains)
    local cls = mono_findClass(namespace, classname)
    if not cls then
      print(string.format("💔 Error: Class not found - %s.%s", namespace, classname))
      return
    end

    local methods = mono_class_enumMethods(cls)
    if not methods then
      print(string.format("💔 Error: No methods found in %s.%s", namespace, classname))
      return
    end

    for _, m in ipairs(methods) do
      if m.name == methodname then
        local sig = mono_method_getSignature(m.method)
        local matched = true
        for _, kw in ipairs(sigContains) do
          if not string.find(sig, kw, 1, true) then
            matched = false
            break
          end
        end

        if matched then
          local addr = mono_compile_method(m.method)
          if addr == 0 then
            print("💔 Error: Signature matched but failed to compile method.")
            return
          end
          registerSymbol(symbolname, addr)
          print(string.format("🪧 Symbol registered by signature: %s = %X", symbolname, addr))
          return
        end
      end
    end

    print(string.format("💔 Error: No matching signature found - %s.%s.%s", namespace, classname, methodname))
  end
end

-- 📏 Register symbol by simple method name (first match)
if _G.mono_registerSymbol == nil then
  _G.mono_registerSymbol = function(symbolname, namespace, classname, methodname)
    local m = mono_findMethod(namespace, classname, methodname)
    if m == nil or m == 0 then
      print(string.format("💔 Error: Method not found - %s.%s.%s", namespace, classname, methodname))
      return
    end

    local addr = mono_compile_method(m)
    if addr == 0 then
      print(string.format("💔 Error: Could not compile method - %s.%s.%s", namespace, classname, methodname))
      return
    end

    registerSymbol(symbolname, addr)
    print(string.format("🪧 Symbol registered: %s = %X", symbolname, addr))
  end
end

-- 🌀 Attach Mono if needed
local pid = getOpenedProcessID()
if pid == 0 then
  print("⚠ Warning: No process is currently open.")
  return
end

if _G.lastMonoPID == nil then _G.lastMonoPID = -1 end

if monopipe == nil or _G.lastMonoPID ~= pid then
  if monopipe ~= nil then
    pcall(_G.SafeMonoDestroy)
  end
  pcall(LaunchMonoDataCollector)
  _G.lastMonoPID = pid
end

-- ⚡ Example usage - Register Mono methods to CE symbol table
-- These functions compile (JIT) a Mono method and register it as a CE symbol

-- 🔹 1. mono_registerSymbol(symbolname, namespace, classname, methodname)
-- Description: Registers the first matched method with given name.
-- ⚠ Use this only when there's no overload (or you're fine with the first one).
-- Params:
--   symbolname: The name you want to register (used in CE as a label)
--   namespace:  Mono namespace of the class (can be "" if none)
--   classname:  Class name that contains the method
--   methodname: Method name to find (first match will be used)
-- Example:

--_G.mono_registerSymbol("MyAttack", "Game.Logic", "BattleManager", "Attack")
--_G.mono_registerSymbol("UseAbility_Any", "Elin", "Chara", "UseAbility")


-- 🔹 2. mono_registerSymbolEx(symbolname, namespace, classname, methodname, paramTypes)
-- Description: Registers a method that exactly matches the provided parameter types.
-- Use this when there are multiple overloads of a method.
-- Params:
--   symbolname: The name to register
--   namespace:  Mono namespace
--   classname:  Class name
--   methodname: Method name (exact match)
--   paramTypes: Array of expected parameter type strings (must match count & order)
--               These are matched using `string.find`, so partial match is allowed.
-- Example:
--   UseAbility(string idAct, Card tc, Point pos, bool pt)

--[[
_G.mono_registerSymbolEx("UseAbility_Exact", "Elin", "Chara", "UseAbility", {
  "System.String", "Card", "Point", "System.Boolean"
})
--]]


-- 🔹 3. mono_registerSymbolBySignatureMatch(symbolname, namespace, classname, methodname, sigContains)
-- Description: Registers the method whose signature contains all given substrings.
-- Flexible, and suitable when exact type names vary or signature format is uncertain.
-- Params:
--   symbolname: The symbol name to register
--   namespace:  Mono namespace
--   classname:  Class name
--   methodname: Method name (will scan all overloads)
--   sigContains: Array of strings that should all appear in the method signature
--                e.g., { "Act", "Card", "Point", "bool" }
-- Example:
--   Will match method like: UseAbility(Act a, Card tc, Point pos, bool pt)

--[[
_G.mono_registerSymbolBySignatureMatch("UseAbility_Act", "Elin", "Chara", "UseAbility", {
  "Act", "Card", "Point", "bool"
})
--]]

--[[

Type Mapping (for overload filtering)
-------------------------------------
String      System.String        C#: string
int         System.Int32         C#: int
float       System.Single        C#: float
bool        System.Boolean       C#: bool
Vector3     UnityEngine.Vector3
Color       UnityEngine.Color
Point       (Game defined)
Card        (Game defined)
Act         (Game defined)

--]]
[DISABLE]
{$asm}
// unregistersymbol(*)
{$lua}
if syntaxcheck then return end

-- ☔ Release mono
----print("Info: Cleaning up MonoDataCollector...")
pcall(_G.SafeMonoDestroy)
----_G.SafeMonoDestroy()


]==]

-- Auto Assembler のメモリレコードを作成
function createMonoEnableMemoryRecord()
    local ct = getAddressList()  -- 現在の Cheat Table を取得
    local newRecord = ct.createMemoryRecord()

    newRecord.Description = 'Enable mono'
    newRecord.Type = vtAutoAssembler  -- Auto Assembler スクリプトとして設定
    newRecord.Script = monoEnableScript  -- スクリプトの内容を設定
    newRecord.Active = false  -- デフォルトでは無効状態
end

-- Compact View メニューを Dev Tools に追加
function addMonoEnableMenu()
    local devToolsMenu = getOrCreateDevToolsMenu()

    -- すでに追加されているか確認し、重複追加を防ぐ
    for i = 0, devToolsMenu.Count - 1 do
        if devToolsMenu[i].Caption == 'Create Mono activate AA Script' then
            return
        end
    end

    -- **メニューを追加（synchronize() を使用）**
    synchronize(function()
        local monoEnableItem = createMenuItem(devToolsMenu)
        monoEnableItem.Caption = 'Create Mono activate AA Script'
        monoEnableItem.OnClick = function()
            createMonoEnableMemoryRecord()
        end
        devToolsMenu.add(monoEnableItem)
    end)
end

-- 機能を実行
addMonoEnableMenu()
