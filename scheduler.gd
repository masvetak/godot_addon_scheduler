extends Node

@export var min_ticks_msec_period: int = 1000

var thread: Thread = Thread.new()
var mutex: Mutex = Mutex.new()

var _time_ticks_msec: int = 0

var _tickers: Array = []
var _tickers_id: int = 0

var _timeouts: Array = []
var _timeouts_id: int = 0

var _events: Array = []
var _events_id: int = 0

# ------------------------------------------------------------------------------
# Build-in methods
# ------------------------------------------------------------------------------

func _ready() -> void:
	thread.start(_thread_loop)

# ------------------------------------------------------------------------------
# Public methods
# ------------------------------------------------------------------------------

func set_ticker(callable: Callable, period_msec: int, execute_immediately: bool = true, ticker_name: String = "") -> int:
	mutex.lock()
	
	# increment id
	_tickers_id = _tickers_id + 1
	
	# add ticker
	var ticker: Dictionary = {
		'id': _tickers_id,
		'callable': callable,
		'period': period_msec,
		'handled_at': -INF if execute_immediately else Time.get_ticks_msec(),
		'name': ticker_name
	}
	_tickers.append(ticker)
	print("[SCHEDULER] added ticker id=%s with period %d msec" % [_tickers_id, period_msec])
	mutex.unlock()
	
	return _tickers_id

func cancel_ticker(id: int) -> void:
	mutex.lock()
	
	var idx_to_remove: int = -1
	for idx in range(_tickers.size()):
		if _tickers[idx]['id'] == id:
			idx_to_remove = idx
			break
	if idx_to_remove != -1:
		_tickers.remove_at(idx_to_remove)
		print("[SCHEDULER] canceling ticker id=%s" % id)
	
	mutex.unlock()

func set_timeout(callable: Callable, timeout_msec: int, timeout_name: String = "") -> int:
	mutex.lock()
	
	# increment id
	_timeouts_id = _timeouts_id + 1
	
	# add timeout
	var timeout: Dictionary = {
		'id': _timeouts_id,
		'callable': callable,
		'timeout': timeout_msec,
		'started_at': Time.get_ticks_msec(),
		'name': timeout_name
	}
	_timeouts.append(timeout)
	print("[SCHEDULER] added timeout id=%s with timeout %d msec" % [_timeouts_id, timeout_msec])
	mutex.unlock()
	
	return _timeouts_id

func cancel_timeout(id: int) -> void:
	mutex.lock()
	
	var idx_to_remove: int = -1
	for idx in range(_timeouts.size()):
		if _timeouts[idx]['id'] == id:
			idx_to_remove = idx
			break
	if idx_to_remove != -1:
		_timeouts.remove_at(idx_to_remove)
		print("[SCHEDULER] canceling timeout id=%s" % id)
	
	mutex.unlock()

# ------------------------------------------------------------------------------
# Private methods
# ------------------------------------------------------------------------------

func _thread_loop() -> void:
	while true:
		if Time.get_ticks_msec() - _time_ticks_msec > min_ticks_msec_period:
			_time_ticks_msec = Time.get_ticks_msec()
			_handler()
		await get_tree().create_timer(min_ticks_msec_period / 1000).timeout

func _handler() -> void:
	_handle_tickers()
	_handle_timeouts()

func _handle_tickers() -> void:
	mutex.lock()
	
	for ticker in _tickers:
		if Time.get_ticks_msec() - ticker['handled_at'] > ticker['period']:
			ticker['callable'].call_deferred()
			ticker['handled_at'] = Time.get_ticks_msec()
	
	mutex.unlock()

func _handle_timeouts() -> void:
	mutex.lock()
	
	var handled_timeout_ids_list: Array = []
	for idx in _timeouts.size():
		var timeout: Dictionary = _timeouts[idx]
		if Time.get_ticks_msec() - timeout['started_at'] > timeout['timeout']:
			timeout['callable'].call_deferred()
			handled_timeout_ids_list.append(idx)
	
	for handled_timeout_idx in handled_timeout_ids_list:
		_timeouts.remove_at(handled_timeout_idx)
	
	mutex.unlock()
