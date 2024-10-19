library DataForm;

{$mode objfpc}{$H+}

uses
  Windows, Classes, SysUtils, Forms, Dialogs, StdCtrls, mainunit0, Interfaces
  { you can add units after this };

procedure ShowValues(Addresses: PUInt64; Count: Integer); stdcall;
var
  MemoryForm: TMainForm;
  i: Integer;
  Value: Int64;
begin
  //Application.Initialize;
  //Application.CreateForm(TMainForm, MainForm);
  try
    MemoryForm := TMainForm.Create(nil);

    MainForm.Memo.Clear;
    for i := 0 to Count - 1 do
    begin
      MainForm.Memo.Lines.Add(IntToStr(i));
      //Value := PInt64(Addresses + i)^;  // 取出地址中的值
      //MainForm.Memo.Lines.Add(Format('Address: %p, Value: %d', [Pointer(Addresses[i]), Value]));
    end;

    MainForm.ShowModal;
  finally
    MainForm.Free;
  end;
end;

function GetCurrentProcessIdWrapper: DWORD; stdcall;
begin
  Result := GetCurrentProcessId();  // 使用 Windows API 取得當前進程 ID
end;

exports
  ShowValues,
  GetCurrentProcessIdWrapper;


begin
end.

