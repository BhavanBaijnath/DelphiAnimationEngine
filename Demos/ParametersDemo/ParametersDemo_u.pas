unit ParametersDemo_u;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Vcl.StdCtrls, DelphiFixes, DelphiAnimationEngine,
  Vcl.Samples.Spin;

type
  TfrmParametersDemo = class(TForm)
    tmrAnimations: TTimer;
    pnlOuterBox: TPanel;
    pnlMoving: TPanel;
    btnPlay: TButton;
    sedMovement: TSpinEdit;
    sedTime: TSpinEdit;
    btnReset: TButton;
    lblTime: TLabel;
    Label1: TLabel;
    cmbEasing: TComboBox;
    lblEasing: TLabel;
    lblProperty: TLabel;
    cmbProperty: TComboBox;
    procedure tmrAnimationsTimer(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure sedMovementChange(Sender: TObject);
    procedure sedTimeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cmbPropertyChange(Sender: TObject);
    procedure cmbEasingChange(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmParametersDemo: TfrmParametersDemo;
  atAnimationType: TAnimationType;
  apAnimationProperty: TAnimationProperty;
  iMovement, iTime: Integer;

implementation

{$R *.dfm}

procedure TfrmParametersDemo.btnPlayClick(Sender: TObject);
begin
  AnimateControl(pnlMoving, atAnimationType, apAnimationProperty, iTime,
    ToInt(iMovement * frmParametersDemo.FScaleFactor))
end;

procedure TfrmParametersDemo.btnResetClick(Sender: TObject);
begin
  pnlMoving.Width := ToInt(60 * frmParametersDemo.FScaleFactor);
  pnlMoving.Height := ToInt(60 * frmParametersDemo.FScaleFactor);
  pnlMoving.Left := (pnlOuterBox.Width - pnlMoving.Width) div 2;
  pnlMoving.Top := (pnlOuterBox.Height - pnlMoving.Height) div 2;
end;

procedure TfrmParametersDemo.cmbEasingChange(Sender: TObject);
begin
  atAnimationType := TAnimationType(cmbEasing.ItemIndex)
end;

procedure TfrmParametersDemo.cmbPropertyChange(Sender: TObject);
begin
  apAnimationProperty := TAnimationProperty(cmbProperty.ItemIndex)
end;

procedure TfrmParametersDemo.FormCreate(Sender: TObject);
begin
  pnlMoving.Width := ToInt(60 * frmParametersDemo.FScaleFactor);
  pnlMoving.Height := ToInt(60 * frmParametersDemo.FScaleFactor);
  pnlMoving.Left := (pnlOuterBox.Width - pnlMoving.Width) div 2;
  pnlMoving.Top := (pnlOuterBox.Height - pnlMoving.Height) div 2;

  atAnimationType := atLinear;
  apAnimationProperty := apLeft;
  iMovement := sedMovement.Value;
  iTime := sedTime.Value;
end;

procedure TfrmParametersDemo.sedMovementChange(Sender: TObject);
begin
  iMovement := sedMovement.Value;
end;

procedure TfrmParametersDemo.sedTimeChange(Sender: TObject);
begin
  iTime := sedTime.Value;
end;

procedure TfrmParametersDemo.tmrAnimationsTimer(Sender: TObject);
begin
  AnimationTimer;
end;

end.
