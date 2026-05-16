/**
 * Cloud Function: resetPasswordByPhone
 *
 * Đặt lại mật khẩu cho user đăng ký bằng phone (synthetic email).
 * Client PHẢI signInWithCredential(PhoneAuthCredential) trước khi gọi
 * function này — để Firebase tạo phiên tạm có phone_number claim.
 *
 * Flow:
 *   1. Đọc phone từ ctx.auth.token.phone_number (KHÔNG nhận phone từ data)
 *   2. Tính synthetic email = phone.replace("+","") + "@phone.coinnest.app"
 *   3. getUserByEmail(syntheticEmail) → lấy uid
 *   4. updateUser(uid, { password: newPassword })
 *   5. revokeRefreshTokens(uid) → buộc user login lại
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

exports.resetPasswordByPhone = onCall(async (request) => {
  // Lấy phone từ token claim — chỉ có nếu client đã signIn bằng PhoneAuth
  const phone = request.auth?.token?.phone_number;
  if (!phone) {
    throw new HttpsError(
      "unauthenticated",
      "Cần xác minh OTP trước khi đặt lại mật khẩu"
    );
  }

  const newPassword = request.data?.newPassword;
  if (!newPassword || typeof newPassword !== "string" || newPassword.length < 8) {
    throw new HttpsError(
      "invalid-argument",
      "Mật khẩu mới phải có ít nhất 8 ký tự"
    );
  }

  // Tính synthetic email — PHẢI khớp 1-1 với PhoneUtils.phoneToSyntheticEmail
  // ở client (bỏ "+", thêm @phone.coinnest.app)
  const syntheticEmail = `${phone.replace("+", "")}@phone.coinnest.app`;

  try {
    const auth = getAuth();
    const user = await auth.getUserByEmail(syntheticEmail);

    // Đổi password trên Firebase Auth (Email/Password provider)
    await auth.updateUser(user.uid, { password: newPassword });

    // Thu hồi refresh token — buộc user phải đăng nhập lại
    await auth.revokeRefreshTokens(user.uid);

    return { ok: true };
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError(
        "not-found",
        "Không tìm thấy tài khoản với số điện thoại này"
      );
    }
    throw new HttpsError(
      "internal",
      "Đặt lại mật khẩu thất bại. Vui lòng thử lại."
    );
  }
});
