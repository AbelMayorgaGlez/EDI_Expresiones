unit Ejercicios;
{$H-}

interface

uses
	Math, SysUtils, ExprShared, ExprTree, CoreFunctions;

{ Ejercicios }

function Join(X : Expr; var ec : TException) : Expr;
function Sort(X : Expr; var ec : TException) : Expr;
function Partition(X : Expr; n : Expr; var ec : TException) : Expr;
function Flatten(X : Expr; var ec : TException) : Expr;
function ReplaceAll(X : Expr; Y : Expr; var ec : TException) : Expr;
function Tally(X : Expr; var ec : TException) : Expr;
function Depth(A : Expr) : Expr;
function First(A : Expr; var ec : TException) : Expr;
procedure MatrixForm(X : Expr; var ec : TException);
function RemoveAll(X : Expr; Y : Expr) : Expr;
Function RemoveAll2(X:Expr; Y:Expr):Expr;
function Part(X : Expr; Spec : Expr; var ec : TException) : Expr;
function PartsOfTerminalNodes(X : Expr; var ec : TException) : Expr;

implementation
function Join(X : Expr; var ec : TException) : Expr; begin Join:=nil; end;
function Sort(X : Expr; var ec : TException) : Expr; begin Sort:=nil; end;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Parte X en trozos del tama�o especificado por n}
function Partition(X : Expr; n : Expr; var ec : TException) : Expr;
	Var
		Nuevo, sub:Expr;
		k,j:TExprIt;
		Num,Error,hijos,i,tratados:Word;
	Begin
		Val(n^.Terminal,Num,Error);{Extrae el n�mero para partir la expresi�n}
		If Error<>0
			Then Begin
				ec.nError:=1;
				ec.Msg:='Error. Debe indicarse de cuantos elementos hay que realizar la partici�n';
				Partition:=NIL;
				End
			Else If X=NIL
				Then Begin
					ec.nError:=2;
					ec.Msg:='Error. La expresi�n est� vac�a';
					Partition:=NIL;
					End
				Else If X^.Head<>'List'
					Then Begin
						ec.nError:=3;
						ec.Msg:='Error. La funcion Partition solo trabaja sobre listas';
						Partition:=NIL;
						End
					Else Begin
						Nuevo:=AllocExpr('List','');
						Hijos:=LengthOfTExprList(X^.SubExprs) div Num;{El n�mero de hijos de la lista devuelta ser� el resultado de la divisi�n entera del n�mero de hijos de X entre n}
						For i:=1 To Hijos Do
							InsertAsLast(Nuevo^.SubExprs,AllocExpr('List',''));
						Tratados:=Hijos*Num;{El n�mero de hijos de X que hay que tratar}
						MoveToFirst(X^.SubExprs,k);
						MoveToFirst(Nuevo^.SubExprs,j);
						For i:=1 To Tratados Do{Recorre todos los hijos que tiene que tratar}
							Begin
								Sub:=ExprAt(j);
								AddSubExpr(DeepCopy(ExprAt(k)),Sub);{A�ade copias al resultado}
								MoveToNext(k);
								If (i mod Num)=0 Then MoveToNext(j);{Si ya se han a�adido n elementos a una subexpresi�n del resultado, pasa a la siguiente}
							End;
						Partition:=Nuevo;
						End;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Si se le pasa una lista, la aplana, si no, devuelve una lista con la expresi�n pasada}
function Flatten(X : Expr; var ec : TException) : Expr;
	Var
		Nuevo,Retorno:Expr;
		k,j:TExprIt;
	Begin
		Nuevo:=AllocExpr('List','');
		If (x^.Head<>'List'){Si no es una lista, copia el contenido}
			Then AddSubExpr(DeepCopy(X),Nuevo)
			Else Begin
				MoveToFirst(X^.SubExprs,k);
				While IsAtNode(k) Do
					Begin
						Retorno:=Flatten(ExprAt(k),ec);
						MoveToFirst(Retorno^.SubExprs,j);
						While IsAtNode(j) Do {Saca las subexpresiones de la expresi�n devuelta y las a�ade al resultado}
							Begin
								AddSubExpr(RemoveNodeAt(Retorno^.SubExprs,j),Nuevo);
								MoveToFirst(Retorno^.SubExprs,j);
							End;
						ReleaseExpr(Retorno);{Libera la memoria que sobra}
						MoveToNext(k);
					End;
				End;
			Flatten:=Nuevo;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Cambia todas las apariciones de la primera subexpresi�n de Y en X por la segunda subexpresi�n de Y}
