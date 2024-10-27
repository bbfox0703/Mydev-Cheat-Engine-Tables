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
    btnClear: TButton;
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
    procedure btnClearClick(Sender: TObject);
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
    CurrentOffset: Integer;  // 用來追蹤目前的偏移量
    procedure OpenSharedMemory;
    procedure CloseSharedMemory;
    function IsMemoryIdle: Boolean;
    procedure WaitForIdleState;
    procedure SetMemoryState(State: Integer);
    procedure AppendOutputWithTimestamp(const Msg: string);
    procedure AppendSysOutputWithTimestamp(const Msg: string);
    procedure ClearSharedMemory;
    function GetOperationState: Integer;
    procedure SetOperationState(State: Integer);
    procedure SetDataType(DataType: Integer);
    procedure StartWriteIntBlock;
    procedure AppendIntBlockData(Address: Int64; Value: Integer);
    procedure EndWriteIntBlock;
    procedure StartWriteFloatBlock;
    procedure AppendFloatBlockData(Address: Int64; Value: Single);
    procedure EndWriteFloatBlock;
    procedure StartWriteQWordBlock;
    procedure AppendQWordBlockData(Address: Int64; Value: Int64);
    procedure EndWriteQWordBlock;
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
  SharedMemorySize := 65536;
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
    AppendSysOutputWithTimestamp('***Failed to set operation state.');
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
    AppendSysOutputWithTimestamp('***Failed to map shared memory state for setting data type.');
end;

// 開始寫入程序 (Type 6: Int Block)
procedure TMainForm.StartWriteIntBlock;
var
  Ptr: Pointer;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory handle is not initialized.');
    Exit;
  end;

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for clearing.');
    Exit;
  end;

  FillChar(Ptr^, SharedMemorySize, 0);  // 清空記憶體
  UnmapViewOfFile(Ptr);  // 解鎖共享記憶體

  CurrentOffset := 0;
  SetOperationState(-1);  // 設定狀態為寫入中 (-1)
  SetDataType(6);         // 設定資料型別為 6 (Int Block)
  AppendSysOutputWithTimestamp('Started write procedure for Type 6 (Int Block) data.');
end;

// 寫入資料程序 (Type 6: Int Block) - 每次寫入一對 Address:Int
procedure TMainForm.AppendIntBlockData(Address: Int64; Value: Integer);
var
  Ptr: Pointer;
begin
  if CurrentOffset >= SharedMemorySize - 12 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory is full.');
    Exit;
  end;

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for appending data.');
    Exit;
  end;

  // 正確地使用偏移位置進行寫入
  Move(Address, (PByte(Ptr) + CurrentOffset)^, SizeOf(Address));
  Move(Value, (PByte(Ptr) + CurrentOffset + 8)^, SizeOf(Value));
  CurrentOffset := CurrentOffset + 12;

  UnmapViewOfFile(Ptr);
  AppendSysOutputWithTimestamp(Format('Appended Int Block Address: 0x%012X, Value: %d', [Address, Value]));
end;


// 結束寫入程序 (Type 6: Int Block)
procedure TMainForm.EndWriteIntBlock;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory handle is not initialized.');
    Exit;
  end;

  SetOperationState(-3);  // 設定狀態為寫入完成 (-3)
  AppendSysOutputWithTimestamp('Finished write procedure for Type 6 (Int Block) data.');
end;

// 開始寫入程序 (Type 7: Float Block)
procedure TMainForm.StartWriteFloatBlock;
var
  Ptr: Pointer;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory handle is not initialized.');
    Exit;
  end;

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for clearing.');
    Exit;
  end;

  FillChar(Ptr^, SharedMemorySize, 0);  // 清空記憶體
  UnmapViewOfFile(Ptr);  // 解鎖共享記憶體

  CurrentOffset := 0;
  SetOperationState(-1);  // 設定狀態為寫入中 (-1)
  SetDataType(7);         // 設定資料型別為 7 (Float Block)
  AppendSysOutputWithTimestamp('Started write procedure for Type 7 (Float Block) data.');
end;

// 寫入資料程序 (Type 7: Float Block) - 每次寫入一對 Address:Float
procedure TMainForm.AppendFloatBlockData(Address: Int64; Value: Single);
var
  Ptr: Pointer;
