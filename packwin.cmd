mkdir package
7z a -tzip package\TypingGame.love *.lua fonts\* graphics\* sound\* dictionary.txt
cd package
copy /b L:\tools\L2d\love.exe+TypingGame.love TypingGame.exe
xcopy /y/d L:\tools\L2d\*.dll .
xcopy /y/d L:\tools\L2d\license.txt .
REM del TypingGame.love
cd ..
