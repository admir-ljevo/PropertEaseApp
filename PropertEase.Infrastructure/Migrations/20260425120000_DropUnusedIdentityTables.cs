using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    public partial class DropUnusedIdentityTables : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "AspNetUserClaims");
            migrationBuilder.DropTable(name: "AspNetUserLogins");
            migrationBuilder.DropTable(name: "AspNetRoleClaims");
            migrationBuilder.DropTable(name: "AspNetUserTokens");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Intentionally not recreating these tables — they were never used by this application.
        }
    }
}