begin
  if CurrentOffset >= SharedMemorySize - 12 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory is full.');
    Exit;
  end;

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for appending data.');
    Exit;
  end;

  Move(Address, (PByte(Ptr) + CurrentOffset)^, SizeOf(Address));
  Move(Value, (PByte(Ptr) + CurrentOffset + 8)^, SizeOf(Value));
  CurrentOffset := CurrentOffset + 12;

  UnmapViewOfFile(Ptr);
  AppendSysOutputWithTimestamp(Format('Appended Float Block Address: 0x%012X, Value: %f', [Address, Value]));
end;

// 結束寫入程序 (Type 7: Float Block)
procedure TMainForm.EndWriteFloatBlock;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory handle is not initialized.');
    Exit;
  end;

  SetOperationState(-3);  // 設定狀態為寫入完成 (-3)
  AppendSysOutputWithTimestamp('Finished write procedure for Type 7 (Float Block) data.');
end;

// 開始寫入程序 (Type 8: QWord Block)
procedure TMainForm.StartWriteQWordBlock;
var
  Ptr: Pointer;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory handle is not initialized.');
    Exit;
  end;

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for clearing.');
    Exit;
  end;

  FillChar(Ptr^, SharedMemorySize, 0);  // 清空記憶體
  UnmapViewOfFile(Ptr);  // 解鎖共享記憶體

  CurrentOffset := 0;
  SetOperationState(-1);  // 設定狀態為寫入中 (-1)
  SetDataType(8);         // 設定資料型別為 8 (QWord Block)
  AppendSysOutputWithTimestamp('Started write procedure for Type 8 (QWord Block) data.');
end;

// 寫入資料程序 (Type 8: QWord Block) - 每次寫入一對 Address:QWord
procedure TMainForm.AppendQWordBlockData(Address: Int64; Value: Int64);
var
  Ptr: Pointer;
begin
  if CurrentOffset >= SharedMemorySize - 16 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory is full.');
    Exit;
  end;

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for appending data.');
    Exit;
  end;

  Move(Address, (PByte(Ptr) + CurrentOffset)^, SizeOf(Address));
  Move(Value, (PByte(Ptr) + CurrentOffset + 8)^, SizeOf(Value));
  CurrentOffset := CurrentOffset + 16;

  UnmapViewOfFile(Ptr);
  AppendSysOutputWithTimestamp(Format('Appended QWord Block Address: 0x%012X, Value: %d', [Address, Value]));
end;

