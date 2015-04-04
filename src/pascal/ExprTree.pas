unit ExprTree;
{$H-}
interface

uses
	SysUtils, ExprShared;

// BEGIN ES-TYPE
type
	{ TAD Expresión Simbólica - definición adelantada }
	Expr = ^TExpr;
	
	{ TAD - Lista de expresiones }
	
	{ nodo en la lista }
	PNodoExprList = ^TNodoExprList;
	TNodoExprList = record
		Element : Expr;
		{ doblemente enlazada }
		Siguiente, Previo : PNodoExprList;
	end;

	{ lista }
	TExprList = record
		Primero, Ultimo : PNodoExprList;
		nNodos : Word;
	end;

	{ iterador sobre la lista }
	TExprIt = record
		Nodo : PNodoExprList;
	end;
	
	{ TAD Expresión Simbólica - definición de tipos }
	
	TExpr = record
		Head : String; Terminal : String; SubExprs : TExprList;
	end;
// END ES-TYPE

// BEGIN ES-OPS

{ Operaciones del TAD Expresión Simbólica }

{ Nueva expresión simbólica inicializada con los valores dados.

	+ Head - valor para el campo cabecera de la expresión.
	+ Terminal - valor para el campo terminal de la expresión.
	+ La lista de sub-expresiones se inicializa a lista vacía.
	
	+ El cliente es responsable de la memoria dinámica del resultado.
}
function AllocExpr(Head : String; Terminal : String) : Expr;

{ Libera la memoria dinámica asociada a la expresión y a sus sub-expresiones.

	+ X - expresión simbólica a eliminar.
	
	+ Post(1) - (X = Nil)
}
procedure ReleaseExpr(var X : Expr);

{ Añade una expresión como última sub-expresión.

	+ X - expresión a añadir como sub-expresión.
	+ ToExpr - expresión padre.
}
procedure AddSubExpr(X : Expr; var ToExpr : Expr);

{ Convierte la expresión en su representación como cadena de caracteres }
function ExprToStr(X : Expr) : String;

{ Muestra en la salida estándar el árbol (ASCII) de la expresión dada }
procedure TreeForm(X : Expr);

{ Muestra en la salida estándar el código LaTeX para representar la expresión }
procedure QTreeForm(X : Expr; var ec : TException);
// END ES-OPS

// BEGIN LE-OPS
{ TAD lista expresiones }

{ inicializa la lista a vacía }
procedure InitTExprList(var L : TExprList);

{ elimina todos los nodos y expresiones }
procedure ReleaseElementsInTExprList(var L : TExprList);

{ inserta un nuevo nodo como primero de la lista }
procedure InsertAsFirst(var L : TExprList; x : Expr);

{ inserta un nuevo nodo como último }
procedure InsertAsLast(var L : TExprList; x : Expr);

{ devuelve cierto si la lista está vacía }
function IsEmptyTExprList(L : TExprList) : Boolean;

{ longitud de la lista }
function LengthOfTExprList(L : TExprList) : Word;

{ Iteradores }

{ iterador - sitúa k sobre el primer nodo de la lista }
procedure MoveToFirst(L : TExprList; var k : TExprIt);

{ iterador - sitúa k sobre el último nodo de la lista }
procedure MoveToLast(L : TExprList; var k : TExprIt);

{ iterador - desplaza k a la derecha }
procedure MoveToNext(var k : TExprIt);

{ iterador - desplaza k a la izquierda }
procedure MoveToPrevious(var k : TExprIt);

{ iterador - devuelve cierto si k está sobre un nodo de la lista }
function IsAtNode(k : TExprIt) : Boolean;

{ iterador - devuelve la expresión almacenada en el nodo sobre el que está k }
function ExprAt(k : TExprIt) : Expr;

{ iterador - elimina el nodo de la lista sobre el que está k ; devuelve la expresión que almacenaba }
{ (esa expresión tendrá que ser gestionada por el cliente - usada, liberada su memoria, etc.) }
function RemoveNodeAt(var L : TExprList; var k : TExprIt) : Expr;

{ iterador - elimina el nodo de la lista sobre el que está k y elimina la expresión que almacenaba }
procedure RemoveNodeAndReleaseExprAt(var L : TExprList; var k : TExprIt);

{ intercambia la expresión en el nodo sobre el que está el iterador ; devuelve la expresión sustituída }
{ (la expresión devuelta tendrá que ser gestionada por el cliente - usada, liberada su memoria, etc.) }
function SwitchExprAt(k : TExprIt; WithExpr : Expr) : Expr;

