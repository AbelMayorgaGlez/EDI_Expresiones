unit Kernel;
{$H-}

interface

uses
	ExprShared, ExprTree, ExprParser, StrUtils, CoreFunctions, Ejercicios;

const
	HASHROWS = 13; { n�mero de listas en la tabla hash de s�mbolos }
	
type
	{ tabla de s�mbolos - asocia una expresi�n (clave) a otra (valor) }
	TSymbolTable = record
		{ claves y valores est�n en listas de expresiones }
		Keys : array[0..HASHROWS] of TExprList;
		Values : array[0..HASHROWS] of TExprList;
	end;
	
	{ n�cleo - almacena el �ltimo resultado y s�mbolos definidos con "Set" }
	TKernel = record
		E1 : Expr; { resultado de la �ltima evaluaci�n }
		Defs : TSymbolTable; { tabla de s�mbolos }
		nExprEval : Word; { evaluaciones }
	end;

{ inicializa / termina }
procedure StartKernel(var K : TKernel);

procedure StopKernel(var K : TKernel);

{ eval�a una expresi�n que viene del int�rprete }
procedure FrontEndEval(E : String; var Ker : TKernel; var ec : TException);

{ guarda las expresiones Set[] para reconstruir la tabla de s�mbolos }
procedure SaveSymbolTableInto(var F : Text; Ker : TKernel);



implementation


{ Utilidades }
function nSubExprs(X : Expr) : Word;
begin
	nSubExprs:=LengthOfTExprList(X^.SubExprs);
end;

function SubExpr(X : Expr; n : Word) : Expr;
begin
	SubExpr:=ExprAtIndex(X^.SubExprs, n);
end;

procedure MoveToFirstSubExpr(X : Expr; var k : TExprIt);
begin
	MoveToFirst(X^.SubExprs, k);
end;



procedure SaveSymbolTableInto(var F : Text; Ker : TKernel);
var
	h : Word; Ki, Vi : TExprIt;
begin
	{ para cada 'fila' de la tabla hash }
	for h:=0 to HASHROWS do
	begin
		{ se mueve sobre las correspondientes listas de claves y valores }
		MoveToFirst(Ker.Defs.Keys[h], Ki); MoveToFirst(Ker.Defs.Values[h], Vi);
		while (IsAtNode(Ki)) do
		begin
			{ reproduce la expresi�n Set[Clave,Valor] necesaria para recrear la definici�n }
			WriteLn(F, 'Set[' + ExprToStr(ExprAt(Ki)) + ',' + ExprToStr(ExprAt(Vi)) + ']');
			{ avanza los iteradores de ambas listas }
			MoveToNext(Ki); MoveToNext(Vi);
		end;
	end;
end;


{ Retiene R como �ltimo resultado conocido en el n�cleo }
procedure StoreLastKnownResult(var K : TKernel; R : Expr);
begin
	{ libera la expresi�n anterior }
	ReleaseExpr(K.E1);
	{ guarda una referencia a R }
	K.E1:=R;
end;

{ Inicializa una tabla de s�mbolos }
procedure InitSymbolTable(var T : TSymbolTable);
var
	i : Word;
begin
	{�para cada par de listas }
	for i:=0 to HASHROWS do
	begin
		InitTExprList(T.Keys[i]);
		InitTExprList(T.Values[i]);
	end;
end;

{ Vac�a una tabla de s�mbolos }
procedure EmptySymbolTable(var T : TSymbolTable);
var
	i : Word;
begin
	for i:=0 to HASHROWS do
	begin
		ReleaseElementsInTExprList(T.Keys[i]);
		ReleaseElementsInTExprList(T.Values[i]);
	end;
end;

{ Valor hash de una clave (cadena) dada }
function Hash(Key : String) : Word;
var
	i : Word;
	Acc : QWord;
begin
	Acc:=0; for i:=1 to Length(Key) do Acc:=Acc + Ord(Key[i]);
	Hash:=Acc mod HASHROWS;
end;

{ Guarda una definici�n en la tabla, asociada a la expresi�n clave (Key), con valor (Value) }
procedure StoreInto(var T : TSymbolTable; Key, Value : Expr);
var
	hKey : Word; Ki, Vi : TExprIt; A : Expr;
begin
	{ aplica la funci�n de hash a la clave }
	hKey:=Hash(ExprToStr(Key));
	
	{ hKey es el �ndice que indica qu� lista de claves y qu� lista de valores usar }
	
	{ intenta localizar la clave (por si ya existe) y su correspondiente valor }
	MoveToFirst(T.Keys[hKey], Ki); MoveToFirst(T.Values[hKey], Vi);
	while (IsAtNode(Ki) and (not Equals(ExprAt(Ki), Key))) do
	begin
		{ mientras queden claves y en la que est� Ki no sea igual a la que piden }
		MoveToNext(Ki); MoveToNext(Vi);
	end;
	
	{ si Ki est� en un nodo de la lista de claves, es que se encontr� Key en ella }
	if (IsAtNode(Ki)) then
	begin
		{ intercambia el valor }
		A:=SwitchExprAt(Vi, DeepCopy(Value));
		{ libera la memoria de la expresi�n sustitu�da }
		ReleaseExpr(A);
	end
	else
	begin
		{ no est�, inserta como �ltimo }
		InsertAsLast(T.Keys[hKey], DeepCopy(Key));
		InsertAsLast(T.Values[hKey], DeepCopy(Value));
	end;
