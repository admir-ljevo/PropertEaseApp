using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MobiFon.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class add_renter_in_reservations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RenterId",
                table: "PropertyReservations",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_PropertyReservations_RenterId",
                table: "PropertyReservations",
                column: "RenterId");

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyReservations_AspNetUsers_RenterId",
                table: "PropertyReservations",
                column: "RenterId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.NoAction);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PropertyReservations_AspNetUsers_RenterId",
                table: "PropertyReservations");

            migrationBuilder.DropIndex(
                name: "IX_PropertyReservations_RenterId",
                table: "PropertyReservations");

            migrationBuilder.DropColumn(
                name: "RenterId",
                table: "PropertyReservations");
        }
    }
}
