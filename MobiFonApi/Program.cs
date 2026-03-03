using FluentValidation;
using FluentValidation.AspNetCore;
using MobiFon.Infrastructure;
using MobiFon.Infrastructure.Mapper;
using MobiFon.Infrastructure.Messaging;
using MobiFon.Infrastructure.Repositories.ApplicationRolesRepository;
using MobiFon.Infrastructure.Repositories.ApplicationUserRolesRepository;
using MobiFon.Infrastructure.Repositories.ApplicationUsersRepository;
using MobiFon.Infrastructure.Repositories.ConversationRepository;
using MobiFon.Infrastructure.Repositories.MessageRepository;
using MobiFon.Infrastructure.Repositories.NotificationRepository;
using MobiFon.Infrastructure.Repositories.PersonsRepository;
using MobiFon.Infrastructure.Repositories.PhotoRepository;
using MobiFon.Infrastructure.Repositories.PropertyRatingRepository;
using MobiFon.Infrastructure.Repositories.PropertyRepository;
using MobiFon.Infrastructure.Repositories.PropertyReservationRepository;
using MobiFon.Infrastructure.Repositories.PropertyTypeRepository;
using MobiFon.Infrastructure.Seed;
using MobiFon.Infrastructure.UnitOfWork;
using MobiFon.Core.Entities.Identity;
using MobiFon.Services.AccessManager;
using MobiFon.Services.EnumManager;
using MobiFon.Services.FileManager;
using MobiFon.Services.Recommendations;
using MobiFon.Services.Reports;
using MobiFon.Services.Services.ApplicationRolesService;
using MobiFon.Services.Services.ApplicationUserRolesService;
using MobiFon.Services.Services.ApplicationUsersService;
using MobiFon.Services.Services.ConversationService;
using MobiFon.Services.Services.MessageService;
using MobiFon.Services.Services.NotificationService;
using MobiFon.Services.Services.PhotoService;
using MobiFon.Services.Services.PropertyRatingService;
using MobiFon.Services.Services.PropertyReservationBackgroundService;
using MobiFon.Services.Services.PropertyReservationService;
using MobiFon.Services.Services.PropertyService;
using MobiFon.Services.Services.PropertyTypeService;
using MobiFon.Services.Validation;
using MobiFon.Shared.Constants;
using MobiFon.Shared.Models;
using MobiFon.Shared.Services.Crypto;
using MobiFon.Shared.Services.LoggedUserData;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption.ConfigurationModel;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using PropertEase.Infrastructure.Repositories.CityRepository;
using PropertEase.Services.Services.CityService;
using PropertEase.Shared.Hubs;
using Swashbuckle.AspNetCore.Filters;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ─── DATABASE ────────────────────────────────────────────────────────────────
builder.Services.AddDbContext<DatabaseContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")));

// ─── AUTOMAPPER ──────────────────────────────────────────────────────────────
builder.Services.AddAutoMapper(typeof(Program), typeof(Profiles));

// ─── FLUENTVALIDATION ────────────────────────────────────────────────────────
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<PropertyReservationValidator>();

// ─── HTTP / API ──────────────────────────────────────────────────────────────
builder.Services.AddSession();
builder.Services.AddHttpContextAccessor();
builder.Services.AddControllers()
    .AddNewtonsoftJson(opt =>
        opt.SerializerSettings.ReferenceLoopHandling = Newtonsoft.Json.ReferenceLoopHandling.Ignore);
builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.Configure<FormOptions>(o =>
{
    o.ValueLengthLimit = int.MaxValue;
    o.MultipartBodyLengthLimit = int.MaxValue;
    o.MemoryBufferThreshold = int.MaxValue;
});

// ─── RABBITMQ ────────────────────────────────────────────────────────────────
builder.Services.Configure<RabbitMQSettings>(builder.Configuration.GetSection("RabbitMQ"));
builder.Services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();

// ─── CUSTOM SERVICES ─────────────────────────────────────────────────────────
builder.Services.AddScoped<ILoggedUserData, LoggedUserData>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddSingleton<ICrypto, Crypto>();
builder.Services.AddScoped<IFileManager, FileManager>();
builder.Services.AddScoped<IEnumManager, EnumManager>();
builder.Services.AddScoped<IReportService, ReportService>();

