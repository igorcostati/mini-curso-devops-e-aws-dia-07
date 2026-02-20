using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
builder.Services.AddHealthChecks();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Youtube Live App Backend API - teste 4",
        Version = "v1"
    });
});

var app = builder.Build();
app.Map("/backend", applicationBuilder =>
{
    applicationBuilder.UseSwagger();
    applicationBuilder.UseSwaggerUI();
    applicationBuilder.UseRouting();
    applicationBuilder.UseAuthentication();
    applicationBuilder.UseAuthorization();

    applicationBuilder.UseEndpoints(endpoints =>
    {
        endpoints.MapControllers();
        endpoints.MapHealthChecks("/health");
    });
});
app.Run();
