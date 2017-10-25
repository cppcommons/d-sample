//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "Unit1.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TForm1 *Form1;
//---------------------------------------------------------------------------
__fastcall TForm1::TForm1(TComponent* Owner)
	: TForm(Owner)
{
}
//---------------------------------------------------------------------------
void __fastcall TForm1::Button1Click(TObject *Sender)
{
MessageBoxA(
	NULL, //_In_opt_ HWND hWnd,
	"text", //_In_opt_ LPCSTR lpText,
	"caption", //_In_opt_ LPCSTR lpCaption,
	MB_OK //_In_ UINT uType
	);
}
//---------------------------------------------------------------------------
