using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Core.Entities;
using Microsoft.AspNetCore.Authorization;

[Route("api/web/users")]
[ApiController]
[Authorize(Policy = "RequireManagerRole")]  // Seuls les managers peuvent gérer les utilisateurs web
public class WebUsersController : ControllerBase
{
    private readonly AppDbContext _context;

    public WebUsersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<WebUserDto>>> GetUsers()
    {
        var users = await _context.WebUsers.ToListAsync();
        return Ok(users.Select(u => new WebUserDto
        {
            Id = u.Id,
            Username = u.Username,
            Email = u.Email,
            FirstName = u.FirstName,
            LastName = u.LastName,
            Role = u.Role.ToString(),
            CreatedAt = u.CreatedAt,
            LastLogin = u.LastLogin
        }));
    }

    [HttpPost]
    public async Task<ActionResult<WebUserDto>> CreateUser(CreateWebUserDto dto)
    {
        if (await _context.WebUsers.AnyAsync(u => u.Username == dto.Username))
            return BadRequest("Ce nom d'utilisateur est déjà pris");

        if (await _context.WebUsers.AnyAsync(u => u.Email == dto.Email))
            return BadRequest("Cet email est déjà utilisé");

        var hashedPassword = BCrypt.Net.BCrypt.HashPassword(dto.Password);
        
        var user = new WebUser
        {
            Username = dto.Username,
            Password = hashedPassword,
            Email = dto.Email,
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            Role = dto.Role
        };
        
        _context.WebUsers.Add(user);
        await _context.SaveChangesAsync();
        
        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, new WebUserDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Role = user.Role.ToString(),
            CreatedAt = user.CreatedAt
        });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<WebUserDto>> GetUser(int id)
    {
        var user = await _context.WebUsers.FindAsync(id);
        
        if (user == null)
            return NotFound();

        return new WebUserDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Role = user.Role.ToString(),
            CreatedAt = user.CreatedAt,
            LastLogin = user.LastLogin
        };
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, UpdateWebUserDto dto)
    {
        var user = await _context.WebUsers.FindAsync(id);
        
        if (user == null)
            return NotFound();

        // Vérifier si le nom d'utilisateur est déjà pris
        if (dto.Username != user.Username && await _context.WebUsers.AnyAsync(u => u.Username == dto.Username))
            return BadRequest("Ce nom d'utilisateur est déjà pris");

        // Vérifier si l'email est déjà utilisé
        if (dto.Email != user.Email && await _context.WebUsers.AnyAsync(u => u.Email == dto.Email))
            return BadRequest("Cet email est déjà utilisé");

        user.Username = dto.Username;
        user.Email = dto.Email;
        user.FirstName = dto.FirstName;
        user.LastName = dto.LastName;
        user.Role = dto.Role;

        if (!string.IsNullOrEmpty(dto.Password))
        {
            user.Password = BCrypt.Net.BCrypt.HashPassword(dto.Password);
        }

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.WebUsers.FindAsync(id);
        
        if (user == null)
            return NotFound();

        // Empêcher la suppression de l'utilisateur admin par défaut
        if (user.Id == 1)
            return BadRequest("Impossible de supprimer l'administrateur par défaut");

        _context.WebUsers.Remove(user);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public class WebUserDto
{
    public int Id { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Role { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLogin { get; set; }
}

public class CreateWebUserDto
{
    public string Username { get; set; }
    public string Password { get; set; }
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public WebUserRole Role { get; set; }
}

public class UpdateWebUserDto
{
    public string Username { get; set; }
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public WebUserRole Role { get; set; }
    public string Password { get; set; } // Optionnel, ne mettre à jour que si non vide
} 