{ inserta una expresión X en la lista, delante del nodo sobre el que está el iterador }
procedure InsertBefore(k : TExprIt; var InList : TExprList; X : Expr);

{ indexación en listas }

{ Nota: recorrer la lista es más eficiente con iteradores.
	
	MoveToFirst(L,k);
	while(IsAtNode(k)) do
	begin
		// ... procesar expresión en el nodo k-ésimo ...
		MoveToNext(k);
	end;
	
	es más eficiente que
	
	for i:=1 to LengthOfTExprList(L) do
	begin
		// ... procesar ExprAtIndex(L,i) ...
	end;
	
	porque ExprAtIndex(L,n) sitúa un iterador al principio y avanza n veces
}
function ExprAtIndex(L : TExprList; n : Word) : Expr;

{ desplaza el iterador k a la posición n-ésima de la lista }
procedure MoveToIndex(L : TExprList; var k : TExprIt; n : Word);
// END LE-OPS

{ ------------------------------------------------------------------------------------------------------- }
implementation


{ TAD Lista de Expresiones Simbólicas }

procedure InitTExprList(var L : TExprList);
begin
	L.Primero:=Nil; L.Ultimo:=Nil; L.nNodos:=0;
end;

procedure ReleaseElementsInTExprList(var L : TExprList);
var
	P : PNodoExprList;
	G : Expr;
begin
	while (L.Primero <> Nil) do
	begin
		P:=L.Primero; L.Primero:=L.Primero^.Siguiente;
		
		G:=P^.Element;
		{ elimina el dato del usuario } ReleaseExpr(G);
		{ elimina el nodo de la lista } Dispose(P); P:=Nil;
	end;
	
	L.nNodos:=0; L.Ultimo:=Nil;
end;

function IsEmptyTExprList(L : TExprList) : Boolean;
begin
	IsEmptyTExprList:=(L.nNodos = 0);
end;

function LengthOfTExprList(L : TExprList) : Word;
begin
	LengthOfTExprList:=(L.nNodos);
end;

procedure InsertAsFirst(var L : TExprList; x : Expr);
var
	Nuevo : PNodoExprList;
begin
	if (L.Primero <> Nil) then
	begin
		{ no vacia }
		New(Nuevo); Nuevo^.Element:=x;
		{ punteros }
		Nuevo^.Siguiente:=L.Primero; L.Primero^.Previo:=Nuevo;
		Nuevo^.Previo:=Nil;
		
		L.Primero:=Nuevo;
		
		L.nNodos:=L.nNodos + 1;
	end
	else
	begin
		{ vacia }
		New(Nuevo); Nuevo^.Element:=x;
		{ punteros }
		Nuevo^.Siguiente:=Nil; Nuevo^.Previo:=Nil;
		
		L.Primero:=Nuevo; L.Ultimo:=Nuevo;
		
		L.nNodos:=1;
	end;
end;

procedure InsertAsLast(var L : TExprList; x : Expr);
var
	Nuevo : PNodoExprList;
begin
	if (L.Ultimo <> Nil) then
	begin
		{ no vacia }
		New(Nuevo); Nuevo^.Element:=x;
		{ punteros }
		Nuevo^.Siguiente:=Nil; L.Ultimo^.Siguiente:=Nuevo;
		Nuevo^.Previo:=L.Ultimo;
		
		L.Ultimo:=Nuevo;
		
		L.nNodos:=L.nNodos + 1;
	end
	else
	begin
		{ vacia }
		New(Nuevo); Nuevo^.Element:=x;
		{ punteros }
		Nuevo^.Siguiente:=Nil; Nuevo^.Previo:=Nil;
		
		L.Primero:=Nuevo; L.Ultimo:=Nuevo;
		
		L.nNodos:=1;
	end;
end;

{ ------------------------------------------------------------------------------------------------------- }

{ Iteradores sobre listas de expresiones }

procedure MoveToFirst(L : TExprList; var k : TExprIt);
begin
	k.Nodo:=L.Primero;
end;

procedure MoveToLast(L : TExprList; var k : TExprIt);
begin
	k.Nodo:=L.Ultimo;
end;

procedure MoveToNext(var k : TExprIt);
begin
	if (k.Nodo <> Nil) then
		k.Nodo:=k.Nodo^.Siguiente;
end;

procedure MoveToPrevious(var k : TExprIt);
begin
	if (k.Nodo <> Nil) then
		k.Nodo:=k.Nodo^.Previo;
