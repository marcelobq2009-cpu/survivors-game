extends GutTest
## XP e level-up (XpCurve + Progression).

var curve: XpCurve


func before_each() -> void:
	curve = XpCurve.new()
	curve.base = 5.0
	curve.growth = 10.0
	curve.exponent = 1.0


func test_curve_grows_with_level() -> void:
	assert_eq(curve.xp_to_next(1), 5)
	assert_eq(curve.xp_to_next(2), 15)
	assert_eq(curve.xp_to_next(3), 25)


func test_curve_never_below_one() -> void:
	curve.base = 0.0
	curve.growth = 0.0
	assert_eq(curve.xp_to_next(1), 1)


func test_add_xp_below_threshold_keeps_level() -> void:
	var p := Progression.new(curve)
	assert_eq(p.add_xp(4), 0)
	assert_eq(p.level, 1)
	assert_eq(p.xp, 4)


func test_add_xp_levels_up_and_keeps_leftover() -> void:
	var p := Progression.new(curve)
	assert_eq(p.add_xp(7), 1)
	assert_eq(p.level, 2)
	assert_eq(p.xp, 2)


func test_big_xp_gives_multiple_levels() -> void:
	var p := Progression.new(curve)
	# 5 (nv1->2) + 15 (nv2->3) + 3 de sobra
	assert_eq(p.add_xp(23), 2)
	assert_eq(p.level, 3)
	assert_eq(p.xp, 3)


func test_negative_xp_is_ignored() -> void:
	var p := Progression.new(curve)
	p.add_xp(-10)
	assert_eq(p.xp, 0)


func test_project_curve_resource_loads() -> void:
	var res := load("res://data/player/xp_curve.tres") as XpCurve
	assert_not_null(res)
	assert_gt(res.xp_to_next(10), res.xp_to_next(1))
