using Lab6;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddGrpc(); 

var app = builder.Build();
app.MapGrpcService<CalculatorService>(); 
app.MapGet("/", () => "gRPC Calculator Server is running.");
app.Run();
