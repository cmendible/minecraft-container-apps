FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

COPY ./dapr.minecraft.poll/dapr.minecraft.poll.csproj ./dapr.minecraft.poll/dapr.minecraft.poll.csproj
RUN dotnet restore ./dapr.minecraft.poll/dapr.minecraft.poll.csproj

# Copy everything else and build website
COPY ./dapr.minecraft.poll/ ./dapr.minecraft.poll/
WORKDIR /src/dapr.minecraft.poll/
RUN dotnet publish -c release

# Final stage / image
FROM mcr.microsoft.com/dotnet/aspnet:7.0
COPY --from=build /src/dapr.minecraft.poll/bin/release/net7.0/publish ./
ENTRYPOINT ["dotnet", "dapr.minecraft.poll.dll"]