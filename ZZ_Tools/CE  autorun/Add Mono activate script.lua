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
  //-------------------------------------------------------------------
  // 【參考備忘】AA 端 registersymbol 的寫法
  // 目前整段被 { } 包住 = AA 註解,不會執行。
  // 日後真的要在 AA 端定義符號時,把它搬出來用。
  //
  // 注意:define 只是純文字取代,define(X, "A.B") 之後 X 會被展開成
  // 帶引號的 "A.B",registersymbol(X) 拿到的並不是位址。
  // 要把 mono 方法變成 CE 符號,請用下面 {$lua} 的 registerSymbol()。
  //-------------------------------------------------------------------
  // define(ResourceManagerClearItemCountsProc, "ResourceManager.ClearItemCounts")
  // registersymbol(ResourceManagerClearItemCountsProc)

{$lua}
if syntaxcheck then return end

--=====================================================================
-- 🌀 Mono attach
--
-- ⚠ 這裡刻意「不」呼叫 monopipe.destroy() / monopipe.unlock()。
--    原本的 SafeMonoDestroy 會觸發兩個 CE error:
--
--    1) CriticalSection leave without enter
--       monopipe 內部用 critical section 保護 pipe I/O,lock/unlock 必須成對。
--       CE 內建的 mono_* 函式自己已經 lock→做事→unlock 平衡完畢,
--       計數本來就是 0。額外呼叫一次 unlock() 會讓計數變負。
--
--    2) Do not call libmono.terminate from external threads
--       libmono 的 terminate/destroy 路徑有 thread guard,只允許 CE 主執行緒。
--       AA 的 {$lua} 區塊不保證跑在主執行緒(table 自動啟用、timer 觸發時尤其如此),
--       而且這個錯誤是 CE 自己彈的 dialog,pcall 攔不到。
--
--    舊 process 結束後 pipe 本來就失效,丟棄參考讓 CE / GC 處理即可,
--    不需要(也不應該)手動 teardown。
--=====================================================================
local pid = getOpenedProcessID()
if pid == 0 then
  print("Warning: No process is currently open.")
  return
end

if _G.lastMonoPID == nil then _G.lastMonoPID = -1 end

if _G.lastMonoPID ~= pid then
  -- 換 process:只丟棄參考,不 destroy
  --monopipe       = nil
  --monoSymbolList = nil
  --monoeventpipe  = nil
  _G.lastMonoPID = pid
end

--if monopipe == nil then
LaunchMonoDataCollector()
--end

if monopipe == nil then
  print("LaunchMonoDataCollector failed(Target may not be Mono / IL2CPP process)")
  return
end


--=====================================================================
-- 🔧 共用比對核心
--    三個對外 API 都走這裡,避免重複的 enumMethods / compile / register 邏輯。
--
--    opts:
--      opts.params   = { "System.String", "Card", ... }
--                      參數型別陣列。數量與順序需相符,型別用子字串比對。
--      opts.contains = { "Act", "Point" }   signature 必須全部包含
--      opts.excludes = { "List" }           signature 不可包含任一
--      (三者皆不給 = 取第一個同名方法)
--
--    回傳:method handle, signature 字串
--=====================================================================
if _G.mono_matchMethod == nil then
  _G.mono_matchMethod = function(namespace, classname, methodname, opts)
    opts = opts or {}

    local cls = mono_findClass(namespace, classname)
    if not cls then
      print(string.format("Error: Class not found - %s.%s", namespace, classname))
      return nil
    end

    local methods = mono_class_enumMethods(cls)
    if not methods then
      print(string.format("Error: No methods found in %s.%s", namespace, classname))
      return nil
    end

    for _, m in ipairs(methods) do
      if m.name == methodname then
        local matched = true
        local sig = nil

        -- (a) 參數型別陣列比對
        if matched and opts.params then
          local okP, p = pcall(mono_method_get_parameters, m.method)
          if not okP or not p or not p.parameters or #p.parameters ~= #opts.params then
            matched = false
          else
            for i = 1, #opts.params do
              if not string.find(p.parameters[i].typename, opts.params[i], 1, true) then
                matched = false
                break
              end
            end
          end
        end

        -- (b) signature 關鍵字包含 / 排除
        if matched and (opts.contains or opts.excludes) then
          local okS, s = pcall(mono_method_getSignature, m.method)
          sig = (okS and type(s) == "string") and s or ""

          for _, kw in ipairs(opts.contains or {}) do
            if not string.find(sig, kw, 1, true) then
              matched = false
              break
            end
          end

          if matched then
            for _, ex in ipairs(opts.excludes or {}) do
              if string.find(sig, ex, 1, true) then
                matched = false
                break
              end
            end
          end
        end

        if matched then
          return m.method, sig
        end
      end
    end

    print(string.format("Error: No matching method - %s.%s.%s", namespace, classname, methodname))
    return nil
  end
end


-- 共用的 compile + register
if _G.mono_compileAndRegister == nil then
  _G.mono_compileAndRegister = function(symbolname, method, sig)
    local addr = mono_compile_method(method)
    if not addr or addr == 0 then
      print(string.format("Error: Method found but failed to compile - %s", symbolname))
      return false
    end

    registerSymbol(symbolname, addr)
    print(string.format("Symbol registered: %s = %X", symbolname, addr))
    if sig and sig ~= "" then
      print(string.format("Matched Signature: %s", sig))
    end
    return true, addr
  end
end


--=====================================================================
-- 📏 對外 API(名稱與參數維持不變,舊 script 可直接沿用)
--=====================================================================

