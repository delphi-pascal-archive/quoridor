unit Quorid1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, Menus, Buttons, AppEvnts,
  Quorid2, Quorid3, Quorid4, Ufinjeu;

type
  Tmurs = record
            cout : integer;
            cl,lg,sn : byte;
          end;

  TForm1 = class(TForm)
    Panel1: TPanel;
    Plato: TImage;
    PionR: TImage;
    PionV: TImage;
    Panel2: TPanel;
    BNouveau: TButton;
    PMess: TPanel;
    Pmenu: TPanel;
    SBrot: TSpeedButton;
    SBok: TSpeedButton;
    SBex: TSpeedButton;
    BAide: TButton;
    Imur1: TImage;
    Imur2: TImage;
    Pnb1: TPanel;
    Pnb2: TPanel;
    Timer1: TTimer;
    Pmes2: TPanel;
    SpeedButton1: TSpeedButton;

    procedure FormCreate(Sender: TObject);
    procedure PlatoMouseUp(Sender: TObject; Button: TMouseButton;
              Shift: TShiftState; X, Y: Integer);
    function  CaseOk(x,y :integer) : boolean;
    procedure AffichePion(no,sp : byte);
    procedure InitPlato;
    procedure DessineMur;
    procedure Init;
    procedure MajCarte(no : byte; des : boolean);
    function  TypeCase(x, y: Integer): integer;
    procedure BQuitterClick(Sender: TObject);
    procedure BNouveauClick(Sender: TObject);
    procedure Gagne(nj : byte);
    procedure Joueur1;
    procedure Joueur2;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SBexClick(Sender: TObject);
    procedure DecompteMur(jr : byte);
    procedure SBokClick(Sender: TObject);
    procedure SBrotClick(Sender: TObject);
    function  MurOk : boolean;
    procedure Timer1Timer(Sender: TObject);
    function  Ligne0 : boolean;
    function  Ligne14 : boolean;
    function  PivotValide(cl,lg,sn : byte) : boolean;
    procedure BAideClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

uses USplash;

{$R *.dfm}

{ Le plateau de jeu comporte 9x9 cases sur lesquelles se déplacent les pions.
  entre ces cases s'intercalent des cases plus étroites qui reçoivent les murs,
  ce qui nous donne un espace de jeu de 17x17 cases.
  L'intersection des cases mur, horizontales et verticales, appelée pivot,
  permet de choisir l'emplacement d'un mur qui se répartit de part et d'autre de
  ce pivot.
  La géographie un peu particulière du terrain de jeu ne facilite pas la lecture
  de ce programme.
  Ce programme a pû être réalisé grâce à l'algorithme A* de Neodelphi, car le
  seul critère pour déterminer le jeu de l'ordinateur est la longueur du chemin
  à parcourir. Comparé à celui du joueur, il permet de choisir entre le
  déplacement du pion et la pose d'un mur.
}
var
  tbPivot : array[0..7,0..7] of byte;
  clmap,lgmap,         // colonne,ligne dans la carte
  lig, col : byte;     // colonne,ligne secteur
  cx,cy : integer;
  typcas : byte;       // 1 = pion / 2 = pivot
  tx,ty : array[0..8] of integer;  // coordonnées des murs
  prepos1,prepos2,
  posPion1,posPion2 : TPoint;      // position des pions
  stop1,stop2 : integer;           // lignes d'arrivée
  joueur : byte;                   // joueur en cours
  finjeu : boolean;
  mur1,mur2 : integer;             // nbre de murs par joueurs
  cout2,
  db,tscou,tsx,tsy : integer;
  tsens : byte;  // 1 : horizontal / 2 : vertical
  tbmurs : array[1..81] of Tmurs;
  imur : byte;
  debut : boolean = true;

