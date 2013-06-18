unit pUCFrame_User;

interface

{$I 'UserControl.inc'}

uses
 {$IFDEF DELPHI5_UP}
 {$ELSE}
  Variants,
 {$ENDIF}
  Buttons,
  Classes,
  Controls,
  Db,
  DBGrids,
  Dialogs,
  ExtCtrls,
  Forms,
  Graphics,
  Grids,
  IncUser_U,
  Messages,
  SenhaForm_U,
  StdCtrls,
  SysUtils,
  UcBase,
  UserPermis_U,
  Windows;

type
  TUCFrame_User = class(TFrame)
    Panel3:     TPanel;
    btAdic:     TBitBtn;
    BtAlt:      TBitBtn;
    BtExclui:   TBitBtn;
    BtAcess:    TBitBtn;
    BtnClose:   TBitBtn;
    BtPass:     TBitBtn;
    DbGridUser: TDBGrid;
    DataUser:   TDataSource;
    DataPerfil: TDataSource;
    procedure btAdicClick(Sender: TObject);
    procedure BtAltClick(Sender: TObject);
    procedure BtAcessClick(Sender: TObject);
    procedure BtPassClick(Sender: TObject);
    procedure BtExcluiClick(Sender: TObject);
  protected
    FormSenha:          TCustomForm;
    FfrmIncluirUsuario: TfrmIncluirUsuario;
    procedure SetWindowUserProfile;
    procedure SetWindowUser(Adicionar: Boolean);
    procedure ActionBtPermissUserDefault;
    procedure FDataSetCadastroUsuarioAfterScroll(DataSet: TDataSet);
  private
    { Private declarations }
  public
    FUsercontrol:            TUserControl;
    FDataSetCadastroUsuario: TDataset;
    procedure SetWindow;
    destructor Destroy; override;    
    { Public declarations }
  end;

implementation

uses
  UCMessages;

{$R *.dfm}

procedure TUCFrame_User.btAdicClick(Sender: TObject);
begin
  FfrmIncluirUsuario              := TfrmIncluirUsuario.Create(Self);
  FfrmIncluirUsuario.FUsercontrol := Self.FUsercontrol;
  SetWindowUser(True);
  FfrmIncluirUsuario.ShowModal;
  FreeAndNil(FfrmIncluirUsuario);
end;

procedure TUCFrame_User.BtAltClick(Sender: TObject);
begin
  if FDataSetCadastroUsuario.IsEmpty then
    Exit;
  FfrmIncluirUsuario              := TfrmIncluirUsuario.Create(Self);
  FfrmIncluirUsuario.FUsercontrol := Self.FUsercontrol;
  SetWindowUser(False);
  with FfrmIncluirUsuario do
  begin
    FAltera                := True;
    vNovoIDUsuario         := FDataSetCadastroUsuario.FieldByName('IdUser').AsInteger;
    EditNome.Text          := FDataSetCadastroUsuario.FieldByName('Nome').AsString;
    EditLogin.Text         := FDataSetCadastroUsuario.FieldByName('Login').AsString;
    EditEmail.Text         := FDataSetCadastroUsuario.FieldByName('Email').AsString;
    ComboPerfil.KeyValue   := FDataSetCadastroUsuario.FieldByName('Perfil').AsInteger;
    ckPrivilegiado.Checked := StrToBool(FDataSetCadastroUsuario.FieldByName('Privilegiado').AsString);
    ckUserExpired.Checked  := StrToBool(FDataSetCadastroUsuario.FieldByName('UserNaoExpira').AsString);
    SpinExpira.Value       := FDataSetCadastroUsuario.FieldByName('DaysOfExpire').AsInteger;
    ComboStatus.ItemIndex  := FDataSetCadastroUsuario.FieldByName('UserInative').AsInteger;
    if FfrmIncluirUsuario.ComboStatus.Enabled then
      FfrmIncluirUsuario.ComboStatus.Enabled := not ((FUsercontrol.User.ProtectAdministrator) and
        (FDataSetCadastroUsuario.FieldByName('Login').AsString = FUsercontrol.Login.InitialLogin.User));
    ShowModal;
  end;
  FreeAndNil(FfrmIncluirUsuario);
end;

procedure TUCFrame_User.BtExcluiClick(Sender: TObject);
var
  TempID:    Integer;
  CanDelete: Boolean;
  ErrorMsg:  String;
begin
  if FDataSetCadastroUsuario.IsEmpty then
    Exit;
  TempID := FDataSetCadastroUsuario.FieldByName('IDUser').AsInteger;
  if MessageBox(Handle, PChar(Format(FUsercontrol.UserSettings.UsersForm.PromptDelete, [FDataSetCadastroUsuario.FieldByName('Login').AsString])),
    PChar(FUsercontrol.UserSettings.UsersForm.PromptDelete_WindowCaption), MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2) = idYes then
  begin
    CanDelete := True;
    if Assigned(FUsercontrol.onDeleteUser) then
      FUsercontrol.onDeleteUser(TObject(Owner), TempID, CanDelete, ErrorMsg);
    if not CanDelete then
    begin
      MessageDlg(ErrorMSG, mtWarning, [mbOK], 0);
      Exit;
    end;

    FUsercontrol.DataConnector.UCExecSQL('Delete from ' + FUsercontrol.TableRights.TableName + ' where ' +
      FUsercontrol.TableRights.FieldUserID + ' = ' + IntToStr(TempID));
    FUsercontrol.DataConnector.UCExecSQL('Delete from ' + FUsercontrol.TableUsers.TableName + ' where ' +
      FUsercontrol.TableUsers.FieldUserID + ' = ' + IntToStr(TempID));
    FDataSetCadastroUsuario.Close;
    FDataSetCadastroUsuario.Open;
  end;
