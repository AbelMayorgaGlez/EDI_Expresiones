{Quita todas las apariciones de Y en X}
Function RemoveAll2(X:Expr; Y:Expr):Expr;
	Var
		Nuevo:Expr;
		k:TExprIt;
	Begin
		Nuevo:=AllocExpr(X^.Head,X^.Terminal);{Copia la cabecera}
		MoveToFirst(X^.SubExprs,k);
		While IsAtNode(k) Do {Compara cada subexpresión de X con Y. Si no son iguales, añade el resultado de aplicar RemoveAll2 a la subexpresión}
			Begin
				If Not(Equals(ExprAt(k),Y))
					Then AddSubExpr(RemoveAll2(ExprAt(k),Y),Nuevo);
				MoveToNext(k);
			End;
		RemoveAll2:=Nuevo;
	End;
