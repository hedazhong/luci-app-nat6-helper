module("luci.controller.nat6-helper", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/nat6-helper") then
		return
	end

	entry({"admin", "services", "nat6-helper"},firstchild(), _("NAT6 配置助手"), 30).dependent = false   --左侧目录
	
	entry({"admin", "services", "nat6-helper", "general"},cbi("nat6-helper"), _("设置"), 1)   --顶级菜单，指向model.cbi

	entry({"admin", "services", "nat6-helper", "nat6_status"},call("nat6_status")).leaf=true   --处理请求，指向controller.function
	
end

function nat6_status()
	local e={}
	--判断nat6启用状态
	e.nat6_enabled=(luci.model.uci.cursor():get("nat6-helper", "@nat6-helper[0]", "enabled")=="1") and 1 or 0
	--判断nat6运行状态
	e.nat6_running=(luci.sys.call("ip6tables -t nat -L | grep 'v6NAT' > /dev/null")==0 and luci.sys.call("ip -6 route | grep '2000::/3' > /dev/null")==0) and 1 or 0
	--判断守护是否启用
	e.daemon_enabled=(luci.model.uci.cursor():get("nat6-helper", "@daemon_ipv6[0]", "daemon_enabled")=="1") and 1 or 0
	--判断守护运行状态
	e.daemon_running=(luci.model.uci.cursor():get("nat6-helper", "@daemon_ipv6[0]", "daemon_running")=="1") and 1 or 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
