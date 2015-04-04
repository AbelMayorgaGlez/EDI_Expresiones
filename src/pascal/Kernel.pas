unit Kernel;
{$H-}

interface

uses
	ExprShared, ExprTree, ExprParser, StrUtils, CoreFunctions, Ejercicios;

const
	HASHROWS = 13; { número de listas en la tabla hash de símbolos }
	
type
	{ tabla de símbolos - asocia una expresión (clave) a otra (valor) }
	TSymbolTable = record
		{ claves y valores están en listas de expresiones }
		Keys : array[0..HASHROWS] of TExprList;
		Values : array[0..HASHROWS] of TExprList;
	end;
	
	{ núcleo - almacena el último resultado y símbolos definidos con "Set" }
	TKernel = record
		E1 : Expr; { resultado de la última evaluación }
		Defs : TSymbolTable; { tabla de símbolos }
		nExprEval : Word; { evaluaciones }
	end;

{ inicializa / termina }
procedure StartKernel(var K : TKernel);

procedure StopKernel(var K : TKernel);

{ evalúa una expresión que viene del intérprete }
procedure FrontEndEval(E : String; var Ker : TKernel; var ec : TException);

{ guarda las expresiones Set[] para reconstruir la tabla de símbolos }
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
			{ reproduce la expresión Set[Clave,Valor] necesaria para recrear la definición }
			WriteLn(F, 'Set[' + ExprToStr(ExprAt(Ki)) + ',' + ExprToStr(ExprAt(Vi)) + ']');
			{ avanza los iteradores de ambas listas }
			MoveToNext(Ki); MoveToNext(Vi);
		end;
	end;
end;


{ Retiene R como último resultado conocido en el núcleo }
procedure StoreLastKnownResult(var K : TKernel; R : Expr);
begin
	{ libera la expresión anterior }
	ReleaseExpr(K.E1);
	{ guarda una referencia a R }
	K.E1:=R;
end;

{ Inicializa una tabla de símbolos }
procedure InitSymbolTable(var T : TSymbolTable);
var
	i : Word;
begin
	{ para cada par de listas }
	for i:=0 to HASHROWS do
	begin
		InitTExprList(T.Keys[i]);
		InitTExprList(T.Values[i]);
	end;
end;

{ Vacía una tabla de símbolos }
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

{ Guarda una definición en la tabla, asociada a la expresión clave (Key), con valor (Value) }
procedure StoreInto(var T : TSymbolTable; Key, Value : Expr);
var
	hKey : Word; Ki, Vi : TExprIt; A : Expr;
begin
	{ aplica la función de hash a la clave }
	hKey:=Hash(ExprToStr(Key));
	
	{ hKey es el índice que indica qué lista de claves y qué lista de valores usar }
	
	{ intenta localizar la clave (por si ya existe) y su correspondiente valor }
	MoveToFirst(T.Keys[hKey], Ki); MoveToFirst(T.Values[hKey], Vi);
	while (IsAtNode(Ki) and (not Equals(ExprAt(Ki), Key))) do
	begin
		{ mientras queden claves y en la que está Ki no sea igual a la que piden }
		MoveToNext(Ki); MoveToNext(Vi);
	end;
	
	{ si Ki está en un nodo de la lista de claves, es que se encontró Key en ella }
	if (IsAtNode(Ki)) then
	begin
		{ intercambia el valor }
		A:=SwitchExprAt(Vi, DeepCopy(Value));
		{ libera la memoria de la expresión sustituída }
		ReleaseExpr(A);
	end
	else
	begin
		{ no está, inserta como último }
		InsertAsLast(T.Keys[hKey], DeepCopy(Key));
		InsertAsLast(T.Values[hKey], DeepCopy(Value));
	end;
end;

{ Devuelve una copia de la expresión almacenada bajo la clave dada }
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

{ sustituye '%' por el último resultado conocido }
function ReplaceInString(S : String; Rx : String) : String;
begin
	ReplaceInString:=AnsiReplaceStr(S,'%',Rx);
