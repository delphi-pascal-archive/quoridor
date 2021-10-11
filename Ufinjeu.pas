unit Ufinjeu;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TDlgFin = class(TForm)
    OKBtn: TButton;
    Joker: TImage;
    PnFin: TPanel;
    Ima1: TImage;
    Ima2: TImage;

    procedure Affiche(gagne : boolean);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DlgFin: TDlgFin;

implementation

{$R *.DFM}

procedure TDlgFin.Affiche(gagne : boolean);
begin
  if gagne then
  begin
    DlgFin.Color := clYellow;
    PnFin.Caption := 'Bravo ! C''est gagné !';
    DlgFin.Joker.Picture := Ima1.Picture;
  end
  else begin
         DlgFin.Color := clAqua;
         PnFin.Caption := 'La prochaine peut-être...';
         DlgFin.Joker.Picture := Ima2.Picture;
       end;
end;

end.
