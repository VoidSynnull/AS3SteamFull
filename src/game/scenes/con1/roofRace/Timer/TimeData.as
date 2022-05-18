package game.scenes.con1.roofRace.Timer
{
	public class TimeData
	{
		public var miliseconds:Number;
		public var seconds:int;
		public var minutes:int;
		public var hours:int;
		
		public static const SIXTY:uint = 60;
		
		public function TimeData(seconds:Number = 0, minutes:int = 0, hours:int = 0)
		{
			setTimeData(seconds, minutes, hours);
		}
		
		// sets and formats time so that you can enter time in just seconds or as there seperate variables
		
		public function setTimeData(seconds:Number = 0, minutes:int = 0, hours:int = 0):void
		{
			var additionalMinutes:int = Math.min(seconds / SIXTY);
			minutes += additionalMinutes;
			this.seconds = seconds % SIXTY;
			miliseconds = seconds - additionalMinutes * 60 - this.seconds;
			hours += Math.min(minutes / SIXTY);
			this.minutes = minutes % SIXTY;
			this.hours = hours;
			
			trace(this.hours + " : " + this.minutes + " : " + this.seconds + " : " + this.miliseconds); 
		}
		
		public function setTimeFromData(timeData:TimeData):void
		{
			setTimeData(timeData.seconds, timeData.minutes, timeData.hours);
		}
		
		public function reachedTime(time:TimeData, forwards:Boolean):Boolean
		{
			if(seconds >= time.seconds && minutes >= time.minutes && hours >= time.hours && forwards)
				return true;
			if(seconds <= time.seconds && minutes <= time.minutes && hours <= time.hours && !forwards)
				return true;
			return false;
		}
		
		public function toSeconds():Number
		{
			return seconds + minutes * SIXTY + hours * SIXTY * SIXTY + miliseconds;
		}
	}
}