end;

{ evaluación de E (cadena) }
procedure FrontEndEval(E : String; var Ker : TKernel; var ec : TException);

{ Evalúa la expresión Ex de forma recursiva (de las hojas hacia arriba) }

{ 	+ La evaluación puede modificar el núcleo Ker y devuelve un código de resultado en ec }
{ 	+ El cliente se hace responsable de la memoria dinámica del resultado }
function EvaluateExpr(Ex : Expr; var Ker : TKernel; var ec : TException) : Expr;
var
	Exi, Exj : TExprIt;
	Ri : Expr;	
begin
	ec.nError:=0; ec.Msg:='';

	{ primero evalúa las sub-expresiones }
	MoveToFirst(Ex^.SubExprs, Exi);
	
	while ((ec.nError = 0) and (IsAtNode(Exi))) do
	begin
		Ri:=EvaluateExpr(ExprAt(Exi), Ker, ec);

		{ si no hay error, continúa }	
		if (ec.nError = 0) then
		begin
			{ guarda el resultado como sub-expresión de Ex }
			Ri:=SwitchExprAt(Exi,Ri);

			{ elimina la que había antes }
			ReleaseExpr(Ri);

			MoveToNext(Exi);
		end;
	end;

	{ después, evalúa la raíz }
	if (ec.nError = 0) then
	begin
		if (Ex^.Head = 'Symbol') then
		begin
			{ si no es '%' - por ejemplo, evaluar "A1" }
			if (Ex^.Terminal <> '%') then
			begin
				{ evaluación de un símbolo - puede tener un valor asociado en la tabla de símbolos }
				EvaluateExpr:=RecallFrom(Ker.Defs, Ex);
				
				{ si no lo tiene, devuelve el propio símbolo }
				if (EvaluateExpr = Nil) then
					EvaluateExpr:=DeepCopy(Ex);
			end
			else
				{ la evaluación de % es el "último resultado conocido" }
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
			{ devuelve una expresión 'True', o 'False' (símbolos) }
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
		{ muestra los símbolos en la tabla del núcleo }
		SaveSymbolTableInto(Output, Ker)
	else
	begin
		{ construye el árbol de expresión }
		Ex:=ParseExpr(E);
		
		{ asignación - Set[LHS,RHS] asigna al lado izquierdo LHS el resultado de evaluar RHS }
		if (Ex^.Head = 'Set') then
		begin
			if (SubExpr(Ex,1)^.Head <> 'Symbol') then
			begin
				ec.nError:=1; ec.Msg:='Únicamente se pueden asignar valores a símbolos';
			end
			else
			begin
				{ evalúa la parte derecha de la asignación }
				Rx:=EvaluateExpr(SubExpr(Ex, 2), Ker, ec);
				
				{ si no hubo error }
				if (ec.nError = 0) then
				begin
					{ almacena el resultado, asociado a la parte izquierda }
					StoreInto(Ker.Defs, SubExpr(Ex, 1), Rx);
				
					{ guarda como último resultado conocido }
					StoreLastKnownResult(Ker, Rx);
				end
				else
				begin
					ec.Msg:='Error al evaluar el lado derecho de la asignación : ' + ec.Msg;
				
					{ error, libera la memoria utilizada }
					ReleaseExpr(Rx);
				end;
			end;
		end
		else
		begin
			{ evaluación de otras expresiones (no Set) }
			Rx:=EvaluateExpr(Ex, Ker, ec);

			{ si no hubo error }
			if (ec.nError = 0) then
			begin
				{ guarda como último resultado conocido }
				StoreLastKnownResult(Ker, Rx);
			end
			else
			begin
				ec.Msg:='Error al evaluar la expresión : ' + ec.Msg;

				{ error, libera la memoria utilizada }
				ReleaseExpr(Rx);
			end;
		end;
		{ libera el árbol de expresión }
		ReleaseExpr(Ex);
	end;
end;

begin
end.
