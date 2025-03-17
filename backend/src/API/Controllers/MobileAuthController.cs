using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Infrastructure.Data;
using Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;

[Route("api/mobile/auth")]
[ApiController]
public class MobileAuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;

    public MobileAuthController(AppDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<ActionResult<string>> Login([FromBody] MobileLoginDto loginDto)
    {
        var user = await _context.MobileUsers
            .FirstOrDefaultAsync(u => u.Email == loginDto.Email);

        if (user == null)
            return Unauthorized("Utilisateur non trouvé");

        if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.Password))
            return Unauthorized("Mot de passe incorrect");

        if (!user.IsActive)
            return Unauthorized("Votre compte a été désactivé");

        user.LastLogin = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        var token = CreateToken(user);
        return Ok(new { 
            token,
            user = new {
                id = user.Id,
                email = user.Email,
                firstName = user.FirstName,
                lastName = user.LastName
            }
        });
    }

    [AllowAnonymous]
    [HttpPost("register")]
    public async Task<ActionResult> Register([FromBody] MobileRegisterDto registerDto)
    {
        if (await _context.MobileUsers.AnyAsync(u => u.Email == registerDto.Email))
            return BadRequest("Cet email est déjà utilisé");

        var hashedPassword = BCrypt.Net.BCrypt.HashPassword(registerDto.Password);
        
        var user = new MobileUser
        {
            Email = registerDto.Email,
            Password = hashedPassword,
            FirstName = registerDto.FirstName,
            LastName = registerDto.LastName,
            PhoneNumber = registerDto.PhoneNumber
        };
        
        _context.MobileUsers.Add(user);
        await _context.SaveChangesAsync();
        
        return Ok(new { 
            message = "Inscription réussie",
            userId = user.Id
        });
    }

    private string CreateToken(MobileUser user)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim("UserType", "MobileUser")
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _configuration.GetSection("JWT:Key").Value!));

        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha512Signature);

        var token = new JwtSecurityToken(
            claims: claims,
            expires: DateTime.Now.AddDays(30),  // Plus long pour les utilisateurs mobiles
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public class MobileLoginDto
{
    public string Email { get; set; }
    public string Password { get; set; }
}

public class MobileRegisterDto
{
    public string Email { get; set; }
    public string Password { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string PhoneNumber { get; set; }
} 