unit DataShareUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, SysUtils, WinUtils;

var
  SharedMemoryHandle: THandle = 0;
  SharedMemoryStateHandle: THandle = 0;
  SharedMemorySize: Integer = 65536;  // 設定記憶體大小，例如64K
  CurrentOffset: Integer = 0;

// 單一函數處理每個數據類型 1-5
procedure WriteInt32(Value: Integer); stdcall;
procedure WriteInt64(Value: Int64); stdcall;
procedure WriteFloat(Value: Single); stdcall;
procedure WriteDouble(Value: Double); stdcall;
procedure WriteString(const Value: AnsiString); stdcall;

// 分為三個處理程序的 Data Type 6-8
procedure StartWriteIntBlock; stdcall;
procedure AppendIntBlockData(Address: Int64; Value: Integer); stdcall;
procedure EndWriteIntBlock; stdcall;

procedure StartWriteFloatBlock; stdcall;
procedure AppendFloatBlockData(Address: Int64; Value: Single); stdcall;
procedure EndWriteFloatBlock; stdcall;

procedure StartWriteInt64Block; stdcall;
procedure AppendInt64BlockData(Address: Int64; Value: Int64); stdcall;
procedure EndWriteInt64Block; stdcall;

implementation

// 基礎功能
procedure OpenSharedMemory;
begin
  if SharedMemoryHandle = 0 then
    SharedMemoryHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, SharedMemorySize, 'MySharedMemory');

  if SharedMemoryStateHandle = 0 then
    SharedMemoryStateHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, 8, 'MySharedMemoryState');
end;

procedure CloseSharedMemory;
begin
  if SharedMemoryHandle <> 0 then
  begin
    CloseHandle(SharedMemoryHandle);
    SharedMemoryHandle := 0;
  end;
  if SharedMemoryStateHandle <> 0 then
  begin
    CloseHandle(SharedMemoryStateHandle);
    SharedMemoryStateHandle := 0;
  end;
end;

procedure SetOperationState(State: Integer);
var
  StatePtr: PInteger;
begin
  StatePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_WRITE, 0, 0, 8);
  if StatePtr <> nil then
  begin
    StatePtr^ := State;
    UnmapViewOfFile(StatePtr);
  end;
end;

procedure SetDataType(DataType: Integer);
var
  DataTypePtr: PInteger;
begin
  DataTypePtr := MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_WRITE, 0, 0, 8);
  if DataTypePtr <> nil then
  begin
    PInteger(PByte(DataTypePtr) + 4)^ := DataType;
    UnmapViewOfFile(DataTypePtr);
  end;
end;

procedure WaitForIdleState;
var
  StartTime: DWORD;
  StatePtr: PInteger;
begin
  StartTime := GetTickCount64;
  while True do
  begin
    if GetTickCount64 - StartTime > 500 then
    begin
      SetOperationState(0);  // 強制重設為空閒狀態
      Break;
    end;

    StatePtr := PInteger(MapViewOfFile(SharedMemoryStateHandle, FILE_MAP_READ, 0, 0, 8));
    if StatePtr <> nil then
    begin
      if StatePtr^ = 0 then
      begin
        UnmapViewOfFile(StatePtr);
        Break;
      end;
      UnmapViewOfFile(StatePtr);
    end;

    Sleep(10);
  end;
end;


// 單一函數處理每個數據類型 1-5
procedure WriteInt32(Value: Integer); stdcall;
var
  Ptr: Pointer;
begin
  OpenSharedMemory;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(1);

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SizeOf(Value));
  if Ptr <> nil then
  begin
    Move(Value, Ptr^, SizeOf(Value));
    UnmapViewOfFile(Ptr);
  end;

  SetOperationState(-3);
  CloseSharedMemory;
end;

procedure WriteInt64(Value: Int64); stdcall;
var
  Ptr: Pointer;
