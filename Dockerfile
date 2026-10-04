# ---- build stage ----
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

ARG BUILD_VERSION=1.0.0.0

COPY src/DockerRazorDemo.csproj .
RUN dotnet restore

COPY src/. .
RUN dotnet publish -c Release -o /app/publish --no-restore \
    -p:Version=${BUILD_VERSION} -p:AssemblyVersion=${BUILD_VERSION}

# ---- runtime stage ----
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

USER $APP_UID

ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

COPY --from=build /app/publish .

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "DockerRazorDemo.dll"]
