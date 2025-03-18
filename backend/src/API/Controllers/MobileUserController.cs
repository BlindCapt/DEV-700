using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace API.Controllers
{
    [Route("api/mobile/user")]
    [ApiController]
    [Authorize(Policy = "RequireMobileUser")]
    public class MobileUserController : ControllerBase
    {
        private readonly AppDbContext _context;

        public MobileUserController(AppDbContext context)
        {
            _context = context;
        }

        // Endpoint pour valider un token JWT
        [HttpGet("validate")]
        public ActionResult ValidateToken()
        {
            // Si nous arrivons jusqu'ici, le token est valide car Authorize a fonctionné
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var email = User.FindFirst(ClaimTypes.Email)?.Value;

                return Ok(new
                {
                    isValid = true,
                    message = "Token valide",
                    userId = userId,
                    email = email
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    isValid = false,
                    message = $"Erreur lors de la validation: {ex.Message}"
                });
            }
        }

        // Endpoint pour récupérer les informations de l'utilisateur connecté
        [HttpGet("profile")]
        public async Task<ActionResult> GetUserProfile()
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return BadRequest(new { message = "Identifiant utilisateur non trouvé dans le token" });
                }

                var user = await _context.MobileUsers
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                {
                    return NotFound(new { message = "Utilisateur non trouvé" });
                }

                // Ne pas renvoyer le mot de passe
                return Ok(new
                {
                    id = user.Id,
                    email = user.Email,
                    firstName = user.FirstName,
                    lastName = user.LastName,
                    phoneNumber = user.PhoneNumber,
                    createdAt = user.CreatedAt,
                    lastLogin = user.LastLogin
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Erreur serveur: {ex.Message}" });
            }
        }
    }
} 