end;

{ Devuelve una copia de la expresi�n almacenada bajo la clave dada }
function RecallFrom(T : TSymbolTable; Key : Expr) : Expr;
var
	hKey : Word; Ki, Vi : TExprIt;
begin
	hKey:=Hash(ExprToStr(Key)) mod HASHROWS;
	
	MoveToFirst(T.Keys[hKey], Ki); MoveToFirst(T.Values[hKey], Vi);
	while (IsAtNode(Ki) and (not Equals(ExprAt(Ki), Key))) do
	begin
		MoveToNext(Ki); MoveToNext(Vi);
	end;
	
	if (IsAtNode(Ki)) then
		RecallFrom:=DeepCopy(ExprAt(Vi))
	else
		RecallFrom:=Nil;
end;

procedure RemoveFrom(var T : TSymbolTable; Key : Expr);
var
	hKey : Word; Ki, Vi : TExprIt;
begin
	hKey:=Hash(ExprToStr(Key));
	
	MoveToFirst(T.Keys[hKey], Ki); MoveToFirst(T.Values[hKey], Vi);
	while (IsAtNode(Ki) and (not Equals(ExprAt(Ki), Key))) do
	begin
		MoveToNext(Ki); MoveToNext(Vi);
	end;
	
	if (IsAtNode(Ki)) then
	begin
		RemoveNodeAndReleaseExprAt(T.Keys[hKey], Ki);
		RemoveNodeAndReleaseExprAt(T.Values[hKey], Vi);
	end;
end;

procedure StartKernel(var K : TKernel);
begin
	K.E1:=AllocExpr('List','');
	
	InitSymbolTable(K.Defs);
	
	K.nExprEval:=0;
end;

procedure StopKernel(var K : TKernel);
begin
	ReleaseExpr(K.E1);
	
	EmptySymbolTable(K.Defs);
end;

{ sustituye '%' por el �ltimo resultado conocido }
function ReplaceInString(S : String; Rx : String) : String;
begin
	ReplaceInString:=AnsiReplaceStr(S,'%',Rx);
end;

{ evaluaci�n de E (cadena) }
procedure FrontEndEval(E : String; var Ker : TKernel; var ec : TException);

{ Eval�a la expresi�n Ex de forma recursiva (de las hojas hacia arriba) }

{ 	+ La evaluaci�n puede modificar el n�cleo Ker y devuelve un c�digo de resultado en ec }
{ 	+ El cliente se hace responsable de la memoria din�mica del resultado }
function EvaluateExpr(Ex : Expr; var Ker : TKernel; var ec : TException) : Expr;
var
	Exi, Exj : TExprIt;
	Ri : Expr;	
