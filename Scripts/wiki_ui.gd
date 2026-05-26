extends PanelContainer

@export var richtextlabel: RichTextLabel
@export var label_h: Label
@export var tree: Tree

func _ready():
	visible = false

func create_tree(wiki):
	tree.clear()

	var root = tree.create_item()
	root.set_text(0, "WIKI")

	for category in wiki.entries.keys():
		var category_item = tree.create_item(root)
		category_item.set_text(0, category)

		for entry in wiki.entries[category]:
			var entry_item = tree.create_item(category_item)
			entry_item.set_text(0, entry["title"])
			entry_item.set_metadata(0, entry)
			entry_item.collapsed = true
			
			
		category_item.collapsed = true
	tree.deselect_all()
	tree.item_selected.connect(_on_item_selected)

func _on_item_selected():
	var item = tree.get_selected()
	var data = item.get_metadata(0)
	if data:
		label_h.text = data["title"]
		richtextlabel.text = data["content"]
