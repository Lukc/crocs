
serpent = require "serpent"
Layout = require "luigi.layout"

local allSales

with d = love.filesystem.getSaveDirectory!
	filename = d .. "/autosave.serpent"
	file = io.open filename

	if file
		content = file\read "*all"

		qapla, data = serpent.load content

		if qapla
			allSales = data
	else
		allSales = {}

autoExport = ->
	d = love.filesystem.getSaveDirectory!

	love.filesystem.createDirectory d

	filename = d .. "/autosave.serpent"

	with file = io.open filename, "w"
		file\write serpent.serialize allSales, {}
		file\close!

	with file = io.open d .. "/autosave.csv", "w"
		total = 0
		file\write "Nom,Menu,Simple,Sucré,Prix\n"

		for k, v in pairs allSales
			price = v.menu * 2.3 + v.simple * 1 + v.sugary * 0.5

			file\write "#{v.name},#{v.menu},#{v.simple},#{v.sugary},#{price} €\n"

		file\write ",,,,#{total}"
		file\close!

breadTypes = {"balek", "blanc", "complet"}
meatTypes = {"balek", "porc", "volaille", "végétarien"}

nextOrFirst = (array, element) ->
	unless element
		return array[1]

	for i = 1, #array
		if array[i] == element
			nIndex = i+1
			if nIndex > #array then
				nIndex = 1

			return array[nIndex]

getByClass = (e, c, matches) ->
	matches = matches or {}

	for i = 1, #e
		child = e[i]

		if child.class == c
			table.insert matches, child

		getByClass child, c, matches

	matches

