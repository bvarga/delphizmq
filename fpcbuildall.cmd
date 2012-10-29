FOR /F "tokens=*" %%G IN ('"dir /b examples\*.dpr | findstr /e .dpr"') DO fpc -FEbin -Fu..\ -FUdcu -Mdelphi examples\%%G
FOR /F "tokens=*" %%G IN ('"dir /b perf\*.dpr | findstr /e .dpr"') DO fpc -FEbin -Fu..\ -FUdcu -Mdelphi perf\%%G
