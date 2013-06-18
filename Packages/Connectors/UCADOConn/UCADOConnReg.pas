unit UCADOConnReg;

interface

uses
  Classes,
  UCADOConn;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('UC Connectors', [TUCADOConn]);
end;

end.

