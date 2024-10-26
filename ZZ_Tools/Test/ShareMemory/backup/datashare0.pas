unit datashare0;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, ValEdit, Math, Clipbrd;

type
  TAddressPair = record
    Address: Int64;
    Value: Integer;
  end;
  PAddressPair = ^TAddressPair; // 宣告指向 TAddressPair 的指標

  { TMainForm }

  TMainForm = class(TForm)
    btnRead: TButton;
    btnSetInterval: TButton;
    btnTimerToggle: TButton;
    btnWrite: TButton;
    btnCopy: TButton;
    cboDataType: TComboBox;
    lblTimerInt: TLabel;
    PageControl1: TPageControl;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    TabSheetGeneral: TTabSheet;
    TabSheetBlockData: TTabSheet;
    txtInput: TEdit;
    TimerRead: TTimer;
    txtOutput: TMemo;
    txtSysOutput: TMemo;
    txtTimerInt: TEdit;
    UpDownInterval: TUpDown;
    VLEditor1: TValueListEditor;
    procedure btnCopyClick(Sender: TObject);
    procedure btnReadClick(Sender: TObject);
    procedure btnSetIntervalClick(Sender: TObject);
    procedure btnTimerToggleClick(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerReadTimer(Sender: TObject);
  private
    SharedMemoryHandle: THandle;
    SharedMemoryStateHandle: THandle;
    SharedMemorySize: Integer;
    SharedMemoryName: string;
    SharedMemoryStateName: string;
    procedure OpenSharedMemory;
    procedure CloseSharedMemory;
    function IsMemoryIdle: Boolean;
    procedure WaitForIdleState;
    procedure SetMemoryState(State: Integer);
    procedure AppendOutputWithTimestamp(const Msg: string);
    procedure AppendSysOutputWithTimestamp(const Msg: string);
    procedure ClearSharedMemory;
    procedure SetOperationState(State: Integer);
    procedure SetDataType(DataType: Integer);
  public

  end;

var
  MainForm: TMainForm;

implementation

function CompareAddressPairs(Item1, Item2: Pointer): Integer;
begin
  Result := CompareValue(PAddressPair(Item1)^.Address, PAddressPair(Item2)^.Address);
end;

{$R *.lfm}
procedure TMainForm.OpenSharedMemory;
begin
  SharedMemorySize := 2048;
  SharedMemoryName := 'MySharedMemory';
  SharedMemoryStateName := 'MySharedMemoryState';

  // 打開現有的共享記憶體
  SharedMemoryHandle := OpenFileMapping(FILE_MAP_READ or FILE_MAP_WRITE, False, PChar(SharedMemoryName));
  SharedMemoryStateHandle := OpenFileMapping(FILE_MAP_READ or FILE_MAP_WRITE, False, PChar(SharedMemoryStateName));

  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Failed to open shared memory!');
    btnRead.Enabled := false;
    btnWrite.Enabled := false;
    btnTimerToggle.Enabled := false;
    UpDownInterval.Enabled := false;
    btnSetInterval.Enabled := false;
  end
  else
    AppendSysOutputWithTimestamp('Open shared memory successfully.');

  if SharedMemoryStateHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Failed to open shared memory state!');
    btnRead.Enabled := false;
    btnWrite.Enabled := false;
    btnTimerToggle.Enabled := false;
    UpDownInterval.Enabled := false;
    btnSetInterval.Enabled := false;
  end
  else
    AppendSysOutputWithTimestamp('Open shared memory state successfully.');
end;

procedure TMainForm.CloseSharedMemory;
begin
  if SharedMemoryHandle <> 0 then
    CloseHandle(SharedMemoryHandle);
  if SharedMemoryStateHandle <> 0 then
    CloseHandle(SharedMemoryStateHandle);
end;


function TMainForm.IsMemoryIdle: Boolean;
var
  StatePtr: PInteger;
begin
  Result := False;
  if SharedMemoryStateHandle <> 0 then
  begin
    StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_READ, 0, 0, SizeOf(Integer));
    if StatePtr <> nil then
    begin
      Result := (StatePtr^ = 0); // 0表示空閒
      UnmapViewOfFile(StatePtr);
    end;
  end;
