package game.utils
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.components.entity.MotionMaster;
	import game.util.DataUtils;

	public class MotionWrapUtils
	{
		public function MotionWrapUtils()
		{
		}
		
		public static function CreateMotionMaster(xml:XML, progressClip:MovieClip = null):MotionMaster
		{
			var motionMaster:MotionMaster;
			
			if( xml )
			{
				motionMaster = new MotionMaster();
				// DETERMINE DIRECTION
				motionMaster.direction = DataUtils.getString( xml.direction );
				motionMaster.axis = DataUtils.getString( xml.axis );
				
				var modifier:Number = motionMaster.direction == "+" ? 1 : -1;
				
				// DETERMINE AXIS
				if( motionMaster.axis == "x" )
				{
					motionMaster.velocity = new Point( DataUtils.useNumber( xml.velocity, 0 ) * modifier, 0 );
					motionMaster.minVelocity = new Point( DataUtils.useNumber( xml.minVelocity, 0 ), 0 ); 
					motionMaster.maxVelocity = new Point( DataUtils.useNumber( xml.maxVelocity, 0 ), 0 ); 
					motionMaster.acceleration = new Point( DataUtils.useNumber( xml.acceleration, 0 ) * modifier, 0 ); 					
				}
				else
				{
					motionMaster.velocity = new Point( 0, DataUtils.useNumber( xml.velocity, 0 ) * modifier );
					motionMaster.minVelocity = new Point( 0, DataUtils.useNumber( xml.minVelocity, 0 )); 
					motionMaster.maxVelocity = new Point( 0, DataUtils.useNumber( xml.maxVelocity, 0 )); 
					motionMaster.acceleration = new Point( 0, DataUtils.useNumber( xml.acceleration, 0 ) * modifier ); 
				}
				
				motionMaster.goalDistance = DataUtils.useNumber( xml.goalDistance, NaN );
				//motionMaster.bgOffset = DataUtils.useNumber( xml.bgOffset, 0 );
				
				// setup progress bar
				if (progressClip)
				{
					motionMaster.progressDisplay = progressClip;
					motionMaster.progressLength = motionMaster.axis == "x"? progressClip.width:progressClip.height;
				}
			}
			
			return motionMaster;
		}
	}
}