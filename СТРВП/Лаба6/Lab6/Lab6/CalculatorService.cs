using Grpc.Core; 
using Lab6;
using System.Net.NetworkInformation;

namespace Lab6
{
    public class CalculatorService : Calculator.CalculatorBase //реализация gRPC сервиса
    {
        public override Task<DoubleReply> Sum(BinaryRequest request, ServerCallContext context)
        {
            return Task.FromResult(new DoubleReply { Result = request.X + request.Y });
        }

        public override Task<DoubleReply> Sub(BinaryRequest request, ServerCallContext context)
        {
            return Task.FromResult(new DoubleReply { Result = request.X - request.Y });
        }

        public override Task<DoubleReply> Mul(BinaryRequest request, ServerCallContext context)
        {
            return Task.FromResult(new DoubleReply { Result = request.X * request.Y });
        }

        public override Task<DoubleReply> Div(BinaryRequest request, ServerCallContext context)
        {
            if (request.Y == 0)
                throw new RpcException(new Status(StatusCode.InvalidArgument, "Division by zero"));

            return Task.FromResult(new DoubleReply { Result = request.X / request.Y });
        }

        public override Task<IntReply> Fact(UnaryRequest request, ServerCallContext context)
        {
            try
            {
                int result = Factorial(request.X);
                return Task.FromResult(new IntReply { Result = result });
            }
            catch (OverflowException)
            {
                throw new RpcException(new Status(StatusCode.OutOfRange, "Factorial result too large"));
            }
        }

        private int Factorial(int x)
        {
            if (x < 0) throw new ArgumentException("Negative input");
            int result = 1;
            checked
            {
                for (int i = 2; i <= x; i++)
                    result *= i;
            }
            return result;
        }
    }

}