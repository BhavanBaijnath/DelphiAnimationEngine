unit DelphiFixes;

{ ToStr(), ToInt(), ToFloat():
  - These custom functions are designed to help speed up typecasting
  - Any type of variable can be inputted into these functions and (hopefully) the correct type will be outputted

  ConnectDatabase():
  - A procedure to connect a ADOConnection to a .mdb file at the specified path (if only part of the path is given it assumes it is in the same directory as the project or in a subfolder in that directory)

  ConnectTable():
  - A procedure to connect a ADOTable to the specified ADOConnection

  ConnectQuery():
  - A procedure to connect a ADOQuery to the specified ADOConnection

  EditRecord() & InsertRecord():
  - Two very similar procedures to edit/insert records in the specified table
  - The input of the fields are specified using an array
  - Inputs for ALL the fields should be given in their original data type
  - To avoid errors when processing, if a field is an autonumber no changes will be made
  eg.
  InsertRecord(tblUsers, ['', 'Bhavan', 'P@$$w0rd', '3 October 2007']) - The fields are UserID | Username | Password | DateOfBirth
  Will output:
  UserID  | Username  | Password  | DateOfBirth
  1       | Bhavan    | P@$$w0rd  | 03/10/2007

  DeleteRecord():
  - A procedure based on Delphi's TADOTable.Delete procedure
  - Also checks if the specified table is not empty to avoid errors

  CloseTables() & OpenTables():
  - Procedures that close all tables inputted through an array

  CentreHorizontal() & CentreVertical():
  - Procedures that centre the inputted control to its parent

  GlobalLeft() & GlobalTop()
  - Finds the Left or Top positions of the inputted control relative to the screen

}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, Math, ADODB, DB;

function ToStr(input: Variant): String;
function ToInt(input: Variant): Integer;
function ToFloat(sInput: String): Real;

procedure ConnectDatabase(var conDatabase: TADOConnection;
  sDatabaseLocation: String; owner: TObject);
procedure ConnectTable(var tblTable: TADOTable; sTableName: String;
  conDatabase: TADOConnection);
procedure ConnectQuery(var qryQuery: TADOQuery; conDatabase: TADOConnection);
procedure RunSQL(var qryQuery: TADOQuery; sSQL: String);
procedure EditRecord(var tblTable: TADOTable; arrInput: Array of Variant);
procedure InsertRecord(var tblTable: TADOTable; arrInput: Array of Variant);
procedure DeleteRecord(var tblTable: TADOTable);

procedure CentreHorizontal(ctrControl: TControl);
procedure CentreVertical(ctrControl: TControl);

function GlobalTop(ctrControl: TWinControl): Integer;
function GlobalLeft(ctrControl: TWinControl): Integer;

implementation

function ToFloat(sInput: String): Real;
var
  iDecimalPos: Integer;
  cFractionSeparator: char;
  sDigits, sDecimals: String;

begin

  if Pos('.', sInput) > 0 then
    cFractionSeparator := '.'
  else
    cFractionSeparator := ',';

  iDecimalPos := Pos(cFractionSeparator, sInput);

  sDigits := Copy(sInput, 1, iDecimalPos - 1);
  sDecimals := Copy(sInput, iDecimalPos + 1);

  Result := StrToInt(sDigits) + Power(StrToInt(sDecimals), Length(sDecimals));

end;

function ToInt(input: Variant): Integer;
begin

  if (VarType(input) = varString) or (VarType(input) = varUString) then
    Result := StrToInt(input)
  else if VarType(input) in [varSmallint, varInteger, varInt64, varByte,
    varShortInt] then
    Result := input
  else
  begin
    if Frac(input) >= 0.5 then
      Result := Trunc(input) + 1
    else
      Result := Trunc(input);
  end;

end;

function ToStr(input: Variant): String;
begin

  if (VarType(input) = varString) or (VarType(input) = varUString) then
    Result := input
  else if VarType(input) in [varSmallint, varInteger, varInt64, varByte,
    varShortInt] then
    Result := IntToStr(input)
  else if VarType(input) in [varSingle, varDouble, varCurrency] then
    Result := FloatToStr(input)
  else if VarType(input) = varBoolean then
    if input = True then
      Result := 'True'
    else
      Result := 'False';

end;

procedure ConnectDatabase(var conDatabase: TADOConnection;
  sDatabaseLocation: String; owner: TObject);
