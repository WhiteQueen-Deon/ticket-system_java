package com.easyticket.controller;

import com.easyticket.service.EmailService;
import com.easyticket.service.TokenService;
import com.easyticket.service.UserService;
import com.easyticket.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.AccountExpiredException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import javax.imageio.ImageIO;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

/**
 * Authentication controller
 *
 * @author hxp
 * @version 1.0.0
 */
@Controller
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private EmailService emailService;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private UserService userService;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * Show login page
     */
    @GetMapping("/login")
    public String login() {
        return "auth/login";
    }

    /**
     * Show registration page
     */
    @GetMapping("/register")
    public String register() {
        return "auth/register";
    }

    /**
     * Handle user registration
     */
    @PostMapping("/api/register")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> performRegisterAjax(
            @RequestParam String username,
            @RequestParam String email,
            @RequestParam String password,
            @RequestParam String confirmPassword,
            @RequestParam(required = false) String nickname,
            @RequestParam(required = false) String phone,
            @RequestParam String captcha,
            HttpSession session) {

        Map<String, Object> result = new HashMap<>();

        try {
            // 验证验证码
            String sessionCaptcha = (String) session.getAttribute("captcha");
            if (sessionCaptcha == null || !sessionCaptcha.equalsIgnoreCase(captcha)) {
                result.put("success", false);
                result.put("message", "Invalid captcha");
                return ResponseEntity.ok(result);
            }

            // Validate password确认
            if (!password.equals(confirmPassword)) {
                result.put("success", false);
                result.put("message", "Passwords do not match");
                return ResponseEntity.ok(result);
            }

            // 验证用户名长度
            if (username.length() < 3 || username.length() > 20) {
                result.put("success", false);
                result.put("message", "Username must be between 3 and 20 characters");
                return ResponseEntity.ok(result);
            }

            // Validate password长度
            if (password.length() < 6) {
                result.put("success", false);
                result.put("message", "Password must be at least 6 characters");
                return ResponseEntity.ok(result);
            }

            // 验证邮箱格式
            if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
                result.put("success", false);
                result.put("message", "Invalid email format");
                return ResponseEntity.ok(result);
            }

            // 检查用户名和邮箱是否已存在
            if (userService.getUserByUsername(username) != null) {
                result.put("success", false);
                result.put("message", "Username already exists, please choose another");
                return ResponseEntity.ok(result);
            }

            if (userService.getUserByEmail(email) != null) {
                result.put("success", false);
                result.put("message", "Email already registered, please use another email");
                return ResponseEntity.ok(result);
            }

            // 创建用户（状态为未激活）
            User newUser = new User();
            newUser.setUsername(username);
            newUser.setEmail(email);
            newUser.setPassword(password);
            newUser.setNickname(nickname);
            newUser.setPhone(phone);
            newUser.setEnabled(true); 
            newUser.setRoles("ROLE_CUSTOMER"); // 默认角色

            // 生成激活令牌
            String activationToken = tokenService.generateActivationToken(null, email);
            newUser.setActivationToken(activationToken);

            // 保存用户到数据库
            User savedUser = userService.createUser(newUser);
            logger.info("New user created successfully: {}, ID: {}", username, savedUser.getId());

            // 发送激活邮件
//            try {
//                emailService.sendActivationEmail(email, username, activationToken);
//                logger.info("Activation email sent to user: {}", username);
//
//                // 清除验证码
//                session.removeAttribute("captcha");

                result.put("success", true);
                result.put("message", "Registration successful! Activation email sent to " + email + ", please check your email and click the activation link.");
                result.put("redirectUrl", "/login");
                return ResponseEntity.ok(result);

//            } catch (Exception e) {
//                logger.error("Failed to send activation email: {}", e.getMessage(), e);
//                result.put("success", false);
//                result.put("message", "Failed to send activation email, please try again later");
//                return ResponseEntity.ok(result);
//            }

        } catch (Exception e) {
            logger.error("Registration failed: {}", e.getMessage(), e);
            result.put("success", false);
            result.put("message", "Registration failed: " + e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    /**
     * Handle account activation
     */
    @GetMapping("/api/activate")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> activateAjax(@RequestParam String token) {
        Map<String, Object> result = new HashMap<>();

        try {
            // 验证并消费激活令牌
            TokenService.TokenInfo tokenInfo = tokenService.consumeToken(token, "ACTIVATION");

            if (tokenInfo == null) {
                result.put("success", false);
                result.put("message", "Activation link is invalid or expired, please register again");
                return ResponseEntity.ok(result);
            }

            String email = (String) tokenInfo.getData().get("email");

            // 根据邮箱Find user并激活
            User user = userService.getUserByEmail(email);
            if (user != null && user.getActivationToken() != null && user.getActivationToken().equals(token)) {
                user.setEnabled(true);
                user.setActivationToken(null); // 清除激活令牌
                userService.updateUser(user);

                logger.info("User account activated successfully: {}", user.getUsername());
                result.put("success", true);
                result.put("message", "Account activated successfully! You can now log in.");
                result.put("redirectUrl", "/login");
            } else {
                result.put("success", false);
                result.put("message", "Activation failed: user account not found or token invalid");
            }

            return ResponseEntity.ok(result);

        } catch (Exception e) {
            logger.error("账户激活失败: {}", e.getMessage(), e);
            result.put("success", false);
            result.put("message", "Activation failed: " + e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    /**
     * Show account activation page
     */
    @GetMapping("/activate")
    public String activate(@RequestParam String token, Model model) {
        model.addAttribute("token", token);
        return "auth/activation-result";
    }

    /**
     * Check login status
     */
    @GetMapping("/api/login-status")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> checkLoginStatus(HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();

        // 检查用户是否已登录
        if (request.getUserPrincipal() != null) {
            result.put("loggedIn", true);
            result.put("username", request.getUserPrincipal().getName());
            result.put("redirectUrl", "/");
        } else {
            result.put("loggedIn", false);
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Handle logout
     */
    @PostMapping("/api/logout")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> logoutAjax(HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();

        try {
            // Spring Security会自动处理注销
            result.put("success", true);
            result.put("message", "Logout successful");
            result.put("redirectUrl", "/login");
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Logout failed");
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Resend activation email
     */
    @PostMapping("/api/resend-activation")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> resendActivationEmail(@RequestParam String email) {
        Map<String, Object> result = new HashMap<>();

        try {
            // 验证邮箱格式
            if (email == null || email.trim().isEmpty()) {
                result.put("success", false);
                result.put("message", "Please enter your email address");
                return ResponseEntity.ok(result);
            }

            if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
                result.put("success", false);
                result.put("message", "Invalid email format");
                return ResponseEntity.ok(result);
            }

            // Find user
            User user = userService.getUserByEmail(email.trim());
            if (user == null) {
                result.put("success", false);
                result.put("message", "This email is not registered, please register first");
                return ResponseEntity.ok(result);
            }

            // 检查激活状态
            if (user.getEnabled()) {
                result.put("success", false);
                result.put("message", "Account is already activated");
                return ResponseEntity.ok(result);
            }

            // 生成新的激活令牌
            String activationToken = tokenService.generateActivationToken(user.getId().toString(), email.trim());

            // 更新用户的激活令牌
            user.setActivationToken(activationToken);
            userService.updateUser(user);

            // 发送激活邮件
            emailService.sendActivationEmail(email.trim(), user.getUsername(), activationToken);

            logger.info("Activation email resent successfully: {}", user.getUsername());

            result.put("success", true);
            result.put("message", "Activation email resent to " + email + ", please check your email and click the activation link");

        } catch (Exception e) {
            logger.error("重新Failed to send activation email: {}", e.getMessage(), e);
            result.put("success", false);
            result.put("message", "Resend failed: " + e.getMessage());
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Generate captcha
     */
    @GetMapping("/captcha")
    public void captcha(HttpServletRequest request, HttpServletResponse response, HttpSession session) throws IOException {
        response.setContentType("image/jpeg");
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        // Generate captcha
        String captchaText = generateCaptchaText(4);
        session.setAttribute("captcha", captchaText);

        // Create captcha image
        BufferedImage image = createCaptchaImage(captchaText, 120, 40);

        ServletOutputStream out = response.getOutputStream();
        try {
            ImageIO.write(image, "jpg", out);
        } finally {
            out.close();
        }
    }

    /**
     * Generate captcha文本
     */
    private String generateCaptchaText(int length) {
        String chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"; // Remove easily confused characters
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    /**
     * Create captcha image
     */
    private BufferedImage createCaptchaImage(String text, int width, int height) {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();

        // 设置抗锯齿
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        // 填充背景
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, width, height);

        // 绘制干扰线
        Random random = new Random();
        g.setColor(Color.LIGHT_GRAY);
        for (int i = 0; i < 5; i++) {
            int x1 = random.nextInt(width);
            int y1 = random.nextInt(height);
            int x2 = random.nextInt(width);
            int y2 = random.nextInt(height);
            g.drawLine(x1, y1, x2, y2);
        }

        // 绘制验证码文字
        g.setFont(new Font("Arial", Font.BOLD, 24));
        int x = 10;
        for (int i = 0; i < text.length(); i++) {
            // 随机颜色
            g.setColor(new Color(random.nextInt(100), random.nextInt(100), random.nextInt(100)));
            // 随机位置
            int y = 20 + random.nextInt(10);
            g.drawString(String.valueOf(text.charAt(i)), x, y);
            x += 25;
        }

        // 添加噪点
        for (int i = 0; i < 50; i++) {
            int x1 = random.nextInt(width);
            int y1 = random.nextInt(height);
            g.setColor(new Color(random.nextInt(255), random.nextInt(255), random.nextInt(255)));
            g.fillOval(x1, y1, 1, 1);
        }

        g.dispose();
        return image;
    }

    /**
     * Handle user login
     */
    @PostMapping("/api/login")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> performLoginAjax(
            @RequestParam String username,
            @RequestParam String password,
            @RequestParam(required = false, defaultValue = "false") boolean rememberMe,
            HttpServletRequest request,
            HttpSession session) {

        Map<String, Object> result = new HashMap<>();

        try {
            // Validate username and password
            if (username == null || username.trim().isEmpty()) {
                result.put("success", false);
                result.put("message", "Please enter your username");
                return ResponseEntity.ok(result);
            }

            if (password == null || password.trim().isEmpty()) {
                result.put("success", false);
                result.put("message", "Please enter your password");
                return ResponseEntity.ok(result);
            }

            // Find user
            User user = userService.getUserByUsername(username.trim());
            if (user == null) {
                result.put("success", false);
                result.put("message", "Invalid username or password");
                return ResponseEntity.ok(result);
            }

            // Check if account is activated
            if (!user.getEnabled()) {
                result.put("success", false);
                result.put("message", "Account not activated, please check your email");
                return ResponseEntity.ok(result);
            }

//             Validate password
            if (!passwordEncoder.matches(password, user.getPassword())) {
                result.put("success", false);
                result.put("message", "Invalid username or password");
                return ResponseEntity.ok(result);
            }



            // Create Spring Security authentication
            UsernamePasswordAuthenticationToken authToken =
                new UsernamePasswordAuthenticationToken(username, password);

            try {
                Authentication authentication = authenticationManager.authenticate(authToken);

                // Set authentication context
                SecurityContextHolder.getContext().setAuthentication(authentication);

                // Create new session (prevent session fixation attack)
                session.invalidate();
                session = request.getSession(true);

                // Save authentication to session
                session.setAttribute(HttpSessionSecurityContextRepository.SPRING_SECURITY_CONTEXT_KEY,
                    SecurityContextHolder.getContext());

                logger.info("User logged in successfully: {}", username);

                result.put("success", true);
                result.put("message", "Login successful");
                result.put("redirectUrl", "/");
                result.put("user", Map.of(
                    "username", user.getUsername(),
                    "nickname", user.getNickname() != null ? user.getNickname() : user.getUsername(),
                    "roles", user.getRoles()
                ));

                return ResponseEntity.ok(result);

            } catch (BadCredentialsException e) {
                result.put("success", false);
                result.put("message", "Invalid username or password");
                return ResponseEntity.ok(result);
            } catch (DisabledException e) {
                result.put("success", false);
                result.put("message", "Account has been disabled");
                return ResponseEntity.ok(result);
            } catch (AccountExpiredException e) {
                result.put("success", false);
                result.put("message", "Account has expired");
                return ResponseEntity.ok(result);
            } catch (LockedException e) {
                result.put("success", false);
                result.put("message", "Account has been locked");
                return ResponseEntity.ok(result);
            }

        } catch (Exception e) {
            logger.error("登录失败: {}", e.getMessage(), e);
            result.put("success", false);
            result.put("message", "Login failed: " + e.getMessage());
            return ResponseEntity.ok(result);
        }
    }
}
