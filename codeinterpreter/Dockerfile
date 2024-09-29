# Use the official .NET Core SDK image as the base image
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /app
COPY ["./CodeInterpreter.csproj", "./"]
RUN dotnet restore "./CodeInterpreter.csproj"
COPY . ./
RUN dotnet build "./CodeInterpreter.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "./CodeInterpreter.csproj" -c Release -o /app/publish

FROM build AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "CodeInterpreter.dll"]