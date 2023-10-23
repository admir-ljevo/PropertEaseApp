using MobiFon.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.OpenApi.Models;
using MobiFon.Core.Entities.Identity;
using MobiFon.Shared.Models;
using Swashbuckle.AspNetCore.Filters;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using System.Text;
using MobiFon.Shared.Constants;
using MobiFon.Infrastructure.Mapper;
using MobiFon.Shared.Services.LoggedUserData;
using MobiFon.Services.AccessManager;
using MobiFon.Services.EnumManager;
using MobiFon.Services.FileManager;
using MobiFon.Shared.Services.Crypto;
using MobiFon.Infrastructure.UnitOfWork;
using MobiFon.Infrastructure.Repositories.ApplicationUsersRepository;
using MobiFon.Infrastructure.Repositories.ApplicationRolesRepository;
using MobiFon.Infrastructure.Repositories.ApplicationUserRolesRepository;
using MobiFon.Services.Services.ApplicationRolesService;
using MobiFon.Services.Services.ApplicationUsersService;
using MobiFon.Services.Services.ApplicationUserRolesService;
using MobiFon.Infrastructure.Repositories.PersonsRepository;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption.ConfigurationModel;
using Microsoft.AspNetCore.DataProtection.AuthenticatedEncryption;
using Microsoft.AspNetCore.DataProtection;
using MobiFon.Infrastructure.Repositories.PropertyTypeRepository;
using MobiFon.Services.Services.PropertyTypeService;
using MobiFon.Infrastructure.Repositories.PropertyRepository;
using MobiFon.Services.Services.PropertyService;
using MobiFon.Infrastructure.Repositories.PropertyRatingRepository;
using MobiFon.Services.Services.PropertyRatingService;
using System;
using MobiFon.Services.Services.PhotoService;
using MobiFon.Infrastructure.Repositories.PhotoRepository;
using MobiFon.Services.Services.PropertyReservationService;
using MobiFon.Infrastructure.Repositories.PropertyReservationRepository;
using Microsoft.Extensions.DependencyInjection;
using MobiFon.Services.Services.PropertyReservationBackgroundService;
using MobiFon.Infrastructure.Repositories.ConversationRepository;
using MobiFon.Services.Services.ConversationService;
using MobiFon.Infrastructure.Repositories.MessageRepository;
using MobiFon.Services.Services.MessageService;
using MobiFon.Infrastructure.Repositories.NotificationRepository;
using MobiFon.Services.Services.NotificationService;
using PropertEase.Infrastructure.Repositories.CityRepository;
using PropertEase.Services.Services.CityService;
using PropertEase.Services.Services.ReportingService;
using Microsoft.ReportingServices.Interfaces;


var builder = WebApplication.CreateBuilder(args);

#region DBContext

builder.Services.AddDbContext<DatabaseContext>(options =>
               options.UseSqlServer(
                   builder.Configuration.GetConnectionString("DefaultConnection")));



#endregion

#region MappingAndValidation

builder.Services.AddScoped<ILoggedUserData, LoggedUserData>();
builder.Services.AddAutoMapper(typeof(Program), typeof(Profiles));

#endregion

#region Api

// Add services to the container.
builder.Services.AddSession();
builder.Services.AddHttpContextAccessor();
builder.Services.AddControllers();
builder.Services.AddSignalR();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.Configure<FormOptions>(o =>
{
    o.ValueLengthLimit = int.MaxValue;
    o.MultipartBodyLengthLimit = int.MaxValue;
    o.MemoryBufferThreshold = int.MaxValue;
});

#endregion

#region CustomServices

builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddSingleton<ICrypto, Crypto>();
builder.Services.AddScoped<IFileManager, FileManager>();
builder.Services.AddScoped<IEnumManager, EnumManager>();


#endregion

#region Repositories

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

#endregion

#region Services

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
builder.Services.AddScoped<IReportingService, ReportingService>();
builder.Services.AddHostedService<PropertyReservationBackgroundService>();


#endregion

builder.Services.AddDataProtection()
                .UseCryptographicAlgorithms(new AuthenticatedEncryptorConfiguration()
                {
                    EncryptionAlgorithm = EncryptionAlgorithm.AES_256_GCM,
                    ValidationAlgorithm = ValidationAlgorithm.HMACSHA256
                })
                .SetApplicationName("MyCommonName");

#region AspNetCoreIdentity

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


builder.Services.AddSwaggerGen(options => {
    options.AddSecurityDefinition("oauth2", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey
    });
    options.OperationFilter<SecurityRequirementsOperationFilter>();
});

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(
              options =>
              {
                  options.TokenValidationParameters = new TokenValidationParameters()
                  {
                      ValidateIssuerSigningKey = true,
                      IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration.GetSection(ConfigurationValues.TokenKey).Value)),
                      ValidateIssuer = false,
                      ValidateAudience = false,
                      ValidateLifetime = true
                  };
              });

#endregion

builder.Logging.ClearProviders();
builder.Logging.AddConsole(options =>
{
    // Set the minimum log level here (e.g., LogLevel.Information)
    options.LogToStandardErrorThreshold = LogLevel.Information;
});

var app = builder.Build();

#region App

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
//{
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "My API V1");
});
app.UseDeveloperExceptionPage();
//}

app.UseHttpsRedirection();
app.UseSession();
app.UseAuthentication();
app.UseStaticFiles();

// global cors policy
app.UseCors(x => x
    .AllowAnyMethod()
    .AllowAnyHeader()
    .WithOrigins("https://localhost:44340") // allow any origin
                                        //.WithOrigins("https://localhost:44340")); // Allow only this origin can also have multiple origins separated with comma
    .AllowCredentials()); // allow credentials
app.UseAuthorization();

app.MapControllers();

await app.RunAsync();
#endregion
