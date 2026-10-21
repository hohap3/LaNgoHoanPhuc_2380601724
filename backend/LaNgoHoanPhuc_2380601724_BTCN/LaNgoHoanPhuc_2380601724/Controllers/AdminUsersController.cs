using LaNgoHoanPhuc_2380601724.DTOs;
using LaNgoHoanPhuc_2380601724.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LaNgoHoanPhuc_2380601724.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class AdminUsersController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;

        public AdminUsersController(UserManager<User> userManager, RoleManager<IdentityRole> roleManager)
        {
            _userManager = userManager;
            _roleManager = roleManager;
        }

        // 1. READ ALL: Lấy danh sách toàn bộ người dùng và danh sách Role
        [HttpGet]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _userManager.Users.ToListAsync();
            var userList = new List<UserDto>();

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                userList.Add(new UserDto
                {
                    Id = user.Id,
                    Username = user.UserName ?? string.Empty,
                    Email = user.Email ?? string.Empty,
                    Roles = roles
                });
            }

            return Ok(new { status = true, data = userList });
        }

        // 2. READ BY ID: Lấy chi tiết 1 người dùng
        [HttpGet("{id}")]
        public async Task<IActionResult> GetUserById(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { status = false, message = "Không tìm thấy người dùng!" });

            var roles = await _userManager.GetRolesAsync(user);
            return Ok(new { status = true, data = new UserDto { Id = user.Id, Username = user.UserName ?? "", Email = user.Email ?? "", Roles = roles } });
        }

        // 3. CREATE: Admin tạo tài khoản trực tiếp
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] RegisterModel model)
        {
            // Kiểm tra trùng Email
            var userByEmail = await _userManager.FindByEmailAsync(model.Email);
            if (userByEmail != null)
                return BadRequest(new { status = false, message = "Email đã tồn tại trong hệ thống!" });

            // Kiểm tra trùng Username
            var userByUsername = await _userManager.FindByNameAsync(model.Username);
            if (userByUsername != null)
                return BadRequest(new { status = false, message = "Tên đăng nhập đã tồn tại trong hệ thống!" });

            var user = new User
            {
                Email = model.Email,
                UserName = model.Username,
                SecurityStamp = Guid.NewGuid().ToString()
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
                return StatusCode(500, new { status = false, message = "Tạo tài khoản thất bại!", errors = result.Errors });

            // Kiểm tra & Gán Role
            string roleName = string.IsNullOrEmpty(model.Role) ? "Customer" : model.Role;
            if (!await _roleManager.RoleExistsAsync(roleName))
                await _roleManager.CreateAsync(new IdentityRole(roleName));

            await _userManager.AddToRoleAsync(user, roleName);

            return Ok(new { status = true, message = "Admin tạo tài khoản thành công!" });
        }

        // 4. UPDATE: Cập nhật thông tin và Quyền (Role)
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromBody] UpdateUserModel model)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { status = false, message = "Không tìm thấy người dùng!" });

            // Cập nhật Email (dùng SetEmailAsync để tự đồng bộ NormalizedEmail)
            if (!string.IsNullOrEmpty(model.Email) && model.Email != user.Email)
            {
                var emailExists = await _userManager.FindByEmailAsync(model.Email);
                if (emailExists != null)
                    return BadRequest(new { status = false, message = "Email mới đã được sử dụng bởi tài khoản khác!" });

                await _userManager.SetEmailAsync(user, model.Email);
            }

            // Cập nhật Role mới
            if (!string.IsNullOrEmpty(model.NewRole))
            {
                if (!await _roleManager.RoleExistsAsync(model.NewRole))
                    return BadRequest(new { status = false, message = "Quyền (Role) không tồn tại!" });

                var currentRoles = await _userManager.GetRolesAsync(user);
                await _userManager.RemoveFromRolesAsync(user, currentRoles);
                await _userManager.AddToRoleAsync(user, model.NewRole);
            }

            return Ok(new { status = true, message = "Cập nhật người dùng thành công!" });
        }

        // 5. DELETE: Xóa tài khoản
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
                return NotFound(new { status = false, message = "Không tìm thấy người dùng!" });

            // Kiểm tra không cho Admin tự xóa chính mình
            if (user.UserName == User.Identity?.Name)
                return BadRequest(new { status = false, message = "Không thể tự xóa tài khoản Admin đang đăng nhập!" });

            var result = await _userManager.DeleteAsync(user);
            if (!result.Succeeded)
                return StatusCode(500, new { status = false, message = "Xóa tài khoản thất bại!" });

            return Ok(new { status = true, message = "Đã xóa người dùng thành công!" });
        }
    }
}