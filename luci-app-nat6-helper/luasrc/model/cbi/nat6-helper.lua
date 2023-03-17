--简介
m = Map("nat6-helper", "NAT6 配置助手") 
m.description = translate("IPv6 路由器做 NAT6，使得路由器下级可以使用 IPv6 协议访问网站。<br />若插件启用失败，请检查路由器是否正常获取到IPv6。")

-- 插件启用状态和nat6运行状态
status = m:section(TypedSection, "nat6_status", translate("NAT6 Status"))
status.anonymous = true
status.addremove = false
status.template = "nat6-helper/nat6_status"


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
    io.popen("/etc/init.d/nat6-helper setLan")
    luci.http.write("<script>alert('已发出初始化指令');</script>")
end

--重启IPv6接口
restart_wan6_button = s:option(Button, "restart_wan6_button", translate("重启WAN6"))
restart_wan6_button.inputtitle = "Restart WAN6"
restart_wan6_button.inputstyle = "apply"
restart_wan6_button.description = translate("点击这个按钮重启WAN6接口")
function restart_wan6_button.write(self, section)
    WAN6_NAME=io.popen("uci get nat6-helper.@nat6-helper[0].name"):read("*line")
    os.execute(string.format("sudo ifdown %s && sudo ifup %s", WAN6_NAME, WAN6_NAME))
    luci.http.write("<script>alert('已发出重启WAN6指令');</script>")
end

--手动重启按钮
enable_nat_button = s:option(Button, "enable_nat_button", translate("重启nat6"))
enable_nat_button.inputtitle = translate("手动重启nat6")
enable_nat_button.inputstyle = "apply"
enable_nat_button.description = translate("手动重启nat6，仅仅配置nat6路由转发规则和下级设备nat6流量的IPv6网关。<br />不会改动其他配置，等效于接口启动或者重启时的动作。")
function enable_nat_button.write(self, section)
    io.popen("/etc/init.d/nat6-helper stopNat6")
    io.popen("/etc/init.d/nat6-helper startNat6")
    luci.http.write("<script>alert('已发出重启指令');</script>")
end

--手动关闭按钮
disable_nat_button = s:option(Button, "disable_nat_button", translate("关闭nat6"))
disable_nat_button.inputtitle = translate("手动关闭nat6")
disable_nat_button.inputstyle = "apply"
disable_nat_button.description = translate("手动暂时关闭nat6，仅仅删除nat6路由转发和nat6的IPv6网关，接口启动或重启后会再次启用nat6。<br />不会改动其他配置，等效于接口关闭时的动作。")
function disable_nat_button.write(self, section)
    io.popen("/etc/init.d/nat6-helper stopNat6")
    luci.http.write("<script>alert('已发出关闭指令');</script>")
end

--恢复原始配置按钮
reset_button = s:option(Button, "reset_button", translate("清除配置"))
reset_button.inputtitle = translate("一键清除配置")
reset_button.inputstyle = "apply"
reset_button.description = translate("需要先关闭本插件否则点击无效。一键重设初始化时所修改的配置为默认值。<br />插件未启动时点击也有效，故也可用于非nat6情况下的重置。")
function reset_button.write(self, section)
    io.popen("/etc/init.d/nat6-helper resetLan")
    luci.http.write("<script>alert('已发出重置指令');</script>")
end

return m