procedure TForm1.FormCreate(Sender: TObject);
var  i : byte;
begin
  sleep(2000);
  FSplash.free;
  Form1.DoubleBuffered := true;
  Randomize;
  tx[0] := 4;
  ty[0] := 4;
  for i := 1 to 8 do
  begin
    tx[i] := tx[i-1] + 48;
    ty[i] := ty[i-1] + 48
  end;
   // Initialise les listes de recherche
  lesCases := TAStarList.Create;
  leChemin := TAStarList.Create;
  macase := TAStarcell.Create;
  stop1 := 16;
  stop2 := 0;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  macase.Free;
  leChemin.Free;
  lesCases.Free;
  FAstar.FreeImages;
end;

procedure TForm1.BQuitterClick(Sender: TObject);
begin

end;

//******************************************************************************
// Initialisation du programme
//******************************************************************************
procedure TForm1.Init;
var  x,y : byte;
begin
  if debut then FAstar.InitImages;
  debut := false;
  // Certaines cases seront toujours des murs.  Gilles.
  for x := 0 to 16 do
    for y := 0 to 16 do
      if TypeCase(x,y) = 2 then carte[x,y] := 1
      else carte[x,y] := 0;
  for x := 0 to 8 do
    for y := 0 to 8 do
      tbPivot[x,y] := 0;
  for y := 0 to 9 do
  begin
    Imur1.Canvas.Draw(0,y * 20,murP);
    Imur2.Canvas.Draw(0,y * 20,murP);
  end;
  mur1 := 10;
  mur2 := 10;
  Pnb1.Top := 225;
  Pnb2.Top := 200;
  Pnb1.Caption := '10';
  Pnb2.Caption := '10';
  finjeu := false;
  posPion1 := Point(8,0);
  posPion2 := Point(8,16);
  InitPlato;
  AffichePion(1,0);
  AffichePion(2,0);
  joueur := random(2)+1;
  db := joueur;
end;

procedure TForm1.BNouveauClick(Sender: TObject);
begin
  Init;
  if joueur = 1 then Joueur1;
  PMess.Caption := 'A vous de jouer';
end;

function TForm1.Ligne0 : boolean;
var  i,v,c : byte;
begin
  Result := false;
  if posPion1.Y = 0 then cy := 0
  else cy := posPion1.Y div 2;
  for i := 0 to 7 do                 // test mur vertical sur le trajet
    if tbPivot[i,cy] = 2 then exit
    else if (cy > 0) and (tbPivot[i,cy-1] = 2) then exit;
  v := 0;
  for i := 0 to 7 do
    if tbPivot[i,cy] = 1 then
    begin
      v := i;
      break;
    end;
  if v = 0 then exit;
  prepos1 := posPion1;
  cx := prepos1.X;
  if carte[cx,prepos1.Y+1] = 0 then exit;  // chemin vers le bas libre
  if Odd(v) then
  begin
    if cx > 0 then
    begin
      dec(cx,2);
      Result := true;
    end;
  end
  else
    if cx < 16 then
    begin
      inc(cx,2);
      Result := true;
    end;
  if Result then               // Chemin proposé plus long ?
  begin
    CheminOk(posPion1,stop1);
    c := cout;
    prepos1.X := cx;
    CheminOk(prepos1,stop1);
    if cout > c then Result := false;
    if (prepos1.X = pospion2.X) and    // Pion devant
       (prepos1.Y = posPion2.Y) then Result := false;
  end;
end;

function TForm1.Ligne14 : boolean;
begin
  Result := false;
  if (posPion1.Y = 12) and          // Test pion 1 en ligne 12
     (posPion2.Y = 14) and (posPion2.X = posPion1.X) and
     (carte[posPion1.X,13] = 0) and
     (carte[posPion1.X,15] = 0) then Result := true
  else if (posPion1.Y = 14) and          // Test pion 1 en ligne 14
          ((posPion2.Y < 16) or (posPion2.X <> posPion1.X)) and
          (carte[posPion1.X,15] = 0) then Result := true
       else if (posPion1.Y = 14) and          // Test pion2 en ligne 16
               (posPion2.Y = 16) and (posPion2.X = posPion1.X) then
            begin
              if posPion1.X > 0 then dec(posPion1.X)
              else inc(posPion1.X);
              Result := true;
            end;
end;

