unit untControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, System.ImageList, untClientObject,
  Vcl.ImgList;

type
  TForm3 = class(TForm)
    TreeView1: TTreeView;
    PageControl1: TPageControl;
    StatusBar1: TStatusBar;
    ImageList1: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure CreateFilemanager;
    procedure CreateProcessmanager;
  private
    { Private-Deklarationen }
  public
    frmProcessmanager:TObject;
    frmFilemanager:TObject;
    { Public-Deklarationen }
    mClientThread:TClientThread;
    procedure InitializeForm(pClientThread:TClientThread);
  end;

var
  Form3: TForm3;

implementation
uses
  untProcessmanager,
  untFilemanager;
{$R *.dfm}

procedure TForm3.InitializeForm(pClientThread:TClientThread);
begin
  Self.mClientThread := pClientThread;
  TForm2(Self.frmFilemanager).InitializeForm(pClientThread);
end;

procedure TForm3.CreateFilemanager;
var
  l :TTabSheet;
  aForm :TForm2;
begin
  l := TTabSheet.Create(PageControl1);
  l.PageControl := PageControl1;
  aForm := TForm2.Create(l) ;
  aForm.Parent := l;
  aForm.Align := alClient;
  aForm.BorderStyle := bsNone;
  aForm.Visible := true;
  l.Caption := 'Filemanager';
  Self.frmFilemanager := aForm;
end;

procedure TForm3.CreateProcessmanager;
var
  l :TTabSheet;
  aForm :TForm4;
begin
  l := TTabSheet.Create(PageControl1);
  l.PageControl := PageControl1;
  aForm := TForm4.Create(l) ;
  aForm.Parent := l;
  aForm.Align := alClient;
  aForm.BorderStyle := bsNone;
  aForm.Visible := true;
  l.Caption := 'Processmanager';
  Self.frmProcessmanager := aForm;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  CreateFilemanager;
  CreateProcessmanager;
end;

end.
