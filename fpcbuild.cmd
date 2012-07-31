FOR /F "tokens=*" %%G IN ('dir /b examples\*.dpr') DO fpc -FEbin -Fu..\ -FUdcu -Mdelphi examples\%%G
