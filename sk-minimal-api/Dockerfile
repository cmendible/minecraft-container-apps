# Imagen base
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /app

# Copiar csproj y restaurar dependencias
COPY *.csproj ./
RUN dotnet restore

# Copiar todo y construir
COPY . ./
RUN dotnet publish -c Release -o out

# Generar imagen de ejecución
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

COPY --from=build-env /app/out .

EXPOSE 8080

ENTRYPOINT ["dotnet", "sk-minimal-api.dll"]