begin
	ec.nError:=0; ec.Msg:='';

	{ primero eval�a las sub-expresiones }
	MoveToFirst(Ex^.SubExprs, Exi);
	
	while ((ec.nError = 0) and (IsAtNode(Exi))) do
	begin
		Ri:=EvaluateExpr(ExprAt(Exi), Ker, ec);

		{ si no hay error, contin�a }	
		if (ec.nError = 0) then
		begin
			{ guarda el resultado como sub-expresi�n de Ex }
			Ri:=SwitchExprAt(Exi,Ri);

			{ elimina la que hab�a antes }
			ReleaseExpr(Ri);

			MoveToNext(Exi);
		end;
	end;

	{ despu�s, eval�a la ra�z }
	if (ec.nError = 0) then
	begin
		if (Ex^.Head = 'Symbol') then
		begin
			{ si no es '%' - por ejemplo, evaluar "A1" }
			if (Ex^.Terminal <> '%') then
			begin
				{ evaluaci�n de un s�mbolo - puede tener un valor asociado en la tabla de s�mbolos }
				EvaluateExpr:=RecallFrom(Ker.Defs, Ex);
				
				{ si no lo tiene, devuelve el propio s�mbolo }
				if (EvaluateExpr = Nil) then
					EvaluateExpr:=DeepCopy(Ex);
			end
			else
				{ la evaluaci�n de % es el "�ltimo resultado conocido" }
				EvaluateExpr:=DeepCopy(Ker.E1);
				
		end { expresiones implementadas }
		else if (Ex^.Head = 'Flatten') then
			EvaluateExpr:=Flatten(SubExpr(Ex,1),ec)
		else if (Ex^.Head = 'Tally') then
			EvaluateExpr:=Tally(SubExpr(Ex,1),ec)
		else if (Ex^.Head = 'Part') then
			EvaluateExpr:=Part(SubExpr(Ex,1), SubExpr(Ex,2), ec)
		else if (Ex^.Head = 'Partition') then
			EvaluateExpr:=Partition(SubExpr(Ex,1), SubExpr(Ex,2), ec)
		else if (Ex^.Head = 'RemoveAll') then
			EvaluateExpr:=RemoveAll(SubExpr(Ex,1), SubExpr(Ex,2))
		else if (Ex^.Head = 'TreeForm') then
		begin
			TreeForm(SubExpr(Ex,1));
			
			EvaluateExpr:=DeepCopy(SubExpr(Ex,1));
		end
		else if (Ex^.Head = 'QTreeForm') then
		begin
			QTreeForm(SubExpr(Ex,1), ec);
			
			EvaluateExpr:=DeepCopy(SubExpr(Ex,1));
		end
		else if (Ex^.Head = 'MatrixForm') then
		begin
			MatrixForm(SubExpr(Ex, 1), ec);
			
			EvaluateExpr:=DeepCopy(SubExpr(Ex, 1));
		end
		else if (Ex^.Head = 'ReplaceAll') then
			EvaluateExpr:=ReplaceAll(SubExpr(Ex, 1), SubExpr(Ex, 2), ec)
		else if (Ex^.Head = 'Depth') then
			EvaluateExpr:=Depth(SubExpr(Ex,1))
		else if (Ex^.Head = 'First') then
			EvaluateExpr:=First(SubExpr(Ex,1), ec)
		else if (Ex^.Head = 'Sort') then
			EvaluateExpr:=Sort(SubExpr(Ex,1), ec)
		else if (Ex^.Head = 'Join') then
			EvaluateExpr:=Join(SubExpr(Ex,1), ec)
		else if (Ex^.Head = 'Terminals') then
			EvaluateExpr:=PartsOfTerminalNodes(SubExpr(Ex,1), ec)
		else if (Ex^.Head = 'CartesianProduct') then
			EvaluateExpr:=CartesianProduct(SubExpr(Ex,1), SubExpr(Ex,2), ec)
		else if (Ex^.Head = 'Equals') then
		begin
			{ devuelve una expresi�n 'True', o 'False' (s�mbolos) }
			if (Equals(SubExpr(Ex, 1), SubExpr(Ex, 2))) then
				EvaluateExpr:=AllocExpr('Symbol', 'True')
			else
				EvaluateExpr:=AllocExpr('Symbol', 'False');
		end
		else if (Ex^.Head = 'ExprCmp') then
		begin
			case ExprCmp(SubExpr(Ex, 1), SubExpr(Ex, 2)) of
				'<': begin
					EvaluateExpr:=AllocExpr('Symbol', 'LessThan');
				end;
				'=': begin
					EvaluateExpr:=AllocExpr('Symbol', 'Equal');
				end;
				'>': begin
					EvaluateExpr:=AllocExpr('Symbol', 'GreaterThan');
				end;
			end;
		end
		else
			{ si no se conoce, devuelve una copia }
			EvaluateExpr:=DeepCopy(Ex);
	end;
end;

var
	Ex : Expr;
	Rx : Expr;
	
begin	
	Inc(Ker.nExprEval);

	if (E = 'Show') then
		{�muestra los s�mbolos en la tabla del n�cleo }
		SaveSymbolTableInto(Output, Ker)
	else
	begin
		{ construye el �rbol de expresi�n }
		Ex:=ParseExpr(E);
		
		{ asignaci�n - Set[LHS,RHS] asigna al lado izquierdo LHS el resultado de evaluar RHS }
		if (Ex^.Head = 'Set') then
		begin
			if (SubExpr(Ex,1)^.Head <> 'Symbol') then
			begin
				ec.nError:=1; ec.Msg:='�nicamente se pueden asignar valores a s�mbolos';
			end
			else
			begin
				{ eval�a la parte derecha de la asignaci�n }
				Rx:=EvaluateExpr(SubExpr(Ex, 2), Ker, ec);
				
				{ si no hubo error }
				if (ec.nError = 0) then
				begin
					{ almacena el resultado, asociado a la parte izquierda }
					StoreInto(Ker.Defs, SubExpr(Ex, 1), Rx);
				
					{ guarda como �ltimo resultado conocido }
					StoreLastKnownResult(Ker, Rx);
				end
				else
				begin
					ec.Msg:='Error al evaluar el lado derecho de la asignaci�n : ' + ec.Msg;
				
					{ error, libera la memoria utilizada }
					ReleaseExpr(Rx);
				end;
			end;
		end
		else
		begin
			{�evaluaci�n de otras expresiones (no Set) }
			Rx:=EvaluateExpr(Ex, Ker, ec);

			{ si no hubo error }
			if (ec.nError = 0) then
			begin
				{ guarda como �ltimo resultado conocido }
				StoreLastKnownResult(Ker, Rx);
			end
			else
			begin
				ec.Msg:='Error al evaluar la expresi�n : ' + ec.Msg;

				{ error, libera la memoria utilizada }
				ReleaseExpr(Rx);
			end;
		end;
		{ libera el �rbol de expresi�n }
		ReleaseExpr(Ex);
	end;
end;

begin
end.
