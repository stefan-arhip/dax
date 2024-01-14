unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mssqlconn, sqldb, odbcconn, Forms, Controls, Graphics,
  Dialogs, ComCtrls, ExtCtrls, IniPropStorage, StdCtrls, PairSplitter, Clipbrd,
  Spin, ListFilterEdit, SynEdit, SynHighlighterSQL, Windows, LCLVersion, MD5;

type

  { TfMain }

  TfMain = class(TForm)
    buReload: TButton;
    cbDatabases: TComboBox;
    cbLimitTopData: TCheckBox;
    ilMain: TImageList;
    Image1: TImage;
    ipMain: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    laChecksum: TLabel;
    laFPC: TLabel;
    laLazarus: TLabel;
    laTarget: TLabel;
    laUsername: TLabel;
    laVersion: TLabel;
    lbApplication: TLabel;
    lbTables: TListBox;
    leHost: TLabeledEdit;
    lePassword: TLabeledEdit;
    leUsername: TLabeledEdit;
    cn: TODBCConnection;
    lfTables: TListFilterEdit;
    lvContent: TListView;
    pcMain: TPageControl;
    pcTable: TPageControl;
    PairSplitter1: TPairSplitter;
    PairSplitterSide1: TPairSplitterSide;
    PairSplitterSide2: TPairSplitterSide;
    seLimitData: TSpinEdit;
    sq: TSQLQuery;
    seDefinition: TSynEdit;
    sbMain: TStatusBar;
    SynSQLSyn1: TSynSQLSyn;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    tr: TSQLTransaction;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure buReloadClick(Sender: TObject);
    procedure cbDatabasesChange(Sender: TObject);
    procedure cbLimitTopDataChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure laChecksumClick(Sender: TObject);
    procedure lbTablesDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure lbTablesSelectionChange(Sender: TObject; User: boolean);
    procedure pcTableChange(Sender: TObject);
  private

  public

  end;

  TCustomStr = class
  private
    fAddress: string;
  public
    property Address: string read fAddress write fAddress;
    constructor Create(_Address: string);
  end;

var
  fMain: TfMain;

implementation

{$R *.lfm}

{ TfMain }

constructor TCustomStr.Create(_Address: string);
begin
  fAddress := _Address;
end;

function GetUserFromWindows: string;
var
  UserName: string;
  UserNameLen: dWord;
begin
  UserNameLen := 255;
  SetLength(UserName, UserNameLen);
  if GetUserName(PChar(UserName), UserNameLen) then
    Result := Copy(UserName, 1, UserNameLen - 1)
  else
    Result := 'Unknown';
end;

procedure TfMain.buReloadClick(Sender: TObject);
var
  s: string;
begin
  sbMain.Panels[0].Text := 'loading...';
  sq.Close;
  cn.Connected := False;
  cn.Params.Clear;
  cn.Params.Add('Driver=SQL Server');
  cn.Params.Add(Format('Server=%s', [leHost.Text]));
  //cn.Params.Add(Format('Database=%s', [cbDatabases.Items[cbDatabases.ItemIndex]]));
  cn.Params.Add('AutoCommit=1');
  cn.UserName := leUsername.Text;
  cn.Password := lePassword.Text;
  cn.Connected := True;

  s := cbDatabases.Text;
  cbDatabases.Items.Clear;
  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('SELECT name FROM master.dbo.sysdatabases');
  sq.Open;
  while not sq.EOF do
  begin
    cbDatabases.Items.Add(sq.FieldByName('name').AsString);
    sq.Next;
  end;
  sq.Close;
  cbDatabases.Text := s;
  sbMain.Panels[0].Text := 'ready';
  sbMain.Panels[1].Text := 'Server: ' + leHost.Text;
end;

procedure TfMain.cbDatabasesChange(Sender: TObject);
var
  s: string;
begin
  if cbDatabases.ItemIndex = -1 then
    exit;

  s := lfTables.Text;
  lfTables.Text := '';
  lfTables.FilteredListbox := nil;
  lfTables.Items.Clear;
  lbTables.Items.Clear;
  sq.Close;
  cn.Connected := False;
  cn.Params.Clear;
  cn.Params.Add('Driver=SQL Server');
  cn.Params.Add(Format('Server=%s', [leHost.Text]));
  cn.Params.Add(Format('Database=%s', [cbDatabases.Items[cbDatabases.ItemIndex]]));
  cn.Params.Add('AutoCommit=1');
  cn.UserName := leUsername.Text;
  cn.Password := lePassword.Text;
  cn.Connected := True;

  sq.Close;
  sq.SQL.Clear;
  //sq.SQL.Add('SELECT table_name FROM INFORMATION_SCHEMA.TABLES');
  //sq.SQL.Add('WHERE TABLE_TYPE=''BASE TABLE'' ');
  sq.SQL.Add(Format('SELECT name,type FROM "%s".."sysobjects"',
    [cbDatabases.Items[cbDatabases.ItemIndex]]));
  sq.SQL.Add('WHERE "type" IN (''U'', ''V'', ''TF'', ''FN'', ''P'') ORDER BY NAME;');
  sq.Open;
  while not sq.EOF do
  begin
    //lbTables.Items.Add(sq.FieldByName('table_name').AsString);
    lbTables.Items.AddObject(sq.FieldByName('name').AsString,
      TCustomStr.Create(sq.FieldByName('type').AsString));
    sq.Next;
  end;
  sq.Close;
  cn.Connected := False;
  lfTables.FilteredListbox := lbTables;
  lfTables.Text := s;
end;

