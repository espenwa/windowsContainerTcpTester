FROM microsoft/windowsservercore:1709
SHELL ["powershell", "-Command","$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
WORKDIR /scripts
EXPOSE 1709

COPY tcpPingPong.ps1 c:/scripts/
COPY library.ps1 c:/scripts/

ENTRYPOINT ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

CMD ["./tcpPingPong.ps1"]