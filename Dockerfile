FROM microsoft/windowsservercore:1709

RUN ["powershell", "New-Item", "c:/tests"]

