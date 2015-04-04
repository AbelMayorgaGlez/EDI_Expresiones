unit Ejercicios;
{$H-}

interface

uses
	Math, SysUtils, ExprShared, ExprTree, CoreFunctions;

{ Ejercicios }

function Join(X : Expr; var ec : TException) : Expr;
function Sort(X : Expr; var ec : TException) : Expr;
function Partition(X : Expr; n : Expr; var ec : TException) : Expr;
function Flatten(X : Expr; var ec : TException) : Expr;
function ReplaceAll(X : Expr; Y : Expr; var ec : TException) : Expr;
function Tally(X : Expr; var ec : TException) : Expr;
function Depth(A : Expr) : Expr;
function First(A : Expr; var ec : TException) : Expr;
procedure MatrixForm(X : Expr; var ec : TException);
function RemoveAll(X : Expr; Y : Expr) : Expr;
function Part(X : Expr; Spec : Expr; var ec : TException) : Expr;
function PartsOfTerminalNodes(X : Expr; var ec : TException) : Expr;

implementation
function Join(X : Expr; var ec : TException) : Expr; begin Join:=nil; end;
function Sort(X : Expr; var ec : TException) : Expr; begin Sort:=nil; end;
function Partition(X : Expr; n : Expr; var ec : TException) : Expr; begin Partition:=nil; end;
function Flatten(X : Expr; var ec : TException) : Expr; begin Flatten:=nil; end;
function ReplaceAll(X : Expr; Y : Expr; var ec : TException) : Expr; begin ReplaceAll:=nil; end;
function Tally(X : Expr; var ec : TException) : Expr; begin Tally:=nil; end;
function Depth(A : Expr) : Expr; begin Depth:=nil; end;
function First(A : Expr; var ec : TException) : Expr; begin First:=nil; end;
procedure MatrixForm(X : Expr; var ec : TException); begin end;
function RemoveAll(X : Expr; Y : Expr) : Expr; begin RemoveAll:=nil; end;
function Part(X : Expr; Spec : Expr; var ec : TException) : Expr; begin Part:=nil; end;
function PartsOfTerminalNodes(X : Expr; var ec : TException) : Expr; begin PartsOfTerminalNodes:=nil; end;


begin
end.