function ReplaceAll(X : Expr; Y : Expr; var ec : TException) : Expr; 	
	Var
		Nuevo,Buscar:Expr;
		k,j:TExprIt;
	Begin
		If Y^.Head<>'Rule'
			Then Begin
				ec.nError:=1;
				ec.Msg:='Error. El reemplazo debe expresarse de la forma Rule[E1,E2]';
				ReplaceAll:=NIL;
				End
			Else If LengthOfTExprList(Y^.SubExprs)<>2
				Then Begin
					ec.nError:=2;
					ec.Msg:='Error. Rule debe recibir 2 par�metros';
					ReplaceAll:=NIL;
					End
				Else Begin
					MoveToFirst(Y^.SubExprs,j);
					Buscar:=ExprAt(j);
					If Equals(X,Buscar) {Si X es igual a la primera subexpresi�n de Y, entonces devuelve una copia de la segunda subexpresi�n de Y}
						Then Begin
							MoveToNext(j);
							Nuevo:=DeepCopy(ExprAt(j));
							End
						Else Begin
							Nuevo:=AllocExpr(X^.Head,X^.Terminal);{Copia la cabecera}
							MoveToFirst(X^.SubExprs,k);
							While IsAtNode(k) Do{A�ade el resultado de aplicar ReplaceAll a cada una de las subexpresiones de X}
								Begin
									AddSubExpr(ReplaceAll(ExprAt(k),Y,ec),Nuevo);
									MoveToNext(k);
								End;
							End;
					ReplaceAll:=Nuevo;
					End;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Devuelve una subexpresi�n que contabiliza el n�mero de veces que se repite cada subexpresi�n de X}
function Tally(X : Expr; var ec : TException) : Expr;

	{Devuelve una lista que contiene como primera subexpresi�n, N, y como segunda, un 1}
	Function NuevaCuenta(N:Expr):Expr;
		Var
			Nuevo:Expr;
		Begin
			Nuevo:=AllocExpr('List','');
			AddSubExpr(DeepCopy(N),Nuevo);
			AddSubExpr(AllocExpr('Symbol','1'),Nuevo);
			NuevaCuenta:=Nuevo;
		End;

	{Devuelve un puntero a la subexpresi�n de En que tiene como primera subexpresi�n a Elemento, o NIL si no se encuentra}
	Function Buscar(Elemento:Expr; En:Expr):Expr;
		Var
			k,j:TExprIt;
			Encontrado:Boolean;
		Begin
			Encontrado:=False;
			MoveToFirst(En^.SubExprs,k);
			While IsAtNode(k) And(Not Encontrado) Do{Busca Elemento en todas las subexpresiones de En}
				Begin
					MoveToFirst(ExprAt(k)^.SubExprs,j);{j queda en la primera subexpresi�n de las subexpresiones de En}
					If (Equals(ExprAt(j),Elemento))
						Then Begin
							Buscar:=ExprAt(k);{Si es igual al buscado, devuelve un puntero a su ra�z}
							Encontrado:=True;
							End
						Else MoveToNext(k);
				End;
			If (Not Encontrado) Then Buscar:=NIL;
		End;

	{Incrementa en 1 la segunda subexpresi�n de X}
	Procedure Incrementa(X:Expr);
		Var
			k:TExprIt;
			Cantidad:Expr;
		Begin
			MoveToLast(X^.SubExprs,k);
			Cantidad:=ExprAt(k);
			Cantidad^.Terminal:=IntToStr(StrToInt(Cantidad^.Terminal)+1);
		End;
	
{INICIO DE TALLY}
	Var
		k:TExprIt;
		Nuevo,Encontrado:Expr;
	Begin
		If (X^.Head<>'List')
			Then Begin
				ec.nError:=1;
				ec.Msg:='La funcion Tally solo trabaja sobre listas';
				Tally:=NIL;
				End;
		Nuevo:=AllocExpr('List','');{Inicia la lista resultante}
		MoveToFirst(X^.SubExprs,k);
		While IsAtNode(k) Do {Por cada subexpresi�n de X, la busca en Nuevo. Si est�, incrementa su contador, si no, la a�ade con contador 1}
			Begin
				Encontrado:=Buscar(ExprAt(k),Nuevo);
				If Encontrado=NIL
					Then AddSubExpr(NuevaCuenta(ExprAt(k)),Nuevo)
					Else Incrementa(Encontrado);
				MoveToNext(k);
			End;
		Tally:=Nuevo;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Devuelve una expresi�n que contiene la altura de la expresi�n pasada}
