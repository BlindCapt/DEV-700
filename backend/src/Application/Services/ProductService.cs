using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Core.Entities;
using System.Linq;

namespace Application.Services
{
    public class ProductService
    {
        private readonly HttpClient _httpClient;

        public ProductService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task<Product> FetchProductFromOpenFoodFacts(string barcode)
        {
            var url = $"https://world.openfoodfacts.org/api/v2/product/{barcode}.json?lc=fr";
            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode) return null;

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);

            var root = doc.RootElement;
            if (!root.TryGetProperty("product", out var productElement)) return null;

            string category = "Inconnu";
            if (productElement.TryGetProperty("categories_hierarchy", out var categoriesArray))
            {
                var frenchCategory = categoriesArray.EnumerateArray()
                    .Select(e => e.GetString())
                    .FirstOrDefault(c => c != null && c.StartsWith("fr:"));
                
                if (frenchCategory != null)
                {
                    category = frenchCategory[3..]; // Enlève "fr:"
                }
                else
                {
                    var englishCategory = categoriesArray.EnumerateArray()
                        .Select(e => e.GetString())
                        .FirstOrDefault(c => c != null && c.StartsWith("en:"));
                    if (englishCategory != null)
                    {
                        category = englishCategory[3..]; // Enlève "en:"
                    }
                    else if (productElement.TryGetProperty("categories", out var categoriesElement))
                    {
                        category = categoriesElement.GetString() ?? "Inconnu";
                    }
                }
            }

            return new Product
            {
                Name = productElement.GetProperty("product_name_fr").GetString() 
                    ?? productElement.GetProperty("product_name").GetString() 
                    ?? "Inconnu",
                Price = 0,
                Quantity = 1,
                Brand = productElement.GetProperty("brands").GetString() ?? "Inconnu",
                Category = category,
                ImageUrl = productElement.GetProperty("image_url").GetString() ?? "",
                Threshold = 10 // Valeur par défaut
            };
        }
    }
}
