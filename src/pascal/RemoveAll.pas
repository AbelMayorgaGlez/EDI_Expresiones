{Quita las apariciones de Y en el primer nivel de X}
Function RemoveAll(X:Expr; Y:Expr):Expr;
	Var
		Nuevo:Expr;
		k:TExprIt;
	Begin
		Nuevo:=AllocExpr(X^.Head,X^.Terminal);{Copia la cabecera}
		MoveToFirst(X^.SubExprs,k);
		While IsAtNode(k) Do{Compara cada subexpresion de X con Y. Si no son iguales, la añade al resultado}
			Begin
				If Not(Equals(ExprAt(k),Y))
					Then AddSubExpr(DeepCopy(ExprAt(k)),Nuevo);
				MoveToNext(k);
			End;
		RemoveAll:=Nuevo;
	End;
