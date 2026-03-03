FROM mcr.microsoft.com/dotnet/runtime:7.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["PropertEase.Worker/PropertEase.Worker.csproj", "PropertEase.Worker/"]
RUN dotnet restore "PropertEase.Worker/PropertEase.Worker.csproj"
COPY . .
WORKDIR "/src/PropertEase.Worker"
RUN dotnet build "PropertEase.Worker.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PropertEase.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "PropertEase.Worker.dll"]
