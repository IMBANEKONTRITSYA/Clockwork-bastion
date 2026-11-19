extends GutTest
## Пул эффектов: без выделения памяти, переиспользование, предел.


func test_pool_reuses_objects_after_expiry() -> void:
	var pool: EffectPool = EffectPool.new(2)
	var a: EffectPool.Effect = pool.spawn(Vector2.ZERO, Vector2.ONE, 0.1)
	pool.update(0.2)
	assert_eq(pool.active_count(), 0)
	var b: EffectPool.Effect = pool.spawn(Vector2.ZERO, Vector2.ONE, 0.1)
	assert_same(a, b)


func test_pool_skips_when_full() -> void:
	var pool: EffectPool = EffectPool.new(2)
	pool.spawn(Vector2.ZERO, Vector2.ONE, 1.0)
	pool.spawn(Vector2.ZERO, Vector2.ONE, 1.0)
	assert_null(pool.spawn(Vector2.ZERO, Vector2.ONE, 1.0))
	assert_eq(pool.items.size(), 2)
