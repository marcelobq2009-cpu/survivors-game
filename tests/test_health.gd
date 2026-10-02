extends GutTest
## Dano, cura, morte e invencibilidade (Health) + stats por nome (StatUtils).


func test_take_damage_reduces_health() -> void:
	var h := Health.new(100.0)
	assert_eq(h.take_damage(30.0), 30.0)
	assert_eq(h.current, 70.0)


func test_damage_is_capped_at_current_and_kills() -> void:
	var h := Health.new(20.0)
	assert_eq(h.take_damage(50.0), 20.0)
	assert_true(h.is_dead())
	assert_eq(h.take_damage(5.0), 0.0, "morto nao leva mais dano")


func test_invincibility_blocks_damage_until_it_ends() -> void:
	var h := Health.new(100.0, 0.5)
	h.take_damage(10.0)
	assert_true(h.is_invincible())
	assert_eq(h.take_damage(10.0), 0.0)
	h.update(0.6)
	assert_false(h.is_invincible())
	assert_eq(h.take_damage(10.0), 10.0)
	assert_eq(h.current, 80.0)


func test_heal_is_capped_at_max() -> void:
	var h := Health.new(100.0)
	h.take_damage(30.0)
	h.heal(50.0)
	assert_eq(h.current, 100.0)


func test_set_max_adds_difference_to_current() -> void:
	var h := Health.new(100.0)
	h.take_damage(50.0)
	h.set_max(120.0)
	assert_eq(h.max_value, 120.0)
	assert_eq(h.current, 70.0)


func test_stat_utils_add_and_multiply() -> void:
	var s := PlayerStats.new()
	s.move_speed = 200.0
	assert_true(s.apply(&"move_speed", 20.0, false))
	assert_eq(s.move_speed, 220.0)
	assert_true(s.apply(&"cooldown_mult", 0.5, true))
	assert_eq(s.cooldown_mult, 0.5)


func test_stat_utils_keeps_ints_as_ints() -> void:
	var w := Weapon.new()
	w.projectile_count = 1
	StatUtils.apply(w, &"projectile_count", 1.0, false)
	assert_eq(w.projectile_count, 2)
	assert_typeof(w.projectile_count, TYPE_INT)
	w.free()


func test_stat_utils_unknown_stat_returns_false() -> void:
	var s := PlayerStats.new()
	assert_false(StatUtils.apply(s, &"does_not_exist", 1.0, false))