procedure TForm1.Joueur1;        // Jeu de l'ordinateur
begin
  if finjeu then exit;
  PMess.Caption := 'A mon tour';
  PMess.Repaint;
  if Ligne14 then
  begin
    posPion1.Y := stop1;
    AffichePion(1,5);
    Gagne(1);
    Exit;
  end;
  if posPion1.Y < 14 then
    if Ligne0 then              // Test côté barré
    begin
      posPion1 := prepos1;
      AffichePion(1,5);
      PMess.Caption := 'A vous de jouer';
      joueur := 2;
      Exit;
    end;
  CheminOk(posPion2,stop2);
  cout2 := cout;
  CheminOk(posPion1,stop1);
  if (propos.X = pospion2.X) and    // présence du pion adverse devant
     (propos.Y = posPion2.Y) then CheminOk(propos,stop1);
  CheminOk(propos,stop1);           // simule l'avance du pion1
  if (cout >= cout2) and (mur1 > 0) and
    ((cout2 < 9) or (mur1-mur2 > 0)) then
    if MurOk then
    begin
      col := tsx;
      lig := tsy;
      MajCarte(tsens,true);
      DecompteMur(1);
      PMess.Caption := 'A vous de jouer';
      Joueur := 2;
      exit;
    end;
  if CheminOk(posPion1,stop1) then     // Chemin le plus court
  begin
    if (propos.X = pospion2.X) and    // présence du pion adverse devant
       (propos.Y = posPion2.Y) then
      if not CheminOk(propos,stop1) then
      begin
        ShowMessage('Y a oun problemo !!!');
        Exit;
      end;
    posPion1 := propos;
    AffichePion(1,5);
  end
  else
    begin
      ShowMessage('Y a oun problemo !!!');
      Exit;
    end;
  PMess.Caption := 'A vous de jouer';
  Joueur := 2;
end;

procedure TForm1.Gagne(nj : byte);
begin
  if nj = 1 then DlgFin.Affiche(false)
  else DlgFin.Affiche(true);
  DlgFin.ShowModal;
  finjeu := true;
end;

procedure TForm1.Joueur2;
var  dif,x,y : integer;
begin
  dif := abs(prepos2.X - posPion2.X) + abs(prepos2.Y - posPion2.Y);
  if dif = 2 then        // déplacement 1 case seulement : doit être voisine
  begin
    x := (prepos2.X + posPion2.X) div 2;
    y := (prepos2.Y + posPion2.Y) div 2;
    if carte[x,y] > 0 then exit;          // test du mur
  end
  else
    begin
      if dif <> 4 then exit;
      dif := abs(prepos2.X - posPion1.X) + abs(prepos2.Y - posPion1.Y);
      if dif <> 2 then exit;
      x := (prepos2.X + posPion1.X) div 2;
      y := (prepos2.Y + posPion1.Y) div 2;
      if carte[x,y] > 0 then exit;
    end;
  posPion2 := prepos2;
  AffichePion(2,5);
  if posPion2.Y = stop2 then  // test fin gagné
  begin
//    repeat
//      Joueur1;
//    until finjeu;
    Gagne(2);
    exit;
  end;
  Joueur := 1;
  Joueur1;
end;

procedure TForm1.PlatoMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if finjeu then exit;
  if Pmenu.Visible then
    if Button = mbLeft then
    begin
      SBrotClick(Self);     // pivoter un mur
      exit;
    end
    else
      begin
        SBokClick(self);    // valider le mur
        exit;
      end;
  if not CaseOk(X,Y) then exit;   // Clic non valide
  if typcas = 1 then              // jeu du pion
  begin
    prepos2 := Point(col*2,lig*2);
    Joueur2;
  end;  
  if typcas = 2 then              // construire un mur
  begin
  //----------------test de validité du pivot
    if mur2 = 0 then exit;
    if tbPivot[col,lig] > 0 then exit;
    if PivotValide(col,lig,1) then
    begin
      MajCarte(1,true);
      if not CheminOk(posPion1,stop1)
      or not CheminOk(posPion2,stop2) then
      begin
        PMess.Caption := 'Barrage interdit';
        beep;
        if not PivotValide(col,lig,2) then
        begin                           // car mur horizontal déjà impossible...
          MajCarte(0,true);
          Exit;
        end;
        MajCarte(0,true);
      end;
    end;
    if tbPivot[col,lig] = 0 then
    begin
      if PivotValide(col,lig,2) then
      begin
        MajCarte(2,true);
        if not CheminOk(posPion1,stop1)
        or not CheminOk(posPion2,stop2) then
        begin
          PMess.Caption := 'Barrage interdit';
          beep;
          MajCarte(0,true);
          Exit;
        end;
      end;
    end;
    if lig > 4 then           // affichage du menu de boutons
      Pmenu.Top := cy
    else Pmenu.Top := cy + 70;
    if col > 4 then
      Pmenu.Left := cx - 50
    else Pmenu.Left := cx + 70;
    Pmenu.Visible := true;
  end;
