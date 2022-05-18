package game.managers {
import flash.events.TimerEvent;

/**
 * The perfect timekeeping device.
 * @author Rich Martin
 * 
 */
public class WallClock 
{
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import org.osflash.signals.Signal;

	public static const DEFAULT_INTERVAL:Number = 300;	// five minutes, in seconds

	public var chime:Signal;
	
	private var birth:Date;
	private var startInstant:int;
	private var lastInstant:int;
	private var lastTimestamp:Date;
	private var tickTimer:Timer;

	public function WallClock(intervalInSeconds:Number = DEFAULT_INTERVAL) 
	{
		var intervalInMilleseconds:Number = intervalInSeconds * 1000;
		chime = new Signal();
		tickTimer = new Timer(intervalInMilleseconds);
		tickTimer.addEventListener(TimerEvent.TIMER, onTickTimer);
		startClock();
	}

	public function get interval():Number {	return tickTimer.delay; }
	public function set interval(newInterval:Number):void {
		tickTimer.delay = newInterval;
		tickTimer.reset();
		tickTimer.start();
	}

	public function get thisInstant():uint {
		lastInstant = getTimer();
		return lastInstant;
	}

	public function get currentTimestamp():Date {
		lastTimestamp = new Date();
		return lastTimestamp;
	}

	public function get age():uint {
		return currentTimestamp.time - birth.time;
	}
	
	public function start() : void
	{
		tickTimer.start();
	}
	
	public function stop() : void
	{
		tickTimer.stop();
	}
	
	
	protected function startClock():void {
		birth = new Date();
		startInstant = getTimer();
		tickTimer.start();
	}

	protected function onTickTimer(e:TimerEvent):void {
		chime.dispatch();
	}
	
	
	
}

}
