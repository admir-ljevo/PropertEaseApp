using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MobiFon.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class add_last_sent_message : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "LastMessage",
                table: "Conversations",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddColumn<DateTime>(
                name: "LastSent",
                table: "Conversations",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastSent",
                table: "Conversations");

            migrationBuilder.AlterColumn<string>(
                name: "LastMessage",
                table: "Conversations",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);
        }
    }
}