end;

//******************************************************************************
// Doit retourner le type de cellule en fonction des coordonnées x,y
//  ( commence à 0,0 )
//  1 = cellule pion                  ==> x et y pairs
//  2 = cellule pivot de mur          ==> x et y impair
//  3 = mur entre les cellules pion   ==> les autres
//******************************************************************************
function TForm1.TypeCase(X: integer; Y: integer): integer;
begin
  result := 1;
  if odd(X) and odd(Y) then result := 2
  else
    if odd(X) or odd(y) then result := 3;
end;

procedure TForm1.InitPlato;    // Affiche l'image de fond
begin
  Plato.Canvas.CopyRect(Rect(0,0,449,449),FAstar.Image1.Canvas,
                        Rect(0,0,449,449));
end;

procedure TForm1.DessineMur;
var
  x, y: integer;
begin
  InitPlato;
  for x := 0 to 7 do
    for y := 0 to 7 do
      if tbPivot[x,y] = 1 then
        Plato.Canvas.Draw(tx[x],ty[y]+40,murH)
      else if tbPivot[x,y] = 2 then
             Plato.Canvas.Draw(tx[x]+40,ty[y],murV);
end;

procedure TForm1.AffichePion(no,sp : byte); // Déplacement d'un pion
var  xd,yd,xf,yf,ix,iy : integer;
begin
  if no = 1 then
  begin
    xf := tx[posPion1.X div 2]+17;
    yf := ty[posPion1.Y div 2]+9;
    xd := PionR.Left;
    yd := PionR.Top;
    ix := 1;
    if xf < xd then ix := -1;
    iy := 1;
    if yf < yd then iy := -1;
    repeat
      if xd <> xf then inc(xd,ix);
      PionR.Left := xd;
      if yd <> yf then inc(yd,iy);
      PionR.Top := yd;
      PionR.Repaint;
      sleep(sp);
    until (xd = xf) and (yd = yf);
  end
  else
    begin
      xf := tx[posPion2.X div 2]+17;
      yf := ty[posPion2.Y div 2]+9;
      xd := PionV.Left;
      yd := PionV.Top;
      ix := 1;
      if xf < xd then ix := -1;
      iy := 1;
      if yf < yd then iy := -1;
      repeat
        if xd <> xf then inc(xd,ix);
        PionV.Left := xd;
        if yd <> yf then inc(yd,iy);
        PionV.Top := yd;
        PionV.Repaint;
        sleep(sp);
      until (xd = xf) and (yd = yf);
    end;
end;

function TForm1.PivotValide(cl,lg,sn : byte) : boolean;
begin
  Result := true;
  case sn of
    1 : begin          // mur horizontal
          if cl = 0 then
          begin
            if tbPivot[cl+1,lg] = 1 then Result := false;
          end
          else
            if cl = 7 then
            begin
              if tbPivot[cl-1,lg] = 1 then Result := false;
            end
              else
                if (tbPivot[cl-1,lg] = 1)
                or (tbPivot[cl+1,lg] = 1) then Result := false;
        end;
    2 : begin          // mur vertical
          if lg = 0 then
          begin
            if tbPivot[cl,lg+1] = 2 then Result := false;
          end
          else
            if lg = 7 then
            begin
              if tbPivot[cl,lg-1] = 2 then Result := false;
            end
              else
                if (tbPivot[cl,lg-1] = 2)
                or (tbPivot[cl,lg+1] = 2) then Result := false;
        end;
  end;
