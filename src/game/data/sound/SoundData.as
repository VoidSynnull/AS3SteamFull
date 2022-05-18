package game.data.sound 
{
	public class SoundData 
	{
		public function SoundData(asset:* = null, modifiers:Array = null)
		{
			if(asset) { this.asset = asset; }
			if(modifiers) { this.modifiers = modifiers; }
		}
		
		public var type:String;              // effects, ambient or music
		public var asset:*;                  // can be either a single asset or an array of assets
		public var event:String;
		public var triggeredByEvent:String;  // If this sound should play when an event is triggered
		public var action:String;
		public var id:String;
		public var loop:Boolean;
		public var fade:Boolean;             // Should this sound fade in and out, or start/stop immediately?
		public var exclusiveType:Boolean;    // If true, only one sound of this type will play on this entity at a time.  If other sounds of the same type are playing they will stop or fade.
		public var exclusive:Boolean;        // If true, ALL sounds on this entity will stop when a new sound plays on this entity.
		public var allowOverlap:Boolean;
		public var modifiers:Array;          // An array of all SoundModifer(s) that effect this sound's volume.
		public var baseVolume:Number = 1.0;    // If we need the volume to be different than the default.
		public var absoluteUrl:Boolean;
	}
}