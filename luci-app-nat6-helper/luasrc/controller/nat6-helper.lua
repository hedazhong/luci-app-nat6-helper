module("luci.controller.nat6-helper", package.seeall)

-- 导入相关的库和函数
local coroutine = require("coroutine")
local nixio = require("nixio")
local luci_sys = require("luci.sys")
local luci_util = require("luci.util")

function index()
	if not nixio.fs.access("/etc/config/nat6-helper") then
		return
	end

	entry({"admin", "services", "nat6-helper"},firstchild(), _("NAT6 配置助手"), 30).dependent = false   --左侧目录
	
	entry({"admin", "services", "nat6-helper", "general"},cbi("nat6-helper"), _("设置"), 1)   --顶级菜单，指向model.cbi

	entry({"admin", "services", "nat6-helper", "nat6_status"},call("nat6_status")).leaf=true   --处理请求，指向controller.function

	entry({"admin", "services", "nat6-helper", "check_ipv6"},call("check_ipv6")).leaf=true   --守护IPv6连通性
	
end

function init()
    local cmd = "nohup " .. luci.dispatcher.build_url("admin", "services", "nat6-helper", "check_ipv6") .. " >/dev/null 2>&1 &"
    os.execute(cmd)
end

function nat6_status()
	local e={}
	--判断nat6启用状态
	e.nat6_enabled=(luci.model.uci.cursor():get("nat6-helper", "@nat6-helper[0]", "enabled")=="1") and 1 or 0
	--判断nat6运行状态
	e.nat6_running=(luci.sys.call("ip6tables -t nat -L | grep 'v6NAT' > /dev/null")==0 and luci.sys.call("ip -6 route | grep '2000::/3' > /dev/null")==0) and 1 or 0
	--判断守护是否启用
	e.daemon_enabled=(luci.model.uci.cursor():get("nat6-helper", "@nat6-helper[0]", "enabled")=="1") and 1 or 0
	--判断守护运行状态
	e.daemon_running=(luci.model.uci.cursor():get("nat6-helper", "@check_ipv6[0]", "daemon_running")=="1") and 1 or 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function check_ipv6()
	local ping_cmd = "ping6 -c 3 -I %s %s >/dev/null  2>&1"
	local restart_cmd = "ifdown %s && ifup %s >/dev/null  2>&1"
	local sleep_cmd = "sleep %s >/dev/null  2>&1"
	
	-- 创建一个协程对象
	local co = coroutine.create(function()
		while true do
			--判断守护是否启用
			local keepipv6_enabled=(luci.model.uci.cursor():get("nat6-helper", "@check_ipv6[0]", "keepipv6_enabled")=="1") and 1 or 0
			if keepipv6_enabled and keepipv6_enabled == "1" then
				local wan6_name = luci.sys.exec("uci get nat6-helper.@nat6-helper[0].name")
				local ping_host = luci.model.uci.cursor():get("nat6-helper", "@check_ipv6[0]", "ping_host")
				local ping_period = luci.model.uci.cursor():get("nat6-helper", "@check_ipv6[0]", "ping_period")
				local ret = os.execute(string.format(ping_cmd, wan6_name, ping_host))
				--表示守护正在运行
				luci.model.uci.cursor():set("nat6-helper", "@check_ipv6[0]", "daemon_running", "1")
				if ret ~= 0 then
					os.execute(string.format(restart_cmd, wan6_name, wan6_name))
				end
				luci.util.execi(string.format(sleep_cmd, ping_period))
			else
				--表示守护终止运行
				luci.model.uci.cursor():set("nat6-helper", "@check_ipv6[0]", "daemon_running", "0")
				break
			end
		end
	end)
	
	-- 启动协程对象
	coroutine.resume(co)
end

