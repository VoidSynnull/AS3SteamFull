package game.data.ui 
{
	import com.greensock.easing.Strong;
	
	import flash.geom.Point;
	/**
	 * ...
	 * @author Bard
	 */
	public class TransitionData 
	{

		import game.util.Utils;

		/**
		* Returns an instance populated with set of properties of your choosing.
		*
		* @example The following code creates a new TransitionData with four properties specified
		*
		*	<listing version="3.0">
		*
		*	var myTD:TransitionData = TransitionData.instanceFromInitializer(
		*		{
		*			startPos:	new Point(100,  100),
		*			endPos:		new Point(1000, 100);
		*			duration:	16,
		*			ease:	Elastic.easeOut
		*		}
		*	);
		*
		*	</listing>
		*/
		public static function instanceFromIntializer(spec:Object):TransitionData {
			return Utils.overlayObjectProperties(spec, new TransitionData()) as TransitionData;
		}

		public function TransitionData()
		{
			startPos = new Point();
			endPos = new Point();
			this.ease = Strong.easeOut;
		}
		
		public function init( startx:int = 0, starty:int = 0, endx:int = 0, endy:int = 0, ease:Function = null, startAlpha:Number = 1, endAlpha:Number = 1, startScale:Number = 1, endScale:Number = 1 ):void
		{
			this.startPos.x 	= startx;
			this.startPos.y 	= starty;
			this.endPos.x 	= endx;
			this.endPos.y 	= endy;
			this.ease 	= ease;
			this.startAlpha = startAlpha;
			this.endAlpha = endAlpha;
			this.startScale = startScale
			this.endScale = endScale
		}
		
		public var startPos:Point;
		public var endPos:Point;
		public var customTweenObject:Object;
		public var startAlpha:Number = 1;
		public var endAlpha:Number = 1;
		public var startScale:Number = 1;
		public var endScale:Number = 1;
		
		public var ease:Function;	// TODO :: using a greensock for now, will wrap in future
		
		public var duration:Number = 1; // duration in seconds

		public function clone():TransitionData {
			var dupe:TransitionData = new TransitionData();
			dupe.init(startPos.x, startPos.y, endPos.x, endPos.y, ease, startAlpha, endAlpha, startScale, endScale);
			dupe.duration = duration;
			return dupe;
		}

		/**
		 * returns a duplicate transition, but with the start and end positions switched
		 * @return
		 */
		public function duplicateSwitch( ease:Function = null ):TransitionData
		{
			if(ease == null)
			{
				ease = this.ease;
			}
			
			var transition:TransitionData = new TransitionData();
			
			transition.startPos.x 	= endPos.x;
			transition.startPos.y 	= endPos.y;
			transition.endPos.x 	= startPos.x;
			transition.endPos.y 	= startPos.y;
			transition.ease = ease;
			transition.duration = duration;
			transition.startAlpha = endAlpha;
			transition.endAlpha = startAlpha;
			transition.endScale = startScale;
			transition.startScale = endScale;
			return transition;
		}
	}
}