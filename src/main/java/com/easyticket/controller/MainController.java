package com.easyticket.controller;

import com.easyticket.service.EventService;
import com.easyticket.service.TicketService;
import com.easyticket.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.HashMap;
import java.util.Map;

/**
 * Main controller
 *
 * @author hxp
 * @version 1.0.0
 */
@Controller
public class MainController {

    @Autowired
    private EventService eventService;

    @Autowired
    private TicketService ticketService;

    @Autowired
    private UserService userService;

    /**
     * Main frame page
     */
    @GetMapping({"/", "/main"})
    public String mainPage() {
        return "main";
    }

    /**
     * System homepage
     */
    @GetMapping("/dashboard")
    public String dashboard() {
        return "dashboard";
    }

    /**
     * Get dashboard stats
     */
    @GetMapping("/api/dashboard/stats")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        try {
            Map<String, Object> result = new HashMap<>();
            
            // Get active event count
            long activeEventCount = eventService.getAllEventsCount(null, "ACTIVE");
            result.put("eventCount", activeEventCount);
            
            // Get today order stats
            Map<String, Object> todayOrderStats = ticketService.getTodayOrderStats();
            result.put("orderCount", todayOrderStats.get("todayOrders"));
            result.put("todayRevenue", todayOrderStats.get("todayRevenue"));
            
            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", "success");
            response.put("data", result);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", 500);
            response.put("msg", "Failed to get stats: " + e.getMessage());
            
            return ResponseEntity.ok(response);
        }
    }

    /**
     * Get admin stats
     */
    @GetMapping("/api/dashboard/admin-stats")
    @ResponseBody
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getAdminStats() {
        try {
            Map<String, Object> result = new HashMap<>();
            
            // Get user stats
            Map<String, Object> userStats = userService.getUserStats();
            result.put("userCount", userStats.get("totalUsers"));
            
            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", "success");
            response.put("data", result);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", 500);
            response.put("msg", "Failed to get admin stats: " + e.getMessage());
            
            return ResponseEntity.ok(response);
        }
    }
}