// 結束寫入程序 (Type 8: QWord Block)
procedure TMainForm.EndWriteQWordBlock;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory handle is not initialized.');
    Exit;
  end;

  SetOperationState(-3);  // 設定狀態為寫入完成 (-3)
  AppendSysOutputWithTimestamp('Finished write procedure for Type 8 (QWord Block) data.');
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
  ValueInt: Integer;
  ValueFloat: Single;
  ValueQword: Int64;
  Offset: Integer;
  AddressStr, OutputText: string;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('***Shared memory handle is not initialized.');
    Exit;
  end;

  // 檢查狀態是否為 -3 (寫入完成)
  if getOperationState <> -3 then
  begin
    Exit;
  end;

  SetOperationState(-2);  // 將操作狀態設為讀取中 (-2)

  // 鎖定共享記憶體
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_READ, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory for reading.');
    SetOperationState(0);  // 重設狀態為空閒
    Exit;
  end;

  // 從偏移量 4 讀取資料型態
  StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_READ or FILE_MAP_WRITE, 0, 0, 8);
  if StatePtr <> nil then
  begin
    DataType := PInteger(PByte(StatePtr) + 4)^;
    AppendSysOutputWithTimestamp('Data type read successfully: ' + IntToStr(DataType));
  end
  else
  begin
    AppendSysOutputWithTimestamp('***Unable to map shared memory state for reading.');
    SetOperationState(0);
    UnmapViewOfFile(Ptr);
    Exit;
  end;

  IntData := -999998;
  QwordData := -999998;
  FloatData := -999998;
  DoubleData := -999998;
  StrData := '';

  VLEditor1.Strings.BeginUpdate;
  try
    Offset := 0;
    OutputText := '';
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
      6: begin  // 64-bit 位址 + 32-bit 整數值
           while Offset < SharedMemorySize do
           begin
             Address := PInt64(PByte(Ptr) + Offset)^;
             ValueInt := PInteger(PByte(Ptr) + Offset + 8)^;
             if Address = 0 then Break;

             AddressStr := '0x' + IntToHex(Address, 12);
             if VLEditor1.Strings.IndexOfName(AddressStr) = -1 then
               VLEditor1.InsertRow(AddressStr, IntToStr(ValueInt), True)
             else
               VLEditor1.Values[AddressStr] := IntToStr(ValueInt);
             Offset := Offset + 12;
           end;
           AppendSysOutputWithTimestamp('Address-Int pairs displayed in block data tab.');

         end;
      7: begin  // 64-bit 位址 + 單精度浮點數
           while Offset < SharedMemorySize do
           begin
             Address := PInt64(PByte(Ptr) + Offset)^;
             ValueFloat := PSingle(PByte(Ptr) + Offset + 8)^;
             if Address = 0 then Break;

             AddressStr := '0x' + IntToHex(Address, 12);
             if VLEditor1.Strings.IndexOfName(AddressStr) = -1 then
               VLEditor1.InsertRow(AddressStr, FloatToStr(ValueFloat), True)
             else
               VLEditor1.Values[AddressStr] := FloatToStr(ValueFloat);
             Offset := Offset + 12;
           end;
           AppendSysOutputWithTimestamp('Address-Int pairs displayed in block data tab.');
         end;
      8: begin  // 64-bit 位址 + 64-bit 整數值
           while Offset < SharedMemorySize do
           begin
             Address := PInt64(PByte(Ptr) + Offset)^;
             ValueQword := PInt64(PByte(Ptr) + Offset + 8)^;
             if Address = 0 then Break;

             AddressStr := '0x' + IntToHex(Address, 12);
             if VLEditor1.Strings.IndexOfName(AddressStr) = -1 then
               VLEditor1.InsertRow(AddressStr, IntToStr(ValueQword), True)
             else
               VLEditor1.Values[AddressStr] := IntToStr(ValueQword);
             Offset := Offset + 16;
           end;
           AppendSysOutputWithTimestamp('Address-Int pairs displayed in block data tab.');
         end;
    else
      //AppendSysOutputWithTimestamp('Unsupported data type or empty shared memory.');
      asm
        nop
      end;
    end;

    // 使用 VLEditor1 內建排序功能
    VLEditor1.Strings.Sort;

  finally
    VLEditor1.Strings.EndUpdate;
  end;

  // 清除共享記憶體並重設操作狀態
  ClearSharedMemory;
  PInteger(StatePtr)^ := 0;
  PInteger(PByte(StatePtr) + 4)^ := 0;
  SetOperationState(0);
  UnmapViewOfFile(StatePtr);
  UnmapViewOfFile(Ptr);

  // 顯示結果於輸出視窗
  if Length(OutputText) > 0 then
    AppendOutputWithTimestamp(OutputText);
end;


// 獲取目前操作狀態
function TMainForm.GetOperationState: Integer;
var
  StatePtr: PInteger;
begin
  StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_READ, 0, 0, SizeOf(Integer));
  if StatePtr <> nil then
  begin
    Result := StatePtr^;
    UnmapViewOfFile(StatePtr);
  end
  else
  begin
    AppendSysOutputWithTimestamp('Failed to retrieve operation state.');
    Result := 0;
  end;
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

procedure TMainForm.btnClearClick(Sender: TObject);
begin
  VLEditor1.Strings.Clear;
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
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('Shared memory handle is not initialized.');
    Exit;
  end;

  // 確保共享記憶體空閒
  if getOperationState <> 0 then
  begin
    AppendSysOutputWithTimestamp('Shared memory is busy. Write operation aborted.');
    Exit;
  end;

  SetOperationState(-1);  // 設定為寫入中 (-1)

  // 鎖定共享記憶體
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('Unable to map shared memory for writing.');
    SetOperationState(0);  // 設定為空閒
    Exit;
  end;

  // 根據 ComboBox 中選擇的資料類型寫入對應的數據
  DataType := cboDataType.ItemIndex + 1;  // 假設 cboDataType 的項目從 1 開始對應
  SetDataType(DataType);  // 設定資料類型

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

  SetOperationState(-3);  // 設定為寫入完成 (-3)
  AppendSysOutputWithTimestamp('Data written to shared memory and state set to -3 (write complete).');
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


