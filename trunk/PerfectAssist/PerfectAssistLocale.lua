local locale = GetLocale()

if locale == "zhTW" then 
	PerfectAssistLocale = {
		-- CC
		["翼龍釘刺"] = true,
		["恐嚇野獸"] = true,
		["變形術"] = true,
		["變豬術"] = true,
		["變龜術"] = true,
		["悶棍"] = true,
		["誘惑"] = true,
		["休眠"] = true,
		["束縛不死生物"] = true,
		["冰凍陷阱效果"] = true,
		["放逐術"] = true,

		-- Skill
		["獵人印記"] = 2
	}
else -- enUS and anything else not translated
	PerfectAssistLocale = {
		-- CC 
		["Wyvern Sting"] = true,
		["Scare Beast"] = true,
		["Polymorph"] = true,
		["Polymorph: Pig"] = true,
		["Polymorph: Turtle"] = true,
		["Sap"] = true,
		["Seduction"] = true,
		["Hibernate"] = true,
		["Shackle Undead"] = true,
		["Freezing Trap Effect"] = true,
		["Banish"] = true,

		-- Skill
		["Hunter's Mark"] = 2
	}
end