begin
  OpenSharedMemory;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(2);

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SizeOf(Value));
  if Ptr <> nil then
  begin
    Move(Value, Ptr^, SizeOf(Value));
    UnmapViewOfFile(Ptr);
  end;

  SetOperationState(-3);
  CloseSharedMemory;
end;

procedure WriteFloat(Value: Single); stdcall;
var
  Ptr: Pointer;
begin
  OpenSharedMemory;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(3);

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SizeOf(Value));
  if Ptr <> nil then
  begin
    Move(Value, Ptr^, SizeOf(Value));
    UnmapViewOfFile(Ptr);
  end;

  SetOperationState(-3);
  CloseSharedMemory;
end;

procedure WriteDouble(Value: Double); stdcall;
var
  Ptr: Pointer;
begin
  OpenSharedMemory;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(4);

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SizeOf(Value));
  if Ptr <> nil then
  begin
    Move(Value, Ptr^, SizeOf(Value));
    UnmapViewOfFile(Ptr);
  end;

  SetOperationState(-3);
  CloseSharedMemory;
end;

procedure WriteString(const Value: AnsiString); stdcall;
var
  Ptr: Pointer;
begin
  OpenSharedMemory;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(5);

  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, Length(Value) + 1);
  if Ptr <> nil then
  begin
    Move(PAnsiChar(Value)^, Ptr^, Length(Value) + 1);
    UnmapViewOfFile(Ptr);
  end;

  SetOperationState(-3);
  CloseSharedMemory;
end;

// Type 6 - Int Block
procedure StartWriteIntBlock; stdcall;
begin
  OpenSharedMemory;
  CurrentOffset := 0;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(6);
end;

procedure AppendIntBlockData(Address: Int64; Value: Integer); stdcall;
var
  Ptr: Pointer;
begin
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr <> nil then
  begin
    Move(Address, (PByte(Ptr) + CurrentOffset)^, SizeOf(Address));
    Move(Value, (PByte(Ptr) + CurrentOffset + 8)^, SizeOf(Value));
    CurrentOffset := CurrentOffset + 12;
    UnmapViewOfFile(Ptr);
  end;
end;

procedure EndWriteIntBlock; stdcall;
begin
  SetOperationState(-3);
  CloseSharedMemory;
end;

// Repeat similarly for Type 7 (Float Block) and Type 8 (Int64 Block)
procedure StartWriteFloatBlock; stdcall;
begin
  OpenSharedMemory;
  CurrentOffset := 0;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(7);
end;

procedure AppendFloatBlockData(Address: Int64; Value: Single); stdcall;
var
  Ptr: Pointer;
begin
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr <> nil then
  begin
    Move(Address, (PByte(Ptr) + CurrentOffset)^, SizeOf(Address));
    Move(Value, (PByte(Ptr) + CurrentOffset + 8)^, SizeOf(Value));
    CurrentOffset := CurrentOffset + 12;
    UnmapViewOfFile(Ptr);
  end;
end;

procedure EndWriteFloatBlock; stdcall;
begin
  SetOperationState(-3);
  CloseSharedMemory;
end;

procedure StartWriteInt64Block; stdcall;
begin
  OpenSharedMemory;
  CurrentOffset := 0;
  WaitForIdleState;
  SetOperationState(-1);
  SetDataType(8);
end;

procedure AppendInt64BlockData(Address: Int64; Value: Int64); stdcall;
var
  Ptr: Pointer;
begin
  Ptr := MapViewOfFile(SharedMemoryHandle, FILE_MAP_WRITE, 0, 0, SharedMemorySize);
  if Ptr <> nil then
  begin
    Move(Address, (PByte(Ptr) + CurrentOffset)^, SizeOf(Address));
    Move(Value, (PByte(Ptr) + CurrentOffset + 8)^, SizeOf(Value));
    CurrentOffset := CurrentOffset + 16;
    UnmapViewOfFile(Ptr);
  end;
end;

procedure EndWriteInt64Block; stdcall;
begin
  SetOperationState(-3);
  CloseSharedMemory;
end;

end.

