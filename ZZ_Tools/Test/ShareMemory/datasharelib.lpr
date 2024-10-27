library datasharelib;

{$mode objfpc}{$H+}

uses
  Windows, Classes, DataShareUnit
  { you can add units after this };

exports
  WriteInt32,
  WriteInt64,
  WriteFloat,
  WriteDouble,
  WriteString,

  StartWriteIntBlock,
  AppendIntBlockData,
  EndWriteIntBlock,

  StartWriteFloatBlock,
  AppendFloatBlockData,
  EndWriteFloatBlock,

  StartWriteInt64Block,
  AppendInt64BlockData,
  EndWriteInt64Block;

begin
end.

