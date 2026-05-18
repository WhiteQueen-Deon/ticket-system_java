<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <title>User List</title>

    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/layui/css/layui.css">
    <meta name="_csrf" content="${_csrf.token}"/>
    <meta name="_csrf_header" content="${_csrf.headerName}"/>

    <style>
        .user-container {
            padding: 15px;
            background: #fff;
            border-radius: 2px;
        }

        .search-form {
            background: #f8f8f8;
            padding: 15px;
            border-radius: 2px;
            margin-bottom: 15px;
            border: 1px solid #e6e6e6;
        }

        .toolbar {
            margin-bottom: 15px;
            padding: 10px 0;
            border-bottom: 1px solid #e6e6e6;
        }

        .status-enabled {
            color: #5FB878;
            font-weight: bold;
            padding: 2px 6px;
            border-radius: 2px;
            border: 1px solid #5FB878;
        }

        .status-disabled {
            color: #FF5722;
            font-weight: bold;
            padding: 2px 6px;
            border-radius: 2px;
            border: 1px solid #FF5722;
        }

        .role-admin { color: #FF5722; font-weight: bold; }
        .role-manager { color: #FF9900; font-weight: bold; }
        .role-customer { color: #1E9FFF; font-weight: bold; }
    </style>
</head>
<body>
<div class="user-container">
    <div class="search-form">
        <form class="layui-form" lay-filter="searchForm">
            <div class="layui-row layui-col-space10">
                <div class="layui-col-md3">
                    <div class="layui-form-item">
                        <input type="text" name="keyword" placeholder="Username/Email/Nickname" class="layui-input">
                    </div>
                </div>
                <div class="layui-col-md2">
                    <div class="layui-form-item">
                        <select name="role">
                            <option value="">All Roles</option>
                            <option value="ROLE_ADMIN">Administrator</option>
                            <option value="ROLE_MANAGER">Manager</option>
                            <option value="ROLE_CUSTOMER">Customer</option>
                        </select>
                    </div>
                </div>
                <div class="layui-col-md2">
                    <div class="layui-form-item">
                        <select name="enabled">
                            <option value="">All Status</option>
                            <option value="true">Enabled</option>
                            <option value="false">Disabled</option>
                        </select>
                    </div>
                </div>
                <div class="layui-col-md3">
                    <button type="button" class="layui-btn layui-btn-primary" onclick="searchUsers()" style="margin-right: 10px;">
                        <i class="layui-icon layui-icon-search"></i> Search
                    </button>
                    <button type="reset" class="layui-btn layui-btn-primary">
                        <i class="layui-icon layui-icon-refresh"></i> Reset
                    </button>
                </div>
            </div>
        </form>
    </div>

    <div class="toolbar">
        <button class="layui-btn layui-btn-normal" onclick="addUser()">
            <i class="layui-icon layui-icon-add-1"></i> Add User
        </button>
        <button class="layui-btn layui-btn-danger" onclick="batchDelete()">
            <i class="layui-icon layui-icon-delete"></i> Batch Delete
        </button>
    </div>

    <table id="userTable" lay-filter="userTable"></table>
</div>

<script type="text/html" id="toolbarDemo">
    <div class="layui-btn-container">
        <button class="layui-btn layui-btn-sm" lay-event="edit">Edit</button>
        <button class="layui-btn layui-btn-sm layui-btn-warm" lay-event="role">Role</button>
        <button class="layui-btn layui-btn-sm layui-btn-normal" lay-event="status">Status</button>
        <button class="layui-btn layui-btn-sm layui-btn-primary" lay-event="resetPwd">Reset Password</button>
        <button class="layui-btn layui-btn-sm layui-btn-danger" lay-event="del">Delete</button>
    </div>
</script>

<script type="text/html" id="enabledTpl">
    {{# if(d.enabled) { }}
    <span class="status-enabled">Enabled</span>
    {{# } else { }}
    <span class="status-disabled">Disabled</span>
    {{# } }}
</script>

<script type="text/html" id="rolesTpl">
    {{# if(d.roles && d.roles.includes('ROLE_ADMIN')) { }}
    <span class="role-admin">Administrator</span>
    {{# } else if(d.roles && d.roles.includes('ROLE_MANAGER')) { }}
    <span class="role-manager">Manager</span>
    {{# } else if(d.roles && d.roles.includes('ROLE_CUSTOMER')) { }}
    <span class="role-customer">Customer</span>
    {{# } else { }}
    <span>Unknown</span>
    {{# } }}
</script>

<script src="${pageContext.request.contextPath}/static/layui/layui.js"></script>

<script>
    layui.config({ lang: 'en' });
    layui.use(['table', 'form', 'layer', 'jquery'], function(){
        var table = layui.table,
            form = layui.form,
            layer = layui.layer,
            $ = layui.jquery;

        var tableIns = table.render({
            elem: '#userTable',
            url: '${pageContext.request.contextPath}/users/api/list',
            method: 'GET',
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            },
            toolbar: '#toolbarDemo',
            defaultToolbar: ['filter', 'exports', 'print'],
            cols: [[
                {type: 'checkbox'},
                {field: 'id', title: 'ID', sort: true},
                {field: 'username',  title: 'Username'},
                {field: 'email',  title: 'Email'},
                {field: 'nickname', title: 'Nickname'},
                {field: 'phone', title: 'Phone'},
                {field: 'roles', title: 'Role', templet: '#rolesTpl'},
                {field: 'enabled',title: 'Status', templet: '#enabledTpl'},
                {field: 'createTime',  title: 'Create Time'},
                {title: 'Operations', width: 350, toolbar: '#toolbarDemo', fixed: 'right'}
            ]],
            page: true,
            limit: 10,
            limits: [10, 20, 30, 50],
            loading: true,
            text: {
                none: 'No relevant data'
            }
        });

        table.on('tool(userTable)', function(obj){
            var data = obj.data;
            if(obj.event === 'edit'){
                editUser(data);
            } else if(obj.event === 'del'){
                layer.confirm('Are you sure to delete this user?', function(index){
                    deleteUser(data.id);
                    layer.close(index);
                });
            } else if(obj.event === 'role'){
                changeUserRole(data);
            } else if(obj.event === 'status'){
                changeUserStatus(data);
            } else if(obj.event === 'resetPwd'){
                resetPassword(data);
            }
        });

        window.searchUsers = function() {
            var formData = form.val('searchForm');
            tableIns.reload({
                where: formData,
                page: {
                    curr: 1
                }
            });
        };

        window.addUser = function() {
            var content = '<form class="layui-form" style="padding: 20px;" lay-filter="addUserForm">' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Username <span style="color:red">*</span></label>' +
                '<div class="layui-input-block">' +
                '<input type="text" name="username" placeholder="Please enter username" lay-verify="required|username" class="layui-input" autocomplete="off">' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Password <span style="color:red">*</span></label>' +
                '<div class="layui-input-block">' +
                '<input type="password" name="password" placeholder="Please enter password (at least 6 characters)" lay-verify="required|password" class="layui-input" autocomplete="off">' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Confirm Password <span style="color:red">*</span></label>' +
                '<div class="layui-input-block">' +
                '<input type="password" name="confirmPassword" placeholder="Please enter password again" lay-verify="required|confirmPassword" class="layui-input" autocomplete="off">' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Email <span style="color:red">*</span></label>' +
                '<div class="layui-input-block">' +
                '<input type="email" name="email" placeholder="Please enter email address" lay-verify="required|email" class="layui-input" autocomplete="off">' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Nickname</label>' +
                '<div class="layui-input-block">' +
                '<input type="text" name="nickname" placeholder="Please enter nickname" class="layui-input" autocomplete="off">' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Phone</label>' +
                '<div class="layui-input-block">' +
                '<input type="text" name="phone" placeholder="Please enter phone number" lay-verify="phone" class="layui-input" autocomplete="off">' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Role <span style="color:red">*</span></label>' +
                '<div class="layui-input-block">' +
                '<select name="roles" lay-verify="required">' +
                '<option value="">Please select role</option>' +
                '<option value="ROLE_CUSTOMER" selected>Customer</option>' +
                '<option value="ROLE_MANAGER">Manager</option>' +
                '<option value="ROLE_ADMIN">Administrator</option>' +
                '</select>' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Status</label>' +
                '<div class="layui-input-block">' +
                '<input type="checkbox" name="enabled" value="true" checked lay-skin="switch" lay-text="Enabled|Disabled">' +
                '</div>' +
                '</div>' +
                '</form>';

            layer.open({
                type: 1,
                title: 'Add User',
                content: content,
                area: ['600px', '650px'],
                success: function() {
                    // Add custom validation rules
                    form.verify({
                        username: function(value) {
                            if (value.length < 3 || value.length > 20) {
                                return 'Username must be between 3-20 characters';
                            }
                            if (!/^[a-zA-Z0-9_\u4e00-\u9fa5]+$/.test(value)) {
                                return 'Username can only contain letters, numbers, underscores and Chinese characters';
                            }
                        },
                        password: function(value) {
                            if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                            }
                        },
                        confirmPassword: function(value) {
                            var password = $('input[name="password"]').val();
                            if (value !== password) {
                                return 'Passwords do not match';
                            }
                        },
                        phone: function(value) {
                            if (value && !/^1[3-9]\d{9}$/.test(value)) {
                                return 'Please enter a valid phone number';
                            }
                        }
                    });
                    form.render();
                },
                btn: ['Save', 'Cancel'],
                yes: function(index, layero) {
                    var formData = form.val('addUserForm');

                    // Validate required fields
                    if (!formData.username || !formData.password || !formData.confirmPassword || !formData.email || !formData.roles) {
                        layer.msg('Please fill in required fields');
                        return false;
                    }

                    // Validate password consistency
                    if (formData.password !== formData.confirmPassword) {
                        layer.msg('Passwords do not match');
                        return false;
                    }

                    formData.enabled = formData.enabled === 'on';
                    delete formData.confirmPassword;

                    createUser(formData, index);
                }
            });
        };

        window.editUser = function(data) {
            var content = '<form class="layui-form" style="padding: 20px;" lay-filter="editForm">' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Username</label>' +
                '<div class="layui-input-block">' +
                '<input type="text" name="username" value="' + data.username + '" class="layui-input" readonly>' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Email</label>' +
                '<div class="layui-input-block">' +
                '<input type="email" name="email" value="' + (data.email || '') + '" class="layui-input" required>' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Nickname</label>' +
                '<div class="layui-input-block">' +
                '<input type="text" name="nickname" value="' + (data.nickname || '') + '" class="layui-input">' +
                '</div>' +
                '</div>' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Phone</label>' +
                '<div class="layui-input-block">' +
                '<input type="text" name="phone" value="' + (data.phone || '') + '" class="layui-input">' +
                '</div>' +
                '</div>' +
                '</form>';

            layer.open({
                type: 1,
                title: 'Edit User',
                content: content,
                area: ['500px', '400px'],
                btn: ['Save', 'Cancel'],
                yes: function(index, layero) {
                    var formData = form.val('editForm');
                    updateUser(data.id, formData, index);
                }
            });
        };

        window.changeUserRole = function(data) {
            var currentRole = '';
            if (data.roles.includes('ROLE_ADMIN')) currentRole = 'ROLE_ADMIN';
            else if (data.roles.includes('ROLE_MANAGER')) currentRole = 'ROLE_MANAGER';
            else if (data.roles.includes('ROLE_CUSTOMER')) currentRole = 'ROLE_CUSTOMER';

            var content = '<form class="layui-form" style="padding: 20px;" lay-filter="roleForm">' +
                '<div class="layui-form-item">' +
                '<label class="layui-form-label">Select Role</label>' +
                '<div class="layui-input-block">' +
                '<select name="roles" required>' +
                '<option value="">Please select role</option>' +
                '<option value="ROLE_ADMIN"' + (currentRole === 'ROLE_ADMIN' ? ' selected' : '') + '>Administrator</option>' +
                '<option value="ROLE_MANAGER"' + (currentRole === 'ROLE_MANAGER' ? ' selected' : '') + '>Manager</option>' +
                '<option value="ROLE_CUSTOMER"' + (currentRole === 'ROLE_CUSTOMER' ? ' selected' : '') + '>Customer</option>' +
                '</select>' +
                '</div>' +
                '</div>' +
                '</form>';

            layer.open({
                type: 1,
                title: 'Change User Role',
                content: content,
                area: ['500px', '250px'],
                success: function() {
                    form.render();
                },
                btn: ['Save', 'Cancel'],
                yes: function(index, layero) {
                    var formData = form.val('roleForm');
                    if (!formData.roles) {
                        layer.msg('Please select a role');
                        return false;
                    }
                    updateRole(data.id, formData.roles, index);
                }
            });
        };

        window.changeUserStatus = function(data) {
            var action = data.enabled ? 'disable' : 'enable';
            var newStatus = !data.enabled;

            layer.confirm('Are you sure to ' + action + ' this user?', function(index){
                updateStatus(data.id, newStatus);
                layer.close(index);
            });
        };

        window.resetPassword = function(data) {
            layer.prompt({
                title: 'Reset Password',
                formType: 1,
                placeholder: 'Please enter new password (at least 6 characters)'
            }, function(value, index, elem){
                if (value.length < 6) {
                    layer.msg('Password must be at least 6 characters');
                    return false;
                }
                resetUserPassword(data.id, value, index);
            });
        };

        window.batchDelete = function() {
            var checkStatus = table.checkStatus('userTable');
            var data = checkStatus.data;

            if (data.length === 0) {
                layer.msg('Please select users to delete');
                return;
            }

            var ids = data.map(function(item) {
                return item.id;
            });

            layer.confirm('Are you sure to delete selected ' + data.length + ' users?', function(index){
                batchDeleteUsers(ids);
                layer.close(index);
            });
        };

        function updateUser(id, formData, layerIndex) {
            layer.load(2);
            $.ajax({
                url: '${pageContext.request.contextPath}/users/api/' + id,
                type: 'PUT',
                contentType: 'application/json',
                data: JSON.stringify(formData),
                beforeSend: function(xhr) {
                    var token = $('meta[name="_csrf"]').attr('content');
                    var header = $('meta[name="_csrf_header"]').attr('content');
                    xhr.setRequestHeader(header, token);
                },
                success: function(res) {
                    layer.closeAll('loading');
                    if (res.code === 0) {
                        layer.msg('Update successful');
                        tableIns.reload();
                        layer.close(layerIndex);
                    } else {
                        layer.msg(res.msg || 'Update failed');
                    }
                },
                error: function() {
                    layer.closeAll('loading');
                    layer.msg('Network error');
                }
            });
        }

        function deleteUser(id) {
            layer.load(2);
            $.ajax({
                url: '${pageContext.request.contextPath}/users/api/' + id,
                type: 'DELETE',
                beforeSend: function(xhr) {
                    var token = $('meta[name="_csrf"]').attr('content');
                    var header = $('meta[name="_csrf_header"]').attr('content');
                    xhr.setRequestHeader(header, token);
                },
                success: function(res) {
                    layer.closeAll('loading');
                    if (res.code === 0) {
                        layer.msg('Delete successful');
                        tableIns.reload();
                    } else {
                        layer.msg(res.msg || 'Delete failed');
                    }
                },
                error: function() {
                    layer.closeAll('loading');
                    layer.msg('Network error');
                }
            });
        }

        function updateRole(id, roles, layerIndex) {
            layer.load(2);
            $.ajax({
                url: '${pageContext.request.contextPath}/users/api/' + id + '/role',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({roles: roles}),
                beforeSend: function(xhr) {
                    var token = $('meta[name="_csrf"]').attr('content');
                    var header = $('meta[name="_csrf_header"]').attr('content');
                    xhr.setRequestHeader(header, token);
                },
                success: function(res) {
                    layer.closeAll('loading');
                    if (res.code === 0) {
                        layer.msg('Role update successful');
                        tableIns.reload();
                        layer.close(layerIndex);
                    } else {
                        layer.msg(res.msg || 'Update failed');
                    }
                },
                error: function() {
                    layer.closeAll('loading');
                    layer.msg('Network error');
                }
            });
        }

        function updateStatus(id, enabled) {
            layer.load(2);
            $.ajax({
                url: '${pageContext.request.contextPath}/users/api/' + id + '/status',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({enabled: enabled}),
                beforeSend: function(xhr) {
                    var token = $('meta[name="_csrf"]').attr('content');
                    var header = $('meta[name="_csrf_header"]').attr('content');
                    xhr.setRequestHeader(header, token);
                },
                success: function(res) {
                    layer.closeAll('loading');
                    if (res.code === 0) {
                        layer.msg('Status update successful');
                        tableIns.reload();
                    } else {
                        layer.msg(res.msg || 'Update failed');
                    }
                },
                error: function() {
                    layer.closeAll('loading');
                    layer.msg('Network error');
                }
            });
        }

        function resetUserPassword(id, password, layerIndex) {
            layer.load(2);
            $.ajax({
                url: '${pageContext.request.contextPath}/users/api/' + id + '/reset-password',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({password: password}),
                beforeSend: function(xhr) {
                    var token = $('meta[name="_csrf"]').attr('content');
                    var header = $('meta[name="_csrf_header"]').attr('content');
                    xhr.setRequestHeader(header, token);
                },
                success: function(res) {
                    layer.closeAll('loading');
                    if (res.code === 0) {
                        layer.msg('Password reset successful');
                        layer.close(layerIndex);
                    } else {
                        layer.msg(res.msg || 'Reset failed');
                    }
                },
                error: function() {
                    layer.closeAll('loading');
                    layer.msg('Network error');
                }
            });
        }

        function batchDeleteUsers(ids) {
            layer.load(2);
            $.ajax({
                url: '${pageContext.request.contextPath}/users/api/batch-delete',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({ids: ids}),
                beforeSend: function(xhr) {
                    var token = $('meta[name="_csrf"]').attr('content');
                    var header = $('meta[name="_csrf_header"]').attr('content');
                    xhr.setRequestHeader(header, token);
                },
                success: function(res) {
                    layer.closeAll('loading');
                    if (res.code === 0) {
                        layer.msg('Batch delete successful');
                        tableIns.reload();
                    } else {
                        layer.msg(res.msg || 'Delete failed');
                    }
                },
                error: function() {
                    layer.closeAll('loading');
                    layer.msg('Network error');
                }
            });
        }

        function createUser(formData, layerIndex) {
            layer.load(2);
            $.ajax({
                url: '${pageContext.request.contextPath}/users/api/create',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify(formData),
                beforeSend: function(xhr) {
                    var token = $('meta[name="_csrf"]').attr('content');
                    var header = $('meta[name="_csrf_header"]').attr('content');
                    xhr.setRequestHeader(header, token);
                },
                success: function(res) {
                    layer.closeAll('loading');
                    if (res.code === 0) {
                        layer.msg('User created successfully');
                        tableIns.reload();
                        layer.close(layerIndex);
                    } else {
                        layer.msg(res.msg || 'Create failed');
                    }
                },
                error: function() {
                    layer.closeAll('loading');
                    layer.msg('Network error');
                }
            });
        }
    });
</script>
</body>
</html>