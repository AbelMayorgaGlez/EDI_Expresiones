{Devuelve el trozo de X especificado por Spec}
function Part(X : Expr; Spec : Expr; var ec : TException) : Expr;
	Var
		Nuevo,Quitado,n:Expr;
		k:TExprIt;
		Num,Error:Word;
	Begin
		If IsEmptyTExprList(Spec^.SubExprs){Si Spec no tiene subexpresiones, devuelve una copia de X}
			Then Part:=DeepCopy(X)
			Else Begin {Hace una copia de Spec y quita la primera subexpresión}
				Quitado:=DeepCopy(Spec);
				MoveToFirst(Quitado^.SubExprs,k);
				n:=RemoveNodeAt(Quitado^.SubExprs,k);
				Val(n^.Terminal,Num,Error);{Extrae el número de la expresión referida}
					If Error<>0
						Then Begin
							ec.nError:=1;
							ec.Msg:='Error. Debe indicarse una referencia numérica';
							Part:=NIL;
							End
						Else If X=NIL
							Then Begin
								ec.nError:=2;
								ec.Msg:='Error. La expresión está vacía';
								Part:=NIL;
								End
							Else If Num>LengthOfTExprList(X^.SubExprs){Si el número es mayor que el número de subexpresiones, no existe la subexpresión buscada}
								Then Begin
									ec.nError:=3;
									ec.Msg:='Error. SubExpresion inexistente';
									Part:=NIL;
									End
								Else Begin{Se mueve a la subexpresión especificada y extrae de ella la parte correspondiente}
									MoveToIndex(X^.SubExprs,k,Num);
									Nuevo:=Part(ExprAt(k),Quitado,ec);
									Part:=Nuevo;
									End;	
				ReleaseExpr(Quitado);{Libera la memoria copiada}
				End;
	End;
