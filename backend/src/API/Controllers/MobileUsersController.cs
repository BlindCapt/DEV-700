using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Core.Entities;
using Microsoft.AspNetCore.Authorization;

[Route("api/mobile/users")]
[ApiController]
[Authorize(Policy = "RequireEmployeeRole")]  // Accessible aux employés et managers
public class MobileUsersController : ControllerBase
{
    private readonly AppDbContext _context;

    public MobileUsersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MobileUserDto>>> GetUsers()
    {
        var users = await _context.MobileUsers.ToListAsync();
        return Ok(users.Select(u => new MobileUserDto
        {
            Id = u.Id,
            Email = u.Email,
            FirstName = u.FirstName,
            LastName = u.LastName,
            PhoneNumber = u.PhoneNumber,
            IsActive = u.IsActive,
            CreatedAt = u.CreatedAt,
            LastLogin = u.LastLogin
        }));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<MobileUserDto>> GetUser(int id)
    {
        var user = await _context.MobileUsers.FindAsync(id);
        
        if (user == null)
            return NotFound();

        return new MobileUserDto
        {
            Id = user.Id,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            PhoneNumber = user.PhoneNumber,
            IsActive = user.IsActive,
            CreatedAt = user.CreatedAt,
            LastLogin = user.LastLogin
        };
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, UpdateMobileUserDto dto)
    {
        var user = await _context.MobileUsers.FindAsync(id);
        
        if (user == null)
            return NotFound();

        // Vérifier si l'email est déjà utilisé
        if (dto.Email != user.Email && await _context.MobileUsers.AnyAsync(u => u.Email == dto.Email))
            return BadRequest("Cet email est déjà utilisé");

        user.Email = dto.Email;
        user.FirstName = dto.FirstName;
        user.LastName = dto.LastName;
        user.PhoneNumber = dto.PhoneNumber;
        user.IsActive = dto.IsActive;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "RequireManagerRole")]  // Seuls les managers peuvent supprimer des utilisateurs
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.MobileUsers.FindAsync(id);
        
        if (user == null)
            return NotFound();

        _context.MobileUsers.Remove(user);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public class MobileUserDto
{
    public int Id { get; set; }
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string PhoneNumber { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLogin { get; set; }
}

public class UpdateMobileUserDto
{
    public string Email { get; set; }
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string PhoneNumber { get; set; }
    public bool IsActive { get; set; }
} 