setmetatable allSales, {
	__index: {
		add: (sale) =>
			self[#self + 1] = sale

			unless sale.breadTypes
				sale.breadTypes = {}

			unless sale.meatTypes
				sale.meatTypes = {}

			if sale.sugary > 0 and (sale.simple > 0 or sale.menu > 0)
				@\add {
					name: sale.name,
					menu: 0,
					simple: 0,
					sugary: sale.sugary,
					bananas: sale.bananas,
					time: sale.time
				}

				sale.sugary = 0

			autoExport!

			return sale
		remove: (sale) =>
			i = 1
			while i <= #self
				if self[i] == sale
					break

				i = i + 1

			while i <= #self
				self[i] = self[i + 1]

				i = i + 1

			autoExport!
	}
}

style = {
	validated: {
		background: {200, 255, 200}
	}
	dialog: {
		type: "submenu",
		width: 600,
		height: 400
	},
	dialogBody: {
		align: "left middle",
		padding: 4,
		wrap: true
	},
	dialogHead: {
		align: "middle center",
		height: 36,
		type: "panel"
		size: 16
	},
	dialogHeadClose: {
		height: 32,
		width: 32
	},
	"error-button": {
		background: {255, 128, 128}
	},
	"sugary": {
		background: {200, 255, 200}
	}
	salesList: {
		padding: 0
	}
	sale: {
		margin: 0
	}
	salePair: {
		margin: 0
		background: {200, 200, 200}
	}
	saleName: {
		size: 20
	}
}

genStepperValues = ->
	values = {}

	for i = 0, 10
		table.insert values, {value: i, text: tostring i}

	return unpack values

crocsConfigurator = (sale) ->
	lines = {
		flow: "y"
	}

	crocsCount = sale.menu * 2 + sale.simple + sale.sugary

	-- FIXME: Remove meat selection for pure sugar meals.
	for i = 1, crocsCount
		table.insert lines, {
			flow: "x",
			style: if i > (sale.menu * 2 + sale.simple) then
				"sugary"
			else
				"normal",
			{},
			{
				type: "button",
				text: sale.breadTypes[i],
				class: "bread",
				style: unless sale.breadTypes[i]
					"error-button"
				index: i
			},
			if i > (sale.menu * 2 + sale.simple) then
				{
				}
			else
				{
					type: "button",
					text: sale.meatTypes[i],
					class: "meat",
					style: unless sale.meatTypes[i]
						"error-button"
					index: i
				}
			{
				width: 160
			}
		}

	unpack lines

updateSalesList = (layout) ->
	totalSalty = 0
	totalSugary = 0

	with list = layout.salesList
		while #list > 0
			list[#list] = nil

		isPair = false
		for _, sale in pairs allSales
			totalSalty += sale.simple + sale.menu * 2
			totalSugary += sale.sugary

			with line = list\addChild {
				type: "panel",
				flow: "y",
				height: "auto",
				style: if isPair
					"salePair"
				else
					"sale",
				{
					flow: "x",
					height: 32,
					{
						text: sale.name,
						style: "saleName"
					},
					{
						text: sale.simple,
						align: "center"
					},
					{
						text: sale.menu,
						align: "center"
					},
					{
						text: sale.sugary,
						align: "center"
					},
					{
						text: sale.bananas,
						align: "center"
					},
					{
						type: "check",
						value: sale.paid,
						text: "#{sale.simple * 1 + sale.menu * 2.3 + sale.sugary * 0.5} €",
						style: sale.validated and "validated" or nil
					},
					{
						flow: "x",
						width: 160,
						{
							type: "button",
							text: "Validate",
							height: 28
						},
						{
							type: "button",
							text: "Remove",
							height: 28
						}
						height: 32
					},
				},
				crocsConfigurator sale
			}
				-- FIXME: write a few getChildBy* and use that.
				checkBox = list[#list][1][6]

				checkBox\onChange (e) ->
					unless sale.validated
						sale.paid = e.target.value
					else
						updateSalesList layout

				buttons = list[#list][1][7]
				validateButton = buttons[1]
				removeButton = buttons[2]

				removeButton\onPress ->
					allSales\remove sale

					updateSalesList layout

				validateButton\onPress ->
					if sale.paid
						sale.validated = true

						updateSalesList layout

				for _, t in pairs getByClass line, "bread"
					t\onPress (e)  ->
						e.target.text = nextOrFirst breadTypes, e.target.text
						sale.breadTypes[e.target.index] = e.target.text

						e.target.style = nil

				for _, t in pairs getByClass line, "meat"
					t\onPress (e)  ->
						e.target.text = nextOrFirst meatTypes, e.target.text
						sale.meatTypes[e.target.index] = e.target.text

						e.target.style = nil

			isPair = not isPair


		list\addChild {}

	layout.infoBarTotals.text = "#{totalSalty} crocs, #{totalSugary} crocs sucrés"

exportDialog = Layout {
	style: "dialog",
	flow: "y",
	width: 400,
	height: 80,
	{
		style: "dialogHead",
		text: "Export",
		{
			type: "button",
			style: "dialogHeadClose",
			text: "x",
			id: "closeButton"
		}
	},
	{
		style: "dialogBody",
		flow: "x",
		{
			type: "text",
			value: os.date "%Y-%m-%d.serpent",
			id: "fileNameInput"
		},
		{
			type: "button",
			width: 160,
			text: "Save!",
			id: "saveButton"
		}
	}
}

with exportDialog
	.saveButton\onPress ->
		file = io.open .fileNameInput.value, "w"
		file\write serpent.serialize allSales, {}
		file\close!

		exportDialog\hide!

	.closeButton\onPress ->
		exportDialog\hide!

	\setStyle style

layout = Layout {
	type: "panel",
	flow: "y"
	{
		type: "panel",
		flow: "x",
		{
			type: "panel",
			text: "Nom"
		},
		{
			type: "panel",
			text: "Simple"
		},
		{
			type: "panel",
			text: "Menu"
		},
		{
			type: "panel",
			text: "Sucré"
		},
		{
			type: "panel",
			text: "Bananes"
		},
		{
			type: "panel",
			text: "A payé",
		},
		{
			type: "panel",
			width: 160
		}
		height: 28
	}
	{
		type: "panel",
		flow: "x",
		{
			type: "text",
			id: "newSaleName"
		},
		{
			type: "stepper",
			id: "newSaleSimple",
			genStepperValues!
		},
		{
			type: "stepper",
			id: "newSaleMenu",
			genStepperValues!
		},
		{
			type: "stepper",
			id: "newSaleSugary",
			genStepperValues!
		},
		{
			type: "stepper",
			id: "newSaleBananas",
			genStepperValues!
		},
		{
			type: "check",
			id: "newSalePaid"
		},
		{
			width: 160,
			type: "button",
			text: "Add",
			id: "newSalesButton"
		},
		height: 40,
		minheight: 40
	},
	{
		-- FIXME: replace with a purely aesthetic separator.
		type: "sash",
	},
	{
		flow: "x",
		height: false,
		{
			id: "salesList",
			style: "salesList",
			type: "panel",
			scroll: true
		},
		{
			flow: "y",
			id: "salesSlider",
			type: "slider",
			width: 32,
			height: false
		}
	},
	{
		type: "sash",
	},
	{
		id: "infoBar",
		type: "panel",
		height: 40,
		minheight: 40,
		flow: "x",
		{
			id: "infoBarTotals"
			text: "data will comez hear (available stocks list)",
		},
		{
			type: "button",
			text: "Export",
			id: "exportButton",
			width: 160
		}
	}
}

with layout
	.salesSlider\onChange (e) ->
		childrenHeight = 0
		for _, child in ipairs e.target
			childrenHeight += child\calculateDimension "height"

		.salesList.scrollY = (1 - e.value) * (.salesList\getContentHeight! - .salesList\getHeight!)

		.salesList\reshape!

	.newSalesButton\onPress ->
		print allSales\add {
			time:    os.time!,
			name:    .newSaleName.value,
			simple:  .newSaleSimple.value,
			menu:    .newSaleMenu.value,
			sugary:  .newSaleSugary.value,
			bananas: .newSaleBananas.value,
			paid:    .newSalePaid.value
		}

		updateSalesList layout

	.exportButton\onPress ->
		exportDialog\show!

	\onWheelMove (e) ->
		.salesSlider.value = 1 - .salesList.scrollY / (.salesList\getContentHeight! - .salesList\getHeight!)

	\setStyle style
	\setTheme require "luigi.theme.light"

	updateSalesList layout

	\show!

--love.keypressed = (key) ->
--	if key == "down"
--		layout.salesList.scrollY += 100
--		layout.salesList\reshape!
--	elseif key == "up"
--		layout.salesList.scrollY -= 100
--		layout.salesList\reshape!

