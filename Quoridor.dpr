program Quoridor;

uses
  Forms,
  Quorid1 in 'Quorid1.pas' {Form1},
  Quorid2 in 'Quorid2.pas' {FAstar},
  Quorid3 in 'Quorid3.pas' {Regles},
  Ufinjeu in 'UFINJEU.PAS' {DlgFin},
  USplash in 'USplash.pas' {FSplash},
  Quorid4 in 'Quorid4.pas' {Apropos};

{$R *.res}

begin
  Application.Initialize;
  FSplash := TFSplash.Create(Application);
  FSplash.Show;
  FSplash.Refresh;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFAstar, FAstar);
  Application.CreateForm(TRegles, Regles);
  Application.CreateForm(TDlgFin, DlgFin);
  Application.CreateForm(TFSplash, FSplash);
  Application.CreateForm(TApropos, Apropos);
  Application.Run;
end.