Function Depth(A:Expr):Expr;

	{A y B son alturas. Devuelve el m�ximo de las 2 y la otra la elimina}
	Function Max(Var A:Expr; Var B:Expr):Expr;
		Begin
			If(StrToInt(A^.Terminal)>StrToInt(B^.Terminal))
				Then Begin
					Max:=A;
					Dispose(B);
					End
				Else Begin
					Max:=B;
					Dispose(A);
					End;
		End;

	Var
		Nuevo,Retorno:Expr;
		k:TExprIt;
	Begin
		If A=NIL
			Then Nuevo:=AllocExpr('Symbol','0') {Si el arbol es vac�o la altura es 0}
			Else If IsEmptyTExprList(A^.SubExprs){Si no tiene subexpresiones, es decir, es una hoja, la altura es 1}
				Then Nuevo:=AllocExpr('Symbol','1')
				Else Begin
					MoveToFirst(A^.SubExprs,k);
					Nuevo:=AllocExpr('Symbol','0');
					While IsAtNode(k) Do {Se va quedando con el m�ximo de las alturas de cada hijo}
						Begin
							Retorno:=Depth(ExprAt(k));
							Nuevo:=Max(Nuevo,Retorno);
							MoveToNext(k);
						End;
					Nuevo^.Terminal:=IntToStr(StrToInt(Nuevo^.Terminal)+1);{A�ade 1 al m�ximo de las alturas de los hijos}
					End;
		Depth:=Nuevo;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

function First(A : Expr; var ec : TException) : Expr; begin First:=nil; end;
procedure MatrixForm(X : Expr; var ec : TException); begin end;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Quita las apariciones de Y en el primer nivel de X}
Function RemoveAll(X:Expr; Y:Expr):Expr;
	Var
		Nuevo:Expr;
		k:TExprIt;
	Begin
		Nuevo:=AllocExpr(X^.Head,X^.Terminal);{Copia la cabecera}
		MoveToFirst(X^.SubExprs,k);
		While IsAtNode(k) Do{Compara cada subexpresion de X con Y. Si no son iguales, la a�ade al resultado}
			Begin
				If Not(Equals(ExprAt(k),Y))
					Then AddSubExpr(DeepCopy(ExprAt(k)),Nuevo);
				MoveToNext(k);
			End;
		RemoveAll:=Nuevo;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Quita todas las apariciones de Y en X}
Function RemoveAll2(X:Expr; Y:Expr):Expr;
	Var
		Nuevo:Expr;
		k:TExprIt;
	Begin
		Nuevo:=AllocExpr(X^.Head,X^.Terminal);{Copia la cabecera}
		MoveToFirst(X^.SubExprs,k);
		While IsAtNode(k) Do {Compara cada subexpresi�n de X con Y. Si no son iguales, a�ade el resultado de aplicar RemoveAll2 a la subexpresi�n}
			Begin
				If Not(Equals(ExprAt(k),Y))
					Then AddSubExpr(RemoveAll2(ExprAt(k),Y),Nuevo);
				MoveToNext(k);
			End;
		RemoveAll2:=Nuevo;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

{Devuelve el trozo de X especificado por Spec}
function Part(X : Expr; Spec : Expr; var ec : TException) : Expr;
	Var
		Nuevo,Quitado,n:Expr;
		k:TExprIt;
		Num,Error:Word;
	Begin
		If IsEmptyTExprList(Spec^.SubExprs){Si Spec no tiene subexpresiones, devuelve una copia de X}
			Then Part:=DeepCopy(X)
			Else Begin {Hace una copia de Spec y quita la primera subexpresi�n}
				Quitado:=DeepCopy(Spec);
				MoveToFirst(Quitado^.SubExprs,k);
				n:=RemoveNodeAt(Quitado^.SubExprs,k);
				Val(n^.Terminal,Num,Error);{Extrae el n�mero de la expresi�n referida}
					If Error<>0
						Then Begin
							ec.nError:=1;
							ec.Msg:='Error. Debe indicarse una referencia num�rica';
							Part:=NIL;
							End
						Else If X=NIL
							Then Begin
								ec.nError:=2;
								ec.Msg:='Error. La expresi�n est� vac�a';
								Part:=NIL;
								End
							Else If Num>LengthOfTExprList(X^.SubExprs){Si el n�mero es mayor que el n�mero de subexpresiones, no existe la subexpresi�n buscada}
								Then Begin
									ec.nError:=3;
									ec.Msg:='Error. SubExpresion inexistente';
									Part:=NIL;
									End
								Else Begin{Se mueve a la subexpresi�n especificada y extrae de ella la parte correspondiente}
									MoveToIndex(X^.SubExprs,k,Num);
									Nuevo:=Part(ExprAt(k),Quitado,ec);
									Part:=Nuevo;
									End;	
				ReleaseExpr(Quitado);{Libera la memoria copiada}
				End;
	End;

{--------------------------------------------------------------------------------------------------------------------------------------------}

function PartsOfTerminalNodes(X : Expr; var ec : TException) : Expr; begin PartsOfTerminalNodes:=nil; end;


begin
end.
