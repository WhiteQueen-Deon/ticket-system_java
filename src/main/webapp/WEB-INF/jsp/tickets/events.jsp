<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <title>Browse Events</title>

    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/layui/css/layui.css">

    <!-- CSRF Token for AJAX -->
    <meta name="_csrf" content="${_csrf.token}"/>
    <meta name="_csrf_header" content="${_csrf.headerName}"/>

    <style>
        body {
            background: #f5f5f5;
            margin: 0;
            padding: 20px;
        }

        .search-form {
            background: #fff;
            padding: 20px;
            border-radius: 4px;
            margin-bottom: 20px;
            border: 1px solid #e6e6e6;
        }

        .event-card {
            background: #fff;
            border-radius: 4px;
            border: 1px solid #e6e6e6;
            margin-bottom: 20px;
            overflow: hidden;
        }

        .event-header {
            background: #f8f8f8;
            padding: 15px 20px;
            border-bottom: 1px solid #e6e6e6;
        }

        .event-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 5px;
            color: #333;
        }

        .event-subtitle {
            color: #666;
            font-size: 14px;
        }

        .event-body {
            padding: 20px;
        }

        .event-info {
            margin-bottom: 20px;
        }

        .info-item {
            margin-bottom: 8px;
            font-size: 14px;
            color: #666;
        }

        .info-item i {
            margin-right: 8px;
            color: #666;
            font-size: 14px;
        }

        .event-actions {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-top: 15px;
            border-top: 1px solid #f0f0f0;
        }

        .price-info {
            font-size: 20px;
            font-weight: bold;
            color: #e74c3c;
        }

        .price-info .currency {
            font-size: 16px;
            margin-right: 2px;
        }

        .tickets-left {
            font-size: 12px;
            color: #999;
            margin-top: 4px;
        }

        .tickets-left.low {
            color: #e74c3c;
            font-weight: bold;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
            background: #fff;
            border: 1px solid #e6e6e6;
            border-radius: 4px;
        }

        .empty-state i {
            font-size: 48px;
            margin-bottom: 20px;
            color: #ddd;
        }

        .page-title {
            background: #fff;
            padding: 15px 20px;
            margin-bottom: 20px;
            border: 1px solid #e6e6e6;
            border-radius: 4px;
        }

        .page-title h3 {
            margin: 0;
            color: #333;
            font-size: 18px;
        }

        /* Ticket purchase modal styles */
        .buy-modal {
            padding: 30px;
        }

        .buy-modal .layui-form-item {
            margin-bottom: 15px;
        }

        .buy-modal .event-title-display {
            padding: 10px 0;
            font-weight: bold;
            color: #333;
        }

        .buy-modal .price-display {
            padding: 10px 0;
            color: #e74c3c;
            font-size: 18px;
            font-weight: bold;
        }

        .buy-modal .total-price-display {
            padding: 10px 0;
            color: #e74c3c;
            font-size: 20px;
            font-weight: bold;
        }

        @media screen and (max-width: 768px) {
            body {
                padding: 10px;
            }

            .event-actions {
                flex-direction: column;
                gap: 15px;
                align-items: stretch;
            }
        }
    </style>
</head>
<body>

<div class="page-title">
    <h3>Browse Events</h3>
</div>

<div class="search-form">
    <form class="layui-form" lay-filter="searchForm">
        <div class="layui-row layui-col-space15">
            <div class="layui-col-md6">
                <input type="text" name="keyword" placeholder="Search event name or description" class="layui-input">
            </div>
            <div class="layui-col-md3">
                <button type="button" class="layui-btn" onclick="searchEvents()">
                    <i class="layui-icon layui-icon-search"></i> Search
                </button>
            </div>
            <div class="layui-col-md3">
                <button type="button" class="layui-btn layui-btn-primary" onclick="resetSearch()">
                    <i class="layui-icon layui-icon-refresh"></i> Reset
                </button>
            </div>
        </div>
    </form>
