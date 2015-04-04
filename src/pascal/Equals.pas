{Compara las dos expresiones y devuelve cierto si son iguales}
function Equals(X1, X2 : Expr) : Boolean;
	Var
		k,j:TExprIt;
	Begin
		Equals:=True;
		If(X1=NIL)XOr(X2=NIL) {Si solo uno de las dos expresiones está vacía, son distintas}
			Then Equals:=False
			Else Begin
				If(ExprCmp(X1,X2)<>'=')
					Then Equals:=False
					Else Begin
						MoveToFirst(X1^.SubExprs,k);
						MoveToFirst(X2^.SubExprs,j);
						While(IsAtNode(k))And(IsAtNode(j)) Do {Compara las subexpresiones de las expresiones pasadas}
							Begin
								Equals:=(Equals) And (Equals(ExprAt(k),ExprAt(j)));
								MoveToNext(k);
								MoveToNext(j);
							End;
						If(IsAtNode(k))xor(IsAtNode(j)) {Si ha acabado de recorrer una subexpresión antes que otra, entonces son distintos}
							Then Equals:=False;
						End;
				End;
	End;
