-- Script pour ajouter un utilisateur mobile de test
-- Le mot de passe hashé correspond à "test123"

INSERT INTO "MobileUsers" (
    "Email", 
    "Password", 
    "FirstName", 
    "LastName", 
    "PhoneNumber", 
    "CreatedAt", 
    "LastLogin", 
    "IsActive"
) VALUES (
    'test@dev700.com', 
    '$2a$11$I0aYxpW8kz8CLlNqpAJGpuVqw53jgWm8eKEUJkdLs67SfUKdJUcvy', -- Mot de passe 'test123' hashé avec BCrypt
    'Test', 
    'User', 
    '0123456789', 
    CURRENT_TIMESTAMP, 
    NULL, 
    TRUE
);

-- Pour information, le mot de passe est 'test123'
-- Si vous voulez vous connecter avec cet utilisateur, utilisez:
-- Email: test@dev700.com
-- Mot de passe: test123 