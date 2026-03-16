using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertEase.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class removeemployeefields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Biography",
                table: "Persons");

            migrationBuilder.DropColumn(
                name: "DateOfEmployment",
                table: "Persons");

            migrationBuilder.DropColumn(
                name: "Pay",
                table: "Persons");

            migrationBuilder.DropColumn(
                name: "Position",
                table: "Persons");

            migrationBuilder.DropColumn(
                name: "Qualifications",
                table: "Persons");

            migrationBuilder.DropColumn(
                name: "WorkExperience",
                table: "Persons");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Biography",
                table: "Persons",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DateOfEmployment",
                table: "Persons",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<float>(
                name: "Pay",
                table: "Persons",
                type: "real",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Position",
                table: "Persons",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Qualifications",
                table: "Persons",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "WorkExperience",
                table: "Persons",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }
    }
}
