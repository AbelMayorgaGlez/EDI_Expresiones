unit CoreFunctions;
{$H-}

interface

uses
	ExprShared, ExprTree, SysUtils, Math;
	
{ Utilidades }
// BEGIN CFS
{ Devuelve una copia completa de la expresión dada.

	+ Esta operación es fundamental, porque permite gestionar la memoria dinámica.
	
		En una operación a implementar, "function F(E : Expr) : Expr",
		la memoria dinámica de E está fuera de nuestro control; podría pasar que fuera
		eliminada nada más terminar el subprograma F.
		
		Si hay que usar partes de E para el resultado, habrá que añadir copias ó nuevas
		expresiones, no se pueden añadir referencias (punteros) a expresiones en E.
		
		Si se usaran referencias, apuntarían a la misma expresión, y al ser E eliminada,
		el resultado (o parte de él) sería destruído.
}
function DeepCopy(X : Expr) : Expr;

{ Devulve cierto si X1 y X2 son iguales (sin pasarlas a cadena de caracteres) }
function Equals(X1, X2 : Expr) : Boolean;

{ Compara dos expresiones y devuelve '<', '=' ó '>' según sean X1,X2 }
function ExprCmp(X1, X2 : Expr) : Char;
// END CFS

{ devuelve el número de sub-expresiones de X }
function LengthOf(X : Expr) : Word;

function CartesianProduct(X1, X2 : Expr; var ec : TException) : Expr;

implementation


{
	Recursiva.
		+ DeepCopy(X) devuelve una copia del árbol con X como raíz.
			+ Ése problema se resuelve (1) copiando la raíz y (2) añadiendo
			al nuevo nodo raíz copias de cada sub-expresión de X.
			
			+ Para el paso (2), se vuelve a usar DeepCopy; el sub-árbol es
			de menor profundidad, por lo que el problema es más pequeño.
			
			+ El caso básico es una expresión sin sub-expresiones, en la
			que el lazo while no hace nada.
			
		+ Se usa un iterador k para moverse por las sub-expresiones de X.
		
		+ Si X es Nil, devuelve Nil.
}
{Devuelve una expresión que es una copia exacta de X}
function DeepCopy(X : Expr) : Expr;
	Var
		k:TExprIt;
		Nuevo:Expr;
	Begin
		If (X=NIL)
			Then
				DeepCopy:=NIL
			Else
				Begin
					Nuevo:=AllocExpr(X^.Head,X^.Terminal);{Copia el nodo raíz}
					MoveToFirst(X^.SubExprs,k);
					While (IsAtNode(k)) Do{Copia todos los hijos y los añade a la expresión copiada}
						Begin
							InsertAsLast(Nuevo^.SubExprs,DeepCopy(ExprAt(k)));
							MoveToNext(k);
						End;
					DeepCopy:=Nuevo;
				End;
	End;

{
	Usa la operación del TAD lista de expresiones.
}
function LengthOf(X : Expr) : Word;
begin
	LengthOf:=LengthOfTExprList(X^.SubExprs);
end;

{
	Recursiva : X1 y X2 son iguales si sus árboles de expresión son iguales.
		+ Mismo nodo raíz.
		+ Sus sub-expresiones son iguales (recursividad directa) ó no tienen.
}

{Compara las dos expresiones y devuelve cierto si son iguales}
function Equals(X1, X2 : Expr) : Boolean;
	Var
		k,j:TExprIt;
	Begin
		Equals:=True;
		If(X1=NIL)XOr(X2=NIL) {Si solo uno de las dos expresiones está vacía, son distintas}
			Then Equals:=False
			Else Begin
				If(ExprCmp(X1,X2)<>'=')
					Then Equals:=False
					Else Begin
						MoveToFirst(X1^.SubExprs,k);
						MoveToFirst(X2^.SubExprs,j);
						While(IsAtNode(k))And(IsAtNode(j)) Do {Compara las subexpresiones de las expresiones pasadas}
							Begin
								Equals:=(Equals) And (Equals(ExprAt(k),ExprAt(j)));
								MoveToNext(k);
								MoveToNext(j);
							End;
						If(IsAtNode(k))xor(IsAtNode(j)) {Si ha acabado de recorrer una subexpresión antes que otra, entonces son distintos}
							Then Equals:=False;
						End;
				End;
	End;

