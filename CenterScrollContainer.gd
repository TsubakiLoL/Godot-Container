@tool
extends Container
##自动定位中心的横向滚动容器
class_name CenterScrollContainer


##tool button指定移动的index
@export_range(0,100) var button_to_index:int=0
##在编辑器测试移动效果
@export_tool_button("移动") var call:Callable=func():
	scroll_to_index(button_to_index)



##x相对于高度的缩放
@export var child_x_scale:float=1
##滚动计数
@export var scroll_range:float=0:
	set(value):
		if scroll_range!=value:
			scroll_range=value
			remap_children()


##字节点最小缩放
@export var child_scale_min:float=0.5
##子节点到达最小缩放的衰减距离
@export var child_distance_min:float=1000

##子节点之间的间隔（当子节点都为最大时）
@export var separation:float=10

##定位子节点归位的速度
@export var move_to_center_speed:float=4000
##归位动画的补间模式
@export var move_to_center_type:Tween.TransitionType=Tween.TransitionType.TRANS_LINEAR
##子节点的x大小
var child_x_max:float:
	get():
		return size.y*child_x_scale
##当前容器的中心
var container_center:Vector2:
	get():
		return size/2

##获取对应坐标子节点的中心
func get_index_center(index:int)->Vector2:
	return container_center-Vector2(scroll_range,0)+Vector2(index*(child_x_max+separation),0)
##获取对应坐标子节点的大小
func get_index_size(index:int)->Vector2:
	return Vector2(child_x_max,size.y)*lerp(child_scale_min,1.0,clamp(1-abs(scroll_range-index*(child_x_max+separation))/child_distance_min,child_scale_min,1))

func _ready() -> void:
	resized.connect(_on_resized)
	
	pass

##当前在这一次按下到松开的过程中是否进行了滚动（用来判断上层的输入是否有效）
var has_dragged:bool=false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if auto_center_tween!=null:
			auto_center_tween.kill()
			auto_center_tween=null
		scroll_range-=event.relative.x
		has_dragged=true
	elif event is InputEventScreenTouch:
		if not event.pressed:
			if has_dragged:
				auto_center_tween=create_tween()
				auto_center_tween.set_trans(move_to_center_type)
				var nearest_index=get_nearest_index(scroll_range,child_x_max+separation,get_child_count())
				var to_range=get_index_range(nearest_index,child_x_max+separation)
				var spend_time=abs(to_range-scroll_range)/move_to_center_speed
				auto_center_tween.tween_property(self,"scroll_range",to_range,spend_time)
		else:
			has_dragged=false
	accept_event()
# 布局子节点
func _notification(what):
	#当接到重新排布指令时进行排布
	if what == NOTIFICATION_SORT_CHILDREN:
		
		remap_children()
func _on_resized():
	if auto_center_tween is Tween:	
		auto_center_tween.kill()
		auto_center_tween=null
	scroll_range=get_index_range(get_now_nearest_index(),child_x_max+separation)
		
	pass

##自动归位到最近index的tween
var auto_center_tween

##重新排布子节点
func remap_children():
	var children:Array[Node]=get_children()
	var _index:int=0
	for i in children:
		if i is Control:
			fit_child_in_rect(i,
			generate_rect2_from_center_and_size(
				get_index_center(_index),
				get_index_size(_index)
				)
			)
			_index+=1


##工具，从中心点和大小生成Rect2
func generate_rect2_from_center_and_size(center:Vector2,rect_size:Vector2)->Rect2:
	var left_up=center-rect_size/2
	return Rect2(left_up,rect_size)

##获取对应的range对应的最近下标
func get_nearest_index(range:float,distance:float,max_index:int)->int:
	
	var floor:int=floor(range/distance-0.5)+1
	return clamp(floor,0,max_index-1)
##获取对应index的range
func get_index_range(index:int,distance:float)->float:
	return index*distance
##获取当前最近的下标
func get_now_nearest_index()->int:
	return get_nearest_index(scroll_range,child_x_max+separation,get_child_count())

##动画滚动到对应下标
func scroll_to_index(index:int):
	if auto_center_tween!=null:
		auto_center_tween.kill()
	auto_center_tween=create_tween()
	var to_range=get_index_range(index,child_x_max+separation)
	var spend_time=abs(to_range-scroll_range)/move_to_center_speed
	auto_center_tween.tween_property(self,"scroll_range",to_range,spend_time)
	pass
