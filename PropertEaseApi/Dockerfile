FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["PropertEaseApi/PropertEase.csproj", "PropertEaseApi/"]
COPY ["PropertEase.Core/PropertEase.Core.csproj", "PropertEase.Core/"]
COPY ["PropertEase.Infrastructure/PropertEase.Infrastructure.csproj", "PropertEase.Infrastructure/"]
COPY ["PropertEase.Services/PropertEase.Services.csproj", "PropertEase.Services/"]
COPY ["PropertEase.Shared/PropertEase.Shared.csproj", "PropertEase.Shared/"]

RUN dotnet restore "PropertEaseApi/PropertEase.csproj"

COPY . .
WORKDIR "/src/PropertEaseApi"
RUN dotnet build "PropertEase.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PropertEase.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "PropertEase.dll"]
