package com.easyticket.controller;

import com.easyticket.entity.Event;
import com.easyticket.entity.Order;
import com.easyticket.entity.User;
import com.easyticket.service.TicketService;
import com.easyticket.service.EventService;
import com.easyticket.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 购票管理控制器
 *
 * @author hxp
 * @version 1.0.0
 */
@Controller
@RequestMapping("/tickets")
public class TicketController {

    private static final Logger logger = LoggerFactory.getLogger(TicketController.class);

    @Autowired
    private TicketService ticketService;

    @Autowired
    private EventService eventService;

    @Autowired
    private UserService userService;

    /**
     * 浏览场次页面
     */
    @GetMapping("/events")
    public String eventsPage(Model model) {
        return "tickets/events";
    }

    /**
     * 获取可购买的活动列表
     */
    @GetMapping("/api/events")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getEvents(
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "15") int size,
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "status", required = false) String status,
            Authentication authentication) {
        try {
            // 获取当前用户的角色
            boolean isAdmin = authentication.getAuthorities().stream()
                    .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
            boolean isManager = authentication.getAuthorities().stream()
                    .anyMatch(auth -> auth.getAuthority().equals("ROLE_MANAGER"));

            List<Event> events;
            long total;

            if (isAdmin) {
                // 管理员可以查看所有场次
                events = eventService.getAllEvents(page, size, keyword, status);
                total = eventService.getAllEventsCount(keyword, status);
            } else if (isManager) {
                // 经理只能查看自己创建的场次
                Long managerId = getCurrentUserId(authentication);
                if (managerId == null) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("code", 500);
                    result.put("msg", "无法获取用户信息，请重新登录");
                    return ResponseEntity.ok(result);
                }
                events = eventService.getEventsByManagerId(managerId, page, size);
                total = eventService.getEventsCountByManagerId(managerId);
            } else {
                // 普通用户只能查看可购买的场次
                events = ticketService.getAvailableEvents(page, size, keyword);
                total = ticketService.getAvailableEventsCount(keyword);
            }

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "success");
            result.put("count", total);
            result.put("data", events);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "获取活动列表失败：" + e.getMessage());

            return ResponseEntity.ok(result);
        }
    }

    /**
     * 获取当前用户ID的辅助方法
     */
    private Long getCurrentUserId(Authentication authentication) {
        try {
            String username = authentication.getName();
            User user = userService.getUserByUsername(username);
            if (user != null) {
                return user.getId();
            } else {
                logger.warn("无法找到用户: {}", username);
                return null;
            }
        } catch (Exception e) {
            logger.error("获取当前用户ID失败: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * 获取活动详情 - API接口
     */
    @GetMapping("/api/events/{eventId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getEventDetail(@PathVariable Long eventId) {
        try {
            Event event = ticketService.getEventById(eventId);

            Map<String, Object> result = new HashMap<>();
            if (event != null) {
                result.put("code", 0);
                result.put("msg", "success");
                result.put("data", event);
            } else {
                result.put("code", 404);
                result.put("msg", "活动不存在");
            }

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "获取活动详情失败：" + e.getMessage());

            return ResponseEntity.ok(result);
        }
    }

    /**
     * 创建订单 - API接口
     */
    @PostMapping("/api/order")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> createOrder(
            @RequestParam Long eventId,
            @RequestParam int quantity,
            Authentication authentication) {

        Map<String, Object> result = new HashMap<>();

        try {
            String username = authentication.getName();
            Order order = ticketService.createOrder(eventId, username, quantity);

            result.put("code", 0);
            result.put("msg", "订单创建成功");
            result.put("data", order);

        } catch (Exception e) {
            result.put("code", 500);
            result.put("msg", e.getMessage());
        }

        return ResponseEntity.ok(result);
    }

    /**
     * 获取订单详情 - API接口
     */
    @GetMapping("/api/order/{orderId}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getOrderDetail(@PathVariable Long orderId) {
        try {
            Order order = ticketService.getOrderById(orderId);

            Map<String, Object> result = new HashMap<>();
            if (order != null) {
                result.put("code", 0);
                result.put("msg", "success");
                result.put("data", order);
            } else {
                result.put("code", 404);
                result.put("msg", "Order not found");
            }

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "获取订单详情失败：" + e.getMessage());

            return ResponseEntity.ok(result);
        }
    }

    /**
     * 我的订单页面
     */
    @GetMapping("/my-orders")
    public String myOrdersPage() {
        return "tickets/my-orders";
    }

    /**
     * 获取我的订单列表 - API接口
     */
    @GetMapping("/api/my-orders")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getMyOrders(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {

        try {
            String username = authentication.getName();
            List<Order> orders = ticketService.getUserOrders(username, page, size);
            long total = ticketService.getUserOrdersCount(username);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "success");
            result.put("count", total);
            result.put("data", orders);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "Failed to get order list: " + e.getMessage());

            return ResponseEntity.ok(result);
        }
    }

    /**
     * 取消订单 - API接口
     */
    @PostMapping("/api/order/{orderId}/cancel")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> cancelOrder(
            @PathVariable Long orderId,
            Authentication authentication) {

        Map<String, Object> result = new HashMap<>();

        try {
            String username = authentication.getName();
            ticketService.cancelOrder(orderId, username);

            result.put("code", 0);
            result.put("msg", "Order cancelled successfully");

        } catch (Exception e) {
            result.put("code", 500);
            result.put("msg", e.getMessage());
        }

        return ResponseEntity.ok(result);
    }

    /**
     * 支付订单 - API接口
     */
    @PostMapping("/api/order/{orderId}/pay")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> payOrder(
            @PathVariable Long orderId,
            Authentication authentication) {

        Map<String, Object> result = new HashMap<>();

        try {
            String username = authentication.getName();
            ticketService.payOrder(orderId, username);

            result.put("code", 0);
            result.put("msg", "Payment successful");

        } catch (Exception e) {
            result.put("code", 500);
            result.put("msg", e.getMessage());
        }

        return ResponseEntity.ok(result);
    }

    /**
     * 所有订单页面（管理员/经理）
     */
    @GetMapping("/all-orders")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public String allOrdersPage() {
        return "tickets/all-orders";
    }

    /**
     * 获取所有订单列表 - API接口（管理员/经理）
     */
    @GetMapping("/api/all-orders")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getAllOrders(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status) {

        try {
            List<Order> orders = ticketService.getAllOrders(page, size, keyword, status);
            long total = ticketService.getAllOrdersCount(keyword, status);

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "success");
            result.put("count", total);
            result.put("data", orders);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "Failed to get order list: " + e.getMessage());

            return ResponseEntity.ok(result);
        }
    }

    /**
     * 更新订单状态 - API接口（管理员/经理）
     */
    @PostMapping("/api/update-order-status")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> updateOrderStatus(
            @RequestParam Long orderId,
            @RequestParam String status) {

        Map<String, Object> result = new HashMap<>();

        try {
            ticketService.updateOrderStatus(orderId, status);

            result.put("code", 0);
            result.put("msg", "订单状态更新成功");

        } catch (Exception e) {
            result.put("code", 500);
            result.put("msg", "更新订单状态失败：" + e.getMessage());
        }

        return ResponseEntity.ok(result);
    }

    /**
     * 完成订单 - API接口（管理员/经理）
     */
    @PostMapping("/api/order/{orderId}/complete")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> completeOrder(@PathVariable Long orderId) {

        Map<String, Object> result = new HashMap<>();

        try {
            ticketService.updateOrderStatus(orderId, "completed");

            result.put("code", 0);
            result.put("msg", "订单已完成");

        } catch (Exception e) {
            result.put("code", 500);
            result.put("msg", "完成订单失败：" + e.getMessage());
        }

        return ResponseEntity.ok(result);
    }

    /**
     * 获取订单统计信息 - API接口（管理员/经理）
     */
    @GetMapping("/api/order-stats")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getOrderStats() {

        try {
            Map<String, Object> stats = ticketService.getOrderStats();

            Map<String, Object> result = new HashMap<>();
            result.put("code", 0);
            result.put("msg", "success");
            result.put("data", stats);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "获取统计信息失败：" + e.getMessage());

            return ResponseEntity.ok(result);
        }
    }

    /**
     * 场次管理页面
     */
    @GetMapping("/event-management")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public String eventManagementPage(Model model) {
        return "events/event-management";
    }

    /**
     * 获取单个场次详情
     */
    @GetMapping("/api/event/{eventId}")
    @ResponseBody
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<Map<String, Object>> getEventById(@PathVariable("eventId") Long eventId) {
        try {
            Event event = eventService.getEventById(eventId);
            if (event == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("code", -1);
                response.put("msg", "活动不存在");
                return ResponseEntity.ok(response);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", "获取成功");
            response.put("data", event);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", -1);
            response.put("msg", "获取失败：" + e.getMessage());

            return ResponseEntity.ok(response);
        }
    }

    /**
     * 创建新场次
     */
    @PostMapping("/api/event")
    @ResponseBody
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<Map<String, Object>> createEvent(@RequestBody Event event, Authentication authentication) {
        try {
            // 设置管理员ID（从认证信息中获取）
            Long managerId = getCurrentUserId(authentication);
            if (managerId == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("code", -1);
                response.put("msg", "无法获取用户信息，请重新登录");
                return ResponseEntity.ok(response);
            }
            event.setManagerId(managerId);

            Event createdEvent = eventService.createEvent(event);

            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", "创建成功");
            response.put("data", createdEvent);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", -1);
            response.put("msg", "创建失败：" + e.getMessage());

            return ResponseEntity.ok(response);
        }
    }

    /**
     * 更新场次信息
     */
    @PutMapping("/api/event/{eventId}")
    @ResponseBody
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<Map<String, Object>> updateEvent(@PathVariable("eventId") Long eventId,
                                                           @RequestBody Event event,
                                                           Authentication authentication) {
        try {
            // 检查权限：经理只能编辑自己创建的场次
            if (!hasPermissionToModifyEvent(eventId, authentication)) {
                Map<String, Object> response = new HashMap<>();
                response.put("code", -1);
                response.put("msg", "无权限编辑此场次");
                return ResponseEntity.ok(response);
            }

            event.setId(eventId);
            Event updatedEvent = eventService.updateEvent(event);

            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", "更新成功");
            response.put("data", updatedEvent);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", -1);
            response.put("msg", "更新失败：" + e.getMessage());

            return ResponseEntity.ok(response);
        }
    }

    /**
     * 检查用户是否有权限修改指定场次
     */
    private boolean hasPermissionToModifyEvent(Long eventId, Authentication authentication) {
        try {
            // 管理员有所有权限
            boolean isAdmin = authentication.getAuthorities().stream()
                    .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));
            if (isAdmin) {
                return true;
            }

            // 经理只能修改自己创建的场次
            boolean isManager = authentication.getAuthorities().stream()
                    .anyMatch(auth -> auth.getAuthority().equals("ROLE_MANAGER"));
            if (isManager) {
                Event event = eventService.getEventById(eventId);
                if (event != null) {
                    Long currentUserId = getCurrentUserId(authentication);
                    if (currentUserId == null) {
                        logger.warn("无法获取当前用户ID，拒绝权限检查");
                        return false;
                    }
                    return event.getManagerId() != null && event.getManagerId().equals(currentUserId);
                }
            }

            return false;
        } catch (Exception e) {
            logger.error("权限检查失败: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * 删除场次
     */
    @DeleteMapping("/api/event/{eventId}")
    @ResponseBody
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<Map<String, Object>> deleteEvent(@PathVariable("eventId") Long eventId,
                                                           @RequestParam(value = "force", defaultValue = "false") boolean forceDelete,
                                                           Authentication authentication) {
        try {
            // 检查权限：经理只能删除自己创建的场次
            if (!hasPermissionToModifyEvent(eventId, authentication)) {
                Map<String, Object> response = new HashMap<>();
                response.put("code", -1);
                response.put("msg", "无权限删除此场次");
                return ResponseEntity.ok(response);
            }

            eventService.deleteEvent(eventId, forceDelete);

            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", forceDelete ? "强制删除成功" : "删除成功");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", -1);
            response.put("msg", "删除失败：" + e.getMessage());

            return ResponseEntity.ok(response);
        }
    }

    /**
     * 检查场次删除状态
     */
    @GetMapping("/api/event/{eventId}/delete-check")
    @ResponseBody
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<Map<String, Object>> checkEventDeletion(@PathVariable("eventId") Long eventId,
                                                                  Authentication authentication) {
        try {
            // 检查权限：经理只能检查自己创建的场次
            if (!hasPermissionToModifyEvent(eventId, authentication)) {
                Map<String, Object> response = new HashMap<>();
                response.put("code", -1);
                response.put("msg", "无权限操作此场次");
                return ResponseEntity.ok(response);
            }

            EventService.EventDeletionCheckResult checkResult = eventService.checkEventDeletion(eventId);

            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", "检查完成");
            response.put("data", Map.of(
                "canDelete", checkResult.isCanDelete(),
                "message", checkResult.getMessage(),
                "orderCount", checkResult.getOrderCount()
            ));

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", -1);
            response.put("msg", "检查失败：" + e.getMessage());

            return ResponseEntity.ok(response);
        }
    }

    /**
     * 启用/禁用场次
     */
    @PostMapping("/api/event/{eventId}/toggle-status")
    @ResponseBody
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<Map<String, Object>> toggleEventStatus(@PathVariable("eventId") Long eventId,
                                                                 Authentication authentication) {
        try {
            // 检查权限：经理只能修改自己创建的场次状态
            if (!hasPermissionToModifyEvent(eventId, authentication)) {
                Map<String, Object> response = new HashMap<>();
                response.put("code", -1);
                response.put("msg", "无权限修改此场次状态");
                return ResponseEntity.ok(response);
            }

            eventService.toggleEventStatus(eventId);

            Map<String, Object> response = new HashMap<>();
            response.put("code", 0);
            response.put("msg", "状态更新成功");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("code", -1);
            response.put("msg", "状态更新失败：" + e.getMessage());

            return ResponseEntity.ok(response);
        }
    }
}
