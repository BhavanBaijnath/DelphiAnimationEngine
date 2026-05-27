program ParametersDemo_p;

uses
  Forms,
  ParametersDemo_u in 'ParametersDemo_u.pas' {frmParametersDemo},
  DelphiAnimationEngine in 'DelphiAnimationEngine.pas',
  DelphiFixes in 'DelphiFixes.pas' {$R *.res};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmParametersDemo, frmParametersDemo);
  Application.Run;
end.
