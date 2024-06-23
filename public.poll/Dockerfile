# Use the official .NET Core SDK image as the base image
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /
COPY ./Public.Poll.Client/ .

WORKDIR /Public.Poll
COPY ["./Public.Poll/Public.Poll.csproj", "./"]
RUN dotnet restore "./Public.Poll.csproj"
COPY ./Public.Poll/ .
RUN dotnet build "./Public.Poll.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "./Public.Poll.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Public.Poll.dll"]