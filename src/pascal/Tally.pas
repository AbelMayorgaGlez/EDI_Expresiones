{Devuelve una subexpresión que contabiliza el número de veces que se repite cada subexpresión de X}
function Tally(X : Expr; var ec : TException) : Expr;

	{Devuelve una lista que contiene como primera subexpresión, N, y como segunda, un 1}
	Function NuevaCuenta(N:Expr):Expr;
		Var
			Nuevo:Expr;
		Begin
			Nuevo:=AllocExpr('List','');
			AddSubExpr(DeepCopy(N),Nuevo);
			AddSubExpr(AllocExpr('Symbol','1'),Nuevo);
			NuevaCuenta:=Nuevo;
		End;

	{Devuelve un puntero a la subexpresión de En que tiene como primera subexpresión a Elemento, o NIL si no se encuentra}
	Function Buscar(Elemento:Expr; En:Expr):Expr;
		Var
			k,j:TExprIt;
			Encontrado:Boolean;
		Begin
			Encontrado:=False;
			MoveToFirst(En^.SubExprs,k);
			While IsAtNode(k) And(Not Encontrado) Do{Busca Elemento en todas las subexpresiones de En}
				Begin
					MoveToFirst(ExprAt(k)^.SubExprs,j);{j queda en la primera subexpresión de las subexpresiones de En}
					If (Equals(ExprAt(j),Elemento))
						Then Begin
							Buscar:=ExprAt(k);{Si es igual al buscado, devuelve un puntero a su raíz}
							Encontrado:=True;
							End
						Else MoveToNext(k);
				End;
			If (Not Encontrado) Then Buscar:=NIL;
		End;

	{Incrementa en 1 la segunda subexpresión de X}
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
		While IsAtNode(k) Do {Por cada subexpresión de X, la busca en Nuevo. Si está, incrementa su contador, si no, la añade con contador 1}
			Begin
				Encontrado:=Buscar(ExprAt(k),Nuevo);
				If Encontrado=NIL
					Then AddSubExpr(NuevaCuenta(ExprAt(k)),Nuevo)
					Else Incrementa(Encontrado);
				MoveToNext(k);
			End;
		Tally:=Nuevo;
	End;
