program FrontEnd;
{$H-}

uses
	ExprShared, Kernel, ExprTree, SysUtils;

procedure ShowHelpFile(Name : String);
var
	fin : Text; B : String;
begin
	if (FileExists(Name)) then
	begin
		Assign(fin, Name); Reset(fin);
		while not EOF(fin) do
		begin
			ReadLn(fin, B); WriteLn(B);
		end;
		Close(fin);
	end
	else
		WriteLn('Ayuda no disponible');
end;
	
procedure ShowHelpOnTopic(E : String);
var
	HelpFile : Text; HelpFileName : String; B : String;
begin
	if (Length(E) = 1) then
		ShowHelpFile('help/index')
	else
		ShowHelpFile('help/' + Trim(Copy(E,2,Length(E))));
end;

var
	E : String; ec : TException; K1 : TKernel; fin : Text; FileName : String; nExpr : Word;
	
begin
	StartKernel(K1); nExpr:=1;
	
	WriteLn('(* Introduzca expresiones para evaluar *)');
	WriteLn('(* Con % se accede al último resultado *)');
	WriteLn('(* Con ? se muestra ayuda *)');
	WriteLn('(* ready *)');	
	
	while not EOF do 
	begin
		ReadLn(E);

		if (Pos('?', E) = 1) then
		begin
			{ ayuda sobre expresiones }
			ShowHelpOnTopic(E);
		end
		else
		begin
			if (Pos('<<', E) = 1) then
			begin
				FileName:=Trim(Copy(E, 3, Length(E)));
				
				Assign(fin, FileName); Reset(fin);
				
				while not EOF(fin) do
				begin
					ReadLn(fin, E);

					if (Pos('(*', E) <> 1) then
					begin					
						FrontEndEval(E, K1, ec);
						
						if (ec.nError <> 0) then
						begin
							WriteLn('(* Error al evaluar ', E, ': ', ec.Msg, '*)');
						end
						else
						begin
							WriteLn('In[', K1.nExprEval, ']:=', E);
							WriteLn('Out[', K1.nExprEval, ']:=', ExprToStr(K1.E1));
						end;
					end;
				end;
				
				Close(fin);					
			end
			else if (Pos('>>', E) = 1) then
			begin
				FileName:=Trim(Copy(E, 3, Length(E)));
				
				Assign(fin, FileName); Rewrite(fin);
				
				SaveSymbolTableInto(fin, K1);
				
				Close(fin);
			end
			else
			begin
				{ evaluación }
				FrontEndEval(E, K1, ec);
			
				if (ec.nError <> 0) then
				begin
					WriteLn('(* Error al evaluar ', E, ': ', ec.Msg, '*)');
				end
				else
				begin
					WriteLn('In[', K1.nExprEval, ']:=', E);
					WriteLn('Out[', K1.nExprEval, ']:=', ExprToStr(K1.E1));
				end;
			end;
		end;
				
		WriteLn('(* ready *)');	
	end;
	
	StopKernel(K1);
end.
