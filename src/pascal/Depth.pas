{Devuelve una expresión que contiene la altura de la expresión pasada}
Function Depth(A:Expr):Expr;

	{A y B son alturas. Devuelve el máximo de las 2 y la otra la elimina}
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
			Then Nuevo:=AllocExpr('Symbol','0') {Si el arbol es vacío la altura es 0}
			Else If IsEmptyTExprList(A^.SubExprs){Si no tiene subexpresiones, es decir, es una hoja, la altura es 1}
				Then Nuevo:=AllocExpr('Symbol','1')
				Else Begin
					MoveToFirst(A^.SubExprs,k);
					Nuevo:=AllocExpr('Symbol','0');
					While IsAtNode(k) Do {Se va quedando con el máximo de las alturas de cada hijo}
						Begin
							Retorno:=Depth(ExprAt(k));
							Nuevo:=Max(Nuevo,Retorno);
							MoveToNext(k);
						End;
					Nuevo^.Terminal:=IntToStr(StrToInt(Nuevo^.Terminal)+1);{Añade 1 al máximo de las alturas de los hijos}
					End;
		Depth:=Nuevo;
	End;
