vim9script

export class Timer
	var _id: number
	var _pause: bool
	var _stoped: bool
	const _delay: number
	const _callback: func(number)

	def new(this._delay, F: func(Timer), repeat: number = 1)
		def Callback(_: number)
			F(this)
		enddef

		this._callback = Callback
		this._id = timer_start(this._delay, this._callback, {repeat: repeat})
	enddef

	def Reset()
		timer_stop(this._id)
		this._id = timer_start(this._delay, this._callback)
	enddef

	def Pause()
		this._pause = !this._pause
		timer_pause(this._id, this._pause ? 0 : 1)
	enddef

	def Stoped(): bool
		return this._stoped
	enddef

	def Stop()
		timer_stop(this._id)
		this._stoped = true
	enddef

	def Info(): dict<any>
		return timer_info(this._id)
	enddef
endclass
