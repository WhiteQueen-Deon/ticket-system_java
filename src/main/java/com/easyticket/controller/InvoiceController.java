package com.easyticket.controller;

import com.easyticket.service.InvoiceService;
import com.easyticket.service.UserService;
import com.easyticket.service.TicketService;
import com.easyticket.entity.User;
import com.easyticket.entity.Order;
import com.easyticket.entity.Event;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/api/invoice")
public class InvoiceController {

    @Autowired
    private InvoiceService invoiceService;

    @Autowired
    private UserService userService;

    @Autowired
    private TicketService ticketService;


    @GetMapping("/download/{orderId}")
    public ResponseEntity<?> downloadInvoice(@PathVariable Long orderId) {
        try {
            // Get current logged-in user
            String username = SecurityContextHolder.getContext().getAuthentication().getName();
            User currentUser = userService.getUserByUsername(username);

            if (currentUser == null) {
                Map<String, Object> result = new HashMap<>();
                result.put("code", 401);
                result.put("msg", "User not logged in");
                return ResponseEntity.ok(result);
            }

            // Get order data from database
            Order order = ticketService.getOrderById(orderId);

            if (order == null) {
                Map<String, Object> result = new HashMap<>();
                result.put("code", 404);
                result.put("msg", "Order not found");
                return ResponseEntity.ok(result);
            }

            // Check order ownership
            if (!order.getUser().getId().equals(currentUser.getId())) {
                Map<String, Object> result = new HashMap<>();
                result.put("code", 403);
                result.put("msg", "No permission to access this invoice");
                return ResponseEntity.ok(result);
            }

            InvoiceService.InvoiceData invoiceData = createInvoiceFromRealOrder(order);

            // Generate PDF
            byte[] pdfBytes = invoiceService.generateInvoicePdf(invoiceData);

            // Set response headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("attachment", "invoice_" + order.getOrderNumber() + ".pdf");
            headers.setContentLength(pdfBytes.length);

            return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);

        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("code", 500);
            result.put("msg", "Failed to generate invoice: " + e.getMessage());
            return ResponseEntity.ok(result);
        }
    }

    private InvoiceService.InvoiceData createInvoiceFromRealOrder(Order order) {
        InvoiceService.InvoiceData invoiceData = new InvoiceService.InvoiceData();

        // Basic info
        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

        invoiceData.setInvoiceNumber("INV" + order.getId() + now.format(DateTimeFormatter.ofPattern("yyyyMMdd")));
        invoiceData.setInvoiceDate(now.format(dateFormatter));
        invoiceData.setOrderNumber(order.getOrderNumber());
        invoiceData.setOrderDate(order.getOrderDate().format(dateFormatter));

        // Customer info
        User orderUser = order.getUser();
        invoiceData.setCustomerName(orderUser.getNickname() != null ? orderUser.getNickname() : orderUser.getUsername());
        invoiceData.setCustomerPhone(orderUser.getPhone() != null ? orderUser.getPhone() : "Not provided");
        invoiceData.setCustomerEmail(orderUser.getEmail() != null ? orderUser.getEmail() : "Not provided");

        // Ticket info
        List<InvoiceService.InvoiceData.TicketItem> ticketItems = new ArrayList<>();

        Event event = order.getEvent();
        InvoiceService.InvoiceData.TicketItem ticketItem = new InvoiceService.InvoiceData.TicketItem();
        ticketItem.setEventName(event.getEventName());
        ticketItem.setEventTime(event.getEventDate().format(formatter));
        ticketItem.setPrice(event.getPrice());
        ticketItem.setQuantity(order.getQuantity());
        ticketItem.setSeatInfo(event.getLocation());
        ticketItem.setSubtotal(order.getTotalAmount());

        ticketItems.add(ticketItem);
        invoiceData.setTicketItems(ticketItems);

        // Fee info
        BigDecimal ticketSubtotal = order.getTotalAmount();
        BigDecimal serviceFee = calculateServiceFee(ticketSubtotal);
        BigDecimal totalAmount = ticketSubtotal.add(serviceFee);

        invoiceData.setSubtotal(ticketSubtotal);
        invoiceData.setServiceFee(serviceFee);
        invoiceData.setTotalAmount(totalAmount);

        // Payment info
        String paymentMethod = getPaymentMethodByStatus(order.getStatus());
        String paymentStatus = getPaymentStatusText(order.getStatus());
        String paymentTime = getPaymentTimeText(order);

        invoiceData.setPaymentMethod(paymentMethod);
        invoiceData.setPaymentStatus(paymentStatus);
        invoiceData.setPaymentTime(paymentTime);
        invoiceData.setTransactionId("TXN" + order.getId() + order.getOrderDate().format(DateTimeFormatter.ofPattern("yyyyMMdd")));

        // Remarks
        String remarks = generateRemarksText(order);
        invoiceData.setRemarks(remarks);

        return invoiceData;
    }

    /**
     * Calculate service fee
     */
    private BigDecimal calculateServiceFee(BigDecimal ticketAmount) {
        BigDecimal feeRate = new BigDecimal("0.05");
        BigDecimal calculatedFee = ticketAmount.multiply(feeRate);
        BigDecimal minFee = new BigDecimal("10.00");

        return calculatedFee.compareTo(minFee) > 0 ? calculatedFee : minFee;
    }

    /**
     * Get payment method by order status
     */
    private String getPaymentMethodByStatus(String status) {
        return switch (status) {
            case "paid", "completed" -> "Online payment";
            case "pending" -> "Unpaid";
            case "cancelled" -> "Cancelled";
            default -> "Unknown";
        };
    }

    /**
     * Get payment status text
     */
    private String getPaymentStatusText(String status) {
        return switch (status) {
            case "paid" -> "Paid";
            case "pending" -> "Pending payment";
            case "cancelled" -> "Cancelled";
            case "completed" -> "Completed";
            default -> status;
        };
    }

    /**
     * Get payment time text
     */
    private String getPaymentTimeText(Order order) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        if (order.getPaymentTime() != null) {
            return order.getPaymentTime().format(formatter);
        } else if ("paid".equals(order.getStatus()) || "completed".equals(order.getStatus())) {
            // 如果状态是Paid但没有支付时间，使用订单时间
            return order.getOrderDate().format(formatter);
        } else {
            return "Unpaid";
        }
    }

    /**
     * 生成Remarks
     */
    private String generateRemarksText(Order order) {
        StringBuilder remarks = new StringBuilder();
        remarks.append("Thank you for using our ticketing service!");

        if ("paid".equals(order.getStatus()) || "completed".equals(order.getStatus())) {
            remarks.append("Please bring valid ID to the event.");
            remarks.append("For refunds or exchanges, contact support 24 hours before the event.");
        } else if ("pending".equals(order.getStatus())) {
            remarks.append("Please complete payment to secure your seat.");
        } else if ("cancelled".equals(order.getStatus())) {
            remarks.append("此订单Cancelled，如有疑问请联系客服。");
        }

        remarks.append("Support: 123-456-7890");

        return remarks.toString();
    }
}
