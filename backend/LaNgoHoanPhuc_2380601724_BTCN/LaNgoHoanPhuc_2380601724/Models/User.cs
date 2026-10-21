using Microsoft.AspNetCore.Identity;

namespace LaNgoHoanPhuc_2380601724.Models
{
    public class User : IdentityUser
    {
        public string? FullName { get; set; }
        public string? OtpCode { get; set; }
        public DateTime? OtpExpireTime { get; set; }

    }

}
