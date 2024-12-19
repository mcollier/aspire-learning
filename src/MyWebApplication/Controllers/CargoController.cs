using System.Text.Json;
using Azure.Messaging.ServiceBus;
using Microsoft.AspNetCore.Mvc;
using MyWebApplication.Models;

namespace MyWebApplication.Controllers;


[ApiController]
[Route("[controller]")]
public class CargoController(ILogger<CargoController> logger,
                            ServiceBusClient _serviceBusClient) : ControllerBase
{
    private readonly ILogger<CargoController> _logger = logger;
    private readonly ServiceBusClient _client = _serviceBusClient;

    [HttpPost]
    public async Task<IActionResult> Post([FromBody] Cargo cargo)
    {
        if (cargo == null)
        {
            return BadRequest("Cargo is null.");
        }

        _logger.LogInformation("Cargo received: {@Cargo}", cargo);

        // Write to the Service Bus queue.
        ServiceBusSender sender = _client.CreateSender("widgets");
        ServiceBusMessage message = new(JsonSerializer.Serialize(cargo));
        await sender.SendMessageAsync(message);

        return Ok("Cargo received successfully.");
    }
}