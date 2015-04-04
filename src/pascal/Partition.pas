{Parte X en trozos del tamaño especificado por n}
function Partition(X : Expr; n : Expr; var ec : TException) : Expr;
	Var
		Nuevo, sub:Expr;
		k,j:TExprIt;
		Num,Error,hijos,i,tratados:Word;
	Begin
		Val(n^.Terminal,Num,Error);{Extrae el número para partir la expresión}
		If Error<>0
			Then Begin
				ec.nError:=1;
				ec.Msg:='Error. Debe indicarse de cuantos elementos hay que realizar la partición';
				Partition:=NIL;
				End
			Else If X=NIL
				Then Begin
					ec.nError:=2;
					ec.Msg:='Error. La expresión está vacía';
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
						Hijos:=LengthOfTExprList(X^.SubExprs) div Num;{El número de hijos de la lista devuelta será el resultado de la división entera del número de hijos de X entre n}
						For i:=1 To Hijos Do
							InsertAsLast(Nuevo^.SubExprs,AllocExpr('List',''));
						Tratados:=Hijos*Num;{El número de hijos de X que hay que tratar}
						MoveToFirst(X^.SubExprs,k);
						MoveToFirst(Nuevo^.SubExprs,j);
						For i:=1 To Tratados Do{Recorre todos los hijos que tiene que tratar}
							Begin
								Sub:=ExprAt(j);
								AddSubExpr(DeepCopy(ExprAt(k)),Sub);{Añade copias al resultado}
								MoveToNext(k);
								If (i mod Num)=0 Then MoveToNext(j);{Si ya se han añadido n elementos a una subexpresión del resultado, pasa a la siguiente}
							End;
						Partition:=Nuevo;
						End;
	End;
