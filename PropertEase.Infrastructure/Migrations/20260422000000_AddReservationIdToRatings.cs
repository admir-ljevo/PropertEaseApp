using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    public partial class AddReservationIdToRatings : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ReservationId",
                table: "PropertyRatings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ReservationId",
                table: "UserRatings",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_PropertyRatings_ReservationId",
                table: "PropertyRatings",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyRatings_ReviewerId_ReservationId",
                table: "PropertyRatings",
                columns: new[] { "ReviewerId", "ReservationId" },
                unique: true,
                filter: "[ReservationId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_UserRatings_ReservationId",
                table: "UserRatings",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRatings_ReviewerId_ReservationId",
                table: "UserRatings",
                columns: new[] { "ReviewerId", "ReservationId" },
                unique: true,
                filter: "[ReservationId] IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyRatings_PropertyReservations_ReservationId",
                table: "PropertyRatings",
                column: "ReservationId",
                principalTable: "PropertyReservations",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_UserRatings_PropertyReservations_ReservationId",
                table: "UserRatings",
                column: "ReservationId",
                principalTable: "PropertyReservations",
                principalColumn: "Id");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PropertyRatings_PropertyReservations_ReservationId",
                table: "PropertyRatings");

            migrationBuilder.DropForeignKey(
                name: "FK_UserRatings_PropertyReservations_ReservationId",
                table: "UserRatings");

            migrationBuilder.DropIndex(
                name: "IX_PropertyRatings_ReviewerId_ReservationId",
                table: "PropertyRatings");

            migrationBuilder.DropIndex(
                name: "IX_PropertyRatings_ReservationId",
                table: "PropertyRatings");

            migrationBuilder.DropIndex(
                name: "IX_UserRatings_ReviewerId_ReservationId",
                table: "UserRatings");

            migrationBuilder.DropIndex(
                name: "IX_UserRatings_ReservationId",
                table: "UserRatings");

            migrationBuilder.DropColumn(
                name: "ReservationId",
                table: "PropertyRatings");

            migrationBuilder.DropColumn(
                name: "ReservationId",
                table: "UserRatings");
        }
    }
}
