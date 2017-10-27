#include <stdio.h>
//#import "C:\winnt\system32\msscript.ocx" // msscript.ocx
#import "C:\Windows\SysWOW64\msscript.ocx" // msscript.ocx
using namespace MSScriptControl;

int main(void)
{
    HRESULT hr = CoInitialize(NULL);

    IScriptControlPtr pScriptControl(__uuidof(ScriptControl));

    // Create a VARIANT array of VARIANTs which hold BSTRs
    LPSAFEARRAY psa;
    SAFEARRAYBOUND rgsabound[] = {3, 0}; // 3 elements, 0-based
    int i;

    psa = SafeArrayCreate(VT_VARIANT, 1, rgsabound);
    if (!psa)
    {
        return E_OUTOFMEMORY;
    }

    VARIANT vFlavors[3];
    for (i = 0; i < 3; i++)
    {
        VariantInit(&vFlavors[i]);
        V_VT(&vFlavors[i]) = VT_BSTR;
    }

    V_BSTR(&vFlavors[0]) = SysAllocString(OLESTR("Vanilla"));
    V_BSTR(&vFlavors[1]) = SysAllocString(OLESTR("Chocolate"));
    V_BSTR(&vFlavors[2]) = SysAllocString(OLESTR("Espresso Chip"));

    long lZero = 0;
    long lOne = 1;
    long lTwo = 2;

    // Put Elements to the SafeArray:
    hr = SafeArrayPutElement(psa, &lZero, &vFlavors[0]);
    hr = SafeArrayPutElement(psa, &lOne, &vFlavors[1]);
    hr = SafeArrayPutElement(psa, &lTwo, &vFlavors[2]);

    // Free Elements from the SafeArray:
    for (i = 0; i < 3; i++)
    {
        SysFreeString(vFlavors[i].bstrVal);
    }

    // Set up Script control properties
    pScriptControl->Language = "JScript";
    pScriptControl->AllowUI = TRUE;
    pScriptControl->AddCode(
        "function MyStringFunction(Argu1,Argu2,Argu3)\
{  return \"hi there\" ;}");

    //  Call MyStringFunction with the two args:
    _variant_t outpar = pScriptControl->Run("MyStringFunction", &psa);

    // Convert VARIANT to C string:
    _bstr_t bstrReturn = (_bstr_t)outpar;
    char *pResult = (char *)bstrReturn;

    // Print the result out:
    printf("func=%s\n", pResult);

    //  Clean up:
    SafeArrayDestroy(psa);

    CoUninitialize();
    return (0);
}
