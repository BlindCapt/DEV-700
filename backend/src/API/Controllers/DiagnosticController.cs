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

        public DiagnosticController(AppDbContext context)
        {
            _context = context;
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
        public IActionResult TestBcryptHash(string password)
        {
            var hashedPassword = BCrypt.Net.BCrypt.HashPassword(password);
            var staticHash = "$2a$11$kkhBm1nsqPJT7MffhvW/A..3QF6yjgI076.F39NoPED4xwGWlIyyO"; // hash pré-calculé pour "admin"
            
            return Ok(new
            {
                inputPassword = password,
                generatedHash = hashedPassword,
                staticHash = staticHash,
                verifyWithGenerated = BCrypt.Net.BCrypt.Verify(password, hashedPassword),
                verifyWithStatic = BCrypt.Net.BCrypt.Verify(password, staticHash)
            });
        }

        [HttpPost("create-test-user")]
        public async Task<IActionResult> CreateTestUser()
        {
            try
            {
                // Vérifier si l'utilisateur test existe déjà
                var existingUser = await _context.WebUsers.FirstOrDefaultAsync(u => u.Username == "testuser");
                if (existingUser != null)
                {
                    return Ok(new { 
                        message = "L'utilisateur test existe déjà", 
                        userId = existingUser.Id,
                        username = existingUser.Username,
                        hashedPassword = existingUser.Password
                    });
                }

                // Créer un hash pour le mot de passe "password"
                var plainPassword = "password";
                var hashedPassword = BCrypt.Net.BCrypt.HashPassword(plainPassword);

                // Créer un nouvel utilisateur test
                var testUser = new WebUser
                {
                    Username = "testuser",
                    Password = hashedPassword,
                    Email = "test@example.com",
                    FirstName = "Test",
                    LastName = "User",
                    Role = WebUserRole.Employee,
                    CreatedAt = DateTime.UtcNow
                };

                _context.WebUsers.Add(testUser);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Utilisateur test créé avec succès", 
                    userId = testUser.Id,
                    username = testUser.Username,
                    plainPassword = plainPassword,
                    hashedPassword = hashedPassword,
                    createdAt = testUser.CreatedAt
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Erreur lors de la création de l'utilisateur test", error = ex.Message });
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
    }
} 