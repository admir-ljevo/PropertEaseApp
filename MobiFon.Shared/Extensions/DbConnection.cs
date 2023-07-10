using System.Data.Common;
using System.Data;
using Dapper;

namespace MobiFon.Shared.Extensions
{
    public static class DbConnectionExtensions
    {
        public static void ExecuteFunction(this DbConnection connection, string functionName, object parameters = null)
        {
            var dynamicParameters = new DynamicParameters();

            if (parameters != null)
            {
                foreach (var parameter in parameters.GetType().GetProperties())
                    dynamicParameters.Add(parameter.Name, parameter.GetValue(parameters));
            }

            connection.Execute(functionName, dynamicParameters, commandType: CommandType.StoredProcedure);
        }

        public static async Task ExecuteFunctionAsync(this DbConnection connection, string functionName, object parameters = null)
        {
            var dynamicParameters = new DynamicParameters();

            if (parameters != null)
            {
                foreach (var parameter in parameters.GetType().GetProperties())
                    dynamicParameters.Add(parameter.Name, parameter.GetValue(parameters));
            }

            await connection.ExecuteAsync(functionName, dynamicParameters, commandType: CommandType.StoredProcedure);
        }

        public static async Task<IEnumerable<T>> QueryFunctionAsync<T>(this DbConnection connection, string functionName, object parameters = null)
        {
            var dynamicParameters = new DynamicParameters();

            if (parameters != null)
            {
                foreach (var parameter in parameters.GetType().GetProperties())
                    dynamicParameters.Add(parameter.Name, parameter.GetValue(parameters));
            }

            return await connection.QueryAsync<T>(functionName, dynamicParameters, commandType: CommandType.StoredProcedure);
        }

        public static async Task<T> QueryFunctionFirstOrDefaultAsync<T>(this DbConnection connection, string functionName, object parameters = null)
        {
            var dynamicParameters = new DynamicParameters();

            if (parameters != null)
            {
                foreach (var parameter in parameters.GetType().GetProperties())
                    dynamicParameters.Add(parameter.Name, parameter.GetValue(parameters));
            }

            return (await connection.QueryAsync<T>(functionName, dynamicParameters, commandType: CommandType.StoredProcedure)).FirstOrDefault();
        }
    }
}
