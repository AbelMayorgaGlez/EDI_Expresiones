unit ExprParser;
{$H-}

interface

uses
	ExprShared, ExprTree;

// BEGIN EP-OPS
{ Crea el árbol para la expresión dada }
function ParseExpr(var E : String) : Expr;
// END EP-OPS	

implementation

{ manejo de la cadena a analizar (SkipUpTo, Skip, SkipOne, etc.) }
function SkipUpTo(var E : String; D : String) : String;
begin
	SkipUpTo:='';
	
	while ((E <> '') and (Pos(E[1],D) = 0)) do
	begin
		SkipUpTo:=SkipUpTo + E[1];
		E:=Copy(E,2,Length(E));
	end;
end;

function Skip(var E : String; D : String) : String;
begin
	Skip:='';
	
	while ((E <> '') and (Pos(E[1],D) <> 0)) do
	begin
		Skip:=Skip + E[1];
		E:=Copy(E,2,Length(E));
	end;
end;

function SkipOne(var E : String; D : String) : String;
begin
	SkipOne:='';
	
	if ((E <> '') and (Pos(E[1],D) <> 0)) then
	begin
		SkipOne:=SkipOne + E[1];
		E:=Copy(E,2,Length(E));
	end;
end;

function SkipPast(var E : String; D : String) : String;
begin
	SkipPast:=SkipUpTo(E,D);
	SkipPast:=SkipPast + Skip(E,D);
end;

function ParseExpr(var E : String) : Expr;
var
	X : Expr; { resultado }
begin
	if (Pos('{',E) = 1) then
	begin
		{ lista }
		X:=AllocExpr('List', '');
		{ salta apertura }
		SkipUpTo(E,'{'); SkipOne(E, '{');
		{ analiza elementos de la lista }
		while (E[1] <> '}') do
		begin
			{ recursivo }
			AddSubExpr(ParseExpr(E), X);
		end;
		{ salta cierre }
		SkipOne(E,'}');
		{ salta posible coma }
		SkipOne(E, ',');
	end
	else
	begin
		{ terminal }
		X:=AllocExpr('Symbol', SkipUpTo(E,'[,]}'));
		{ salta posible coma }
		SkipOne(E,',');
		{ tiene []? }
		if (E[1] = '[') then
		begin
			{ entonces Head es lo que había antes de [ }
			X^.Head:=X^.Terminal; X^.Terminal:='';
			{ salta apertura }
			Skip(E,'[');
			{ analiza secuencia dentro de [] }
			while(E[1] <> ']') do
			begin
				{ recursivo }
				AddSubExpr(ParseExpr(E), X);				
			end;
			{ salta cierre }
			SkipOne(E,']');
			{ salta posible coma }
			SkipOne(E,',');
		end;
	end;
	
	ParseExpr:=X;
end;

begin
end.	
