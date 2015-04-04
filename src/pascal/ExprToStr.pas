{Convierte la expresión pasada a cadena de caracteres}
function ExprToStr(X : Expr) : String;
	Var
		R:String;
		k:TExprIt;
	Begin
		R:='';
		If(X<>NIL)
			Then Begin
				If (X^.Head='List') {Si es una lista, abre una llave, inserta las subexpresiones y luego cierra la llave}
					Then
						Begin
							R:=R+'{';
							MoveToFirst(X^.SubExprs,k);
							If(IsAtNode(k)) Then
								Begin
									R:=R+ExprToStr(ExprAt(k));
									MoveToNext(k);
								End;
							While(IsAtNode(k)) Do
								Begin
									R:=R+','+ExprToStr(ExprAt(k));
									MoveToNext(k);
								End;
							R:=R+'}';
						End
					Else 
						Begin
							If(X^.Head='Symbol') {Si es un símbolo, simplemente lo inserta}
								Then R:=R+X^.Terminal
								Else {Si es una función, añade el nombre de la función y habre un corchete. Luego añade las subexpresiones y cierra el corchete}
									Begin
										R:=R+X^.Head+'[';
										MoveToFirst(X^.SubExprs,k);
										If(IsAtNode(k)) Then
											Begin
												R:=R+ExprToStr(ExprAt(k));
												MoveToNext(k);
											End;
										While(IsAtNode(k)) Do
											Begin
												R:=R+','+ExprToStr(ExprAt(k));
												MoveToNext(k);
											End;
										R:=R+ExprToStr(ExprAt(k))+']';
									End;
						End;
				End;
		ExprToStr:=R;
	End;
