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