end;

procedure TMainForm.WaitForIdleState;
var
  StatePtr: PInteger;
begin
  repeat
    StatePtr := PInteger(MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_READ, 0, 0, SizeOf(Integer)));
    if StatePtr <> nil then
    begin
      if StatePtr^ = 0 then
      begin
        UnmapViewOfFile(StatePtr);
        Break;
      end;
      UnmapViewOfFile(StatePtr);
    end;
    Sleep(10);  // 每10毫秒檢查一次
    Application.ProcessMessages;
  until False;
end;

procedure TMainForm.SetMemoryState(State: Integer);
var
  StatePtr: PInteger;
begin
  if SharedMemoryStateHandle <> 0 then
  begin
    StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_WRITE, 0, 0, SizeOf(Integer));
    if StatePtr <> nil then
    begin
      StatePtr^ := State;  // 將狀態設定為傳入的 State 值
      UnmapViewOfFile(StatePtr);
    end
    else
      AppendSysOutputWithTimestamp('***Failed to map shared memory state for writing!');
  end;
end;

procedure TMainForm.AppendOutputWithTimestamp(const Msg: string);
var
  Timestamp: string;
begin
  Timestamp := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now);  // 包含毫秒
  txtOutput.Lines.Add('[' + Timestamp + ']: ' + Msg);
end;

procedure TMainForm.AppendSysOutputWithTimestamp(const Msg: string);
var
  Timestamp: string;
begin
  Timestamp := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now);  // 包含毫秒
  txtSysOutput.Lines.Add('[' + Timestamp + ']: ' + Msg);
end;

procedure TMainForm.ClearSharedMemory;
var
  Ptr: Pointer;
begin
  if SharedMemoryHandle = 0 then Exit;

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for clearing!');
    Exit;
  end;

  // 清空共享記憶體
  FillChar(Ptr^, SharedMemorySize, 0);

  // 解鎖共享記憶體
  UnmapViewOfFile(Ptr);
end;


procedure TMainForm.SetOperationState(State: Integer);
var
  StatePtr: PInteger;
begin
  StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_WRITE, 0, 0, SizeOf(Integer));
  if StatePtr <> nil then
  begin
    StatePtr^ := State;  // 設置操作狀態
    UnmapViewOfFile(StatePtr);
  end
  else
    AppendSysOutputWithTimestamp('Failed to set operation state.');
end;

procedure TMainForm.SetDataType(DataType: Integer);
var
  BasePtr: Pointer;
  DataTypePtr: PInteger;
begin
  // 映射整個狀態記憶體，並從中偏移4個字節
  BasePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_WRITE, 0, 0, 8);  // 映射 8 個字節
  if BasePtr <> nil then
  begin
    DataTypePtr := PInteger(PByte(BasePtr) + 4);  // 偏移 4 字節
    DataTypePtr^ := DataType;  // 設置數據類型
    UnmapViewOfFile(BasePtr);  // 解鎖
    AppendSysOutputWithTimestamp('Data type set to ' + IntToStr(DataType));
  end
  else
    AppendSysOutputWithTimestamp('Failed to map shared memory state for setting data type.');
end;

