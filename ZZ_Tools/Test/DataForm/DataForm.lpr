library DataForm;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Forms, Dialogs, StdCtrls, mainunit0, Interfaces
  { you can add units after this };

procedure ShowValues(Addresses: PUInt64; Count: Integer); stdcall;
var
  MemoryForm: TMainForm;
  i: Integer;
  Value: Int64;
begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);

  MainForm.Memo.Clear;
  for i := 0 to Count - 1 do
  begin
    Value := PInt64(Addresses + i)^;  // 取出地址中的值
    MainForm.Memo.Lines.Add(Format('Address: %p, Value: %d', [Pointer(Addresses[i]), Value]));
  end;

  MainForm.ShowModal;
  MainForm.Free;
end;

exports
  ShowValues;


begin
end.

