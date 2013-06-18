unit UCDBXConnReg;

interface

uses
  Classes;

procedure Register;

implementation

uses
  UCDBXConn;

procedure Register;
begin
  RegisterComponents('UC Connectors', [TUCDBXConn]);
end;

end.

