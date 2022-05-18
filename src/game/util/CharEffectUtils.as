package game.util
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.Emitter;

	public class CharEffectUtils
	{
		/**
		 * Color character's parts, by default excludes mouth & eyes
		 * @param charEntity
		 * @param color
		 */
		public static function colorize( charEntity:Entity, color:Number, partsToColor:Vector.<String> = null, permanent:Boolean = false):void
		{
			// TODO :: do we want to exclude item?
			if( partsToColor == null )
			{
				// all parts except for mouth, eyes, hands, feet
				partsToColor = new<String>[
					CharUtils.SHIRT_PART,
					CharUtils.PANTS_PART,
					CharUtils.FACIAL_PART,
					CharUtils.MARKS_PART,
					CharUtils.PACK,
					CharUtils.HAIR,
					CharUtils.ITEM,
					CharUtils.OVERPANTS_PART,
					CharUtils.OVERSHIRT_PART];
			}
			
			// set skin color
			SkinUtils.setSkinPart( charEntity, SkinUtils.SKIN_COLOR, color, permanent );
			
			// color parts
			var i:int
			for (i = 0; i < partsToColor.length; i++) 
			{
				var partEntity:Entity = CharUtils.getPart(charEntity, partsToColor[i]);
				if (partEntity)
				{
					var clip:MovieClip = partEntity.get(Display).displayObject;
					ColorUtil.colorize(clip, color);
				}
			}
		}
		
		public static function electrify( charEntity:Entity, color:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function electrocute( charEntity:Entity, duration:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function glow( charEntity:Entity, color:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function transport( charEntity:Entity, color:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function torch( charEntity:Entity, color:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function phantom( charEntity:Entity, alpha:Number, glowColor:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function emitParticles( charEntity:Entity, effect:Emitter ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function atomPower( charEntity:Entity, color:Number, pulseRate:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function bobbleHead( charEntity:Entity, springValue:Number ):void
		{
			// Needs ot be filled implemented
		}
		
		public static function squash( charEntity:Entity, squashDuration:Number, remainSquashedDuration:Number ):void
		{
			// Needs ot be filled implemented
		}
	}
}