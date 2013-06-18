{-----------------------------------------------------------------------------
 Unit Name: UCDBXConn
 Author:    QmD
 Date:      08-nov-2004
 Purpose:   ADO Support

 registered in UCDBXReg.pas
-----------------------------------------------------------------------------}

unit UCDBXConn;

interface

uses
  Classes,
  DB,SimpleDS,
  SqlExpr,
  SysUtils,
  UCDataConnector;

type
  TUCDBXConn = class(TUCDataConnector)
  private
    FConnection: TSQLConnection;
    FSchema:     String;
    procedure SetSQLConnection(Value: TSQLConnection);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    function GetDBObjectName: String; override;
    function GetTransObjectName: String; override;
    function UCFindDataConnection: Boolean; override;
    function UCFindTable(const Tablename: String): Boolean; override;
    function UCGetSQLDataset(FSQL: String): TDataset; override;
    procedure UCExecSQL(FSQL: String); override;
  published
    property Connection: TSQLConnection read FConnection write SetSQLConnection;
    property SchemaName: String read FSchema write FSchema;
  end;

implementation

{ TUCDBXConn }

procedure TUCDBXConn.SetSQLConnection(Value: TSQLConnection);
begin
  if FConnection <> Value then
    FConnection := Value;
  if FConnection <> nil then
    FConnection.FreeNotification(Self);
end;

procedure TUCDBXConn.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FConnection) then
    FConnection := nil;
  inherited Notification(AComponent, Operation);
end;

function TUCDBXConn.UCFindTable(const TableName: String): Boolean;
var
  TempList: TStringList;
begin
  Result := False;
  try
    TempList := TStringList.Create;
    if SchemaName <> '' then
      FConnection.GetTableNames(TempList, SchemaName)
    else
      FConnection.GetTableNames(TempList);
    TempList.Text := UpperCase(TempList.Text);
    Result        := TempList.IndexOf(UpperCase(TableName)) > -1;
  finally
    FreeAndNil(TempList);
  end;

end;

function TUCDBXConn.UCFindDataConnection: Boolean;
begin
  Result := Assigned(FConnection) and (FConnection.Connected);
end;

function TUCDBXConn.GetDBObjectName: String;
begin
  if Assigned(FConnection) then
  begin
    if Owner = FConnection.Owner then
      Result := FConnection.Name
    else
    begin
      Result := FConnection.Owner.Name + '.' + FConnection.Name;
    end;
  end
  else
    Result := '';
end;

function TUCDBXConn.GetTransObjectName: String;
begin
  Result := '';
end;

procedure TUCDBXConn.UCExecSQL(FSQL: String);
begin
//  FConnection.Execute(FSQL, nil);
  FConnection.ExecuteDirect(FSQL);
end;

function TUCDBXConn.UCGetSQLDataset(FSQL: String): TDataset;
begin
  Result := TSimpleDataSet.Create(nil);
  with Result as TSimpleDataSet do
  begin
    Connection          := FConnection;
    DataSet.CommandText := FSQL;
    SchemaName          := FSchema;
    Open;
  end;
end;

end.

