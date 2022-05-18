package engine.util
{   
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.events.Event;

    public class Command
    {
        public static function create( handler:Function, ...args ):Function
        {
            return function(...innerArgs):*
            {
                return handler.apply( this, innerArgs.concat( args ) );
            }
        }

		public static function callAfterDelay(func:Function, millisToWait:uint, ...args):Timer
		{
			var t:Timer = new Timer(millisToWait, 1);
			callWithTimer.apply(null, [func, t].concat(args));
			return t;
		}

		public static function callWithTimer(func:Function, timer:Timer, ...args):void
		{
			timer.addEventListener(TimerEvent.TIMER,
				function (e:Event):void {
					if (timer) {
						if (timer.running) {
							func.apply(null, args);
						}
					}
					timer = null;
				}
			);
			timer.start();
		}

	}
}
