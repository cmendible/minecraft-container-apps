using System.Web;

public class GetForecast
{
    [KernelFunction]
    [Description("Get weather forecast as Json for a given set of GPS coordinates")]
    public async Task<string> GetForecastJsonData(Kernel kernel,
        [Description("set of GPS coordinates")] string jsonCoordinates)
    {
        string coordinates = HttpUtility.HtmlDecode(jsonCoordinates);
        Console.WriteLine("Input json coordinates: " + coordinates);

        JObject jsonNode;
        try
        {
            jsonNode = JObject.Parse(coordinates);
        }
        catch (Exception e)
        {
            Console.WriteLine("Error parsing json coordinates: " + e.Message);
            return "{ \"error\": \"Error parsing json coordinates\" }";
        }

#pragma warning disable CS8602 // Dereference of a possibly null reference.
        string latitude = jsonNode["latitude"].ToString();
        string longitude = jsonNode["longitude"].ToString();
        string city = jsonNode["city"].ToString();
#pragma warning restore CS8602 // Dereference of a possibly null reference.

        HttpClient httpClient = new HttpClient();
        string url = $"https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours,precipitation_probability_mean,wind_speed_10m_max";

        httpClient.DefaultRequestHeaders.Accept.Clear();
        httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        HttpResponseMessage response = await httpClient.GetAsync(url);
        string responseBody = await response.Content.ReadAsStringAsync();

        JObject jsonNodeForResponse;
        try
        {
            jsonNodeForResponse = JObject.Parse(responseBody);
            jsonNodeForResponse["city"] = city;
        }
        catch (Exception e)
        {
            Console.WriteLine("Error parsing response: " + e.Message);
            return "{ \"error\": \"Error parsing response\" }";
        }

        Console.WriteLine("Output forecast json: " + jsonNodeForResponse.ToString());
        return jsonNodeForResponse.ToString();
    }
}