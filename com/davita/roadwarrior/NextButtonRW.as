﻿package com.davita.roadwarrior {
	import flash.display.*;
	import flash.events.*;

	/**
	 * ...
	 * @author Ian Kennedy
	 */
	public class NextButtonRW extends MovieClip {
		// ---------------------------------------
		// PRIVATE VARIABLES
		// ---------------------------------------
		private var _frameLabel : String;

		// ---------------------------------------
		// CONSTRUCTOR
		// ---------------------------------------
		public function NextButtonRW() : void {
			if (stage) {
				init();
			} else {
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}

		// ---------------------------------------
		// GETTER / SETTERS
		// ---------------------------------------
		public function get frameLabel() : String {
			return _frameLabel;
		}

		public function set frameLabel(value : String) : void {
			trace("NextButtonRW::set frameLabel(" + value + ")");
			_frameLabel = value;
		}

		// ---------------------------------------
		// PRIVATE METHODS
		// ---------------------------------------
		private function init(e : Event = null) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			this.addEventListener(MouseEvent.CLICK, nextButtonClickHandler);
			this.buttonMode = true;
			this.useHandCursor = true;
		}

		private function nextButtonClickHandler(event : MouseEvent) : void {
			trace("NextButtonRW::nextButtonClickHandler()");
			if ((_frameLabel != null) && (_frameLabel != "")) {
				this.parent.gotoAndStop(_frameLabel);
			} else {
				this.parent.nextFrame();
			}
		}
	}
}