end;

procedure TUCFrame_User.BtPassClick(Sender: TObject);
begin
  if FDataSetCadastroUsuario.IsEmpty then
    Exit;

  FormSenha                          := TSenhaForm.Create(Self);
  TSenhaForm(FormSenha).Position     := FUsercontrol.UserSettings.WindowsPosition;
  TSenhaForm(FormSenha).FUsercontrol := FUsercontrol;
  TSenhaForm(FormSenha).Caption      := Format(FUsercontrol.UserSettings.ResetPassword.WindowCaption,
    [FDataSetCadastroUsuario.FieldByName('Login').AsString]);
  if TSenhaForm(FormSenha).ShowModal = mrOk then
    Begin

(*
      if (Assigned(FUsercontrol.MailUserControl)) and (FUsercontrol.MailUserControl.SenhaForcada.Ativo ) then
        try
          FUsercontrol.MailUserControl.EnviaEmailSenhaForcada(
             FDataSetCadastroUsuario.FieldByName('NOME').AsString ,
             FDataSetCadastroUsuario.FieldByName('LOGIN').AsString,
             TSenhaForm(FormSenha).edtSenha.Text ,
             FDataSetCadastroUsuario.FieldByName('EMAIL').AsString,
              '');
  
        except
          on E : Exception do FUsercontrol.Log(e.Message, 0);
        end;
    
*)
      FUsercontrol.ChangePassword(FDataSetCadastroUsuario.FieldByName('IDUser').AsInteger, TSenhaForm(FormSenha).edtSenha.Text);
    End;
  FreeAndNil(FormSenha);
end;

destructor TUCFrame_User.Destroy;
begin
   //nada a destruir
  //n�o destruir o FDataSetCadastroUsuario o USERCONTROL toma conta dele
  inherited;
end;

procedure TUCFrame_User.BtAcessClick(Sender: TObject);
begin
  if FDataSetCadastroUsuario.IsEmpty then
    Exit;
  UserPermis              := TUserPermis.Create(self);
  UserPermis.FUsercontrol := FUsercontrol;
  SetWindowUserProfile;
  UserPermis.lbUser.Caption := FDataSetCadastroUsuario.FieldByName('Login').AsString;
  ActionBtPermissUserDefault;
end;

procedure TUCFrame_User.SetWindowUserProfile;
begin
  with  FUsercontrol.UserSettings.Rights do
  begin
    UserPermis.Caption              := WindowCaption;
    UserPermis.LbDescricao.Caption  := LabelUser;
    UserPermis.lbUser.Left          := UserPermis.LbDescricao.Left + UserPermis.LbDescricao.Width + 5;
    UserPermis.PageMenu.Caption     := PageMenu;
    UserPermis.PageAction.Caption   := PageActions;
    UserPermis.PageControls.Caption := PageControls; // By Vicente Barros Leonel
    UserPermis.BtLibera.Caption     := BtUnlock;
    UserPermis.BtBloqueia.Caption   := BtLOck;
    UserPermis.BtGrava.Caption      := BtSave;
    UserPermis.BtCancel.Caption     := BtCancel;
    UserPermis.Position             := FUsercontrol.UserSettings.WindowsPosition;
  end;
end;

procedure TUCFrame_User.ActionBtPermissUserDefault;
var
  TempCampos, TempCamposEX: String;
