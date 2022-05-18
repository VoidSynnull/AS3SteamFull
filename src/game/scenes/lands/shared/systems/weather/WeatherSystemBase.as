package game.scenes.lands.shared.systems.weather {
	
	import flash.display.DisplayObject;
	
	import ash.core.System;
	
	
	public class WeatherSystemBase extends System {

		public function fade():void {}
		//public function hide():void {}
		//public function show():void {}

		/**
		 * true if the weather has effectively stopped. using this to control
		 * the weather systems from the master realmsWeather system.
		 */
		protected var _stopped:Boolean;
		protected var weatherClip:DisplayObject;

		/**
		 * get a display object that can be faded in/out when the weather isn't suppose to display.
		 */
		public function getWeatherClip():DisplayObject { return this.weatherClip; }

		public function get stopped():Boolean {
			return this._stopped;
		}
		public function set stopped( b:Boolean ):void {
			this._stopped = b;
		}

	} // class
	
} // package