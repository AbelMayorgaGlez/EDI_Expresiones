{Cambia todas las apariciones de la primera subexpresión de Y en X por la segunda subexpresión de Y}
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
					ec.Msg:='Error. Rule debe recibir 2 parámetros';
					ReplaceAll:=NIL;
					End
				Else Begin
					MoveToFirst(Y^.SubExprs,j);
					Buscar:=ExprAt(j);
					If Equals(X,Buscar) {Si X es igual a la primera subexpresión de Y, entonces devuelve una copia de la segunda subexpresión de Y}
						Then Begin
							MoveToNext(j);
							Nuevo:=DeepCopy(ExprAt(j));
							End
						Else Begin
							Nuevo:=AllocExpr(X^.Head,X^.Terminal);{Copia la cabecera}
							MoveToFirst(X^.SubExprs,k);
							While IsAtNode(k) Do{Añade el resultado de aplicar ReplaceAll a cada una de las subexpresiones de X}
								Begin
									AddSubExpr(ReplaceAll(ExprAt(k),Y,ec),Nuevo);
									MoveToNext(k);
								End;
							End;
					ReplaceAll:=Nuevo;
					End;
	End;