// ─── RECOMMENDATION ENGINE ───────────────────────────────────────────────────
builder.Services.Configure<RecommendationConfig>(
    builder.Configuration.GetSection("RecommendationEngine"));
builder.Services.AddScoped<IRecommendationEngine, AssociationRulesEngine>();

// ─── REPOSITORIES ────────────────────────────────────────────────────────────
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddScoped<IApplicationUsersRepository, ApplicationUsersRepository>();
builder.Services.AddScoped<IApplicationRolesRepository, ApplicationRolesRepository>();
builder.Services.AddScoped<IApplicationUserRolesRepository, ApplicationUserRolesRepository>();
builder.Services.AddScoped<IPersonsRepository, PersonsRepository>();
builder.Services.AddScoped<IPropertyTypeRepository, PropertyTypeRepository>();
builder.Services.AddScoped<IPropertyRepository, PropertyRepository>();
builder.Services.AddScoped<IPropertyReservationRepository, PropertyReservationRepository>();
builder.Services.AddScoped<IPropertyRatingRepository, PropertyRatingRepository>();
builder.Services.AddScoped<IPhotoRepository, PhotoRepository>();
builder.Services.AddScoped<IConversationRepository, ConversationRepository>();
builder.Services.AddScoped<IMessageRepository, MessageRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<ICityRepository, CityRepository>();

// ─── SERVICES ────────────────────────────────────────────────────────────────
builder.Services.AddScoped<IApplicationUsersService, ApplicationUsersService>();
builder.Services.AddScoped<IApplicationUserRolesService, ApplicationUserRolesService>();
builder.Services.AddScoped<IApplicationRolesService, ApplicationRolesService>();
builder.Services.AddScoped<IPropertyTypeService, PropertyTypeService>();
builder.Services.AddScoped<IPropertyService, PropertyService>();
builder.Services.AddScoped<IPropertyRatingService, PropertyRatingService>();
builder.Services.AddScoped<IPropertyReservationService, PropertyReservationService>();
builder.Services.AddScoped<IPhotoService, PhotoService>();
builder.Services.AddScoped<IConversationService, ConversationService>();
builder.Services.AddScoped<IMessageService, MessageService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddHostedService<PropertyReservationBackgroundService>();

// ─── DATA PROTECTION ─────────────────────────────────────────────────────────
builder.Services.AddDataProtection()
    .UseCryptographicAlgorithms(new AuthenticatedEncryptorConfiguration
    {
        EncryptionAlgorithm = EncryptionAlgorithm.AES_256_GCM,
        ValidationAlgorithm = ValidationAlgorithm.HMACSHA256
    })
    .SetApplicationName("PropertEase");

// ─── IDENTITY ────────────────────────────────────────────────────────────────
builder.Services.Configure<JWTConfig>(builder.Configuration.GetSection("JWTConfig"));
builder.Services.Configure<CookiePolicyOptions>(options =>
{
    options.CheckConsentNeeded = _ => false;
    options.Secure = CookieSecurePolicy.SameAsRequest;
    options.HttpOnly = Microsoft.AspNetCore.CookiePolicy.HttpOnlyPolicy.Always;
});
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

// ─── JWT AUTHENTICATION ───────────────────────────────────────────────────────
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
});

// ─── CORS ────────────────────────────────────────────────────────────────────
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "https://localhost:44340" };

builder.Services.AddCors(opt =>
    opt.AddPolicy("DefaultCors", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials()));

// ─── LOGGING ─────────────────────────────────────────────────────────────────
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

// ─── BUILD ───────────────────────────────────────────────────────────────────
var app = builder.Build();

// ─── SEED DATABASE ────────────────────────────────────────────────────────────
await DatabaseSeeder.SeedAsync(app.Services);

// ─── MIDDLEWARE PIPELINE ─────────────────────────────────────────────────────
app.UseSwagger();
app.UseSwaggerUI(c =>
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "PropertEase API V1"));

if (app.Environment.IsDevelopment())
    app.UseDeveloperExceptionPage();

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