</div>

<div id="eventsContainer">
    <!-- Event list will be loaded via AJAX -->
</div>

<!-- Pagination -->
<div id="pagination"></div>

<!-- Ticket purchase modal -->
<div id="buyTicketModal" style="display: none;">
    <div class="buy-modal">
        <form class="layui-form" id="buyTicketForm">
            <input type="hidden" name="eventId" id="modalEventId">

            <div class="layui-form-item">
                <label class="layui-form-label">Event Name</label>
                <div class="layui-input-block">
                    <div id="modalEventTitle" class="event-title-display"></div>
                </div>
            </div>

            <div class="layui-form-item">
                <label class="layui-form-label">Unit Price</label>
                <div class="layui-input-block">
                    <div id="modalEventPrice" class="price-display"></div>
                </div>
            </div>

            <div class="layui-form-item">
                <label class="layui-form-label">Quantity</label>
                <div class="layui-input-block">
                    <input type="number" name="quantity" id="ticketQuantity" required lay-verify="required|number"
                           placeholder="Enter quantity" value="1" min="1" class="layui-input">
                </div>
            </div>

            <div class="layui-form-item">
                <label class="layui-form-label">Total Price</label>
                <div class="layui-input-block">
                    <div id="totalPrice" class="total-price-display">¥0.00</div>
                </div>
            </div>

            <div class="layui-form-item">
                <div class="layui-input-block">
                    <button type="submit" class="layui-btn layui-btn-lg" lay-submit lay-filter="buyTicket">
                        <i class="layui-icon layui-icon-cart-simple"></i> Confirm Purchase
                    </button>
                    <button type="button" class="layui-btn layui-btn-primary layui-btn-lg" onclick="layer.closeAll()">Cancel</button>
                </div>
            </div>
        </form>
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
        var pageSize = 6;
        var currentEventPrice = 0;

        // Load events when page loads
        loadEvents();

        // Search events
        window.searchEvents = function() {
            currentPage = 1;
            loadEvents();
        };

        // Reset search
        window.resetSearch = function() {
            document.querySelector('input[name="keyword"]').value = '';
            currentPage = 1;
            loadEvents();
        };

        // Load events list
        function loadEvents() {
            var keyword = document.querySelector('input[name="keyword"]').value;

            var params = new URLSearchParams({
                page: currentPage - 1,
                size: pageSize
            });

            if (keyword) params.append('keyword', keyword);

            // Show loading animation
            var loadIndex = layer.load(1, {shade: [0.1,'#fff']});

            fetch('${pageContext.request.contextPath}/tickets/api/events?' + params.toString())
                .then(response => response.json())
                .then(data => {
                    layer.close(loadIndex);

                    if (data.code === 0) {
                        renderEvents(data.data);
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

        // Render events list
        function renderEvents(events) {
            var container = document.getElementById('eventsContainer');

            if (events.length === 0) {
                container.innerHTML =
                    '<div class="empty-state">' +
                    '<i class="layui-icon layui-icon-search"></i>' +
                    '<h3>No Events Available</h3>' +
                    '<p>There are currently no events available for purchase, please try again later</p>' +
                    '</div>';
                return;
            }

            var html = '';
            events.forEach(function(event) {
                var eventTime = new Date(event.eventDate).toLocaleString();
                var isLowStock = event.availableQuantity <= 10;

                html +=
                    '<div class="event-card">' +
                    '<div class="event-header">' +
                    '<div class="event-title">' + event.eventName + '</div>' +
                    '<div class="event-subtitle">' + event.location + ' | ' + eventTime + '</div>' +
                    '</div>' +
                    '<div class="event-body">' +
                    '<div class="event-info">' +
                    '<div class="info-item">' +
                    '<i class="layui-icon layui-icon-location"></i>' +
                    'Location: ' + event.location +
                    '</div>' +
                    '<div class="info-item">' +
                    '<i class="layui-icon layui-icon-date"></i>' +
                    'Time: ' + eventTime +
                    '</div>' +
                    '<div class="info-item">' +
                    '<i class="layui-icon layui-icon-user"></i>' +
                    'Available Tickets: ' + event.availableQuantity +
                    '</div>' +
                    '<div class="info-item">' +
                    '<i class="layui-icon layui-icon-read"></i>' +
                    'Description: ' + (event.description || 'No description') +
                    '</div>' +
                    '</div>' +
                    '<div class="event-actions">' +
                    '<div>' +
                    '<div class="price-info">' +
                    '<span class="currency">¥</span>' + event.price +
                    '</div>' +
                    '<div class="tickets-left ' + (isLowStock ? 'low' : '') + '">' +
                    (isLowStock ? 'Only ' + event.availableQuantity + ' left' : 'Tickets available') +
                    '</div>' +
                    '</div>' +
                    '<button class="layui-btn" onclick="openBuyModal(' + event.id + ', \'' + event.eventName + '\', ' + event.price + ', ' + event.availableQuantity + ')">' +
                    '<i class="layui-icon layui-icon-cart-simple"></i> Buy Now' +
                    '</button>' +
                    '</div>' +
                    '</div>' +
                    '</div>';
            });

            container.innerHTML = html;
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
                        loadEvents();
                    }
                }
            });
        }

        // Open ticket purchase modal
        window.openBuyModal = function(eventId, eventName, price, maxQuantity) {
            document.getElementById('modalEventId').value = eventId;
            document.getElementById('modalEventTitle').textContent = eventName;
            document.getElementById('modalEventPrice').textContent = '¥' + price;
            document.getElementById('ticketQuantity').setAttribute('max', maxQuantity);
            document.getElementById('ticketQuantity').value = 1;

            currentEventPrice = price;
            updateTotalPrice();

            layer.open({
                type: 1,
                title: 'Purchase Tickets',
                area: ['500px', '450px'],
                content: document.getElementById('buyTicketModal').innerHTML,
                success: function(layero) {
                    // Rebind events
                    var quantityInput = layero.find('#ticketQuantity')[0];
                    var totalPriceDiv = layero.find('#totalPrice')[0];

                    function updateTotal() {
                        var quantity = parseInt(quantityInput.value) || 1;
                        var total = currentEventPrice * quantity;
                        totalPriceDiv.textContent = '¥' + total.toFixed(2);
                    }

                    quantityInput.addEventListener('input', updateTotal);
                    updateTotal();

                    form.render();
                }
            });
        };

        // Update total price
        function updateTotalPrice() {
            var quantity = parseInt(document.getElementById('ticketQuantity').value) || 1;
            var total = currentEventPrice * quantity;
            document.getElementById('totalPrice').textContent = '¥' + total.toFixed(2);
        }

        // Submit ticket purchase form
        form.on('submit(buyTicket)', function(data) {
            var eventId = data.field.eventId;
            var quantity = data.field.quantity;

            // Get CSRF token
            var token = document.querySelector('meta[name="_csrf"]').getAttribute('content');
            var header = document.querySelector('meta[name="_csrf_header"]').getAttribute('content');

            var formData = new FormData();
            formData.append('eventId', eventId);
            formData.append('quantity', quantity);

            fetch('${pageContext.request.contextPath}/tickets/api/order', {
                method: 'POST',
                headers: {
                    [header]: token
                },
                body: formData
            })
                .then(response => response.json())
                .then(data => {
                    if (data.code === 0) {
                        layer.closeAll();
                        layer.msg('Ticket purchase successful!', {icon: 1}, function() {
                            loadEvents(); // Refresh events list
                        });
                    } else {
                        layer.msg(data.msg, {icon: 5});
                    }
                })
                .catch(error => {
                    layer.msg('Purchase failed: ' + error.message, {icon: 5});
                });

            return false;
        });
    });
</script>

</body>
</html>