procedure TMainForm.btnReadClick(Sender: TObject);
var
  Ptr: Pointer;
  StatePtr: Pointer;
  DataType: Integer;
  IntData: Integer;
  QwordData: Int64;
  FloatData: Single;
  DoubleData: Double;
  StrData: array[0..2047] of AnsiChar;
  Address: Int64;
  Value: Integer;
  Offset: Integer;
  AddressStr, OutputText: string;
  AddressList: TList;
  i: Integer;
  AddressPair: ^TAddressPair;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('Shared memory handle is not initialized.');
    Exit;
  end;

  WaitForIdleState;  // 等待共享記憶體空閒
  SetOperationState(-2);  // 將操作狀態設為讀取中 (-2)

  // 鎖定共享記憶體
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_READ, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('Unable to map shared memory for reading.');
    SetOperationState(0);  // 重設狀態為空閒
    Exit;
  end;

  // 從偏移量 4 讀取資料型態
  StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_READ or FILE_MAP_WRITE, 0, 0, 8);  // 映射完整 8 個位元組
  if StatePtr <> nil then
  begin
    DataType := PInteger(PByte(StatePtr) + 4)^;  // 從偏移量 4 開始讀取 `DataType`
    if DataType > 0 then
      AppendSysOutputWithTimestamp('Data type read successfully: ' + IntToStr(DataType));
  end
  else
  begin
    AppendSysOutputWithTimestamp('Unable to map shared memory state for reading.');
    SetOperationState(0);
    UnmapViewOfFile(Ptr);
    Exit;
  end;

  // 根據 DataType 讀取對應資料
  case DataType of
    1: begin  // 32-bit 整數
         Move(Ptr^, IntData, SizeOf(IntData));
         OutputText := '32-bit Integer: ' + IntToStr(IntData);
       end;
    2: begin  // 64-bit 整數
         Move(Ptr^, QwordData, SizeOf(QwordData));
         OutputText := '64-bit Integer: ' + IntToStr(QwordData);
       end;
    3: begin  // 單精度浮點數
         Move(Ptr^, FloatData, SizeOf(FloatData));
         OutputText := 'Single Precision Float: ' + FloatToStr(FloatData);
       end;
    4: begin  // 雙精度浮點數
         Move(Ptr^, DoubleData, SizeOf(DoubleData));
         OutputText := 'Double Precision Float: ' + FloatToStr(DoubleData);
       end;
    5: begin  // 字串
         FillChar(StrData, SizeOf(StrData), 0);
         Move(Ptr^, StrData, SizeOf(StrData) - 1);
         OutputText := 'String: ' + string(StrData);
       end;
    6: begin  // 新資料型態: 64-bit 位址 + 32-bit 整數值
         Offset := 0;
         AddressList := TList.Create;
         try
           VLEditor1.Strings.BeginUpdate;  // 暫停 UI 更新
           while Offset < SharedMemorySize do
           begin
             Address := PInt64(PByte(Ptr) + Offset)^;  // 讀取 64-bit 位址
             Value := PInteger(PByte(Ptr) + Offset + 8)^;  // 讀取 32-bit 整數值
             if Address = 0 then Break;  // 位址為 0 表示結束

             // 將地址轉為十六進位字串，並填補前導零至 16 位數
             AddressStr := IntToHex(Address, 16);
             AddressStr := '0x' + AddressStr;  // 添加 "0x" 前綴

             // 將新資料插入 VLEditor1
             if VLEditor1.Strings.IndexOfName(AddressStr) = -1 then
               VLEditor1.InsertRow(AddressStr, IntToStr(Value), True)  // 位址不存在時新增
             else
               VLEditor1.Values[AddressStr] := IntToStr(Value);  // 位址存在時更新資料

             Offset := Offset + 12;  // 移動到下一筆 12-byte 結構
           end;

           // 排序 VLEditor1 中的所有項目
           VLEditor1.Strings.Sort;
           OutputText := 'New data type (Address-Value pairs) displayed and sorted in VLEditor1.';
         finally
           VLEditor1.Strings.EndUpdate;  // 恢復 UI 更新
           for i := 0 to AddressList.Count - 1 do
             Dispose(PAddressPair(AddressList[i]));
           AddressList.Free;
         end;
       end;
  else
    asm
      nop
    end;
  end;

  // 清除共享記憶體並重設操作狀態
  ClearSharedMemory;
  PInteger(StatePtr)^ := 0;  // 重設操作狀態為空閒
  PInteger(PByte(StatePtr) + 4)^ := 0;  // 重設 DataType
  SetOperationState(0);
  UnmapViewOfFile(StatePtr);
  UnmapViewOfFile(Ptr);

  // 顯示結果於輸出視窗
  if Length(OutputText) > 0 then
    AppendOutputWithTimestamp(OutputText);
end;


procedure TMainForm.btnCopyClick(Sender: TObject);
var
  i: Integer;
  CSVData: TStringList;
  Row: string;
