using FluentValidation;
using FluentValidation.AspNetCore;
using PropertEase.Infrastructure;
using PropertEase.Infrastructure.Mapper;
using PropertEase.Infrastructure.Messaging;
using PropertEase.Infrastructure.Repositories.ApplicationRolesRepository;
using PropertEase.Infrastructure.Repositories.ApplicationUserRolesRepository;
using PropertEase.Infrastructure.Repositories.ApplicationUsersRepository;
using PropertEase.Infrastructure.Repositories.ConversationRepository;
using PropertEase.Infrastructure.Repositories.MessageRepository;
using PropertEase.Infrastructure.Repositories.NotificationRepository;
using PropertEase.Infrastructure.Repositories.PaymentRepository;
using PropertEase.Infrastructure.Repositories.PersonsRepository;
using PropertEase.Infrastructure.Repositories.PhotoRepository;
using PropertEase.Infrastructure.Repositories.PropertyRatingRepository;
using PropertEase.Infrastructure.Repositories.UserRatingRepository;
using PropertEase.Infrastructure.Repositories.PropertyRepository;
using PropertEase.Infrastructure.Repositories.PropertyReservationRepository;
using PropertEase.Infrastructure.Repositories.PropertyTypeRepository;
using PropertEase.Infrastructure.Seed;
using PropertEase.Infrastructure.UnitOfWork;
using PropertEase.Core.Entities.Identity;
using PropertEase.Services.AccessManager;
using PropertEase.Services.EnumManager;
using PropertEase.Services.FileManager;
using PropertEase.Services.Recommendations;
using PropertEase.Services.Reports;
using PropertEase.Services.Services.ApplicationRolesService;
using PropertEase.Services.Services.ApplicationUserRolesService;
using PropertEase.Services.Services.ApplicationUsersService;
using PropertEase.Services.Services.ConversationService;
using PropertEase.Services.Services.MessageService;
using PropertEase.Services.Services.NotificationService;
using PropertEase.Services.Services.PhotoService;
using PropertEase.Services.Services.PaymentService;
using PropertEase.Services.Services.PropertyRatingService;
using PropertEase.Services.Services.UserRatingService;
using PropertEase.Services.Services.PropertyReservationBackgroundService;
using PropertEase.Services.Services.PropertyReservationService;
using PropertEase.Services.Services.PropertyService;
using PropertEase.Services.Services.PropertyTypeService;
using PropertEase.Services.Validation;
using PropertEase.Shared.Constants;
using PropertEase.Shared.Models;
using PropertEase.Shared.Services.Crypto;
using PropertEase.Shared.Services.LoggedUserData;
using PropertEase.Shared.Services.TokenBlacklist;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption.ConfigurationModel;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using PropertEase.Infrastructure.Repositories.CountryRepository;
using PropertEase.Infrastructure.Repositories.ReservationNotificationRepository;
using PropertEase.Services.Services.ReservationNotificationService;
using PropertEase.Services.Services.CountryService;
using PropertEase.Infrastructure.Repositories.CityRepository;
using PropertEase.Services.Services.CityService;
using Microsoft.AspNetCore.SignalR;
using PropertEase.Api.Hubs;
using PropertEase.Api.Workers;
using PropertEase.Shared.Hubs;
using Swashbuckle.AspNetCore.Filters;
using System.Text;
using PropertEase.Api.Middleware;

// Load .env file for local development — Docker already injects these as real env vars
var envFile = Path.Combine(Directory.GetCurrentDirectory(), "..", ".env");
if (File.Exists(envFile))
{
    foreach (var line in File.ReadAllLines(envFile))
    {
        if (string.IsNullOrWhiteSpace(line) || line.TrimStart().StartsWith('#')) continue;
        var parts = line.Split('=', 2);
        if (parts.Length == 2)
            Environment.SetEnvironmentVariable(parts[0].Trim(), parts[1].Trim());
    }
}

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddEnvironmentVariables();

// DATABASE
builder.Services.AddDbContext<DatabaseContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sql => sql.CommandTimeout(60)));