end;

function IsAtNode(k : TExprIt) : Boolean;
begin
	IsAtNode:=(k.Nodo <> Nil);
end;

function ExprAt(k : TExprIt) : Expr;
begin
	if (k.Nodo <> Nil) then
		ExprAt:=(k.Nodo^.Element)
	else
		ExprAt:=Nil;
end;

procedure RemoveNodeAndReleaseExprAt(var L : TExprList; var k : TExprIt);
var
	A : Expr;
begin
	A:=RemoveNodeAt(L,k); ReleaseExpr(A);
end;

function RemoveNodeAt(var L : TExprList; var k : TExprIt) : Expr;
var
	NuevoK : PNodoExprList;
begin
	if (IsAtNode(k)) then
	begin
		if (L.nNodos > 1) then
		begin
			{ al menos dos nodos }
			if (L.Ultimo = k.Nodo) then
			begin
				{ borrar el último, mover k al siguiente (nil) }
				
				L.Ultimo:=L.Ultimo^.Previo; { existe #nodos > 1 }
				L.Ultimo^.Siguiente:=Nil;
				
				NuevoK:=Nil;
			end
			else
				if (L.Primero = k.Nodo) then
				begin
					{ borrar el primero, mover al siguiente }
					L.Primero:=L.Primero^.Siguiente; { existe, #nodos > 1 }
					L.Primero^.Previo:=Nil;
					
					NuevoK:=L.Primero;
				end
				else
				begin
					{ borrar nodo interno, mover al siguiente }
					Assert (L.nNodos > 2);
					
					k.Nodo^.Previo^.Siguiente:=k.Nodo^.Siguiente;
					k.Nodo^.Siguiente^.Previo:=k.Nodo^.Previo;
					
					NuevoK:=k.Nodo^.Siguiente;
				end;
		end
		else
		begin
			{ unico nodo }
			L.Primero:=Nil; L.Ultimo:=Nil;
			
			NuevoK:=Nil;
		end;
		
		L.nNodos:=L.nNodos - 1;
		
		RemoveNodeAt:=k.Nodo^.Element;
		
		Dispose(k.Nodo); k.Nodo:=NuevoK;
	end;
end;

function SwitchExprAt(k : TExprIt; WithExpr : Expr) : Expr;
begin
	SwitchExprAt:=(k.Nodo^.Element); k.Nodo^.Element:=WithExpr;
end;

function ExprAtIndex(L : TExprList; n : Word) : Expr;
var
	k : TExprIt;
begin
	MoveToIndex(L,k,n);
	
	ExprAtIndex:=ExprAt(k);
end;

procedure MoveToIndex(L : TExprList; var k : TExprIt; n : Word);
var
	i : Word;
	
begin
	Assert ((1 <= n) and (n <= LengthOfTExprList(L)));
	
	MoveToFirst(L,k); for i:=2 to n do MoveToNext(k);
end;

{ ------------------------------------------------------------------------------------------------------- }
{ TAD Expresión Simbólica }

function AllocExpr(Head : String; Terminal : String) : Expr;
begin
	{ crea e inicializa }
	New(AllocExpr); AllocExpr^.Head:=Head; AllocExpr^.Terminal:=Terminal;	
	InitTExprList(AllocExpr^.SubExprs);
end;

procedure ReleaseExpr(var X : Expr);
var
	k : Expr;
begin
	if (X <> Nil) then
	begin
		{ elimina las expresiones en su lista de hijos }
		ReleaseElementsInTExprList(X^.SubExprs);
		{ libera el nodo raíz }
		Dispose(X); X:=Nil;
	end;
end;

procedure AddSubExpr(X : Expr; var ToExpr : Expr);
begin
	InsertAsLast(ToExpr^.SubExprs, X);
end;

{Convierte la expresión pasada a cadena de caracteres}
function ExprToStr(X : Expr) : String;
	Var
		R:String;
		k:TExprIt;
	Begin
		R:='';
		If(X<>NIL)
			Then Begin
				If (X^.Head='List') {Si es una lista, abre una llave, inserta las subexpresiones y luego cierra la llave}
					Then
						Begin
							R:=R+'{';
							MoveToFirst(X^.SubExprs,k);
							If(IsAtNode(k)) Then
								Begin
									R:=R+ExprToStr(ExprAt(k));
									MoveToNext(k);
								End;
							While(IsAtNode(k)) Do
								Begin
									R:=R+','+ExprToStr(ExprAt(k));
									MoveToNext(k);
								End;
							R:=R+'}';
						End
					Else 
						Begin
							If(X^.Head='Symbol') {Si es un símbolo, simplemente lo inserta}
								Then R:=R+X^.Terminal
								Else {Si es una función, añade el nombre de la función y habre un corchete. Luego añade las subexpresiones y cierra el corchete}
									Begin
										R:=R+X^.Head+'[';
										MoveToFirst(X^.SubExprs,k);
										If(IsAtNode(k)) Then
											Begin
												R:=R+ExprToStr(ExprAt(k));
												MoveToNext(k);
											End;
										While(IsAtNode(k)) Do
											Begin
												R:=R+','+ExprToStr(ExprAt(k));
												MoveToNext(k);
											End;
										R:=R+ExprToStr(ExprAt(k))+']';
									End;
						End;
				End;
		ExprToStr:=R;
	End;

procedure TreeForm(X : Expr);

{ muestra sub-expresión, que está en el nivel dado }
procedure TreeFormImpl(X : Expr; IdLvl : Word);
var
	k : TExprIt; i, j : Word;
begin
	if (X <> Nil) then
	begin
		for i:=1 to IdLvl do
		begin
			Write('|'); for j:=1 to 4 do Write(' ');
		end;
			
		if (X^.Terminal = '') then
			WriteLn(X^.Head)
		else
			WriteLn(X^.Head, '(', X^.Terminal, ')');
		
		{ desciende recursivamente por sub-expresiones }
		MoveToFirst(X^.SubExprs, k);
		while (IsAtNode(k)) do
		begin
			TreeFormImpl(ExprAt(k), IdLvl + 1);
			MoveToNext(k);
		end;
	end;
end;

begin
	{ empieza por X (raíz) en nivel 0 }
	TreeFormImpl(X,0);
end;

function ExprToQTreeForm(X : Expr) : String;

var
	B : String;
	
{ genera el código LaTeX para nodos internos del árbol de expresión }
procedure QTreeFormInner(Z : Expr);
var
	Zi : TExprIt;	
begin
	if (Z <> Nil) then
	begin
		{ si no tiene sub-expresiones }
		if (IsEmptyTExprList(Z^.SubExprs)) then
		begin
			if (Z^.Terminal <> '') then
				B:=B + ' {' + Z^.Head + '\\``' + Z^.Terminal + '''''}'
			else
				B:=B + ' {' + Z^.Head + '\\``''''}';
		end
		else
		begin
			if (Z^.Terminal <> '') then
				B:=B + ' [.{' + Z^.Head + '\\``' + Z^.Terminal + '''''}'
			else
				B:=B + ' [.{' + Z^.Head + '\\``''''}';
			{ sub-expresiones }
			MoveToFirst(Z^.SubExprs, Zi);
			while (IsAtNode(Zi)) do
			begin
				QTreeFormInner(ExprAt(Zi));
				MoveToNext(Zi);
			end;
			 
			B:=B + ' ]';
		end;
	end;
end;

var
	k : TExprIt;
begin
	B:='';
	
	if (X <> Nil) then
	begin
		{ raíz }
		if (X^.Terminal <> '') then
			B:=B + '\Tree[.{' + X^.Head + '\\``' + X^.Terminal + '''''}'
		else
			B:=B + '\Tree[.{' + X^.Head + '\\``''''}';
			
		{ sub-expresiones }
		MoveToFirst(X^.SubExprs, k);
		while (IsAtNode(k)) do
		begin
			QTreeFormInner(ExprAt(k));
			MoveToNext(k);
		end;
		
		B:=B + ' ]';
	end;
	
	ExprToQTreeForm:=B;
end;

procedure QTreeForm(X : Expr; var ec : TException);
begin
	WriteLn(ExprToQTreeForm(X));
end;

procedure InsertBefore(k : TExprIt; var InList : TExprList; X : Expr);
var
	Nuevo : PNodoExprList;
begin
	Assert (IsAtNode(k));
	
	if (k.Nodo = InList.Primero) then
		InsertAsFirst(InList, X)
	else
	begin
		New(Nuevo); Nuevo^.Element:=X;
		
		{ punteros }
		Nuevo^.Siguiente:=k.Nodo; 
		Nuevo^.Previo:=k.Nodo^.Previo;
		
		k.Nodo^.Previo:=Nuevo;
		Nuevo^.Previo^.Siguiente:=Nuevo;		
	end;
end;

begin
end.
	
