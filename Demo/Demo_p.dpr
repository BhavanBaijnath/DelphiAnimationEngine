program Demo_p;

uses
  Forms,
  Demo_u in 'Demo_u.pas' {frmParametersDemo},
  DelphiAnimationEngine in 'DelphiAnimationEngine.pas',
  DelphiFixes in 'DelphiFixes.pas' {$R *.res};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmParametersDemo, frmParametersDemo);
  Application.Run;
end.