-- 🔹 1. 用方法名註冊(取第一個同名方法)
if _G.mono_registerSymbol == nil then
  _G.mono_registerSymbol = function(symbolname, namespace, classname, methodname)
    local m = _G.mono_matchMethod(namespace, classname, methodname)
    if not m then return false end
    return _G.mono_compileAndRegister(symbolname, m)
  end
end

-- 🔹 2. 用參數型別陣列註冊(overload 精確比對)
if _G.mono_registerSymbolEx == nil then
  _G.mono_registerSymbolEx = function(symbolname, namespace, classname, methodname, paramTypes)
    local m = _G.mono_matchMethod(namespace, classname, methodname, { params = paramTypes })
    if not m then return false end
    return _G.mono_compileAndRegister(symbolname, m)
  end
end

-- 🔹 3. 用 signature 關鍵字註冊(包含 / 排除)
if _G.mono_registerSymbolBySignatureMatch == nil then
  _G.mono_registerSymbolBySignatureMatch = function(symbolname, namespace, classname, methodname, sigContains, sigExcludes)
    local m, sig = _G.mono_matchMethod(namespace, classname, methodname, {
      contains = sigContains,
      excludes = sigExcludes,
    })
    if not m then return false end
    return _G.mono_compileAndRegister(symbolname, m, sig)
  end
end


--=====================================================================
-- ⚡ 使用範例 —— 把 Mono 方法註冊成 CE 符號
--    這些函式會 JIT 編譯 Mono 方法,取得實體位址後註冊為 CE label,
--    之後 {$asm} 區塊就能直接用該名稱做 code injection。
--=====================================================================

--[[---------------------------------------------------------------------
🔹 1. mono_registerSymbol(symbolname, namespace, classname, methodname)

   取第一個同名方法。
   ⚠ 只在「確定沒有 overload」或「第一個就是你要的」時使用。

   symbolname : 要註冊的 CE 符號名(之後在 AA 當 label 用)
   namespace  : Mono namespace(沒有的話填 "")
   classname  : 類別名稱
   methodname : 方法名稱(第一個 match 即採用)
-----------------------------------------------------------------------]]

--_G.mono_registerSymbol("MyAttack",       "Game.Logic", "BattleManager", "Attack")
--_G.mono_registerSymbol("UseAbility_Any", "Elin",       "Chara",         "UseAbility")


--[[---------------------------------------------------------------------
🔹 2. mono_registerSymbolEx(symbolname, namespace, classname, methodname, paramTypes)

   用「參數型別陣列」比對,適合有多個 overload 的情況。

   paramTypes : 預期的參數型別字串陣列,數量與順序都必須相符。
                內部用 string.find(plain) 比對,所以允許部分字串。

   目標方法:UseAbility(string idAct, Card tc, Point pos, bool pt)
-----------------------------------------------------------------------]]

--[[
_G.mono_registerSymbolEx("UseAbility_Exact", "Elin", "Chara", "UseAbility", {
  "System.String", "Card", "Point", "System.Boolean"
})
--]]


--[[---------------------------------------------------------------------
🔹 3. mono_registerSymbolBySignatureMatch(symbolname, namespace, classname,
                                          methodname, sigContains, sigExcludes)

   用 signature 關鍵字比對。當型別名稱寫法不確定、或 signature 格式有出入時最好用。

   sigContains : signature 必須「全部包含」的字串陣列
   sigExcludes : signature 「不可包含」的字串陣列(可省略)

   目標方法:UseAbility(Act a, Card tc, Point pos, bool pt)
-----------------------------------------------------------------------]]

--[[
_G.mono_registerSymbolBySignatureMatch("UseAbility_Act", "Elin", "Chara", "UseAbility", {
  "Act", "Card", "Point", "bool"
})

-- 排除的實際用途:兩個 overload 的 signature 分別是
--     System.Collections.Generic.List<Item>
--     Item
-- 兩者都含 "Item",但第一個多了 "List",所以用 excludes 排掉。
_G.mono_registerSymbolBySignatureMatch("GetItemCount_Item", "Assembly-CSharp", "ItemStorage", "GetItemCount",
  { "Item" },   -- sigContains
  { "List" }    -- sigExcludes
)
--]]


--[[---------------------------------------------------------------------
型別對照(overload 過濾用)
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
-----------------------------------------------------------------------]]


--=====================================================================
-- 👇 實際註冊寫在這裡
--=====================================================================
--_G.mono_registerSymbol("ResourceManagerClearItemCounts", "", "ResourceManager", "ClearItemCounts")


{$asm}
//---------------------------------------------------------------------
// Code injection 寫在這裡。
// 上面 Lua 註冊的符號可直接當 label 使用,例如:
//
//   alloc(newmem,$400,ResourceManagerClearItemCounts)
//   label(code)
//   label(return)
//
//   newmem:
//     jmp return
//
//   code:
//     // ← CE 模板產生的 original code
//     jmp return
//
//   ResourceManagerClearItemCounts:
//     jmp newmem
//   return:
//---------------------------------------------------------------------


[DISABLE]
{$asm}
//---------------------------------------------------------------------
// 還原 code injection
//
//   ResourceManagerClearItemCounts:
//     db XX XX XX XX XX     // ← original bytes
//
//   dealloc(newmem)
//---------------------------------------------------------------------

{$lua}
if syntaxcheck then return end

-- 只反註冊自己註冊過的符號,不要用 unregistersymbol(*),
-- 那會把同一張表其他 script 的符號一起清掉。
--pcall(unregisterSymbol, "ResourceManagerClearItemCounts")

-- ⚠ 不要在這裡呼叫 SafeMonoDestroy / monopipe.destroy(),原因見 [ENABLE] 開頭說明。

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