end;

//******************************************************************************
// Mise à jour de la carte avec les murs
// no : type de mur / des : faut-il dessiner les murs ?
//******************************************************************************
procedure TForm1.MajCarte(no : byte; des : boolean);
var  x,y,cm,lm : byte;
     np : byte;
begin
  np := 0;
  if PivotValide(col,lig,no) then np := no;
  tbPivot[col,lig] := np;
  x := 1;                     // Raz de la carte
  repeat
    y := 1;
    repeat
      carte[x-1,y] := 0;
      carte[x+1,y] := 0;
      carte[x,y-1] := 0;
      carte[x,y+1] := 0;
      inc(y,2);
    until y > 15;
    inc(x,2);
  until x > 15;
  for x :=0 to 7 do         // mise en place des murs
  begin
    cm := x * 2 + 1;
    for y := 0 to 7 do
    begin
      lm := y * 2 + 1;
      if tbPivot[x,y] = 1 then
      begin
        carte[cm-1,lm] := 1;
        carte[cm+1,lm] := 1;
      end;
      if tbPivot[x,y] = 2 then
      begin
        carte[cm,lm-1] := 1;
        carte[cm,lm+1] := 1;
      end;
    end;
  end;
  if des then DessineMur;
end;

//******************************************************************************
// Validation d'une case clickée
//******************************************************************************
function TForm1.CaseOk(x,y :integer) : boolean;
var  tc : byte;
     sx,sy,px,py : integer;
begin
  sx := X-9;
  sy := Y-9;
  Result := false;
  if (x < 10) or (x > 433) then exit;
  if (y < 10) or (y > 433) then exit;
  tc := 0;
  col := sx div 48;    // calcul n° colonne
  lig := sy div 48;    // calcul n° ligne
  cx := 48 * col;     // base d'affichage secteur
  cy := 48 * lig;
  px := sx-cx;         // calcul position dans secteur
  py := sy-cy;
  clmap := col * 2;             // indices de la carte
  lgmap := lig * 2;
  if px > 40 then
  begin
    inc(tc);
    inc(clmap);
  end;
  if py > 40 then
  begin
    inc(tc);
    inc(lgmap);
  end;
  case tc of
    0 : typcas := 1;       // case pion
    1 : Exit;              // case mur
    2 : typcas := 2;       // case pivot
  end;
  Result := true;
end;

procedure TForm1.SBrotClick(Sender: TObject);    // Pivoter mur
begin
   if tbPivot[col,lig] = 1 then
   begin
     MajCarte(2,true);
     if not CheminOk(posPion1,stop1)
     or not CheminOk(posPion2,stop2) then
     begin
       PMess.Caption := 'Barrage interdit';
       beep;
       MajCarte(1,true);
       Exit;
     end;
   end
   else if tbPivot[col,lig] = 2 then
        begin
          MajCarte(1,true);
          if not CheminOk(posPion1,stop1)
          or not CheminOk(posPion2,stop2) then
          begin
            PMess.Caption := 'Barrage interdit';
            beep;
            MajCarte(2,true);
            Exit;
          end;
        end;
end;

procedure TForm1.SBokClick(Sender: TObject);     // Mur OK
begin
  DecompteMur(2);
  Pmenu.Visible := false;
  joueur := 1;
  Joueur1;
end;

procedure TForm1.SBexClick(Sender: TObject);     // Mur abandon
begin
  Pmenu.Visible := false;
  MajCarte(0,true);
end;

procedure TForm1.DecompteMur(jr : byte);
begin
  if jr = 1 then
  begin
    dec(mur1);
    Imur1.Canvas.Draw(0,mur1 * 20,vide);
    Pnb1.Caption := IntToStr(mur1);
    Pnb1.Top := Pnb1.Top - 20;
  end
  else
    begin
      Imur2.Canvas.Draw(0,(10-mur2) * 20,vide);
      dec(mur2);
      Pnb2.Caption := IntToStr(mur2);
      Pnb2.Top := Pnb2.Top + 20;
    end;
