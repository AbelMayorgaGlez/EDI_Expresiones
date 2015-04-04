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
