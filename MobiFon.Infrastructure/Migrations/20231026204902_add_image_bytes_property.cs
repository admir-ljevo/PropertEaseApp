using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MobiFon.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class add_image_bytes_property : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "ImageBytes",
                table: "Photos",
                type: "varbinary(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageBytes",
                table: "Photos");
        }
    }
}
