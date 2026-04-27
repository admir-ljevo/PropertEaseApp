using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    public partial class AddNotificationTitle : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "ReservationNotifications",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Title",
                table: "ReservationNotifications");
        }
    }
}