{
	+ Si X1 y X2 son símbolos, se comparan sus terminales.
		+ Por ejemplo, X < Z
		
	+ Si sólo una es símbolo, es la menor de las dos.
		+ Por ejemplo, X < Cos[Z], x < List[x]
		
	+ En otro caso, se comparan las cabeceras.
		+ Si no son iguales, establecen el orden.
			+ Cos[x] < Sin[z]
			
		+ Si son iguales, la primera sub-expresión diferente establece el orden.
			+ Si es necesario, la de menor longitud será la menor.
			
			+ Cos[a] < Cos[b], List[a,b,c] < List[a,b,x], List[a,b] < List[a,b,c]
}
function ExprCmp(X1, X2 : Expr) : Char;

function StrCmp(S1, S2 : String) : Char;
begin
	if (S1 < S2) then StrCmp:='<';
	if (S1 = S2) then StrCmp:='=';
	if (S1 > S2) then StrCmp:='>';
end;
	
var
	X1i, X2i : TExprIt;
begin
	if ((X1^.Head = 'Symbol') and (X2^.Head = 'Symbol')) then
		ExprCmp:=StrCmp(X1^.Terminal, X2^.Terminal)
	else
	begin
		if (X1^.Head = 'Symbol') then
			ExprCmp:='<'
		else if (X2^.Head = 'Symbol') then
			ExprCmp:='>'
		else
		begin
			case StrCmp(X1^.Head,X2^.Head) of
				'<': begin
					ExprCmp:='<';
				end;
				'=': begin
					MoveToFirst(X1^.SubExprs, X1i);
					MoveToFirst(X2^.SubExprs, X2i);
					{ avanza en ambas listas mientras haya elementos y sean iguales }
					while (IsAtNode(X1i) and IsAtNode(X2i) and (ExprCmp(ExprAt(X1i),ExprAt(X2i)) = '=')) do
					begin
						MoveToNext(X1i);
						MoveToNext(X2i);
					end;
					{ si (1) ambas terminaron ó (2) se encontraron sub-expresiones diferentes }
					if (not (IsAtNode(X1i) xor IsAtNode(X2i))) then
					begin
						if (IsAtNode(X1i) and IsAtNode(X2i)) then
							{ (2) ésa determina el orden }
							ExprCmp:=ExprCmp(ExprAt(X1i),ExprAt(X2i))
						else
							{ (1) de igual longitud y todas las sub-expresiones iguales }
							ExprCmp:='=';
					end
					else
						if (not IsAtNode(X1i)) then
							{ la primera se terminó y la segunda no }
							ExprCmp:='<'
						else
							{ la segunda es más corta }
							ExprCmp:='>';
				end;
				'>': begin
					ExprCmp:='>';
				end;
			end;
		end;
	end;		
end;

function CartesianProduct(X1, X2 : Expr; var ec : TException) : Expr;
var
	CP, GP : Expr; X1i, X2i : TExprIt;
begin
	{ árbol para el resultado ; es una lista }
	CP:=AllocExpr('List','');	
	{ para cada sub-expr de X1 }
	MoveToFirst(X1^.SubExprs, X1i);	
	while (IsAtNode(X1i)) do
	begin
		{ para cada sub-expr de X2 }
		MoveToFirst(X2^.SubExprs, X2i);	
		while (IsAtNode(X2i)) do
		begin
			// sub-lista para el resultado, con el par GP={X1i,X2i}
			GP:=AllocExpr('List','');
			{ añade sub-expresión a GP }			
			{ la memoria dinámica de ExprAt(X1i) pertenece a X1, hay que hacer una copia }
			AddSubExpr(DeepCopy(ExprAt(X1i)), GP);
			{ la memoria dinámica de ExprAt(X2i) pertenece a X2, hay que hacer una copia }
			AddSubExpr(DeepCopy(ExprAt(X2i)), GP);
			// el par {X1i,X2i} se añade al resultado
			AddSubExpr(GP, CP);
			{ siguiente sub-expresión de X2 }
			MoveToNext(X2i);
		end;
		{ siguiente sub-expresión de X1 }
		MoveToNext(X1i);		
	end;
	{ resultado final }
	CartesianProduct:=CP;
end;

begin
end.