begin

  // Checks if a full file path was given (eg. 'C:\...'
  if not(Pos(':', sDatabaseLocation) > 0) then
    sDatabaseLocation := sDatabaseLocation;

  // Creating connection
  conDatabase := TADOConnection.Create(nil);

  // Setting up connection
  conDatabase.ConnectionString :=
    'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=' + sDatabaseLocation +
    ';Mode=ReadWrite;Persist Security Info=False';
  conDatabase.LoginPrompt := False;
  conDatabase.Open;

end;

procedure ConnectTable(var tblTable: TADOTable; sTableName: String;
  conDatabase: TADOConnection);
begin

  tblTable := TADOTable.Create(conDatabase.owner);
  tblTable.Connection := conDatabase;
  tblTable.TableName := sTableName;
  tblTable.Active := True;

end;

procedure ConnectQuery(var qryQuery: TADOQuery; conDatabase: TADOConnection);
begin

  qryQuery := TADOQuery.Create(conDatabase.owner);
  qryQuery.Connection := conDatabase;

end;

procedure RunSQL(var qryQuery: TADOQuery; sSQL: String);

var
  sFirstStatement: String;

begin

  qryQuery.Close;
  qryQuery.SQL.Text := sSQL;

  sFirstStatement := Trim(UpperCase(Copy(sSQL, 1, Pos(' ', sSQL))));

  // If the starting statement is not 'SELECT' the SQL will be executed instead of opening the query
  if (sFirstStatement = 'UPDATE') or (sFirstStatement = 'DELETE') or
    ((sFirstStatement = 'INSERT')) then
    qryQuery.ExecSQL
  else
    qryQuery.Open;

end;

procedure EditRecord(var tblTable: TADOTable; arrInput: Array of Variant);

var
  i: Integer;
  bOpen: Boolean;
begin

  bOpen := tblTable.Active;

  if not bOpen then
    tblTable.Open;

  tblTable.Edit;

  // Looping through each field in the table and finding the fileds name
  for i := 0 to tblTable.FieldCount - 1 do
  begin
    // if the datatype is a date it won't convert it to a string
    if tblTable.Fields[i].DataType in [ftDate, ftDateTime] then
      tblTable[tblTable.Fields[i].DisplayName] := arrInput[i]
      // if the field is not a autonumber it will convert the value to a string and assign
    else if tblTable.Fields[i].DataType <> ftAutoInc then
      tblTable[tblTable.Fields[i].DisplayName] := arrInput[i];
  end;

  tblTable.Post;

  if not bOpen then
    tblTable.Close;

end;

procedure InsertRecord(var tblTable: TADOTable; arrInput: Array of Variant);

var
  i: Integer;
  bOpen: Boolean;
begin

  bOpen := tblTable.Active;

  if not bOpen then
    tblTable.Open;

  tblTable.Insert;

  // Looping through each field in the table and finding the fileds name
  for i := 0 to tblTable.FieldCount - 1 do
  begin
    // if the datatype is a date it won't convert it to a string
    if tblTable.Fields[i].DataType in [ftDate, ftDateTime] then
      tblTable[tblTable.Fields[i].DisplayName] := arrInput[i]
      // if the field is not a autonumber it will convert the value to a string and assign
    else if tblTable.Fields[i].DataType <> ftAutoInc then
      tblTable[tblTable.Fields[i].DisplayName] := ToStr(arrInput[i]);
  end;

  tblTable.Post;

  if not bOpen then
    tblTable.Close;

end;

procedure DeleteRecord(var tblTable: TADOTable);

var
  bOpen: Boolean;

begin

  bOpen := tblTable.Active;

  if not bOpen then
    tblTable.Open;

  if tblTable.RecordCount > 0 then
    tblTable.Delete;

  if not bOpen then
    tblTable.Close;

end;

procedure CentreHorizontal(ctrControl: TControl);
begin
  ctrControl.Left := (ctrControl.Parent.Width - ctrControl.Width) div 2;
end;

procedure CentreVertical(ctrControl: TControl);
begin
  ctrControl.Top := (ctrControl.Parent.Height - ctrControl.Height) div 2;
end;

function GlobalTop(ctrControl: TWinControl): Integer;
begin

  { Code modfied from ChatGPT
    https://chatgpt.com/share/66f5e402-3688-8008-9784-64a0014cf576 }

  Result := ctrControl.Top;

  while ctrControl.Parent <> nil do
  begin
    ctrControl := ctrControl.Parent;
    Result := Result + ctrControl.Top
  end;

end;

function GlobalLeft(ctrControl: TWinControl): Integer;
begin
  Result := ctrControl.Left;

  while ctrControl.Parent <> nil do
  begin
    ctrControl := ctrControl.Parent;
    Result := Result + ctrControl.Left
  end;

end;

end.
