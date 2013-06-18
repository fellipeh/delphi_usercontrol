unit UCZEOSConnReg;

interface

uses Classes;

procedure Register;

implementation

uses UCZEOSConn;

procedure Register;
begin
  RegisterComponents('UC Connectors', [TUCZEOSConn]);
end;
end.
