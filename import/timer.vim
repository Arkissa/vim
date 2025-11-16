vim9script

export class Timer
	var _id: number
	var _pause: bool
	var _stoped: bool
	var _opt: dict<any> = {}

	def new(delay: number, F: func(Timer), repeat: number = 1)
		this._opt = {
			delay: delay,
			repeat: repeat,
			Callback: (_: number) => {
				F(this)
			},
		}
	enddef

	def Start()
		this._stoped = false
		this._id = timer_start(this._opt.delay, this._opt.Callback, {repeat: this._opt.repeat})
	enddef

	def Started(): bool
		return !this.Info()->empty()
	enddef

	def Reset()
		timer_stop(this._id)
		this.Start()
	enddef

	def Toggle()
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

	def Info(): list<any>
		return timer_info(this._id)
	enddef
endclass
