-- Copyright TheyCallMeTim13 (c) 2022
-- Revised by bbfox <at> https://opencheattables.com 2025
--
--


-- デバッグモードの設定（true = デバッグメッセージ表示, false = 非表示）
local debugMode = false

-- Dev Tools メニューの設定
local DevToolsMenuItemName = 'miDevTools'
local DevToolsMenuItemCaption = '&Dev Tools'
local miDevTools

local CheatNameChildBlackList = {
	-- ['Example cheat name (Description)'] = true, 
}

-- 文字列を指定した区切り文字で分割する関数
local function split(str, delimiter)
	if type(str) ~= 'string' or not str:match(delimiter) then return end
	local patt = '(.-)'
	if delimiter == '.' then
		patt = patt..'%'..delimiter
	else
		patt = patt..delimiter
	end
	result = {}
	for match in (str .. delimiter):gmatch(patt) do
		table.insert(result, match)
	end
	return result
end

-- すべてのメモリレコードを無効化する
local function disableAllMemoryRecords()
	local msg = translate('Disable all memory records?')
	local mr = messageDialog(msg, mtConfirmation, mbYes, mbNo, mbCancel)
	if mr == mrYes then
		synchronize(function()
			for i = 0, AddressList.Count - 1 do
				local memoryRecord = AddressList[i]
				if memoryRecord and memoryRecord.Active then
					memoryRecord.Active = false
				end
			end
		end)
	end
end

-- DISABLE セクションを実行せずにすべてのメモリレコードを無効化
local function disableAllMemoryRecordsWithoutExecute()
	local msg = translate('Disable all memory records without executing the disable section?')
	local mr = messageDialog(msg, mtConfirmation, mbYes, mbNo, mbCancel)
	if mr == mrYes then
		synchronize(function()
			AddressList.disableAllWithoutExecute()
		end)
	end
end

-- 無名の構造体を削除する
local function removeAllUnnamedStructures()
	local msg = translate('Remove all unnamed structures from the table?')
	--local mr = messageDialog(msg, mtConfirmation, mbYes, mbNo, mbCancel)
	local mr = mrYes
	if mr == mrYes then
		synchronize(function()
			for i = getStructureCount() - 1, 0, -1 do
				local struct = getStructure(i)
				if struct.Name == 'unnamed structure' then
					struct.removeFromGlobalStructureList()
				end
			end
		end)
		return true
	elseif mr == mrNo then
		return true
	end
	return false
end

-- すべての構造体を削除する
local function removeAllStructures()
	local msg = translate('Remove all structures from the table?')
	--local mr = messageDialog(msg, mtConfirmation, mbYes, mbNo, mbCancel)
	local mr = mrYes
	if mr == mrYes then
		synchronize(function()
			for i = getStructureCount() - 1, 0, -1 do
				local struct = getStructure(i)
				struct.removeFromGlobalStructureList()
			end
		end)
		return true
	elseif mr == mrNo then
		return true
	end
	return false
end

-- チートリストを生成する
local function generateCheatsList()
	local function getCheatName(desc)
		return desc
	end
	local nl = '\n'
	local indStr = '    '

	-- synchronize() 内で AddressList のデータを安全に取得
	local str = ''
	synchronize(function()
		local function getCheatsFromMR(mr, ind)
			local padd = string.rep(indStr, ind)
			local opt = ''
			if mr.DropDownList and mr.DropDownList.Count > 0 then
				opt = ' : '
				for j = 0, mr.DropDownList.Count - 1 do
					local data = split(mr.DropDownList[j], ':')
					if data[2] then
						opt = opt..data[2]..', '
					end
				end
				opt = opt:sub(1, -3)
			end
			local cheatName = getCheatName(mr.Description)
			local str = padd..'□'..cheatName..opt..nl
			if mr and mr.Count > 0 and not CheatNameChildBlackList[cheatName] then
				for i = 0, mr.Count - 1 do
					if mr[i] then
						str = str..getCheatsFromMR(mr[i], ind + 1)
					end
				end
			end
			return str
		end

		for i = 0, AddressList.Count - 1 do
			if AddressList[i] and not AddressList[i].Parent then
				str = str..getCheatsFromMR(AddressList[i], 1)
			end
		end
	end)

	-- synchronize() 外で print を実行（スレッド安全）
	print(str)
end

-- Dev Tools メニューを取得、存在しない場合は作成
local function getMainFormMenuItem()
	if MainForm.Menu == nil then return nil end
	local menuItems = MainForm.Menu.Items
	local mi = nil
	
	-- **既存の Dev Tools メニューがあるか確認**
	for i = 0, menuItems.Count - 1 do
		if menuItems[i].Name == DevToolsMenuItemName or menuItems[i].Caption == DevToolsMenuItemCaption then
			synchronize(function()
				menuItems[i].visible = true
			end)
			return menuItems[i]  -- **既存のメニューを返す**
		end
	end

	-- **Dev Tools メニューが見つからない場合、新規作成**
	synchronize(function()
		mi = createMenuItem(MainForm)
		mi.Name = DevToolsMenuItemName
		mi.Caption = DevToolsMenuItemCaption
		MainForm.Menu.Items.add(mi)
	end)

	return mi
end

-- Dev Tools メニューに新しい項目を追加する関数
local function addMenuItem(caption, onClick)
	if not miDevTools then return nil end
	synchronize(function()
		local newItem = createMenuItem(miDevTools)
		newItem.Caption = caption
		newItem.OnClick = onClick
		miDevTools.add(newItem)
	end)
end

-- Dev Tools メニューのロード
local function loadMenuDevTools()
	miDevTools = getMainFormMenuItem()
	if miDevTools == nil then return end

	-- **既存の項目がある場合、区切り線を追加**
	if miDevTools.Count > 0 then
		addMenuItem('-')
	end

	-- **各機能をメニューに追加**
	addMenuItem(translate('Generate Cheats List'), generateCheatsList)
	addMenuItem('-')

	addMenuItem(translate('Remove All Unnamed Structures'), removeAllUnnamedStructures)
	addMenuItem(translate('Remove All Structures'), removeAllStructures)
	addMenuItem('-')

	addMenuItem(translate('Disable All Memory Records'), disableAllMemoryRecords)
	addMenuItem(translate('Disable All Memory Records Without Executing'), disableAllMemoryRecordsWithoutExecute)
end

-- Dev Tools メニューをロード
loadMenuDevTools()