// AUTOMAPPER 
builder.Services.AddAutoMapper(typeof(Program), typeof(Profiles));

// FLUENTVALIDATION 
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<PropertyReservationValidator>();

//  API 
builder.Services.AddSession();
builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient();
builder.Services.AddControllers()
    .AddNewtonsoftJson(opt =>
        opt.SerializerSettings.ReferenceLoopHandling = Newtonsoft.Json.ReferenceLoopHandling.Ignore);
builder.Services.AddSignalR();
builder.Services.AddSingleton<IUserIdProvider, NotificationUserIdProvider>();
builder.Services.AddHostedService<NotificationPushWorker>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.Configure<FormOptions>(o =>
{
    o.ValueLengthLimit = int.MaxValue;
    o.MultipartBodyLengthLimit = int.MaxValue;
    o.MemoryBufferThreshold = int.MaxValue;
});

// RABBITMQ 
builder.Services.Configure<RabbitMQSettings>(builder.Configuration.GetSection("RabbitMQ"));
builder.Services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();

//  CUSTOM SERVICES 
builder.Services.AddScoped<ILoggedUserData, LoggedUserData>();
builder.Services.AddSingleton<ITokenBlacklistService, TokenBlacklistService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddSingleton<ICrypto, Crypto>();
builder.Services.AddScoped<IFileManager, FileManager>();
builder.Services.AddScoped<IEnumManager, EnumManager>();
builder.Services.AddScoped<IReportService, ReportService>();

//  RECOMMENDATION ENGINE 
builder.Services.Configure<RecommendationConfig>(
    builder.Configuration.GetSection("RecommendationEngine"));
builder.Services.AddScoped<IRecommendationEngine, AssociationRulesEngine>();

//  REPOSITORIES 
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<IApplicationUsersRepository, ApplicationUsersRepository>();
builder.Services.AddScoped<IApplicationRolesRepository, ApplicationRolesRepository>();
builder.Services.AddScoped<IApplicationUserRolesRepository, ApplicationUserRolesRepository>();
builder.Services.AddScoped<IPersonsRepository, PersonsRepository>();
builder.Services.AddScoped<IPropertyTypeRepository, PropertyTypeRepository>();
builder.Services.AddScoped<IPropertyRepository, PropertyRepository>();
builder.Services.AddScoped<IPropertyReservationRepository, PropertyReservationRepository>();
builder.Services.AddScoped<IPropertyRatingRepository, PropertyRatingRepository>();
builder.Services.AddScoped<IUserRatingRepository, UserRatingRepository>();
builder.Services.AddScoped<IPhotoRepository, PhotoRepository>();
builder.Services.AddScoped<IConversationRepository, ConversationRepository>();
builder.Services.AddScoped<IMessageRepository, MessageRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<ICityRepository, CityRepository>();
builder.Services.AddScoped<ICountryRepository, CountryRepository>();
builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<IReservationNotificationRepository, ReservationNotificationRepository>();

//  SERVICES 
builder.Services.AddScoped<IApplicationUsersService, ApplicationUsersService>();
builder.Services.AddScoped<IApplicationUserRolesService, ApplicationUserRolesService>();
builder.Services.AddScoped<IApplicationRolesService, ApplicationRolesService>();
builder.Services.AddScoped<IPropertyTypeService, PropertyTypeService>();
builder.Services.AddScoped<IPropertyService, PropertyService>();
builder.Services.AddScoped<IPropertyRatingService, PropertyRatingService>();
builder.Services.AddScoped<IUserRatingService, UserRatingService>();
builder.Services.AddScoped<IPropertyReservationService, PropertyReservationService>();
builder.Services.AddScoped<IPhotoService, PhotoService>();
builder.Services.AddScoped<IConversationService, ConversationService>();
builder.Services.AddScoped<IMessageService, MessageService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IReservationNotificationService, ReservationNotificationService>();
builder.Services.AddHostedService<PropertyReservationBackgroundService>();

