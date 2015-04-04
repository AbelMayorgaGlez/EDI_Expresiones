{Si se le pasa una lista, la aplana, si no, devuelve una lista con la expresión pasada}
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
						While IsAtNode(j) Do {Saca las subexpresiones de la expresión devuelta y las añade al resultado}
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
