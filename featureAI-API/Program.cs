var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient<featureAI_API.Services.IOpenRouterService, featureAI_API.Services.OpenRouterService>(
    client =>
    {
        client.BaseAddress = new Uri("https://openrouter.ai/api/v1/");
        client.Timeout = TimeSpan.FromSeconds(45);
    });

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();

app.MapControllers();

app.Run();
