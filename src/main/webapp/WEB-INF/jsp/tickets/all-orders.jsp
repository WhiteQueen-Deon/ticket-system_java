<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <title>Order Management</title>

    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/layui/css/layui.css">

    <!-- CSRF Token for AJAX -->
    <meta name="_csrf" content="${_csrf.token}"/>
    <meta name="_csrf_header" content="${_csrf.headerName}"/>

    <style>
        body {
            background: #f2f2f2;
            margin: 0;
            padding: 20px;
        }

        .stats-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.1);
            text-align: center;
        }

        .stat-icon {
            font-size: 32px;
            margin-bottom: 10px;
        }

        .stat-icon.pending { color: #FF9800; }
        .stat-icon.paid { color: #4CAF50; }
        .stat-icon.cancelled { color: #F44336; }
        .stat-icon.completed { color: #2196F3; }

        .stat-number {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 5px;
            color: #333;
        }

        .stat-label {
            font-size: 12px;
            color: #666;
        }

        .search-form {
            background: #fff;
            padding: 20px;
            border-radius: 6px;
            margin-bottom: 20px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.1);
        }

        .orders-table {
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.1);
            overflow: hidden;
        }

        .status-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .status-pending { background: rgba(255, 193, 7, 0.2); color: #856404; }
        .status-paid { background: rgba(40, 167, 69, 0.2); color: #155724; }
        .status-cancelled { background: rgba(220, 53, 69, 0.2); color: #721c24; }
        .status-completed { background: rgba(23, 162, 184, 0.2); color: #0c5460; }

        @media screen and (max-width: 768px) {
            body {
                padding: 10px;
            }

            .stats-cards {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>
<body>

<!-- Stats Cards -->
<div class="stats-cards">
    <div class="stat-card">
        <div class="stat-icon pending">
            <i class="layui-icon layui-icon-time"></i>
        </div>
        <div class="stat-number" id="pendingCount">0</div>
        <div class="stat-label">Pending</div>
    </div>

    <div class="stat-card">
        <div class="stat-icon paid">
            <i class="layui-icon layui-icon-ok"></i>
        </div>
        <div class="stat-number" id="paidCount">0</div>
        <div class="stat-label">Paid</div>
    </div>

    <div class="stat-card">
        <div class="stat-icon cancelled">
            <i class="layui-icon layui-icon-close"></i>
        </div>
        <div class="stat-number" id="cancelledCount">0</div>
        <div class="stat-label">Cancelled</div>
    </div>

    <div class="stat-card">
        <div class="stat-icon completed">
            <i class="layui-icon layui-icon-ok-circle"></i>
        </div>
        <div class="stat-number" id="completedCount">0</div>
        <div class="stat-label">Completed</div>
    </div>
</div>

<!-- Search Form -->
<div class="layui-card search-form">
    <div class="layui-card-body">
        <form class="layui-form" lay-filter="searchForm">
            <div class="layui-row layui-col-space15">
                <div class="layui-col-md3">
                    <input type="text" name="orderNumber" placeholder="Search order number" class="layui-input">
                </div>
                <div class="layui-col-md3">
                    <input type="text" name="username" placeholder="Search username" class="layui-input">
                </div>
                <div class="layui-col-md2">
                    <select name="status" lay-search="">
                        <option value="">All Status</option>
                        <option value="pending">Pending</option>
                        <option value="paid">Paid</option>
                        <option value="cancelled">Cancelled</option>
                        <option value="completed">Completed</option>
                    </select>
                </div>
                <div class="layui-col-md2">
                    <button type="button" class="layui-btn" onclick="searchOrders()">
                        <i class="layui-icon layui-icon-search"></i> Search
                    </button>
                </div>
                <div class="layui-col-md2">
                    <button type="button" class="layui-btn layui-btn-normal" onclick="resetSearch()">
                        <i class="layui-icon layui-icon-refresh"></i> Reset
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<!-- Orders Table -->
<div class="layui-card orders-table">
    <div class="layui-card-header">
        <h3>All Orders</h3>
    </div>
    <div class="layui-card-body" style="padding: 0;">
        <table class="layui-table" lay-even lay-skin="nob">
            <thead>
            <tr>
                <th>Order No.</th>
                <th>User</th>
                <th>Event</th>
                <th>Quantity</th>
                <th>Total</th>
                <th>Status</th>
                <th>Order Date</th>
                <th>Actions</th>
            </tr>
            </thead>
            <tbody id="ordersTableBody">
            <!-- Order data will be loaded via AJAX -->
            </tbody>
        </table>

        <!-- Pagination -->
        <div id="pagination" style="padding: 20px; text-align: center;"></div>
    </div>
</div>

<!-- Order Detail Modal -->
<div id="orderDetailModal" style="display: none; padding: 30px;">
    <div id="orderDetailContent">
        <!-- Detail content will be loaded dynamically -->
    </div>
</div>

<!-- LayUI JS -->
<script src="${pageContext.request.contextPath}/static/layui/layui.js"></script>

<script>
    layui.config({ lang: 'en' });
    layui.use(['layer', 'form', 'laypage'], function(){
        var layer = layui.layer,
            form = layui.form,
            laypage = layui.laypage;

        var currentPage = 1;
        var pageSize = 15;

        // Load orders and stats when page loads
        loadOrders();
        loadStats();

        // Search orders
        window.searchOrders = function() {
            currentPage = 1;
            loadOrders();
        };

        // Reset search
        window.resetSearch = function() {
            document.querySelector('input[name="orderNumber"]').value = '';
            document.querySelector('input[name="username"]').value = '';
            document.querySelector('select[name="status"]').value = '';
            form.render('select');
            currentPage = 1;
            loadOrders();
        };

        // Load orders list
        function loadOrders() {
            var orderNumber = document.querySelector('input[name="orderNumber"]').value;
            var username = document.querySelector('input[name="username"]').value;
            var status = document.querySelector('select[name="status"]').value;

            var params = new URLSearchParams({
                page: currentPage - 1,
                size: pageSize
            });

            if (orderNumber) params.append('orderNumber', orderNumber);
            if (username) params.append('username', username);
            if (status) params.append('status', status);

            // Show loading animation
            var loadIndex = layer.load(1, {shade: [0.1,'#fff']});

            fetch('${pageContext.request.contextPath}/tickets/api/all-orders?' + params.toString())
                .then(response => response.json())
                .then(data => {
                    layer.close(loadIndex);

                    if (data.code === 0) {
                        renderOrdersTable(data.data);
                        renderPagination(data.count);
                    } else {
                        layer.msg(data.msg, {icon: 5});
                    }
                })
                .catch(error => {
                    layer.close(loadIndex);
                    layer.msg('Loading failed: ' + error.message, {icon: 5});
                });
        }

        // Render orders table
        function renderOrdersTable(orders) {
            var tbody = document.getElementById('ordersTableBody');

            if (orders.length === 0) {
                tbody.innerHTML =
                    '<tr>' +
                    '<td colspan="8" style="text-align: center; padding: 40px; color: #999;">' +
                    '<i class="layui-icon layui-icon-template-1" style="font-size: 48px; display: block; margin-bottom: 10px;"></i>' +
                    'No order data available' +
                    '</td>' +
                    '</tr>';
                return;
            }

            var html = '';
            orders.forEach(function(order) {
                var orderTime = new Date(order.orderDate).toLocaleString();
                var statusClass = 'status-' + order.status;
                var statusText = getStatusText(order.status);

                html +=
                    '<tr>' +
                    '<td>' + order.orderNumber + '</td>' +
                    '<td>' + order.user.username + '</td>' +
                    '<td>' + order.event.eventName + '</td>' +
                    '<td>' + order.quantity + '</td>' +
                    '<td style="color: #e74c3c; font-weight: 600;">¥' + order.totalAmount + '</td>' +
                    '<td><span class="status-badge ' + statusClass + '">' + statusText + '</span></td>' +
                    '<td>' + orderTime + '</td>' +
                    '<td>' +
                    '<button class="layui-btn layui-btn-xs" onclick="viewOrderDetail(' + order.id + ')">' +
                    '<i class="layui-icon layui-icon-search"></i> Details' +
                    '</button>' +
                    (order.status === 'paid' ?
                            '<button class="layui-btn layui-btn-xs layui-btn-normal" onclick="completeOrder(' + order.id + ')"><i class="layui-icon layui-icon-ok"></i> Complete</button>' : ''
                    ) +
                    '</td>' +
                    '</tr>';
            });

            tbody.innerHTML = html;
        }

        // Render pagination
        function renderPagination(total) {
            laypage.render({
                elem: 'pagination',
                count: total,
                limit: pageSize,
                curr: currentPage,
                layout: ['count', 'prev', 'page', 'next', 'limit', 'skip'],
                jump: function(obj, first) {
                    if (!first) {
                        currentPage = obj.curr;
                        pageSize = obj.limit;
                        loadOrders();
                    }
                }
            });
        }

        // Load statistics
        function loadStats() {
            fetch('${pageContext.request.contextPath}/tickets/api/order-stats')
                .then(response => response.json())
                .then(data => {
                    if (data.code === 0) {
                        var stats = data.data;
                        document.getElementById('pendingCount').textContent = stats.pendingOrders || 0;
                        document.getElementById('paidCount').textContent = stats.paidOrders || 0;
                        document.getElementById('cancelledCount').textContent = stats.cancelledOrders || 0;
                        document.getElementById('completedCount').textContent = stats.completedOrders || 0;
                    }
                })
                .catch(error => {
                    console.log('Stats loading failed: ' + error.message);
                });
        }

        // Get status text
        function getStatusText(status) {
            switch (status) {
                case 'pending': return 'Pending';
                case 'paid': return 'Paid';
                case 'cancelled': return 'Cancelled';
                case 'completed': return 'Completed';
                default: return status;
            }
        }

        // View order details
        window.viewOrderDetail = function(orderId) {
            // Show loading animation
            var loadIndex = layer.load(1);

            fetch('${pageContext.request.contextPath}/tickets/api/order/' + orderId)
                .then(response => response.json())
                .then(data => {
                    layer.close(loadIndex);

                    if (data.code === 0) {
                        showOrderDetail(data.data);
                    } else {
                        layer.msg(data.msg, {icon: 5});
                    }
                })
                .catch(error => {
                    layer.close(loadIndex);
                    layer.msg('Loading failed: ' + error.message, {icon: 5});
                });
        };

        // Show order details
        function showOrderDetail(order) {
            console.log(order)
            var orderTime = new Date(order.orderDate).toLocaleString();
            var eventTime = new Date(order.event.eventDate).toLocaleString();
            var paymentTime = order.paymentTime ? new Date(order.paymentTime).toLocaleString() : '-';
            var statusText = getStatusText(order.status);

            var content =
                '<div style="line-height: 2; padding: 30px; font-family: Arial, sans-serif;">' +
                '<div style="margin-bottom: 25px; background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #009688;">' +
                '<strong style="color: #009688; font-size: 16px;">📋 Order Information</strong><br>' +
                '<div style="margin-top: 10px;">' +
                'Order Number: <span style="color: #333; font-weight: 600;">' + order.orderNumber + '</span><br>' +
                'Status: <span style="color: #333; font-weight: 600;">' + statusText + '</span><br>' +
                'Order Date: <span style="color: #666;">' + orderTime + '</span><br>' +
                'Payment Time: <span style="color: #666;">' + paymentTime + '</span>' +
                '</div>' +
                '</div>' +

                '<div style="margin-bottom: 25px; background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #2196F3;">' +
                '<strong style="color: #2196F3; font-size: 16px;">👤 User Information</strong><br>' +
                '<div style="margin-top: 10px;">' +
                'Username: <span style="color: #333; font-weight: 600;">' + order.user.username + '</span><br>' +
                'Email: <span style="color: #666;">' + order.user.email + '</span><br>' +
                'Roles: <span style="color: #666;">' + order.user.roles + '</span>' +
                '</div>' +
                '</div>' +

                '<div style="margin-bottom: 25px; background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #FF9800;">' +
                '<strong style="color: #FF9800; font-size: 16px;">🎯 Event Information</strong><br>' +
                '<div style="margin-top: 10px;">' +
                'Event Name: <span style="color: #333; font-weight: 600;">' + order.event.eventName + '</span><br>' +
                'Location: <span style="color: #666;">' + order.event.location + '</span><br>' +
                'Event Time: <span style="color: #666;">' + eventTime + '</span><br>' +
                'Category: <span style="color: #666;">' + (order.event.category || 'Other') + '</span>' +
                '</div>' +
                '</div>' +

                '<div style="margin-bottom: 20px; background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #4CAF50;">' +
                '<strong style="color: #4CAF50; font-size: 16px;">💰 Purchase Information</strong><br>' +
                '<div style="margin-top: 10px;">' +
                'Quantity: <span style="color: #333; font-weight: 600;">' + order.quantity + ' tickets</span><br>' +
                'Unit Price: <span style="color: #666;">¥' + order.event.price + '</span><br>' +
                'Total Amount: <span style="color: #e74c3c; font-size: 20px; font-weight: 700; background: #fff; padding: 5px 10px; border-radius: 4px; display: inline-block; margin-top: 5px;">¥' + order.totalAmount + '</span>' +
                '</div>' +
                '</div>' +
                '</div>';

            document.getElementById('orderDetailContent').innerHTML = content;

            layer.open({
                type: 1,
                title: 'Order Details',
                area: ['700px', '650px'],
                content: document.getElementById('orderDetailContent').innerHTML
            });
        }

        // Complete order
        window.completeOrder = function(orderId) {
            layer.confirm('Are you sure to mark this order as completed?', {
                btn: ['Confirm', 'Cancel'],
                icon: 3,
                title: 'Confirmation'
            }, function(index) {
                // Get CSRF token
                var token = document.querySelector('meta[name="_csrf"]').getAttribute('content');
                var header = document.querySelector('meta[name="_csrf_header"]').getAttribute('content');

                fetch('${pageContext.request.contextPath}/tickets/api/order/' + orderId + '/complete', {
                    method: 'POST',
                    headers: {
                        [header]: token
                    }
                })
                    .then(response => response.json())
                    .then(data => {
                        if (data.code === 0) {
                            layer.close(index);
                            layer.msg('Order completed', {icon: 1}, function() {
                                loadOrders(); // Refresh orders list
                                loadStats(); // Refresh statistics
                            });
                        } else {
                            layer.msg(data.msg, {icon: 5});
                        }
                    })
                    .catch(error => {
                        layer.msg('Operation failed: ' + error.message, {icon: 5});
                    });
            });
        };
    });
</script>

</body>
</html>