procedure TfMain.cbLimitTopDataChange(Sender: TObject);
begin
  seLimitData.Visible := cbLimitTopData.Checked;
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  FileDate: integer;
begin
  ipMain.IniFileName := ChangeFileExt(ParamStr(0), '.ini');


  laChecksum.Caption := 'Checksum: ' + MD5.MD5Print(MD5File(Application.ExeName));
  laUsername.Caption := 'User: ' + GetUserFromWindows;

  FileDate := FileAge(Application.ExeName);
  if FileDate > -1 then
    laVersion.Caption := 'File date: ' + FormatDateTime('yyyymmdd-hhnn',
      FileDateToDateTime(FileDate));

  laLazarus.Caption := 'Lazarus: ' + lcl_version;
  laFPC.Caption := 'FPC: ' + {$I %FPCVersion%};
  laTarget.Caption := 'Target: ' + {$I %FPCTarget%};
end;

procedure TfMain.laChecksumClick(Sender: TObject);
begin
  Clipboard.AsText := Copy(laChecksum.Caption, Pos(': ', laChecksum.Caption), 999) +
    ' *' + ExtractFileName(Application.ExeName);
end;

procedure TfMain.lbTablesDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  lB: TListBox;
  _name, _type: string;
begin
  if Index >= 0 then
  begin
    lB := (Control as TListBox);

    _name := lB.Items[Index];
    _type := Trim(TCustomStr(lB.Items.Objects[Index]).Address);

    {case _type of
      'V':  // V = View, U = Tables
        lB.Canvas.Font.Style := [fsItalic];
      'U':
        lB.Canvas.Font.Style := [];
    end; }

    if lB.Selected[Index] then
    begin
      lB.Canvas.Font.Color := clHighlightText;
      lB.Canvas.Brush.Color := clHighlight;
    end
    else
    begin
      lB.Canvas.Brush.Color := clDefault;  // clDefault;
      {if (fSettings.tbStripAccountList.Position = 1) and Odd(Index) then
        lB.Canvas.Brush.Color := clMenu;//clCream;  }

      {if _type = 'V' then
        lB.Canvas.Font.Color := clGray
      else }
      lB.Canvas.Font.Color := clDefault;
    end;

    lB.Canvas.FillRect(ARect);
    case _type of
      'U':
        ilMain.Draw(lB.Canvas, ARect.Left + 1, ARect.Top + 1, 0, True);
      'V':
        ilMain.Draw(lB.Canvas, ARect.Left + 1, ARect.Top + 1, 1, True);
      'TF': ilMain.Draw(lB.Canvas, ARect.Left + 1, ARect.Top + 1, 2, True);
      'FN': ilMain.Draw(lB.Canvas, ARect.Left + 1, ARect.Top + 1, 3, True);
      'P': ilMain.Draw(lB.Canvas, ARect.Left + 1, ARect.Top + 1, 4, True);
      else
        ilMain.Draw(lB.Canvas, ARect.Left + 1, ARect.Top + 1, 5, True);
    end;
    lB.Canvas.TextOut(ARect.Left + 20, ARect.Top, _name);
  end;
end;

procedure TfMain.lbTablesSelectionChange(Sender: TObject; User: boolean);
begin
  pcTableChange(Sender);
end;

procedure TfMain.pcTableChange(Sender: TObject);
var
  i, j: integer;
  s: string;
begin
  if lbTables.ItemIndex = -1 then
    exit;

  sbMain.Panels[0].Text := 'loading...';
  case pcTable.PageIndex of
    0:
    begin
      lvContent.Items.BeginUpdate;
      lvContent.Columns.Clear;
      lvContent.Items.Clear;

      if (Trim(TCustomStr(lbTables.Items.Objects[lbTables.ItemIndex]).Address) = 'U') or
        (Trim(TCustomStr(lbTables.Items.Objects[lbTables.ItemIndex]).Address) = 'V') then
      begin
        sq.Close;
        sq.SQL.Clear;
        if cbLimitTopData.Checked then
          s := Format('Top %d', [seLimitData.Value])
        else
          s := '';
        sq.SQL.Add(Format('Select %s * From [%s]',
          [s, lbTables.Items[lbTables.ItemIndex]]));
        try
          sq.Open;

        except
          sq.Close;
          Exit;
        end;

        for i := 1 to sq.FieldCount do
          with lvContent.Columns.Add do
          begin
            Caption := sq.FieldDefs[i - 1].DisplayName;
            AutoSize := True;
          end;
        while not sq.EOF do
        begin
          with lvContent.Items.Add do
          begin
            //Caption:= IntToStr(lvReportResult.Items.Count);
            j := 0;
            for i := 1 to sq.FieldCount do
            begin
              Inc(j);
              if j = 1 then
                Caption := sq.Fields[i - 1].AsString
              else
                SubItems.Add(sq.Fields[i - 1].AsString);
            end;
          end;
          sq.Next;
        end;
        sq.Close;
      end;
      lvContent.Items.EndUpdate;
    end;
    1:
    begin
      seDefinition.Lines.Clear;
      if Trim(TCustomStr(lbTables.Items.Objects[lbTables.ItemIndex]).Address) <> 'U' then
      begin
        sq.Close;
        sq.SQL.Clear;
        sq.SQL.Add('EXEC sp_helptext :P;');
        sq.ParamByName('P').AsString := '[' + lbTables.Items[lbTables.ItemIndex] + ']';
        try
          sq.Open;
        except
          sq.Close;
          Exit;
        end;
        seDefinition.Lines.Clear;
        while not sq.EOF do
        begin
          seDefinition.Lines.Add(sq.FieldByName('TEXT').AsString);
          sq.Next;
        end;
        sq.Close;
      end;
    end;
  end;
  sbMain.Panels[0].Text := 'ready';
end;

end.
