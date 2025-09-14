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
{
define(ResourceManagerClearItemCountsProc, "ResourceManager.ClearItemCounts")

registersymbol(ResourceManagerClearItemCountsProc)
}

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
    print(string.format("🚨 Destroying monopipe，This may take several minutes (or longer)👺👺👺... [Start: %.3fs]", t0))

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

-- 列出指定 class 中、同名方法的所有 overload，回傳詳盡資訊（不註冊符號）
if _G.mono_listMethodsByName == nil then
  _G.mono_listMethodsByName = function(namespace, classname, methodname)
    local cls = mono_findClass(namespace, classname)
    if not cls then
      print(string.format("💔 Class not found: %s.%s", namespace, classname))
      return {}
    end

    local mtds = mono_class_enumMethods(cls)
    if not mtds then
      print(string.format("💔 No methods in: %s.%s", namespace, classname))
      return {}
    end

    local out = {}
    local cnt = 0
    for _, v in ipairs(mtds) do
      if v.name == methodname then
        local entry = { name = v.name, method = v.method }

        -- 參數/回傳型別（用 CE 提供的 parameters API，比較穩）
        local okP, p = pcall(mono_method_get_parameters, v.method)
        if okP and p and p.parameters then
          entry.params = p.parameters         -- array of {typename=..., name=...}
          entry.paramnames = {}
          for i, pi in ipairs(p.parameters) do
            entry.paramnames[i] = pi.name
          end
          entry.returntype = p.returntype and p.returntype.name or nil
        else
          -- 後備：某些版本 mono_method_getSignature 可能回傳字串或多返回值
          local okS, a, b, c = pcall(mono_method_getSignature, v.method)
          if okS then
            -- 嘗試相容 ijm_mtd_by_sig 的 (params, paramnames, returntype)
            entry.params      = a
            entry.paramnames  = b
            entry.returntype  = c
            entry.signature   = type(a) == "string" and a or nil
          end
        end

        -- 編譯 JIT 取得地址
        local addr = mono_compile_method(v.method)
        entry.address = addr

        cnt = cnt + 1
        out[cnt] = entry
      end
    end

    print(string.format("🔎 Found %d overload(s) for %s.%s.%s", cnt, namespace, classname, methodname))
    return out
  end
end

-- 產生欄位 offset 對照表（若 CE 版本支援欄位列舉/offset 取得）
if _G.mono_offsetsTable == nil then
  _G.mono_offsetsTable = function(cacheTable, classname, namespace, opts)
    -- 行為與 ijm_offset_table 類似：若已有表且非空就直接回傳
    if cacheTable and type(cacheTable) == "table" then
      local hasAny = next(cacheTable) ~= nil
      if hasAny then return cacheTable end
    end

    local t = {}
    local cls = mono_findClass(namespace or "", classname)
    if not cls then
      print(string.format("💔 Class not found: %s.%s", namespace or "", classname))
      return t
    end

    -- 嘗試列舉欄位
    local fields = nil
    if mono_class_enumFields then
      local okF, res = pcall(mono_class_enumFields, cls)
      if okF then fields = res end
    end

    if not fields or #fields == 0 then
      print("⚠ 無法列舉欄位（當前 CE/Mono 外掛可能不支援 mono_class_enumFields）。")
      return t
    end

    for _, f in ipairs(fields) do
      local fname = f.name or ("<noname_"..tostring(_)..">")
      local off = nil
      if mono_field_get_offset then
        local okO, o = pcall(mono_field_get_offset, f.field)
        if okO then off = o end
      end
      t[fname] = off
    end

    -- 若需要標註是 Mono 單例/IL2CPP Enum 等，可透過 opts 設定，這裡僅示意保留
    if opts and opts.meta then t.__meta = opts.meta end

    return t
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

-- 📏 Register symbol by partial signature match (overload-safe, with excludes and match info)
if _G.mono_registerSymbolBySignatureMatch == nil then
  _G.mono_registerSymbolBySignatureMatch = function(symbolname, namespace, classname, methodname, sigContains, sigExcludes)
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

        -- Check required substrings
        for _, kw in ipairs(sigContains) do
          if not string.find(sig, kw, 1, true) then
            matched = false
            break
          end
        end

        -- Check excluded substrings (if given)
        if matched and sigExcludes then
          for _, ex in ipairs(sigExcludes) do
            if string.find(sig, ex, 1, true) then
              matched = false
              break
            end
          end
        end

        if matched then
          local addr = mono_compile_method(m.method)
          if addr == 0 then
            print("💔 Error: Signature matched but failed to compile method.")
            return
          end
          registerSymbol(symbolname, addr)
          print(string.format("🪧 Symbol registered: %s = %X", symbolname, addr))
          print(string.format("🔎 Matched Signature: %s", sig))
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


-- 🔹 3. mono_registerSymbolBySignatureMatch(symbolname, namespace, classname, methodname, sigContains, sigExcludes)
-- Description: Registers the method whose signature contains all given substrings.
-- Flexible, and suitable when exact type names vary or signature format is uncertain.
-- Params:
--   symbolname: The symbol name to register
--   namespace:  Mono namespace
--   classname:  Class name
--   methodname: Method name (will scan all overloads)
--   sigContains: Array of strings that should all appear in the method signature
--                e.g., { "Act", "Card", "Point", "bool" }
--   sigExcludes: Signatures to exclude
-- Example:
--   Will match method like: UseAbility(Act a, Card tc, Point pos, bool pt)

--[[
_G.mono_registerSymbolBySignatureMatch("UseAbility_Act", "Elin", "Chara", "UseAbility", {
  "Act", "Card", "Point", "bool"
})

_G.mono_registerSymbolBySignatureMatch("GetItemCount_Item", "Assembly-CSharp", "ItemStorage", "GetItemCount",
  {"Item"},      -- sigContains
  {"List"}       -- sigExcludes
)

Signatures above:
System.Collections.Generic.List<Item> 
Item 

** Both have "Item" but first one have "List"
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
{$lua}
if syntaxcheck then return end
--pcall(_G.SafeMonoDestroy)
{$asm}
//unregistersymbol(*)

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
