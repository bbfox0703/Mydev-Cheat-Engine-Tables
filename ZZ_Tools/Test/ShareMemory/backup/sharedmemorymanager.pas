unit SharedMemoryManager;

interface

uses
  Windows, SysUtils, Classes;

type
  TSharedMemoryManager = class
  private
    FSharedMemoryHandle: THandle;
    FSharedMemoryStateHandle: THandle;
    FSharedMemorySize: Integer;
    FCurrentOffset: Integer;
    procedure SetOperationState(State: Integer);
    procedure SetDataType(DataType: Integer);
  public
    constructor Create(SharedMemorySize: Integer; SharedMemoryName, SharedMemoryStateName: string);
    destructor Destroy; override;
    procedure ClearSharedMemory;
    procedure StartWriteIntBlock;
    procedure AppendIntBlockData(Address: Int64; Value: Integer);
    procedure EndWriteIntBlock;
    function GetOperationState: Integer;
    function MapMemoryForRead: Pointer;
    function MapMemoryForWrite: Pointer;
    procedure UnmapMemory(Ptr: Pointer);
  end;

implementation

constructor TSharedMemoryManager.Create(SharedMemorySize: Integer; SharedMemoryName, SharedMemoryStateName: string);
begin
  FSharedMemorySize := SharedMemorySize;
  FCurrentOffset := 0;
  FSharedMemoryHandle := OpenFileMapping(FILE_MAP_READ or FILE_MAP_WRITE, False, PChar(SharedMemoryName));
  FSharedMemoryStateHandle := OpenFileMapping(FILE_MAP_READ or FILE_MAP_WRITE, False, PChar(SharedMemoryStateName));

  if FSharedMemoryHandle = 0 then
    raise Exception.Create('Failed to open shared memory!');
  if FSharedMemoryStateHandle = 0 then
    raise Exception.Create('Failed to open shared state memory!');
end;

destructor TSharedMemoryManager.Destroy;
begin
  if FSharedMemoryHandle <> 0 then
    CloseHandle(FSharedMemoryHandle);
  if FSharedMemoryStateHandle <> 0 then
    CloseHandle(FSharedMemoryStateHandle);
  inherited Destroy;
end;

procedure TSharedMemoryManager.SetOperationState(State: Integer);
var
  StatePtr: PInteger;
begin
  StatePtr := MapViewOfFile(FSharedMemoryStateHandle, FILE_MAP_WRITE, 0, 0, SizeOf(Integer));
  if StatePtr <> nil then
  begin
    StatePtr^ := State;
    UnmapViewOfFile(StatePtr);
  end
  else
    raise Exception.Create('Failed to set operation state.');
end;

procedure TSharedMemoryManager.SetDataType(DataType: Integer);
var
  StatePtr: PInteger;
begin
  StatePtr := MapViewOfFile(FSharedMemoryStateHandle, FILE_MAP_WRITE, 0, 0, 8);
  if StatePtr <> nil then
  begin
    PInteger(PByte(StatePtr) + 4)^ := DataType;
    UnmapViewOfFile(StatePtr);
  end
  else
    raise Exception.Create('Failed to set data type.');
end;

function TSharedMemoryManager.GetOperationState: Integer;
var
  StatePtr: PInteger;
begin
  StatePtr := MapViewOfFile(FSharedMemoryStateHandle, FILE_MAP_READ, 0, 0, SizeOf(Integer));
  if StatePtr <> nil then
  begin
    Result := StatePtr^;
    UnmapViewOfFile(StatePtr);
  end
  else
    raise Exception.Create('Failed to retrieve operation state.');
end;

procedure TSharedMemoryManager.ClearSharedMemory;
var
  Ptr: Pointer;
begin
  Ptr := MapMemoryForWrite;
  if Ptr = nil then
    raise Exception.Create('Failed to clear shared memory.');
  FillChar(Ptr^, FSharedMemorySize, 0);
  UnmapMemory(Ptr);
end;

procedure TSharedMemoryManager.StartWriteIntBlock;
begin
  ClearSharedMemory;
  FCurrentOffset := 0;
  SetOperationState(-1);
  SetDataType(6);
end;

procedure TSharedMemoryManager.AppendIntBlockData(Address: Int64; Value: Integer);
var
  Ptr: Pointer;
begin
  if FCurrentOffset >= FSharedMemorySize - 12 then
    raise Exception.Create('Shared memory is full.');

  Ptr := MapMemoryForWrite;
  if Ptr = nil then
    raise Exception.Create('Unable to map shared memory for appending data.');

  Move(Address, (PByte(Ptr) + FCurrentOffset)^, SizeOf(Address));
  Move(Value, (PByte(Ptr) + FCurrentOffset + 8)^, SizeOf(Value));
  FCurrentOffset := FCurrentOffset + 12;

  UnmapMemory(Ptr);
end;

procedure TSharedMemoryManager.EndWriteIntBlock;
begin
  SetOperationState(-3);
end;

function TSharedMemoryManager.MapMemoryForRead: Pointer;
begin
  Result := MapViewOfFile(FSharedMemoryHandle, FILE_MAP_READ, 0, 0, FSharedMemorySize);
  if Result = nil then
    raise Exception.Create('Unable to map shared memory for reading.');
end;

function TSharedMemoryManager.MapMemoryForWrite: Pointer;
begin
  Result := MapViewOfFile(FSharedMemoryHandle, FILE_MAP_WRITE, 0, 0, FSharedMemorySize);
  if Result = nil then
    raise Exception.Create('Unable to map shared memory for writing.');
end;

procedure TSharedMemoryManager.UnmapMemory(Ptr: Pointer);
begin
  if Ptr <> nil then
    UnmapViewOfFile(Ptr);
end;

end.