begin
  // 創建 TStringList 來存儲 CSV 資料
  CSVData := TStringList.Create;
  try
    // 添加標頭列
    CSVData.Add('Address,Value');

    // 遍歷 VLEditor1 中的每個項目，並以 CSV 格式添加到 CSVData
    for i := 1 to VLEditor1.RowCount - 1 do
    begin
      Row := VLEditor1.Keys[i] + ',' + VLEditor1.Values[VLEditor1.Keys[i]];
      CSVData.Add(Row);
    end;

    // 將 CSVData 的所有內容複製到剪貼簿
    Clipboard.AsText := CSVData.Text;

    // 輸出訊息
    AppendSysOutputWithTimestamp('VLEditor1 content copied to clipboard as CSV.');
  finally
    CSVData.Free;  // 釋放記憶體
  end;
end;


procedure TMainForm.btnSetIntervalClick(Sender: TObject);
begin
  TimerRead.Interval := UpDownInterval.Position;
  AppendSysOutputWithTimestamp('Timer interval set to ' + IntToStr(UpDownInterval.Position) + ' ms');
end;

procedure TMainForm.btnTimerToggleClick(Sender: TObject);
begin
  if btnTimerToggle.Tag = 0 then
  begin
    btnTimerToggle.Tag := 1;
    btnTimerToggle.Caption := 'Disable read timer';
    TimerRead.Enabled := true;
    AppendSysOutputWithTimestamp('Enable read timer');
  end
  else
  begin
    btnTimerToggle.Tag := 0;
    btnTimerToggle.Caption := 'Enable read timer';
    TimerRead.Enabled := false;
    AppendSysOutputWithTimestamp('Disable read timer');
  end;
end;

procedure TMainForm.btnWriteClick(Sender: TObject);
var
  Ptr: Pointer;
  DataType: Integer;
  IntData: Integer;
  QwordData: Int64;
  FloatData: Single;
  DoubleData: Double;
  StrData: AnsiString;
begin
  //btnWrite.Tag := btnWrite.Tag + 1;
  //AppendSysOutputWithTimestamp(IntToStr(btnWrite.Tag));
  if SharedMemoryHandle = 0 then Exit;

  waitForIdleState;  // 等待共享記憶體空閒
  setOperationState(-1);  // 將操作狀態設為寫入中 (-1)

  // 鎖定共享記憶體
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('Unable to map shared memory for writing.');
    setOperationState(0);  // 將狀態設為空閒
    Exit;
  end;

  // 根據 ComboBox 中選擇的資料類型寫入對應的數據
  DataType := cboDataType.ItemIndex + 1;  // 假設 cboDataType 的項目從 1 開始對應
  setDataType(DataType);  // 設定資料類型

  case DataType of
    1:  // 32-bit 整數
    begin
      IntData := StrToIntDef(txtInput.Text, 0);
      Move(IntData, Ptr^, SizeOf(IntData));
    end;
    2:  // 64-bit 整數
    begin
      QwordData := StrToInt64Def(txtInput.Text, 0);
      Move(QwordData, Ptr^, SizeOf(QwordData));
    end;
    3:  // 單精度浮點數
    begin
      FloatData := StrToFloatDef(txtInput.Text, 0.0);
      Move(FloatData, Ptr^, SizeOf(FloatData));
    end;
    4:  // 雙精度浮點數
    begin
      DoubleData := StrToFloatDef(txtInput.Text, 0.0);
      Move(DoubleData, Ptr^, SizeOf(DoubleData));
    end;
    5:  // 字串
    begin
      StrData := AnsiString(txtInput.Text);
      Move(PAnsiChar(StrData)^, Ptr^, Length(StrData) + 1);  // 包含字串結尾
    end;
  else
    AppendSysOutputWithTimestamp('Unsupported data type selected!');
  end;

  UnmapViewOfFile(Ptr);  // 解鎖共享記憶體
  setOperationState(0);  // 重設狀態為空閒

  AppendSysOutputWithTimestamp('Data written to shared memory.');
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  OpenSharedMemory;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
   CloseSharedMemory;
end;

procedure TMainForm.TimerReadTimer(Sender: TObject);
begin
  btnReadClick(Sender);  // 每次計時器觸發時執行 btnReadClick 來讀取資料
end;



end.






