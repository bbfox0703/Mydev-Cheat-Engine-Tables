library datasharelib;

{$mode objfpc}{$H+}

uses
  Windows, Classes, DataShareUnit
  { you can add units after this };
exports
  StartWriteInt32,
  AppendInt32Data,
  EndWriteInt32,

  StartWriteInt64,
  AppendInt64Data,
  EndWriteInt64,

  StartWriteFloat,
  AppendFloatData,
  EndWriteFloat,

  StartWriteDouble,
  AppendDoubleData,
  EndWriteDouble,

  StartWriteString,
  AppendStringData,
  EndWriteString,

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

