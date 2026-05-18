<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <title>My Orders</title>

    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/layui/css/layui.css">

    <!-- CSRF Token for AJAX -->
    <meta name="_csrf" content="${_csrf.token}"/>
    <meta name="_csrf_header" content="${_csrf.headerName}"/>

    <style>
        .orders-container {
            padding: 15px;
            background: #fff;
            border-radius: 2px;
            min-height: 600px;
        }

        .search-form {
            background: #f8f8f8;
            padding: 15px;
            border-radius: 2px;
            margin-bottom: 15px;
            border: 1px solid #e6e6e6;
        }

        .order-card {
            border: 1px solid #e6e6e6;
            border-radius: 6px;
            margin-bottom: 15px;
            background: #fff;
            overflow: hidden;
            transition: all 0.3s ease;
            box-shadow: 0 2px 6px rgba(0,0,0,0.05);
        }

        .order-card:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transform: translateY(-2px);
        }

        .order-header {
            background: linear-gradient(135deg, #f8f8f8, #f0f0f0);
            padding: 15px 20px;
            border-bottom: 1px solid #e6e6e6;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .order-number {
            font-weight: bold;
            color: #333;
            font-size: 16px;
        }

        .order-date {
            color: #666;
            font-size: 12px;
            margin-top: 2px;
        }

        .order-status {
            padding: 6px 14px;
            border-radius: 16px;
            font-size: 12px;
            font-weight: bold;
            text-align: center;
            min-width: 70px;
        }

        .status-paid {
            background: linear-gradient(135deg, #52c41a, #73d13d);
            color: white;
            box-shadow: 0 2px 6px rgba(82, 196, 26, 0.3);
        }

        .status-pending {
            background: linear-gradient(135deg, #fa8c16, #ffa940);
            color: white;
            box-shadow: 0 2px 6px rgba(250, 140, 22, 0.3);
        }

        .status-cancelled {
            background: linear-gradient(135deg, #ff4d4f, #ff7875);
            color: white;
            box-shadow: 0 2px 6px rgba(255, 77, 79, 0.3);
        }

        .status-completed {
            background: linear-gradient(135deg, #1890ff, #40a9ff);
            color: white;
            box-shadow: 0 2px 6px rgba(24, 144, 255, 0.3);
        }

        .order-content {
            padding: 20px;
        }

        .event-info {
            display: flex;
            margin-bottom: 15px;
            align-items: center;
        }

        .event-poster {
            width: 80px;
            height: 100px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            border-radius: 6px;
            margin-right: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 12px;
            font-weight: bold;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .event-details {
            flex: 1;
        }

        .event-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
            line-height: 1.4;
        }

        .event-meta {
            color: #666;
            font-size: 14px;
            line-height: 1.8;
        }

        .event-meta p {
            margin: 0;
            padding: 2px 0;
        }

        .event-meta i {
            margin-right: 8px;
            color: #1890ff;
            width: 16px;
        }

        .order-summary {
            background: linear-gradient(135deg, #f6f9fc, #eef2f7);
            padding: 15px;
            border-radius: 6px;
            margin: 15px 0;
            border: 1px solid #e8f4fd;
        }

        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 14px;
        }

        .summary-row:last-child {
            margin-bottom: 0;
            font-weight: bold;
            font-size: 16px;
            color: #ff4d4f;
            padding-top: 8px;
            border-top: 1px solid #e8f4fd;
        }

        .order-actions {
            text-align: right;
            padding-top: 15px;
            border-top: 1px solid #e6e6e6;
        }

        .order-actions .layui-btn {
            margin-left: 8px;
            border-radius: 4px;
            font-size: 12px;
            padding: 0 15px;
        }

        .empty-state {
            text-align: center;
            padding: 80px 20px;
            color: #999;
        }

        .empty-state i {
            font-size: 64px;
            margin-bottom: 20px;
            color: #d9d9d9;
        }

        .empty-state p {
            font-size: 16px;
            margin-bottom: 20px;
        }

        .loading-state {
            text-align: center;
            padding: 80px 20px;
            color: #999;
        }

        .loading-state i {
            font-size: 48px;
            margin-bottom: 15px;
            color: #1890ff;
        }

        /* Popup styles */
        .order-detail-content {
            padding: 20px;
            max-height: 500px;
            overflow-y: auto;
        }

        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #f0f0f0;
        }

        .detail-row:last-child {
            border-bottom: none;
        }

        .detail-label {
            font-weight: bold;
            color: #666;
            min-width: 100px;
        }

        .detail-value {
            color: #333;
            flex: 1;
            text-align: right;
        }

        /* Responsive design */
        @media (max-width: 768px) {
            .orders-container {
                padding: 10px;
            }

            .event-info {
                flex-direction: column;
                align-items: flex-start;
            }

            .event-poster {
                width: 100%;
                height: 60px;
                margin-bottom: 10px;
                margin-right: 0;
            }

            .order-actions {
                text-align: center;
            }

            .order-actions .layui-btn {
                margin: 4px;
                display: inline-block;
            }
        }
    </style>
</head>
<body>

<div class="orders-container">
    <div class="search-form">
        <form class="layui-form" lay-filter="searchForm">
            <div class="layui-row layui-col-space10">
                <div class="layui-col-md3">
                    <div class="layui-form-item">
                        <input type="text" name="keyword" placeholder="Order No./Event Name" class="layui-input">
                    </div>
                </div>
                <div class="layui-col-md2">
                    <div class="layui-form-item">
                        <select name="status">
                            <option value="">All Status</option>
                            <option value="paid">Paid</option>
                            <option value="pending">Pending</option>
                            <option value="cancelled">Cancelled</option>
                            <option value="completed">Completed</option>
                        </select>
                    </div>
                </div>
                <div class="layui-col-md3">
                    <div class="layui-form-item">
                        <input type="text" name="dateRange" placeholder="Select Date Range" class="layui-input" id="dateRange">
                    </div>
                </div>
                <div class="layui-col-md2">
                    <button type="button" class="layui-btn layui-btn-primary" onclick="searchOrders()">
                        <i class="layui-icon layui-icon-search"></i> Search
                    </button>
                </div>
                <div class="layui-col-md2">
                    <button type="button" class="layui-btn layui-btn-normal" onclick="loadOrders()">
                        <i class="layui-icon layui-icon-refresh"></i> Refresh
                    </button>
                </div>
            </div>
        </form>
    </div>

    <div id="ordersList">
        <div class="loading-state">
            <i class="layui-icon layui-icon-loading layui-anim layui-anim-rotate layui-anim-loop"></i>
            <p>Loading order data...</p>
        </div>
    </div>

    <div id="pagination"></div>
</div>

<!-- LayUI JS -->
<script src="${pageContext.request.contextPath}/static/layui/layui.js"></script>

<script>
    layui.config({ lang: 'en' });
    layui.use(['form', 'layer', 'laydate', 'laypage', 'jquery'], function(){
        var form = layui.form,
            layer = layui.layer,
            laydate = layui.laydate,
            laypage = layui.laypage,
            $ = layui.jquery;

        // Date range picker
        laydate.render({
            elem: '#dateRange',
            range: true,
            format: 'yyyy-MM-dd'
        });

        // Load orders when page loads
        loadOrders();

        function loadOrders() {
            var token = $('meta[name="_csrf"]').attr('content');
            var header = $('meta[name="_csrf_header"]').attr('content');

            $('#ordersList').html('<div class="loading-state"><i class="layui-icon layui-icon-loading layui-anim layui-anim-rotate layui-anim-loop"></i><p>Loading order data...</p></div>');

            $.ajax({
                url: '${pageContext.request.contextPath}/tickets/api/my-orders',
                type: 'GET',
                headers: {
                    [header]: token
                },
                success: function(response) {
                    if (response.code === 0) {
                        displayOrders(response.data);
                    } else {
                        layer.msg(response.msg || 'Failed to load orders', {icon: 2});
                        $('#ordersList').html('<div class="empty-state"><i class="layui-icon layui-icon-face-cry"></i><p>Failed to load orders</p><button class="layui-btn layui-btn-primary" onclick="loadOrders()">Retry</button></div>');
                    }
                },
                error: function(xhr, status, error) {
                    layer.msg('Network error, please try again later', {icon: 2});
                    $('#ordersList').html('<div class="empty-state"><i class="layui-icon layui-icon-face-cry"></i><p>Network error, please try again later</p><button class="layui-btn layui-btn-primary" onclick="loadOrders()">Retry</button></div>');
                }
            });
        }

        function displayOrders(orders) {
            var html = '';

            if (orders.length === 0) {
                html = '<div class="empty-state">' +
                    '<i class="layui-icon layui-icon-cart-simple"></i>' +
                    '<p>No order records</p>' +
                    '<p style="color: #999; font-size: 14px;">You don\'t have any orders yet, <a href="${pageContext.request.contextPath}/tickets/events" style="color: #1890ff;">check out events</a></p>' +
                    '</div>';
            } else {
                orders.forEach(function(order) {
                    var statusClass = 'status-' + order.status;
                    var statusText = getStatusText(order.status);

                    // Format time
                    var orderDate = formatDateTime(order.orderDate);
                    var eventDate = formatDateTime(order.event.eventDate);
                    var paymentDate = order.paymentTime ? formatDateTime(order.paymentTime) : 'Not paid';

                    html += '<div class="order-card">' +
                        '<div class="order-header">' +
                        '<div>' +
                        '<div class="order-number">Order No.: ' + order.orderNumber + '</div>' +
                        '<div class="order-date">Order Time: ' + orderDate + '</div>' +
                        '</div>' +
                        '<span class="order-status ' + statusClass + '">' + statusText + '</span>' +
                        '</div>' +
                        '<div class="order-content">' +
                        '<div class="event-info">' +
                        '<div class="event-details">' +
                        '<div class="event-title">' + order.event.eventName + '</div>' +
                        '<div class="event-meta">' +
                        '<p><i class="layui-icon layui-icon-date"></i>Event Time: ' + eventDate + '</p>' +
                        '<p><i class="layui-icon layui-icon-location"></i>Location: ' + order.event.location + '</p>' +
                        '<p><i class="layui-icon layui-icon-username"></i>Quantity: ' + order.quantity + ' tickets</p>' +
                        (order.paymentTime ? '<p><i class="layui-icon layui-icon-rmb"></i>Payment Time: ' + paymentDate + '</p>' : '') +
                        '</div>' +
                        '</div>' +
                        '</div>' +
                        '<div class="order-summary">' +
                        '<div class="summary-row">' +
                        '<span>Ticket Price (' + order.quantity + ' × ￥' + order.event.price.toFixed(2) + ')</span>' +
                        '<span>￥' + order.totalAmount.toFixed(2) + '</span>' +
                        '</div>' +
                        '<div class="summary-row">' +
                        '<span>Actual Payment</span>' +
                        '<span>￥' + order.totalAmount.toFixed(2) + '</span>' +
                        '</div>' +
                        '</div>' +
                        '<div class="order-actions">' +
                        (order.status === 'pending' ?
                            '<button class="layui-btn layui-btn-warm layui-btn-sm" onclick="payOrder(' + order.id + ')">Pay Now</button>' +
                            '<button class="layui-btn layui-btn-danger layui-btn-sm" onclick="cancelOrder(' + order.id + ')">Cancel Order</button>'
                            : '') +
                        (order.status === 'paid' || order.status === 'completed' ?
                            '<button class="layui-btn layui-btn-normal layui-btn-sm" onclick="downloadInvoice(' + order.id + ')"><i class="layui-icon layui-icon-download-circle"></i> Download Invoice</button>'
                            : '') +
                        '<button class="layui-btn layui-btn-primary layui-btn-sm" onclick="viewOrderDetail(' + order.id + ')">View Details</button>' +
                        '</div>' +
                        '</div>' +
                        '</div>';
                });
            }

            $('#ordersList').html(html);
        }

        function getStatusText(status) {
            switch(status) {
                case 'paid': return 'Paid';
                case 'pending': return 'Pending';
                case 'cancelled': return 'Cancelled';
                case 'completed': return 'Completed';
                default: return status;
            }
        }

        function formatDateTime(dateTimeStr) {
            if (!dateTimeStr) return '';
            var date = new Date(dateTimeStr);
            return date.getFullYear() + '-' +
                String(date.getMonth() + 1).padStart(2, '0') + '-' +
                String(date.getDate()).padStart(2, '0') + ' ' +
                String(date.getHours()).padStart(2, '0') + ':' +
                String(date.getMinutes()).padStart(2, '0');
        }

        window.searchOrders = function() {
            var formData = form.val('searchForm');
            console.log('Search criteria:', formData);
            loadOrders(); // Can pass search parameters to backend
        };

        window.payOrder = function(orderId) {
            layer.confirm('Confirm to pay this order?<br><br><span style="color: #999; font-size: 12px;">Click OK to simulate successful payment</span>', {
                btn: ['Confirm Payment', 'Cancel'],
                icon: 3,
                title: 'Payment Confirmation'
            }, function(index) {
                layer.close(index);

                // Show payment in progress
                var loadIndex = layer.msg('Processing payment...', {
                    icon: 16,
                    shade: 0.3,
                    time: 0
                });

                var token = $('meta[name="_csrf"]').attr('content');
                var header = $('meta[name="_csrf_header"]').attr('content');

                // Call payment API
                $.ajax({
                    url: '${pageContext.request.contextPath}/tickets/api/order/' + orderId + '/pay',
                    type: 'POST',
                    headers: {
                        [header]: token
                    },
                    success: function(response) {
                        layer.close(loadIndex);
                        if (response.code === 0) {
                            layer.msg('Payment successful!', {icon: 1}, function() {
                                loadOrders(); // Reload order list
                            });
                        } else {
                            layer.msg('Payment failed: ' + response.msg, {icon: 2});
                        }
                    },
                    error: function() {
                        layer.close(loadIndex);
                        layer.msg('Payment failed, please try again later', {icon: 2});
                    }
                });
            });
        };

        window.cancelOrder = function(orderId) {
            layer.confirm('Confirm to cancel this order?<br><br><span style="color: #ff4d4f; font-size: 12px;">Cannot be recovered after cancellation, inventory will be released</span>', {
                btn: ['Confirm Cancel', 'Don\'t Cancel'],
                icon: 3,
                title: 'Cancel Order'
            }, function(index) {
                layer.close(index);

                var loadIndex = layer.msg('Cancelling order...', {
                    icon: 16,
                    shade: 0.3,
                    time: 0
                });

                var token = $('meta[name="_csrf"]').attr('content');
                var header = $('meta[name="_csrf_header"]').attr('content');

                // Call cancel order API
                $.ajax({
                    url: '${pageContext.request.contextPath}/tickets/api/order/' + orderId + '/cancel',
                    type: 'POST',
                    headers: {
                        [header]: token
                    },
                    success: function(response) {
                        layer.close(loadIndex);
                        if (response.code === 0) {
                            layer.msg('Order cancelled', {icon: 1}, function() {
                                loadOrders(); // Reload order list
                            });
                        } else {
                            layer.msg('Cancellation failed: ' + response.msg, {icon: 2});
                        }
                    },
                    error: function() {
                        layer.close(loadIndex);
                        layer.msg('Cancellation failed, please try again later', {icon: 2});
                    }
                });
            });
        };

        window.downloadInvoice = function(orderId) {
            layer.msg('Generating invoice...', {icon: 16, shade: 0.3});

            // Create download link - now orderId is numeric type
            var downloadUrl = '${pageContext.request.contextPath}/api/invoice/download/' + orderId;

            // Add CSRF token
            var token = $('meta[name="_csrf"]').attr('content');
            var header = $('meta[name="_csrf_header"]').attr('content');

            // Use fetch to download file
            fetch(downloadUrl, {
                method: 'GET',
                headers: {
                    [header]: token
                }
            })
                .then(response => {
                    if (response.ok) {
                        return response.blob();
                    } else {
                        return response.json().then(errorData => {
                            throw new Error(errorData.msg || 'Download failed');
                        });
                    }
                })
                .then(blob => {
                    layer.closeAll('msg');

                    // Create download link
                    var url = window.URL.createObjectURL(blob);
                    var a = document.createElement('a');
                    a.href = url;
                    a.download = 'invoice_' + orderId + '.pdf';
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    window.URL.revokeObjectURL(url);

                    layer.msg('Invoice downloaded successfully', {icon: 1});
                })
                .catch(error => {
                    layer.closeAll('msg');
                    layer.msg('Download failed: ' + error.message, {icon: 2});
                });
        };

        window.viewOrderDetail = function(orderId) {
            var loadIndex = layer.msg('Loading details...', {
                icon: 16,
                shade: 0.3,
                time: 0
            });

            var token = $('meta[name="_csrf"]').attr('content');
            var header = $('meta[name="_csrf_header"]').attr('content');

            // Get order details
            $.ajax({
                url: '${pageContext.request.contextPath}/tickets/api/order/' + orderId,
                type: 'GET',
                headers: {
                    [header]: token
                },
                success: function(response) {
                    layer.close(loadIndex);
                    if (response.code === 0) {
                        showOrderDetailModal(response.data);
                    } else {
                        layer.msg('Failed to get order details: ' + response.msg, {icon: 2});
                    }
                },
                error: function() {
                    layer.close(loadIndex);
                    layer.msg('Failed to get order details, please try again later', {icon: 2});
                }
            });
        };

        function showOrderDetailModal(order) {
            var statusText = getStatusText(order.status);
            var orderDate = formatDateTime(order.orderDate);
            var eventDate = formatDateTime(order.event.eventDate);
            var paymentDate = order.paymentTime ? formatDateTime(order.paymentTime) : 'Not paid';

            var content = '<div class="order-detail-content">' +
                '<div class="detail-row"><span class="detail-label">Order No.:</span><span class="detail-value">' + order.orderNumber + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Order Status:</span><span class="detail-value status-' + order.status + '">' + statusText + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Order Time:</span><span class="detail-value">' + orderDate + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Event Name:</span><span class="detail-value">' + order.event.eventName + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Event Time:</span><span class="detail-value">' + eventDate + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Location:</span><span class="detail-value">' + order.event.location + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Ticket Price:</span><span class="detail-value">￥' + order.event.price.toFixed(2) + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Quantity:</span><span class="detail-value">' + order.quantity + ' tickets</span></div>' +
                '<div class="detail-row"><span class="detail-label">Total Amount:</span><span class="detail-value" style="color: #ff4d4f; font-weight: bold;">￥' + order.totalAmount.toFixed(2) + '</span></div>' +
                (order.paymentTime ? '<div class="detail-row"><span class="detail-label">Payment Time:</span><span class="detail-value">' + paymentDate + '</span></div>' : '') +
                '<div class="detail-row"><span class="detail-label">Customer Name:</span><span class="detail-value">' + (order.user.nickname || order.user.username) + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Phone:</span><span class="detail-value">' + (order.user.phone || 'Not provided') + '</span></div>' +
                '<div class="detail-row"><span class="detail-label">Email:</span><span class="detail-value">' + (order.user.email || 'Not provided') + '</span></div>' +
                '</div>';

            layer.open({
                type: 1,
                title: 'Order Details',
                content: content,
                area: ['500px', '600px'],
                btn: ['Close'],
                btn1: function(index) {
                    layer.close(index);
                }
            });
        }

        // Page refresh function
        window.loadOrders = loadOrders;
    });
</script>

</body>
</html>