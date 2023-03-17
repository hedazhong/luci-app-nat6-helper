--简介
m = Map("nat6-helper", "NAT6 配置助手") 
m.description = translate("IPv6 路由器做 NAT6，使得路由器下级可以使用 IPv6 协议访问网站。<br />若插件启用失败，请检查路由器是否正常获取到IPv6。")

-- 插件启用状态和nat6运行状态
status = m:section(TypedSection, "nat6_status", translate("NAT6 Status"))
status.anonymous = true
status.addremove = false
status.template = "nat6-helper/nat6_status"   --view的路径，这里调用nat6_status.html

--配置nat6的会话
s = m:section(TypedSection, "nat6-helper")
s.addremove = false
s.anonymous = true

--启用开关
enabled = s:option(Flag, "enabled", translate("Enable"))
enabled.default = 0
enabled.rmempty = false

--IPv6接口
name = s:option(Value, "name", translate("Interface"))
name.rmempty = false
name.default = "wan6"
name.description = translate("默认为wan6，也可自行设置为有ipv6的接口名称。启用插件后，当该接口变动时自动设置nat6。")

--初始化按钮
init_button = s:option(Button, "init_button", translate("初始化"))
init_button.inputtitle = translate("一键配置")
init_button.inputstyle = "apply"
init_button.description = translate("需要先启用本插件否则点击无效，一键设置ULA、IPv6-DNS和DHCPv6。<br />配置时会重启一次网络，稍等片刻网络恢复。接口获得IPv6网络后会自动配置nat6。")
function init_button.write(self, section)
    io.popen("/etc/init.d/nat6-helper set_lan")
    luci.http.write("<script>alert('已发出初始化指令');</script>")
end

--手动重启按钮
enable_nat_button = s:option(Button, "enable_nat_button", translate("重启nat6"))
enable_nat_button.inputtitle = translate("手动重启nat6")
enable_nat_button.inputstyle = "apply"
enable_nat_button.description = translate("手动重启nat6，仅仅配置nat6路由转发规则和下级设备nat6流量的IPv6网关。<br />不会改动其他配置，等效于接口启动或者重启时的动作。")
function enable_nat_button.write(self, section)
    io.popen("/etc/init.d/nat6-helper stop_nat6")
    io.popen("/etc/init.d/nat6-helper start_nat6")
    luci.http.write("<script>alert('已发出重启指令');</script>")
end

--手动关闭按钮
disable_nat_button = s:option(Button, "disable_nat_button", translate("关闭nat6"))
disable_nat_button.inputtitle = translate("手动关闭nat6")
disable_nat_button.inputstyle = "apply"
disable_nat_button.description = translate("手动暂时关闭nat6，仅仅删除nat6路由转发和nat6的IPv6网关，接口启动或重启后会再次启用nat6。<br />不会改动其他配置，等效于接口关闭时的动作。")
function disable_nat_button.write(self, section)
    io.popen("/etc/init.d/nat6-helper stop_nat6")
    luci.http.write("<script>alert('已发出关闭指令');</script>")
end

--恢复原始配置按钮
reset_button = s:option(Button, "reset_button", translate("清除配置"))
reset_button.inputtitle = translate("一键清除配置")
reset_button.inputstyle = "apply"
reset_button.description = translate("需要先关闭本插件否则点击无效。一键重设初始化时所修改的配置为默认值。<br />插件未启动时点击也有效，故也可用于非nat6情况下的重置。")
function reset_button.write(self, section)
    io.popen("/etc/init.d/nat6-helper reset_lan")
    luci.http.write("<script>alert('已发出重置指令');</script>")
end


--配置守护接口IPv6连通性的会话
p = m:section(TypedSection, "check_ipv6")
p.addremove = false
p.anonymous = true


--守护接口IPv6连通性的开关
keepipv6_enabled = p:option(Flag, "keepipv6_enabled", translate("启用IPv6连通性守护"))
keepipv6_enabled.default = 0
keepipv6_enabled.rmempty = false
keepipv6_enabled.description = translate("保持IPv6接口的网络连通性。")

--Ping主机
ping_host = p:option(Value, "ping_host", translate("Ping主机"), translate("Ping该主机以检查IPv6网络连通性"))
ping_host.rmempty = false
ping_host.default = "240c::6666"
ping_host.datatype = "host(2)"

--Ping周期
ping_period = p:option(Value, "ping_period", translate("Ping周期"))
ping_period.rmempty = false
ping_period.default = "30"
ping_period.description = translate("检测网络连接的频率。单位为秒。")

--启动IPv6连通性守护
start_daemon_button = p:option(Button, "start_daemon_button", translate("启动守护"))
start_daemon_button.inputtitle = "开启守护"
start_daemon_button.inputstyle = "apply"
start_daemon_button.description = translate("点击该按钮前请先开启守护开关。守护启用时，开机加载插件时会自动启动。<br />守护丢失或者初次启用可手动点击启动。")
function start_daemon_button.write(self, section)
    --sh后台运行
    os.execute("nohup /etc/init.d/nat6-helper ipv6_daemon &")
    luci.http.write("<script>alert('已开始守护接口IPv6连通性');</script>")
end

--关闭IPv6连通性守护
stop_daemon_button = p:option(Button, "start_daemon_button", translate("终止守护"))
stop_daemon_button.inputtitle = "关闭守护"
stop_daemon_button.inputstyle = "apply"
stop_daemon_button.description = translate("点击该按钮前请先开启守护开关。守护启用时，开机加载插件时会自动启动。<br />守护丢失或者初次启用可手动点击启动。")
function start_daemon_button.write(self, section)
    --sh后台运行
    luci.model.uci.cursor():set("nat6-helper", "@check_ipv6[0]", "daemon_running", "0")
    luci.http.write("<script>alert('已结束守护接口IPv6连通性');</script>")
end

--手动重启IPv6接口
restart_wan6_button = p:option(Button, "restart_wan6_button", translate("重启WAN6"))
restart_wan6_button.inputtitle = "手动重启WAN6"
restart_wan6_button.inputstyle = "apply"
restart_wan6_button.description = translate("点击这个按钮重启WAN6接口")
function restart_wan6_button.write(self, section)
    WAN6_NAME=io.popen("uci get nat6-helper.@nat6-helper[0].name"):read("*line")
    os.execute(string.format("sudo ifdown %s && sudo ifup %s", WAN6_NAME, WAN6_NAME))
    luci.http.write("<script>alert('已发出重启WAN6指令');</script>")
end

return m