end;

function TForm1.MurOk : boolean;   // recherche du mur le plus gênant
var  x,y,cout0,cout1,cout2,mv,i : byte;
     cok1,cok2 : boolean;
     dif1, dif2 : integer;
begin
  CheminOk(posPion1,stop1);
  cout0 := cout;
  CheminOk(posPion2,stop2);
  tscou := cout;
  imur := 0;
  for x := 0 to 7 do
    for y := 0 to 7 do
      if tbPivot[x,y] = 0 then
      begin
        col := x;
        lig := y;
        Majcarte(2,false);                   // mur vertical
        cok1 := CheminOk(posPion1,stop1);
        cout1 := cout;
        cok2 := CheminOk(posPion2,stop2);
        cout2 := cout;
        dif1 := 0;
        if cok1 and cok2 then    // contrôle de NON barrage
        begin
          dif2 := cout2-cout1;
          if dif2 > dif1 then
          begin
            if CheminOk(posPion1,stop1) and
              (cout <= cout0) then
            begin
              dif1 := dif2;
              inc(imur);
              with tbmurs[imur] do
              begin
                cl := col;                 // on stocke les coordonnées
                lg := lig;
                sn := 2;
                cout := cout2;
              end;
            end;
          end;
          if cout2 > tscou then      // rallonge le chemin du joueur 2
          begin
            if CheminOk(posPion1,stop1) and
              (cout <= cout0) then
            begin
              inc(imur);
              with tbmurs[imur] do
              begin
                cl := col;                 // on stocke les coordonnées
                lg := lig;
                sn := 2;
                cout := cout2;
              end;
            end;
          end;
        end;
        Majcarte(1,false);                   // mur horizontal
        cok1 := CheminOk(posPion1,stop1);
        cout1 := cout;
        cok2 := CheminOk(posPion2,stop2);
        cout2 := cout;
        if cok1 and cok2 then    // contrôle de NON barrage
        begin
          dif2 := cout2-cout1;
          if dif2 > dif1 then
          begin
            if CheminOk(posPion1,stop1) and
              (cout <= cout0) then
            begin
              inc(imur);
              with tbmurs[imur] do
              begin
                cl := col;                 // on stocke les coordonnées
                lg := lig;
                sn := 1;
                cout := cout2;
              end;
            end;
          end;
          if cout2 > tscou then      // rallonge le chemin du joueur 2
          begin
            if CheminOk(posPion1,stop1) and
              (cout <= cout0) then
            begin
              inc(imur);
              with tbmurs[imur] do
              begin
                cl := col;                 // on stocke les coordonnées
                lg := lig;
                sn := 1;
                cout := cout2;
              end;
            end;
          end;
        end;
        Majcarte(0,false);                 // on efface le mur provisoire
      end;
  if imur = 1 then
    with tbmurs[1] do
    begin
      tscou := cout;
      tsx := cl;
      tsy := lg;
      tsens := sn;
      Result := true;
      exit;
    end;
  Result := false;
  if imur = 0 then exit;
  mv := 1;
  while mv > 0 do               // Tri descendant de tbmurs
  begin
    mv := 0;
    for i := 1 to imur-1 do
      if tbmurs[i+1].cout > tbmurs[i].cout then
      begin
        tbmurs[i] := tbmurs[i+1];
        inc(mv);
      end;
  end;
  while tbmurs[imur].cout <> tbmurs[1].cout do
    dec(imur);
  if imur > 1 then
    i := random(imur)+1        // choix aléatoire d'une solution
  else i := 1;
  with tbmurs[i] do
  begin
    tscou := cout;
    tsx := cl;
    tsy := lg;
    tsens := sn;
    Result := true;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := false;
  BNouveauClick(self);
end;

procedure TForm1.BAideClick(Sender: TObject);
begin
  Regles.Show;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  Apropos.Show;
end;

end.

