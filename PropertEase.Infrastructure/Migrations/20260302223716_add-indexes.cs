using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class addindexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_PropertyReservations_DateOfOccupancyStart_DateOfOccupancyEnd",
                table: "PropertyReservations",
                columns: new[] { "DateOfOccupancyStart", "DateOfOccupancyEnd" });

            migrationBuilder.CreateIndex(
                name: "IX_PropertyReservations_IsActive",
                table: "PropertyReservations",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_IsAvailable",
                table: "Properties",
                column: "IsAvailable");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_IsDeleted",
                table: "Properties",
                column: "IsDeleted");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PropertyReservations_DateOfOccupancyStart_DateOfOccupancyEnd",
                table: "PropertyReservations");

            migrationBuilder.DropIndex(
                name: "IX_PropertyReservations_IsActive",
                table: "PropertyReservations");

            migrationBuilder.DropIndex(
                name: "IX_Properties_IsAvailable",
                table: "Properties");

            migrationBuilder.DropIndex(
                name: "IX_Properties_IsDeleted",
                table: "Properties");
        }
    }
}
