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
