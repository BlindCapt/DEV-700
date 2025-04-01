using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Application.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Authorization;

var builder = WebApplication.CreateBuilder(args);

// Configuration explicite des URLs pour écouter sur toutes les interfaces
builder.WebHost.ConfigureKestrel(options => {
    options.Listen(System.Net.IPAddress.Any, 5094);
});

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Ajout du DbContext avec PostgreSQL
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add services to the container.
builder.Services.AddControllers();  // Assurez-vous que cette ligne est présente
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Ajoutez ces lignes pour enregistrer ProductService et HttpClient
builder.Services.AddHttpClient();  // Nécessaire pour ProductService
builder.Services.AddScoped<ProductService>();

// Modifier la configuration CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend",
        policy =>
        {
            policy.AllowAnyOrigin()  // Permettre toutes les origines
                  .AllowAnyHeader()
                  .AllowAnyMethod();
            // Note: AllowAnyOrigin et AllowCredentials ne peuvent pas être utilisés ensemble
            // Si vous avez besoin de credentials, utilisez WithOrigins spécifique à la place
        });
});

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8
                .GetBytes(builder.Configuration.GetSection("JWT:Key").Value!)),
            ValidateIssuer = false,
            ValidateAudience = false
        };
    });

builder.Services.AddAuthorization(options =>
{
    // Politiques pour les utilisateurs web
    options.AddPolicy("RequireWebUser", policy => 
        policy.RequireClaim("UserType", "WebUser"));
        
    options.AddPolicy("RequireManagerRole", policy => 
        policy.RequireClaim("UserType", "WebUser")
              .RequireRole("Manager"));
              
    options.AddPolicy("RequireEmployeeRole", policy => 
        policy.RequireClaim("UserType", "WebUser")
              .RequireRole("Manager", "Employee"));
    
    // Politiques pour les utilisateurs mobiles
    options.AddPolicy("RequireMobileUser", policy => 
        policy.RequireClaim("UserType", "MobileUser"));
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Déplacer CORS avant les autres middlewares
app.UseCors("AllowFrontend");

// Commenté pour éviter les problèmes de redirection
// app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

// Initialiser la base de données avec les données de test
Infrastructure.Data.DbInitializer.Initialize(app.Services);

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
