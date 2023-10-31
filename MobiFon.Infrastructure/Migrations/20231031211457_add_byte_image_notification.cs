using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MobiFon.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class add_byte_image_notification : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "ImageBytes",
                table: "Notifications",
                type: "varbinary(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageBytes",
                table: "Notifications");
        }
    }
}
