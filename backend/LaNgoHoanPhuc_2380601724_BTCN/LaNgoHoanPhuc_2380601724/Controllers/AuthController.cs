using LaNgoHoanPhuc_2380601724.DTOs;
using LaNgoHoanPhuc_2380601724.Models;
using LaNgoHoanPhuc_2380601724.Services; // Thêm namespace chứa IEmailService
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace LaNgoHoanPhuc_2380601724.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly IConfiguration _configuration;
        private readonly IEmailService _emailService; // Inject Email Service

        public AuthController(
            UserManager<User> userManager,
            RoleManager<IdentityRole> roleManager,
            IConfiguration configuration,
            IEmailService emailService)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _configuration = configuration;
            _emailService = emailService;
        }

        // 1. ĐĂNG KÝ TÀI KHOẢN
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterModel model)
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
                return StatusCode(500, new { status = false, message = "Đăng ký thất bại!", errors = result.Errors });

            // Gán Role (Mặc định Customer nếu không truyền Role)
            string assignedRole = string.IsNullOrEmpty(model.Role) ? "Customer" : model.Role;
            if (!await _roleManager.RoleExistsAsync(assignedRole))
                await _roleManager.CreateAsync(new IdentityRole(assignedRole));

            await _userManager.AddToRoleAsync(user, assignedRole);

            return Ok(new { status = true, message = "Đăng ký tài khoản thành công!" });
        }

        // 2. ĐĂNG NHẬP & GỬI OTP VỀ EMAIL
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginModel model)
        {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
                return Unauthorized(new { status = false, message = "Sai tên đăng nhập hoặc mật khẩu!" });

            // Tạo mã OTP ngẫu nhiên 6 chữ số
            string otpCode = new Random().Next(100000, 999999).ToString();
            user.OtpCode = otpCode;
            user.OtpExpireTime = DateTime.UtcNow.AddMinutes(3); // Hết hạn sau 3 phút

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
                return StatusCode(500, new { status = false, message = "Không thể lưu mã OTP!" });

            // Gửi OTP qua Email
            if (!string.IsNullOrEmpty(user.Email))
            {
                string subject = "Mã xác thực đăng nhập OTP";
                string body = $@"
                    <h3>Mã xác thực OTP</h3>
                    <p>Mã OTP để hoàn tất đăng nhập của bạn là: <b style='font-size: 20px; color: blue;'>{otpCode}</b></p>
                    <p>Mã có hiệu lực trong vòng <b>3 phút</b>. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>";

                await _emailService.SendEmailAsync(user.Email, subject, body);
            }

            return Ok(new { status = true, message = "Mật khẩu đúng. Mã OTP đã được gửi về Email của bạn!" });
        }

        // 3. XÁC THỰC OTP & TRẢ VỀ TOKEN
        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpModel model)
        {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user == null)
                return BadRequest(new { status = false, message = "Tài khoản không tồn tại!" });

            // Kiểm tra OTP hợp lệ và thời gian hiệu lực
            if (string.IsNullOrEmpty(user.OtpCode) || user.OtpCode != model.OtpCode || user.OtpExpireTime < DateTime.UtcNow)
            {
                return BadRequest(new { status = false, message = "Mã OTP không hợp lệ hoặc đã hết hạn!" });
            }

            // Xóa OTP ngay sau khi dùng thành công
            user.OtpCode = null;
            user.OtpExpireTime = null;
            await _userManager.UpdateAsync(user);

            // Khởi tạo JWT Token & Claims
            var roles = await _userManager.GetRolesAsync(user);
            var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName!),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            foreach (var role in roles)
            {
                authClaims.Add(new Claim(ClaimTypes.Role, role));
            }

            var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JWTKey:Secret"]!));
            var token = new JwtSecurityToken(
                issuer: _configuration["JWTKey:ValidIssuer"],
                audience: _configuration["JWTKey:ValidAudience"],
                expires: DateTime.UtcNow.AddHours(4),
                claims: authClaims,
                signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
            );

            return Ok(new
            {
                status = true,
                message = "Xác thực OTP thành công!",
                token = new JwtSecurityTokenHandler().WriteToken(token),
                roles = roles
            });
        }
    }
}