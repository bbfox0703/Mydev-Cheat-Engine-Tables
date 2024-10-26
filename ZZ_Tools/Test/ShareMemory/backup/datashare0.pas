unit datashare0;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, ValEdit;

type

  { TMainForm }

  TMainForm = class(TForm)
    btnRead: TButton;
    btnSetInterval: TButton;
    btnTimerToggle: TButton;
    btnWrite: TButton;
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
    VLEditor: TValueListEditor;
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

procedure TMainForm.waitForIdleState;
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
  OutputText: string;
begin
  if SharedMemoryHandle = 0 then
  begin
    AppendSysOutputWithTimestamp('Shared memory handle is not initialized.');
    Exit;
  end;

  waitForIdleState;  // 等待共享記憶體空閒
  setOperationState(-2);  // 將操作狀態設為讀取中 (-2)

  // 鎖定共享記憶體
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_READ, 0, 0, SharedMemorySize);
  if Ptr = nil then
  begin
    AppendSysOutputWithTimestamp('Unable to map shared memory for reading.');
    setOperationState(0);  // 將狀態設為空閒
    Exit;
  end;

  // 嘗試從偏移量 4 讀取數據類型
  StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_READ or FILE_MAP_WRITE, 0, 0, 8);  // 映射完整 8 個位元組
  if StatePtr <> nil then
  begin
    DataType := PInteger(PByte(StatePtr) + 4)^;  // 從偏移量 4 開始讀取 `DataType`
    if DataType > 0 then
      AppendSysOutputWithTimestamp('Data type read successfully: ' + IntToStr(DataType));
  end
  else
  begin
    //AppendSysOutputWithTimestamp('Unable to map shared memory state for reading.');
    setOperationState(0);  // 將狀態設為空閒
    UnmapViewOfFile(Ptr);  // 解鎖共享記憶體
    Exit;
  end;

  IntData := -99999;
  QwordData := -99999;
  FloatData := -99999;
  DoubleData := -99999;
  StrData := '';


  // 根據數據類型讀取對應的數據
  OutputText := '';
  case DataType of
    1: begin  // 32-bit 整數
         Move(Ptr^, IntData, SizeOf(IntData));
         OutputText := IntToStr(IntData);
       end;
    2: begin  // 64-bit 整數
         Move(Ptr^, QwordData, SizeOf(QwordData));
         OutputText := IntToStr(QwordData);
       end;
    3: begin  // 單精度浮點數
         Move(Ptr^, FloatData, SizeOf(FloatData));
         OutputText := FloatToStr(FloatData);
       end;
    4: begin  // 雙精度浮點數
         Move(Ptr^, DoubleData, SizeOf(DoubleData));
         OutputText := FloatToStr(DoubleData);
       end;
    5: begin  // 字串
         FillChar(StrData, SizeOf(StrData), 0);
         Move(Ptr^, StrData, SizeOf(StrData) - 1);
         OutputText := string(StrData);
       end;
  else
    //OutputText := 'Unsupported data type or empty memory!';
  end;

  // 清除共享記憶體內容
  ClearSharedMemory;

  // 清除 `State` 和 `DataType`
  PInteger(StatePtr)^ := 0;          // 設定操作狀態為空閒
  PInteger(PByte(StatePtr) + 4)^ := 0; // 設定數據類型為 0

  setOperationState(0);  // 重設狀態為空閒
  UnmapViewOfFile(StatePtr);  // 解鎖共享記憶體狀態
  UnmapViewOfFile(Ptr);  // 解鎖共享記憶體
  if length(OutputText) > 0 then
    AppendOutputWithTimestamp(OutputText);  // 輸出結果
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






