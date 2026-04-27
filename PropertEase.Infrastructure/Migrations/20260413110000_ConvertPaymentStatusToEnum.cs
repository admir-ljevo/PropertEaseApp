using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ConvertPaymentStatusToEnum : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Drop the old nvarchar Status column
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Payments");

            // Add the new int Status column.
            // Default value 1 = PaymentStatus.Completed — all existing rows are completed payments.
            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Payments",
                type: "int",
                nullable: false,
                defaultValue: 1);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Payments");

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "Completed");
        }
    }
}
