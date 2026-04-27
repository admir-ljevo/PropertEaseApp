using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DropIsActiveColumnAddMissingIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PropertyReservations_IsActive",
                table: "PropertyReservations");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "PropertyReservations");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyReservations_Status",
                table: "PropertyReservations",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PropertyReservations_Status",
                table: "PropertyReservations");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "PropertyReservations",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_PropertyReservations_IsActive",
                table: "PropertyReservations",
                column: "IsActive");
        }
    }
}
