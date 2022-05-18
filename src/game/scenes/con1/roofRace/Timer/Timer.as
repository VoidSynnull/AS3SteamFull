package game.scenes.con1.roofRace.Timer
{
	import flash.text.TextField;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Timer extends Component
	{
		public var time:TimeData;
		public var endTime:TimeData;
		public var display:TextField;
		public var format:String;
		public var active:Boolean;
		public var scale:Number;
		public var timesUp:Signal;
		public var showMiliSeconds:Boolean;
		public var showHours:Boolean;
		public var invalidate:Boolean;
		
		/*
		this component allows for dynamic keeping track of time
		can start, stop, and even rewind at different speeds
		can be formatted to work like a clock or a stop watch
		*/
		
		public function Timer(display:TextField, format = TIMER, scale:Number = 1, start:Boolean = true)
		{
			this.display = display;
			this.format = format;
			this.scale = scale;
			active = start;
			time = new TimeData();
			timesUp = new Signal(Timer);
			invalidate = true;
		}
		
		public function start():void
		{
			active = true;
		}
		
		public function stop():void
		{
			active = false;
		}
		
		public function setTime(seconds:Number=0, minutes:uint = 0, hours:uint = 0):void
		{
			time.setTimeData(seconds, minutes, hours);
			invalidate = true;
		}
		
		public function setEndTime(seconds:Number=0, minutes:uint = 0, hours:uint = 0):void
		{
			endTime.setTimeData(seconds, minutes, hours);
		}
		
		public function toString():String
		{
			var string:String ="";
			
			var strHours:String = formatTimeToString(time.hours);
			var strMins:String = formatTimeToString(time.minutes);
			var strSecs:String = formatTimeToString(time.seconds);
			var strMili:String = formatTimeToString(int(time.miliseconds * 100));
			
			if(showHours)
				string += strHours+":";
			
			string +=strMins+":"+strSecs;
			
			if(showMiliSeconds)
				string += ":"+strMili;
			
			return string;
		}
		
		private function formatTimeToString(time:int):String
		{
			var str:String;
			if(time < 10)
				str = "0"+time;
			else
				str = ""+time;
			return str;
		}
		
		public static const CLOCK:String = "clock";// 12 Am - 12 PM
		public static const TIMER:String = "timer";// hours are endless
	}
}