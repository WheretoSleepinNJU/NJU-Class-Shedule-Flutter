function scheduleHtmlParser() {
	// 1. 获取学期列表
	var getTerms = () => {
		var xhr = new XMLHttpRequest();
		xhr.open(
			"GET",
			"https://ehall.seu.edu.cn/jwapp/sys/wdkb/modules/jshkcb/xnxqcx.do",
			false,
		);
		xhr.send();
		var data = JSON.parse(xhr.responseText);
		var terms = data.datas.xnxqcx.rows;
		terms.sort((a, b) => a.PX - b.PX); // 早→新
		return terms;
	};

	// 2. 获取课表
	var getRawKb = (termCode) => {
		var xhr = new XMLHttpRequest();
		xhr.open(
			"GET",
			"https://ehall.seu.edu.cn/jwapp/sys/wdkb/modules/xskcb/xskcb.do?XNXQDM=" +
				termCode,
			false,
		);
		xhr.send();
		return JSON.parse(xhr.responseText).datas.xskcb.rows;
	};

	// 3. 解析周数
	function parseWeekRange(zcmc) {
		if (!zcmc) return [];

		const parts = zcmc.split(",");
		const allWeeks = [];

		parts.forEach((part) => {
			// 车带课表里可能会出现'9-11周(单),13-15周,16周'这样的字符串
			// (\d+) 开始周
			// (?:-(\d+))? 可选的结束周
			// 周? 匹配可能出现的“周”字（"?"不必要，因为我没发现不带周的文本，但是加一下确保鲁棒性）
			// (?:\((单|双)\))? 可选的单双周标识
			const m = part.match(/(\d+)(?:-(\d+))?周?(?:\((单|双)\))?/);
			if (!m) return;

			const start = parseInt(m[1], 10);
			const end = m[2] ? parseInt(m[2], 10) : start; // 如果没写结束周，就等于开始周
			const flag = { 单: 1, 双: 2 }[m[3]] || 0;

			for (let w = start; w <= end; w++) {
				if (
					flag === 0 ||
					(flag === 1 && w % 2 !== 0) ||
					(flag === 2 && w % 2 === 0)
				) {
					if (!allWeeks.includes(w)) allWeeks.push(w);
				}
			}
		});

		return allWeeks.sort((a, b) => a - b);
	}

	// 4. 从DOM获取当前学期
	var currentTermCode = null;
	var currentTermName = null;

	var terms = getTerms();
	var currentTerm = terms[0];
	currentTermCode = currentTerm.DM;
	currentTermName = currentTerm.MC;

	if (!currentTermCode) {
		return encodeURIComponent(
			JSON.stringify({
				name: "无法获取学期信息",
				courses: [],
			}),
		);
	}

	// 5. 抓取并转换
	var rows = getRawKb(currentTermCode);
	var courses = [];
	rows.forEach((r) => {
		var weeksArr = parseWeekRange(r.ZCMC);
		if (!weeksArr.length) return;
		courses.push({
			name: r.KCM,
			classroom: r.JASMC,
			class_number: r.KCH,
			teacher: r.SKJS,
			test_time: null,
			test_location: null,
			link: null,
			weeks: weeksArr,
			week_time: parseInt(r.SKXQ, 10),
			start_time: parseInt(r.KSJC, 10),
			time_count: parseInt(r.JSJC, 10) - parseInt(r.KSJC, 10),
			import_type: 1,
			info: r.ZCMC,
			data: null,
		});
	});

	console.log(`已选择学期：${currentTermCode} ${currentTermName}`);

	// 返回符合南哪课表格式的数据
	var result = {
		name: currentTermName,
		courses: courses,
	};
	return encodeURIComponent(JSON.stringify(result));
}

scheduleHtmlParser();