//  DATA PROTECTION 
builder.Services.AddDataProtection()
    .UseCryptographicAlgorithms(new AuthenticatedEncryptorConfiguration
    {
        EncryptionAlgorithm = EncryptionAlgorithm.AES_256_GCM,
        ValidationAlgorithm = ValidationAlgorithm.HMACSHA256
    })
    .SetApplicationName("PropertEase");

//  IDENTITY 
builder.Services.Configure<JWTConfig>(builder.Configuration.GetSection("JWTConfig"));
builder.Services.Configure<CookiePolicyOptions>(options =>
{
    options.CheckConsentNeeded = _ => false;
    options.Secure = CookieSecurePolicy.SameAsRequest;
    options.HttpOnly = Microsoft.AspNetCore.CookiePolicy.HttpOnlyPolicy.Always;
});
builder.Services.AddMemoryCache();
builder.Services.AddDistributedMemoryCache();

builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(options =>
{
    options.SignIn.RequireConfirmedAccount = false;
    options.Password = new PasswordOptions
    {
        RequireDigit = true,
        RequiredLength = 6,
        RequireLowercase = true,
        RequireUppercase = true,
        RequireNonAlphanumeric = false,
        RequiredUniqueChars = 0
    };
})
.AddEntityFrameworkStores<DatabaseContext>()
.AddDefaultTokenProviders();

//  JWT AUTHENTICATION 
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "PropertEase API", Version = "v1" });
    options.AddSecurityDefinition("oauth2", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Description = "Enter: Bearer {your JWT token}"
    });
    options.OperationFilter<SecurityRequirementsOperationFilter>();
});

var jwtTokenKey = builder.Configuration["JWTConfig:TokenKey"]
    ?? throw new InvalidOperationException("JWT TokenKey is not configured.");

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtTokenKey)),
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateLifetime = true
    };
    
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var path = context.HttpContext.Request.Path;
            if (!path.StartsWithSegments("/hubs/messageHub"))
                return Task.CompletedTask;

            // signalr_core (Flutter) sends the token as Authorization: Bearer for
            // negotiate (HTTP) and as ?access_token= for WebSocket upgrade; handle both.
            var accessToken = context.Request.Query["access_token"].ToString();
            if (string.IsNullOrEmpty(accessToken))
            {
                var auth = context.Request.Headers.Authorization.ToString();
                if (auth.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                    accessToken = auth["Bearer ".Length..];
            }
            if (!string.IsNullOrEmpty(accessToken))
                context.Token = accessToken;

            return Task.CompletedTask;
        }
    };
});

//  CORS 
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "https://localhost:44340" };

builder.Services.AddCors(opt =>
    opt.AddPolicy("DefaultCors", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials()));

//  LOGGING 
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

// BUILD 
var app = builder.Build();

// ─── MIGRATE + SEED DATABASE ─────────────────────────────────────────────────
{
    const int maxRetries = 10;
    for (int attempt = 1; attempt <= maxRetries; attempt++)
    {
        using var scope = app.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<PropertEase.Infrastructure.DatabaseContext>();
        try
        {
            db.Database.Migrate();
            break;
        }
        catch (Exception ex) when (attempt < maxRetries)
        {
            var startupLogger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
            startupLogger.LogWarning("Migration attempt {Attempt}/{Max} failed: {Message}. Retrying in 5s...", attempt, maxRetries, ex.Message);
            Thread.Sleep(5000);
        }
    }
}
await DatabaseSeeder.SeedAsync(app.Services);

//  MIDDLEWARE PIPELINE 
app.UseSwagger();
app.UseSwaggerUI(c =>
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "PropertEase API V1"));

app.UseMiddleware<RequestLoggingMiddleware>();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<TokenBlacklistMiddleware>();

if (!app.Environment.IsDevelopment())
    app.UseHttpsRedirection();
app.UseSession();
app.UseStaticFiles();
app.UseCors("DefaultCors");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<MessageHub>("/hubs/messageHub");

await app.RunAsync();
