package game.scenes.deepDive1.shared.data
{
	import flash.display.MovieClip;

	public class FishData
	{
		public function FishData()
		{
		}
		
		public var type:String;
		public var component:Class;
		public var asset:String;
		public var clip:MovieClip;
		public var segmentAsset:String;
		public var tailAsset:String;
		public var scale:Number;
		public var level:int;
		public var maxVelocity:*;
		public var minVelocity:*;
		public var acceleration:Number;
		public var friction:Number;
		public var maxDamage:Number;
		public var impactDamage:Number;
		public var projectileDamage:Number;
		public var ignoreOffscreenSleep:Boolean;
		public var targetOffset:Number;
		public var followTarget:Boolean;
		public var faceTarget:Boolean;
		public var rotationEasing:Number;
		public var value:Number;
		public var attackDistance:Number;
		public var lifetime:Number;
		public var children:Number;
	}
}