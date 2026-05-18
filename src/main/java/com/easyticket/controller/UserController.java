package com.easyticket.controller;

import com.easyticket.entity.User;
import com.easyticket.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/users")
@PreAuthorize("hasRole('ADMIN')")
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping("/list")
    public String userListPage() {
        return "users/user-list";
    }

    @GetMapping("/api/list")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getUserList(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) Boolean enabled) {

        try {
            List<User> users = userService.getAllUsers(page, size, keyword, role, enabled);
            long total = userService.getAllUsersCount(keyword, role, enabled);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "success");
            result.put("count", total);
            result.put("data", users);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "failure：" + e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @GetMapping("/api/{userId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getUserDetail(@PathVariable Long userId) {
        try {
            User user = userService.getUserById(userId);
            
            Map<String, Object> result = new HashMap<>();
            if (user != null) {
                result.put("code", 0);
                result.put("msg", "success");
                result.put("data", user);
            } else {
                result.put("code", 404);
                result.put("msg", "not exist");
            }

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "failure：" + e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @PostMapping("/api/create")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> createUser(@RequestBody User user) {
        try {
            User createdUser = userService.createUser(user);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "User created successfully");
            result.put("data", createdUser);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @PutMapping("/api/{userId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> updateUser(@PathVariable Long userId, @RequestBody User user) {
        try {
            user.setId(userId);
            User updatedUser = userService.updateUser(user);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "User updated successfully");
            result.put("data", updatedUser);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @DeleteMapping("/api/{userId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> deleteUser(@PathVariable Long userId) {
        try {
            userService.deleteUser(userId);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "User deleted successfully");

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @PostMapping("/api/batch-delete")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> batchDeleteUsers(@RequestBody Map<String, Object> request) {
        try {
            @SuppressWarnings("unchecked")
            List<Integer> idList = (List<Integer>) request.get("ids");
            List<Long> ids = idList.stream().map(Long::valueOf).toList();
            
            userService.deleteUsers(ids);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "Batch delete successful");

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @PostMapping("/api/{userId}/role")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> updateUserRole(@PathVariable Long userId, @RequestBody Map<String, String> request) {
        try {
            String roles = request.get("roles");
            userService.updateUserRole(userId, roles);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "Role updated successfully");

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @PostMapping("/api/{userId}/status")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> updateUserStatus(@PathVariable Long userId, @RequestBody Map<String, Boolean> request) {
        try {
            Boolean enabled = request.get("enabled");
            userService.updateUserStatus(userId, enabled);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "Status updated successfully");

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @PostMapping("/api/{userId}/reset-password")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> resetPassword(@PathVariable Long userId, @RequestBody Map<String, String> request) {
        try {
            String newPassword = request.get("password");
            userService.resetPassword(userId, newPassword);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "Password reset successfully");

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    @GetMapping("/api/stats")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getUserStats() {
        try {
            Map<String, Object> stats = userService.getUserStats();

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "success");
            result.put("data", stats);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "Failed to get stats: " + e.getMessage());
            return ResponseEntity.ok(result);
        }
    }
} 