using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Infrastructure.Data;
using Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;

namespace API.Controllers
{
    [Route("api/web/auth")]
    [ApiController]
    public class WebAuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public WebAuthController(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<string>> Login([FromBody] WebLoginDto loginDto)
        {
            Console.WriteLine($"[DEBUG] Tentative de connexion avec username: {loginDto.Username}");

            // Forcer les données pour tester - UNIQUEMENT POUR DÉBOGUER
            if (loginDto.Username == "admin" && loginDto.Password == "admin")
            {
                Console.WriteLine("[DEBUG] Mode de secours activé pour admin");
                
                // Récupérer l'utilisateur admin
                var adminUser = await _context.WebUsers.FirstOrDefaultAsync(u => u.Username == "admin");
                
                if (adminUser == null)
                {
                    Console.WriteLine("[DEBUG] Utilisateur admin introuvable, création d'un admin temporaire");
                    // Créer un admin temporaire si aucun n'existe
                    adminUser = new WebUser
                    {
                        Username = "admin",
                        Password = BCrypt.Net.BCrypt.HashPassword("admin"),
                        Email = "admin@example.com",
                        FirstName = "Admin",
                        LastName = "User",
                        Role = WebUserRole.Manager,
                        CreatedAt = DateTime.UtcNow
                    };
                    
                    _context.WebUsers.Add(adminUser);
                    await _context.SaveChangesAsync();
                }
                
                // Générer le token directement
                var adminToken = CreateToken(adminUser);
                
                return Ok(new { 
                    token = adminToken,
                    user = new {
                        id = adminUser.Id,
                        username = adminUser.Username,
                        email = adminUser.Email,
                        firstName = adminUser.FirstName,
                        lastName = adminUser.LastName,
                        role = adminUser.Role.ToString()
                    },
                    note = "Mode de secours utilisé"
                });
            }

            // Vérifier si l'utilisateur existe
            var user = await _context.WebUsers
                .FirstOrDefaultAsync(u => u.Username == loginDto.Username);

            if (user == null)
            {
                Console.WriteLine("[DEBUG] Utilisateur non trouvé");
                return Unauthorized("Utilisateur non trouvé");
            }
            
            Console.WriteLine($"[DEBUG] Utilisateur trouvé: {user.Username}, ID: {user.Id}");
            
            // Vérifier le mot de passe
            bool isPasswordValid = BCrypt.Net.BCrypt.Verify(loginDto.Password, user.Password);
            Console.WriteLine($"[DEBUG] Mot de passe valide: {isPasswordValid}");
            Console.WriteLine($"[DEBUG] Hash en base: {user.Password}");
            Console.WriteLine($"[DEBUG] Mot de passe fourni: {loginDto.Password}");

            if (!isPasswordValid)
                return Unauthorized("Mot de passe incorrect");

            // Mise à jour de la dernière connexion
            user.LastLogin = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            var token = CreateToken(user);
            Console.WriteLine("[DEBUG] Token généré avec succès");
            
            return Ok(new { 
                token,
                user = new {
                    id = user.Id,
                    username = user.Username,
                    email = user.Email,
                    firstName = user.FirstName,
                    lastName = user.LastName,
                    role = user.Role.ToString()
                }
            });
        }

        private string CreateToken(WebUser user)
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role.ToString()),
                new Claim("UserType", "WebUser")
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                _configuration.GetSection("JWT:Key").Value!));

            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha512Signature);

            var token = new JwtSecurityToken(
                claims: claims,
                expires: DateTime.Now.AddDays(1),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }

    public class WebLoginDto
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }
} 