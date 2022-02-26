extends Control



onready var myName = $UpgradeName
onready var myDescription = $Desc/Label
onready var myChanges = $Changes/RichLabel
onready var myBuyButton : Button = $Purchase/Button
onready var myMoney = get_node("../")
var currently_selected_node

func _ready() -> void:
	myBuyButton.connect("button_down", self, "buy_button_pressed")
	pass

func UpdateInformation(var _title, var description, var formattedChanges, var is_purchased, var price, var upgrade_node):
	myName.text = _title
	myDescription.text = description
	myChanges.bbcode_text = formattedChanges
	#myChanges.append_bbcode(formattedChanges)
	currently_selected_node = upgrade_node
	if(is_purchased):
		#Set the text of the button to show it's already been bought & disable it
		myBuyButton.text = "PURCHASED"
		myBuyButton.disabled = true
		pass
	else:
		myBuyButton.text = "PRICE: " + str(price)
		myBuyButton.disabled = false
		pass
	pass

func buy_button_pressed():
	#Check if the price is within range
	#print("hi :-)")
	if currently_selected_node == null:
		return
	if currently_selected_node.is_bought:
		return
	if myMoney.try_buy_upgrade(currently_selected_node.upgrade_price):
		#If the upgrade was bought
		currently_selected_node.upgrade_bought()
		myMoney.check_visibility()
		pass
	pass





