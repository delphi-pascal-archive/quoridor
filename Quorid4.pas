unit Quorid4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TApropos = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    Label3: TLabel;
    Label4: TLabel;
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Apropos: TApropos;

implementation

{$R *.dfm}

end.
