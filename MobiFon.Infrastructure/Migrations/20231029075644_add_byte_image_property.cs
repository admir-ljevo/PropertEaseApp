using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MobiFon.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class add_byte_image_property : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "ProfilePhotoBytes",
                table: "Persons",
                type: "varbinary(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ProfilePhotoBytes",
                table: "Persons");
        }
    }
}
