unit CoreFunctions;
{$H-}

interface

uses
	ExprShared, ExprTree, SysUtils, Math;
	
{ Utilidades }
// BEGIN CFS
{ Devuelve una copia completa de la expresi�n dada.

	+ Esta operaci�n es fundamental, porque permite gestionar la memoria din�mica.
	
		En una operaci�n a implementar, "function F(E : Expr) : Expr",
		la memoria din�mica de E est� fuera de nuestro control; podr�a pasar que fuera
		eliminada nada m�s terminar el subprograma F.
		
		Si hay que usar partes de E para el resultado, habr� que a�adir copias � nuevas
		expresiones, no se pueden a�adir referencias (punteros) a expresiones en E.
		
		Si se usaran referencias, apuntar�an a la misma expresi�n, y al ser E eliminada,
		el resultado (o parte de �l) ser�a destru�do.
}
function DeepCopy(X : Expr) : Expr;

{ Devulve cierto si X1 y X2 son iguales (sin pasarlas a cadena de caracteres) }
function Equals(X1, X2 : Expr) : Boolean;

{�Compara dos expresiones y devuelve '<', '=' � '>' seg�n sean X1,X2 }
function ExprCmp(X1, X2 : Expr) : Char;
// END CFS

{ devuelve el n�mero de sub-expresiones de X }
function LengthOf(X : Expr) : Word;

function CartesianProduct(X1, X2 : Expr; var ec : TException) : Expr;

implementation


{
	Recursiva.
		+ DeepCopy(X) devuelve una copia del �rbol con X como ra�z.
			+ �se problema se resuelve (1) copiando la ra�z y (2) a�adiendo
			al nuevo nodo ra�z copias de cada sub-expresi�n de X.
			
			+ Para el paso (2), se vuelve a usar DeepCopy; el sub-�rbol es
			de menor profundidad, por lo que el problema es m�s peque�o.
			
			+ El caso b�sico es una expresi�n sin sub-expresiones, en la
			que el lazo while no hace nada.
			
		+ Se usa un iterador k para moverse por las sub-expresiones de X.
		
		+ Si X es Nil, devuelve Nil.
}
function DeepCopy(X : Expr) : Expr;
var
	k : TExprIt;
begin
	if (X <> Nil) then
	begin
		{�Copia los datos de la ra�z }
		DeepCopy:=AllocExpr(X^.Head, X^.Terminal);
		{ Recorre con k la lista de sub-expresiones }
		MoveToFirst(X^.SubExprs, k);		
		while (IsAtNode(k)) do
		begin
			{�A�ade al resultado una copia de cada sub-expresi�n de X }
			AddSubExpr(DeepCopy(ExprAt(k)), DeepCopy);
			{ Mueve el iterador al siguiente elemento de la lista }
			MoveToNext(k);
		end;
	end
	else
		DeepCopy:=Nil;
end;

{
	Usa la operaci�n del TAD lista de expresiones.
}
function LengthOf(X : Expr) : Word;
begin
	LengthOf:=LengthOfTExprList(X^.SubExprs);
end;

{
	Recursiva : X1 y X2 son iguales si sus �rboles de expresi�n son iguales.
		+ Mismo nodo ra�z.
		+ Sus sub-expresiones son iguales (recursividad directa) � no tienen.
}
function Equals(X1, X2 : Expr) : Boolean;
var
	kX1, kX2 : TExprIt;
begin
	{ si Head y Terminal son iguales ... }
	if ((X1^.Head = X2^.Head) and (X1^.Terminal = X2^.Terminal)) then
	begin
		Equals:=True;
		{ ... y tienen el mismo n�mero de sub-expresiones ... }
		if (LengthOf(X1) = LengthOf(X2)) then
		begin
			MoveToFirst(X1^.SubExprs, kX1);
			MoveToFirst(X2^.SubExprs, kX2);			
			{ ... y ... }
			while (IsAtNode(kX1) and IsAtNode(kX2)) do
			begin
				{ ... cada sub-expresi�n es igual ... }
				Equals:=Equals and Equals(ExprAt(kX1),ExprAt(kX2));
			
				MoveToNext(kX1);
				MoveToNext(kX2);				
			end;
		end
		else
			{ diferente n�mero de sub-expresiones }
			Equals:=False;
	end
	else
		{ ni siquiera Head y Terminal son iguales }
		Equals:=False;
end;


{
	+ Si X1 y X2 son s�mbolos, se comparan sus terminales.
		+ Por ejemplo, X < Z
		
	+ Si s�lo una es s�mbolo, es la menor de las dos.
		+ Por ejemplo, X < Cos[Z], x < List[x]
		
	+ En otro caso, se comparan las cabeceras.
		+ Si no son iguales, establecen el orden.
			+ Cos[x] < Sin[z]
			
		+ Si son iguales, la primera sub-expresi�n diferente establece el orden.
			+ Si es necesario, la de menor longitud ser� la menor.
			
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
					{�avanza en ambas listas mientras haya elementos y sean iguales }
					while (IsAtNode(X1i) and IsAtNode(X2i) and (ExprCmp(ExprAt(X1i),ExprAt(X2i)) = '=')) do
					begin
						MoveToNext(X1i);
						MoveToNext(X2i);
					end;
					{ si (1) ambas terminaron � (2) se encontraron sub-expresiones diferentes }
					if (not (IsAtNode(X1i) xor IsAtNode(X2i))) then
					begin
						if (IsAtNode(X1i) and IsAtNode(X2i)) then
							{ (2) �sa determina el orden }
							ExprCmp:=ExprCmp(ExprAt(X1i),ExprAt(X2i))
						else
							{ (1) de igual longitud y todas las sub-expresiones iguales }
							ExprCmp:='=';
					end
					else
						if (not IsAtNode(X1i)) then
							{ la primera se termin� y la segunda no }
							ExprCmp:='<'
						else
							{ la segunda es m�s corta }
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
	{ �rbol para el resultado ; es una lista }
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
			{ a�ade sub-expresi�n a GP }			
			{ la memoria din�mica de ExprAt(X1i) pertenece a X1, hay que hacer una copia }
			AddSubExpr(DeepCopy(ExprAt(X1i)), GP);
			{ la memoria din�mica de ExprAt(X2i) pertenece a X2, hay que hacer una copia }
			AddSubExpr(DeepCopy(ExprAt(X2i)), GP);
			// el par {X1i,X2i} se a�ade al resultado
			AddSubExpr(GP, CP);
			{ siguiente sub-expresi�n de X2 }
			MoveToNext(X2i);
		end;
		{ siguiente sub-expresi�n de X1 }
		MoveToNext(X1i);		
	end;
	{ resultado final }
	CartesianProduct:=CP;
end;

begin
end.
