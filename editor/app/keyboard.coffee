# TODO docs

define (require) ->
	KEY_CODE_MAP = {
		13: 'enter'
		27: 'escape'
		48: '0'
		49: '1'
		50: '2'
		51: '3'
		52: '4'
		53: '5'
		54: '6'
		55: '7'
		56: '8'
		57: '9'
		65: 'a'
		66: 'b'
		67: 'c'
		68: 'd'
		69: 'e'
		70: 'f'
		71: 'g'
		72: 'h'
		73: 'i'
		74: 'j'
		75: 'k'
		76: 'l'
		77: 'm'
		78: 'n'
		79: 'o'
		80: 'p'
		81: 'q'
		82: 'r'
		83: 's'
		84: 't'
		85: 'u'
		86: 'v'
		87: 'w'
		88: 'x'
		89: 'y'
		90: 'z'
	}

	# Dispatches key strokes to listeners based on current mode
	class KeyDispatcher
		constructor: () ->
			@_listeners = []

		addListener: ({mode, keyName, ctrl, alt, shift, onKey}) ->
			@_listeners.push {
				mode
				keyName
				ctrl: !!ctrl
				alt: !!alt
				shift: !!shift
				onKey
			}

		dispatch: (event, mode) ->
			keyName = KEY_CODE_MAP[event.keyCode]
			ctrl = event.ctrlKey
			alt = event.altKey
			shift = event.shiftKey

			foundListener = false

			# TODO switch to hashtable lookup if performance needed
			for ln in @_listeners
				if ln.mode is mode
					if ln.ctrl is ctrl and ln.alt is alt and ln.shift is shift
						if ln.keyName is keyName
							ln.onKey()
							foundListener = true

			if foundListener
				event.preventDefault()

			return

	return {KeyDispatcher}