begin
  UserPermis.FTempIdUser := FDataSetCadastroUsuario.FieldByName('IdUser').AsInteger;
  with FUsercontrol do
  begin
    TempCampos   := Format(' %s as IdUser, %s as Modulo, %s as ObjName, %s as UCKey ', [TableRights.FieldUserID,
      TableRights.FieldModule, TableRights.FieldComponentName, TableRights.FieldKey]);
    TempCamposEX := Format(' %s, %s as FormName ', [TempCampos, TableRights.FieldFormName]);

    UserPermis.DSPermiss := DataConnector.UCGetSQLDataset(Format('SELECT %s FROM %s TAB WHERE TAB.%s = %s AND TAB.%s = %s',
      [TempCampos, TableRights.TableName, TableRights.FieldUserID, FDataSetCadastroUsuario.FieldByName('IdUser').AsString,
      TableRights.FieldModule, QuotedStr(ApplicationID)]));
    UserPermis.DSPermiss.Open;

    UserPermis.DSPermissEX := DataConnector.UCGetSQLDataset(Format('SELECT %s FROM %s TAB1 WHERE TAB1.%s = %s AND TAB1.%s = %s',
      [TempCamposEX, TableRights.TableName + 'EX', TableRights.FieldUserID, FDataSetCadastroUsuario.FieldByName('IdUser').AsString,
      TableRights.FieldModule, QuotedStr(ApplicationID)]));
    UserPermis.DSPermissEX.Open;

    UserPermis.DSPerfil := DataConnector.UCGetSQLDataset(Format('Select %s from %s tab Where tab.%s = %s and tab.%s = %s',
      [TempCampos, TableRights.TableName, TableRights.FieldUserID, FDataSetCadastroUsuario.FieldByName('Perfil').AsString,
      TableRights.FieldModule, QuotedStr(ApplicationID)]));
    UserPermis.DSPerfil.Open;

    UserPermis.DSPerfilEX := DataConnector.UCGetSQLDataset(Format('Select %s from %s tab1 Where tab1.%s = %s and tab1.%s = %s',
      [TempCamposEX, TableRights.TableName + 'EX', TableRights.FieldUserID, FDataSetCadastroUsuario.FieldByName('Perfil').AsString,
      TableRights.FieldModule, QuotedStr(ApplicationID)]));

    UserPermis.DSPerfilEX.Open;

    UserPermis.ShowModal;

    FDataSetCadastroUsuario.Close;
    FDataSetCadastroUsuario.Open;

    FDataSetCadastroUsuario.Locate('idUser', UserPermis.FTempIdUser, []);

    FreeAndNil(UserPermis);
  end;
end;

procedure TUCFrame_User.FDataSetCadastroUsuarioAfterScroll(DataSet: TDataSet);
begin
  if (FUsercontrol.User.ProtectAdministrator) and (Dataset.FieldByName('Login').AsString = FUsercontrol.Login.InitialLogin.User) then
  begin
    BtExclui.Enabled := False;
    BtPass.Enabled   := False;
    if FUsercontrol.CurrentUser.Username <> FUsercontrol.Login.InitialLogin.User then
      BtAcess.Enabled := False;
  end
  else
  begin
    BtExclui.Enabled := True;
    BtPass.Enabled   := True;
    BtAcess.Enabled  := True;
  end;
end;


procedure TUCFrame_User.SetWindow;
begin
  FDataSetCadastroUsuario.AfterScroll := FDataSetCadastroUsuarioAfterScroll;
  FDataSetCadastroUsuarioAfterScroll(FDataSetCadastroUsuario);
  with FUsercontrol.UserSettings.UsersForm do
  begin
    DbGridUser.Columns[0].Title.Caption := ColName;
    DbGridUser.Columns[1].Title.Caption := ColLogin;
    DbGridUser.Columns[2].Title.Caption := ColEmail;

    btAdic.Caption   := BtAdd;
    BtAlt.Caption    := BtChange;
    BtExclui.Caption := BtDelete;
    BtAcess.Caption  := BtRights;
    BtPass.Caption   := BtPassword;
    BtnClose.Caption := BtClose;
  end;

end;

procedure TUCFrame_User.SetWindowUser(Adicionar: Boolean);
begin
  with FUsercontrol.UserSettings.AddChangeUser do
  begin
    FfrmIncluirUsuario.Caption := WindowCaption;
    if Adicionar then
      FfrmIncluirUsuario.LbDescricao.Caption := LabelAdd
    else
    begin
      FfrmIncluirUsuario.LbDescricao.Caption := LabelChange;
      FfrmIncluirUsuario.LbDescricao.Tag     := FDataSetCadastroUsuario.FieldByName('IdUser').AsInteger;
    end;

    FfrmIncluirUsuario.FDataSetCadastroUsuario := DataUser.DataSet;
    FfrmIncluirUsuario.Label1.Caption          := LabelStatus;
    FfrmIncluirUsuario.lbNome.Caption          := LabelName;
    FfrmIncluirUsuario.lbLogin.Caption         := LabelLogin;
    FfrmIncluirUsuario.lbEmail.Caption         := LabelEmail;
    FfrmIncluirUsuario.ckPrivilegiado.Caption  := CheckPrivileged;
    FfrmIncluirUsuario.lbPerfil.Caption        := LabelPerfil;
    FfrmIncluirUsuario.btGravar.Caption        := BtSave;
    FfrmIncluirUsuario.btCancela.Caption       := BtCancel;
    FfrmIncluirUsuario.Position                := Self.FUsercontrol.UserSettings.WindowsPosition;
    FfrmIncluirUsuario.LabelExpira.Caption     := ExpiredIn;
    FfrmIncluirUsuario.LabelDias.Caption       := Day;
    FfrmIncluirUsuario.ckUserExpired.Caption   := CheckExpira;
    FfrmIncluirUsuario.ComboPerfil.ListSource  := DataPerfil;
    FfrmIncluirUsuario.ComboStatus.Enabled     := not Adicionar;
    with FfrmIncluirUsuario.ComboStatus.Items do
    begin
      Clear;
      Add(StatusActive);
      Add(StatusDisabled);
    end;
    FfrmIncluirUsuario.ComboStatus.ItemIndex := 0;
  end;
end;

end.
