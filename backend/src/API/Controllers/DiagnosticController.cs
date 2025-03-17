using Microsoft.AspNetCore.Mvc;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using System.Text.Json;
using Core.Entities;
using System;

namespace API.Controllers
{
    [Route("api/diagnostic")]
    [ApiController]
    [AllowAnonymous] // Important pour le diagnostic
    public class DiagnosticController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public DiagnosticController(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers()
        {
            var webUsers = await _context.WebUsers.ToListAsync();
            var mobileUsers = await _context.MobileUsers.ToListAsync();

            return Ok(new 
            {
                webUsersCount = webUsers.Count,
                webUsers = webUsers.Select(u => new 
                {
                    u.Id,
                    u.Username,
                    u.Email,
                    u.FirstName,
                    u.LastName,
                    Role = u.Role.ToString(),
                    PasswordLength = u.Password?.Length ?? 0,
                    PasswordStart = u.Password?.Substring(0, Math.Min(10, u.Password?.Length ?? 0))
                }),
                mobileUsersCount = mobileUsers.Count
            });
        }

        [HttpGet("hash-test")]
        public IActionResult TestHashPassword(string password = "admin")
        {
            var hash = BCrypt.Net.BCrypt.HashPassword(password);
            var staticHash = "$2a$11$Xmj3aNxU5OJBM7/W85J0OO4wh7oGr7a5qnhKnf3I/.bGaW89sliqW"; // Hash for "admin"
            var isValid = BCrypt.Net.BCrypt.Verify(password, staticHash);
            var isDynamicValid = BCrypt.Net.BCrypt.Verify(password, hash);

            return Ok(new {
                providedPassword = password,
                generatedHash = hash,
                staticHash = staticHash,
                isStaticHashValid = isValid,
                isDynamicHashValid = isDynamicValid
            });
        }

        [HttpPost("create-test-user")]
        public async Task<IActionResult> CreateTestUser()
        {
            try
            {
                // Vérifier si l'utilisateur existe déjà
                var existingUser = await _context.WebUsers
                    .FirstOrDefaultAsync(u => u.Username == "testuser");

                if (existingUser != null)
                {
                    return Ok(new { message = "L'utilisateur de test existe déjà", userId = existingUser.Id });
                }

                // Créer un nouvel utilisateur avec BCrypt pour le hachage du mot de passe
                var hashedPassword = BCrypt.Net.BCrypt.HashPassword("password");
                
                var newUser = new WebUser
                {
                    Username = "testuser",
                    Email = "test@example.com",
                    Password = hashedPassword,
                    FirstName = "Test",
                    LastName = "User",
                    Role = WebUserRole.Employee,
                    CreatedAt = DateTime.UtcNow
                };
                
                _context.WebUsers.Add(newUser);
                await _context.SaveChangesAsync();
                
                return Ok(new { message = "Utilisateur de test créé avec succès", userId = newUser.Id });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        [HttpPost("create-mobile-user")]
        public async Task<IActionResult> CreateMobileUser()
        {
            try
            {
                // Vérifier si l'utilisateur mobile existe déjà
                var existingUser = await _context.MobileUsers
                    .FirstOrDefaultAsync(u => u.Email == "test@dev700.com");

                if (existingUser != null)
                {
                    return Ok(new { 
                        message = "L'utilisateur mobile de test existe déjà", 
                        userId = existingUser.Id,
                        email = existingUser.Email
                    });
                }

                // Créer un nouvel utilisateur mobile avec BCrypt pour le hachage du mot de passe
                var hashedPassword = BCrypt.Net.BCrypt.HashPassword("test123");
                
                var newUser = new MobileUser
                {
                    Email = "test@dev700.com",
                    Password = hashedPassword,
                    FirstName = "Test",
                    LastName = "User",
                    PhoneNumber = "0123456789",
                    CreatedAt = DateTime.UtcNow,
                    IsActive = true
                };
                
                _context.MobileUsers.Add(newUser);
                await _context.SaveChangesAsync();
                
                return Ok(new { 
                    message = "Utilisateur mobile de test créé avec succès", 
                    userId = newUser.Id,
                    email = newUser.Email,
                    password = "test123" // Uniquement pour informer l'utilisateur, ne pas faire ça en production
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        [HttpGet("jwt-config")]
        public IActionResult GetJwtConfig([FromServices] IConfiguration configuration)
        {
            var jwtKey = configuration.GetSection("JWT:Key").Value;
            var keyExists = !string.IsNullOrEmpty(jwtKey);
            
            return Ok(new
            {
                keyExists,
                keyLength = jwtKey?.Length ?? 0,
                keyStart = keyExists ? jwtKey?.Substring(0, Math.Min(5, jwtKey?.Length ?? 0)) + "..." : null
            });
        }

        [HttpGet("ping")]
        public IActionResult Ping()
        {
            return Ok(new
            {
                message = "Pong!",
                timestamp = DateTime.UtcNow,
                serverInfo = new {
                    platform = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
                    serverTime = DateTime.Now.ToString(),
                    environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"
                }
            });
        }
    }
} 