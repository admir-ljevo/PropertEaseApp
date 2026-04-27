using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationAuditTrail : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ConfirmedById",
                table: "PropertyReservations",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ConfirmedAt",
                table: "PropertyReservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CancelledById",
                table: "PropertyReservations",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "PropertyReservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "PropertyReservations",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "ConfirmedById",      table: "PropertyReservations");
            migrationBuilder.DropColumn(name: "ConfirmedAt",        table: "PropertyReservations");
            migrationBuilder.DropColumn(name: "CancelledById",      table: "PropertyReservations");
            migrationBuilder.DropColumn(name: "CancelledAt",        table: "PropertyReservations");
            migrationBuilder.DropColumn(name: "CancellationReason", table: "PropertyReservations");
        }
    }
}
